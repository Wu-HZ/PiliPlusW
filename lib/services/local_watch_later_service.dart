import 'package:PiliMinus/models/model_owner.dart';
import 'package:PiliMinus/models_new/later/list.dart';
import 'package:PiliMinus/utils/storage.dart';

/// Local watch later storage service using Hive
/// Replaces the login-required remote watch later API
class LocalWatchLaterService {
  LocalWatchLaterService._();

  /// Generate a unique key for a watch later item
  /// Format: "aid_{aid}" or "bvid_{bvid}"
  static String _generateKey(int? aid, String? bvid) {
    if (aid != null && aid != 0) {
      return 'aid_$aid';
    }
    return 'bvid_$bvid';
  }

  /// Convert dynamic map to Map<String, dynamic> recursively
  static Map<String, dynamic> _convertMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data.map((key, value) => MapEntry(key, _convertValue(value)));
    }
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), _convertValue(value)));
    }
    return {};
  }

  /// Convert dynamic value recursively
  static dynamic _convertValue(dynamic value) {
    if (value is Map) {
      return _convertMap(value);
    }
    if (value is List) {
      return value.map(_convertValue).toList();
    }
    return value;
  }

  /// Add a video to watch later
  static Future<void> add(LaterItemModel item) async {
    final key = _generateKey(item.aid, item.bvid);
    await GStorage.watchLater.put(key, item.toJson());
    await GStorage.watchLater.flush();
  }

  /// Add video to watch later from minimal data (used when adding from video pages)
  static Future<void> addFromVideo({
    required int? aid,
    required String? bvid,
    required int? cid,
    required String? title,
    required String? cover,
    required int? duration,
    required String? authorName,
    required int? authorMid,
    required String? authorFace,
  }) async {
    final key = _generateKey(aid, bvid);

    final item = LaterItemModel(
      aid: aid,
      bvid: bvid,
      cid: cid,
      title: title,
      pic: cover,
      duration: duration,
      owner: authorMid != null || authorName != null
          ? Owner(mid: authorMid, name: authorName, face: authorFace)
          : null,
      progress: 0,
      pubdate: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    await GStorage.watchLater.put(key, item.toJson());
    await GStorage.watchLater.flush();
  }

  /// Check if a video is in watch later
  static bool contains({int? aid, String? bvid}) {
    final key = _generateKey(aid, bvid);
    return GStorage.watchLater.containsKey(key);
  }

  /// Delete a watch later item by aid/bvid
  static Future<void> delete({int? aid, String? bvid}) async {
    final key = _generateKey(aid, bvid);
    await GStorage.watchLater.delete(key);
    await GStorage.watchLater.flush();
  }

  /// Delete multiple watch later items
  static Future<void> deleteMultiple(Iterable<LaterItemModel> items) async {
    final keys = items.map((item) => _generateKey(item.aid, item.bvid));
    await GStorage.watchLater.deleteAll(keys);
    await GStorage.watchLater.flush();
  }

  /// Clear all watch later items
  static Future<void> clear() async {
    await GStorage.watchLater.clear();
    await GStorage.watchLater.flush();
  }

  /// Get all watch later items with optional filtering and pagination
  /// [viewType]: 0 = all, 2 = unfinished only
  static List<LaterItemModel> getAll({
    int viewType = 0,
    int? limit,
    int offset = 0,
  }) {
    final allItems = <LaterItemModel>[];

    for (final key in GStorage.watchLater.keys) {
      final data = GStorage.watchLater.get(key);
      if (data != null) {
        try {
          final jsonMap = _convertMap(data);
          final item = LaterItemModel.fromJson(jsonMap);
          // Filter by viewType: 0 = all, 2 = unfinished (progress != -1 and progress < duration)
          if (viewType == 0 || _isUnfinished(item)) {
            allItems.add(item);
          }
        } catch (_) {
          // Skip invalid entries
        }
      }
    }

    // Sort by pubdate descending (most recently added first)
    allItems.sort((a, b) => (b.pubdate ?? 0).compareTo(a.pubdate ?? 0));

    // Apply pagination
    final startIndex = offset.clamp(0, allItems.length);
    final endIndex = limit != null
        ? (startIndex + limit).clamp(0, allItems.length)
        : allItems.length;

    return allItems.sublist(startIndex, endIndex);
  }

  /// Check if video is unfinished
  static bool _isUnfinished(LaterItemModel item) {
    if (item.progress == null || item.progress == -1) {
      return item.progress != -1; // -1 means completed
    }
    if (item.duration == null || item.duration == 0) {
      return true; // Unknown duration, consider unfinished
    }
    return item.progress! < item.duration!;
  }

  /// Get count of watch later items
  static int getCount({int viewType = 0}) {
    if (viewType == 0) {
      return GStorage.watchLater.length;
    }

    int count = 0;
    for (final key in GStorage.watchLater.keys) {
      final data = GStorage.watchLater.get(key);
      if (data != null) {
        try {
          final jsonMap = _convertMap(data);
          final item = LaterItemModel.fromJson(jsonMap);
          if (_isUnfinished(item)) {
            count++;
          }
        } catch (_) {}
      }
    }
    return count;
  }

  /// Update progress for a video in watch later
  static Future<void> updateProgress({
    required int? aid,
    required String? bvid,
    required int progress,
  }) async {
    final key = _generateKey(aid, bvid);
    final data = GStorage.watchLater.get(key);
    if (data != null) {
      try {
        final jsonMap = _convertMap(data);
        jsonMap['progress'] = progress;
        await GStorage.watchLater.put(key, jsonMap);
        await GStorage.watchLater.flush();
      } catch (_) {}
    }
  }

  /// Check if there are more items (for pagination)
  static bool hasMore({int viewType = 0, required int currentCount}) {
    return currentCount < getCount(viewType: viewType);
  }
}

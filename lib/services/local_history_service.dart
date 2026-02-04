import 'package:PiliMinus/models_new/history/history.dart';
import 'package:PiliMinus/models_new/history/list.dart';
import 'package:PiliMinus/utils/storage.dart';

/// Local history storage service using Hive
/// Replaces the login-required remote history API
class LocalHistoryService {
  LocalHistoryService._();

  /// Generate a unique key for a history item
  /// Format: "{business}_{oid}"
  static String _generateKey(String business, int oid) => '${business}_$oid';

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

  /// Add or update a history item
  static Future<void> addOrUpdate(HistoryItemModel item) async {
    final key = _generateKey(
      item.history.business ?? 'archive',
      item.history.oid ?? 0,
    );
    await GStorage.watchHistory.put(key, item.toJson());
    await GStorage.watchHistory.flush();
  }

  /// Add or update history from video playback data
  static Future<void> addFromPlayback({
    required int? aid,
    required String? bvid,
    required int? cid,
    required int? epid,
    required String? title,
    required String? cover,
    required int progress,
    required int duration,
    required String? authorName,
    required int? authorMid,
    required String? authorFace,
    String business = 'archive',
    int? seasonId,
  }) async {
    final oid = aid ?? 0;
    final key = _generateKey(business, oid);

    final item = HistoryItemModel(
      title: title ?? '',
      cover: cover,
      history: History(
        oid: oid,
        bvid: bvid,
        cid: cid,
        business: business,
        epid: epid,
      ),
      viewAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      progress: progress,
      duration: duration,
      authorName: authorName,
      authorMid: authorMid,
      authorFace: authorFace,
      kid: oid,
      videos: 1, // Default to 1 for local history
    );

    await GStorage.watchHistory.put(key, item.toJson());
    await GStorage.watchHistory.flush();
  }

  /// Delete a history item by key
  static Future<void> delete(String key) async {
    await GStorage.watchHistory.delete(key);
    await GStorage.watchHistory.flush();
  }

  /// Delete multiple history items
  static Future<void> deleteMultiple(Iterable<String> keys) async {
    await GStorage.watchHistory.deleteAll(keys);
    await GStorage.watchHistory.flush();
  }

  /// Clear all history
  static Future<void> clear() async {
    await GStorage.watchHistory.clear();
    await GStorage.watchHistory.flush();
  }

  /// Get all history items with optional filtering and pagination
  static List<HistoryItemModel> getAll({
    String? type,
    int? limit,
    int offset = 0,
  }) {
    final allItems = <HistoryItemModel>[];

    for (final key in GStorage.watchHistory.keys) {
      final data = GStorage.watchHistory.get(key);
      if (data != null) {
        try {
          final jsonMap = _convertMap(data);
          final item = HistoryItemModel.fromJson(jsonMap);
          // Filter by type if specified
          if (type == null || type == 'all' || item.history.business == type) {
            allItems.add(item);
          }
        } catch (_) {
          // Skip invalid entries
        }
      }
    }

    // Sort by viewAt descending (most recent first)
    allItems.sort((a, b) => (b.viewAt ?? 0).compareTo(a.viewAt ?? 0));

    // Apply pagination
    final startIndex = offset.clamp(0, allItems.length);
    final endIndex = limit != null
        ? (startIndex + limit).clamp(0, allItems.length)
        : allItems.length;

    return allItems.sublist(startIndex, endIndex);
  }

  /// Search history by keyword
  static List<HistoryItemModel> search(String keyword, {int? limit, int offset = 0}) {
    if (keyword.isEmpty) {
      return getAll(limit: limit, offset: offset);
    }

    final lowerKeyword = keyword.toLowerCase();
    final allItems = <HistoryItemModel>[];

    for (final key in GStorage.watchHistory.keys) {
      final data = GStorage.watchHistory.get(key);
      if (data != null) {
        try {
          final jsonMap = _convertMap(data);
          final item = HistoryItemModel.fromJson(jsonMap);
          // Search in title and author name
          final titleMatch = item.title?.toLowerCase().contains(lowerKeyword) ?? false;
          final authorMatch = item.authorName?.toLowerCase().contains(lowerKeyword) ?? false;
          if (titleMatch || authorMatch) {
            allItems.add(item);
          }
        } catch (_) {
          // Skip invalid entries
        }
      }
    }

    // Sort by viewAt descending (most recent first)
    allItems.sort((a, b) => (b.viewAt ?? 0).compareTo(a.viewAt ?? 0));

    // Apply pagination
    final startIndex = offset.clamp(0, allItems.length);
    final endIndex = limit != null
        ? (startIndex + limit).clamp(0, allItems.length)
        : allItems.length;

    return allItems.sublist(startIndex, endIndex);
  }

  /// Get count of history items
  static int getCount({String? type}) {
    if (type == null || type == 'all') {
      return GStorage.watchHistory.length;
    }

    int count = 0;
    for (final key in GStorage.watchHistory.keys) {
      final data = GStorage.watchHistory.get(key);
      if (data != null) {
        try {
          final jsonMap = _convertMap(data);
          final item = HistoryItemModel.fromJson(jsonMap);
          if (item.history.business == type) {
            count++;
          }
        } catch (_) {}
      }
    }
    return count;
  }

  /// Check if there are more items (for pagination)
  static bool hasMore({String? type, required int currentCount}) {
    return currentCount < getCount(type: type);
  }
}

import 'package:PiliMinus/models/model_owner.dart';
import 'package:PiliMinus/models_new/fav/fav_detail/cnt_info.dart';
import 'package:PiliMinus/models_new/fav/fav_detail/media.dart';
import 'package:PiliMinus/models_new/fav/fav_folder/data.dart';
import 'package:PiliMinus/models_new/fav/fav_folder/list.dart';
import 'package:PiliMinus/models_new/media_list/media_list.dart';
import 'package:PiliMinus/models_new/media_list/page.dart' as media_page;
import 'package:PiliMinus/utils/storage.dart';

/// Local favorites storage service using Hive
/// Replaces the login-required remote favorites API
class LocalFavoritesService {
  LocalFavoritesService._();

  static const int defaultFolderId = 1;
  static const String defaultFolderTitle = '默认收藏夹';

  /// Convert dynamic map to Map<String, dynamic> recursively
  static Map<String, dynamic> _convertMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data.map((key, value) => MapEntry(key, _convertValue(value)));
    }
    if (data is Map) {
      return data
          .map((key, value) => MapEntry(key.toString(), _convertValue(value)));
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

  /// Generate a unique folder ID based on timestamp
  static int _generateFolderId() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  /// Generate key for folder
  static String _folderKey(int folderId) => 'folder_$folderId';

  /// Generate key for favorite item
  static String _itemKey(int folderId, int videoId) =>
      'folder_${folderId}_video_$videoId';

  /// Initialize with default folder if needed
  static Future<void> ensureDefaultFolder() async {
    if (!GStorage.favFolders.containsKey(_folderKey(defaultFolderId))) {
      final defaultFolder = {
        'id': defaultFolderId,
        'mid': 0,
        'attr': 0, // public
        'title': defaultFolderTitle,
        'cover': '',
        'media_count': 0,
        'ctime': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'mtime': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };
      await GStorage.favFolders.put(_folderKey(defaultFolderId), defaultFolder);
      await GStorage.favFolders.flush();
    }
  }

  // ==================== Folder Operations ====================

  /// Create a new folder
  static Future<FavFolderInfo> createFolder({
    required String title,
    int privacy = 0, // 0 = public, 1 = private
    String intro = '',
    String cover = '',
  }) async {
    final folderId = _generateFolderId();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final folderData = {
      'id': folderId,
      'mid': 0,
      'attr': privacy,
      'title': title,
      'cover': cover,
      'intro': intro,
      'media_count': 0,
      'ctime': now,
      'mtime': now,
    };

    await GStorage.favFolders.put(_folderKey(folderId), folderData);
    await GStorage.favFolders.flush();

    return FavFolderInfo.fromJson(folderData);
  }

  /// Update an existing folder
  static Future<FavFolderInfo?> updateFolder({
    required int folderId,
    String? title,
    int? privacy,
    String? intro,
    String? cover,
  }) async {
    final key = _folderKey(folderId);
    final data = GStorage.favFolders.get(key);
    if (data == null) return null;

    final folderData = _convertMap(data);
    if (title != null) folderData['title'] = title;
    if (privacy != null) folderData['attr'] = privacy;
    if (intro != null) folderData['intro'] = intro;
    if (cover != null) folderData['cover'] = cover;
    folderData['mtime'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await GStorage.favFolders.put(key, folderData);
    await GStorage.favFolders.flush();

    return FavFolderInfo.fromJson(folderData);
  }

  /// Delete a folder and all its items
  static Future<void> deleteFolder(int folderId) async {
    // Don't allow deleting default folder
    if (folderId == defaultFolderId) return;

    // Delete all items in the folder
    final keysToDelete = <String>[];
    for (final key in GStorage.favItems.keys) {
      if (key.toString().startsWith('folder_${folderId}_')) {
        keysToDelete.add(key.toString());
      }
    }
    await GStorage.favItems.deleteAll(keysToDelete);

    // Delete the folder
    await GStorage.favFolders.delete(_folderKey(folderId));
    await GStorage.favFolders.flush();
    await GStorage.favItems.flush();
  }

  /// Get all folders
  static List<FavFolderInfo> getAllFolders() {
    final folders = <FavFolderInfo>[];

    for (final key in GStorage.favFolders.keys) {
      final data = GStorage.favFolders.get(key);
      if (data != null) {
        try {
          final jsonMap = _convertMap(data);
          folders.add(FavFolderInfo.fromJson(jsonMap));
        } catch (_) {}
      }
    }

    // Sort: default folder first, then by mtime descending
    folders.sort((a, b) {
      if (a.id == defaultFolderId) return -1;
      if (b.id == defaultFolderId) return 1;
      return (b.mtime ?? 0).compareTo(a.mtime ?? 0);
    });

    return folders;
  }

  /// Get folder data in the format expected by controllers
  static FavFolderData getFolderData() {
    final folders = getAllFolders();
    return FavFolderData(
      count: folders.length,
      list: folders,
      hasMore: false,
    );
  }

  /// Get a specific folder by ID
  static FavFolderInfo? getFolder(int folderId) {
    final data = GStorage.favFolders.get(_folderKey(folderId));
    if (data == null) return null;
    return FavFolderInfo.fromJson(_convertMap(data));
  }

  // ==================== Item Operations ====================

  /// Add a video to a folder
  static Future<void> addToFolder({
    required int folderId,
    required int videoId,
    String? bvid,
    String? title,
    String? cover,
    int? duration,
    int? cid,
    Owner? upper,
    CntInfo? cntInfo,
    int? type,
  }) async {
    final key = _itemKey(folderId, videoId);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final itemData = {
      'id': videoId,
      'type': type ?? 2, // 2 = video
      'title': title ?? '',
      'cover': cover ?? '',
      'duration': duration ?? 0,
      'attr': 0, // 0 = normal/valid
      'bvid': bvid,
      'fav_time': now,
      'pubtime': now,
      if (cid != null) 'ugc': {'first_cid': cid},
      'upper': upper != null
          ? {
              'mid': upper.mid,
              'name': upper.name,
              'face': upper.face,
            }
          : null,
      'cnt_info': cntInfo != null
          ? {
              'play': cntInfo.play,
              'danmaku': cntInfo.danmaku,
              'collect': cntInfo.collect,
            }
          : null,
    };

    await GStorage.favItems.put(key, itemData);
    await GStorage.favItems.flush();

    // Update folder media count and cover
    await _updateFolderStats(folderId);
  }

  /// Remove a video from a folder
  static Future<void> removeFromFolder({
    required int folderId,
    required int videoId,
  }) async {
    final key = _itemKey(folderId, videoId);
    await GStorage.favItems.delete(key);
    await GStorage.favItems.flush();

    // Update folder media count
    await _updateFolderStats(folderId);
  }

  /// Remove a video from all folders
  static Future<void> removeFromAllFolders(int videoId) async {
    final keysToDelete = <String>[];
    final affectedFolders = <int>{};

    for (final key in GStorage.favItems.keys) {
      if (key.toString().endsWith('_video_$videoId')) {
        keysToDelete.add(key.toString());
        // Extract folder ID from key
        final match = RegExp(r'folder_(\d+)_video_').firstMatch(key.toString());
        if (match != null) {
          affectedFolders.add(int.parse(match.group(1)!));
        }
      }
    }

    await GStorage.favItems.deleteAll(keysToDelete);
    await GStorage.favItems.flush();

    // Update affected folders
    for (final folderId in affectedFolders) {
      await _updateFolderStats(folderId);
    }
  }

  /// Get videos in a folder with pagination
  static List<FavDetailItemModel> getVideosInFolder({
    required int folderId,
    int page = 1,
    int pageSize = 20,
  }) {
    final items = <FavDetailItemModel>[];
    final prefix = 'folder_${folderId}_video_';

    for (final key in GStorage.favItems.keys) {
      if (key.toString().startsWith(prefix)) {
        final data = GStorage.favItems.get(key);
        if (data != null) {
          try {
            final jsonMap = _convertMap(data);
            items.add(FavDetailItemModel.fromJson(jsonMap));
          } catch (_) {}
        }
      }
    }

    // Sort by fav_time descending
    items.sort((a, b) => (b.favTime ?? 0).compareTo(a.favTime ?? 0));

    // Apply pagination
    final startIndex = ((page - 1) * pageSize).clamp(0, items.length);
    final endIndex = (startIndex + pageSize).clamp(0, items.length);

    return items.sublist(startIndex, endIndex);
  }

  /// Get total count of videos in a folder
  static int getVideoCountInFolder(int folderId) {
    int count = 0;
    final prefix = 'folder_${folderId}_video_';

    for (final key in GStorage.favItems.keys) {
      if (key.toString().startsWith(prefix)) {
        count++;
      }
    }
    return count;
  }

  /// Check if a video is in a specific folder
  static bool isVideoInFolder({
    required int folderId,
    required int videoId,
  }) {
    return GStorage.favItems.containsKey(_itemKey(folderId, videoId));
  }

  /// Get all folder IDs that contain a specific video
  static Set<int> getFoldersContainingVideo(int videoId) {
    final folderIds = <int>{};

    for (final key in GStorage.favItems.keys) {
      if (key.toString().endsWith('_video_$videoId')) {
        final match = RegExp(r'folder_(\d+)_video_').firstMatch(key.toString());
        if (match != null) {
          folderIds.add(int.parse(match.group(1)!));
        }
      }
    }

    return folderIds;
  }

  /// Check if a video is favorited in any folder
  static bool isVideoFavorited(int videoId) {
    for (final key in GStorage.favItems.keys) {
      if (key.toString().endsWith('_video_$videoId')) {
        return true;
      }
    }
    return false;
  }

  /// Get folders with favState indicating if video is in each folder
  static FavFolderData getFoldersWithVideoState(int videoId) {
    final folders = getAllFolders();
    final videoFolders = getFoldersContainingVideo(videoId);

    for (final folder in folders) {
      folder.favState = videoFolders.contains(folder.id) ? 1 : 0;
    }

    return FavFolderData(
      count: folders.length,
      list: folders,
      hasMore: false,
    );
  }

  /// Update favorites based on folder selection changes
  static Future<void> updateVideoFavorites({
    required int videoId,
    String? bvid,
    String? title,
    String? cover,
    int? duration,
    int? cid,
    Owner? upper,
    CntInfo? cntInfo,
    required Set<int> addToFolders,
    required Set<int> removeFromFolders,
  }) async {
    // Remove from folders
    for (final folderId in removeFromFolders) {
      await removeFromFolder(folderId: folderId, videoId: videoId);
    }

    // Add to folders
    for (final folderId in addToFolders) {
      await addToFolder(
        folderId: folderId,
        videoId: videoId,
        bvid: bvid,
        title: title,
        cover: cover,
        duration: duration,
        cid: cid,
        upper: upper,
        cntInfo: cntInfo,
      );
    }
  }

  /// Update folder statistics (media count and cover)
  static Future<void> _updateFolderStats(int folderId) async {
    final folderKey = _folderKey(folderId);
    final folderData = GStorage.favFolders.get(folderKey);
    if (folderData == null) return;

    final folder = _convertMap(folderData);
    final count = getVideoCountInFolder(folderId);
    folder['media_count'] = count;
    folder['mtime'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Update cover from first video if folder cover is empty
    if ((folder['cover'] as String?)?.isEmpty ?? true) {
      final videos = getVideosInFolder(folderId: folderId, page: 1, pageSize: 1);
      if (videos.isNotEmpty && videos.first.cover != null) {
        folder['cover'] = videos.first.cover;
      }
    }

    await GStorage.favFolders.put(folderKey, folder);
    await GStorage.favFolders.flush();
  }

  /// Clean invalid items (videos that no longer exist)
  static Future<int> cleanInvalidItems(int folderId) async {
    // In local storage, we don't have a way to check if videos are invalid
    // This is kept for API compatibility
    return 0;
  }

  /// Delete multiple items from a folder
  static Future<void> deleteMultipleFromFolder({
    required int folderId,
    required List<int> videoIds,
  }) async {
    for (final videoId in videoIds) {
      await GStorage.favItems.delete(_itemKey(folderId, videoId));
    }
    await GStorage.favItems.flush();
    await _updateFolderStats(folderId);
  }

  /// Get favorites as MediaListItemModel for the video player media list panel
  /// Supports cursor-based pagination using oid (video id)
  static List<MediaListItemModel> getAsMediaList({
    required int folderId,
    int? oid,
    int ps = 20,
    bool desc = false,
    bool isLoadPrevious = false,
  }) {
    final allItems = <FavDetailItemModel>[];
    final prefix = 'folder_${folderId}_video_';

    for (final key in GStorage.favItems.keys) {
      if (key.toString().startsWith(prefix)) {
        final data = GStorage.favItems.get(key);
        if (data != null) {
          try {
            final jsonMap = _convertMap(data);
            allItems.add(FavDetailItemModel.fromJson(jsonMap));
          } catch (_) {
            // Skip invalid entries
          }
        }
      }
    }

    // Sort by fav_time
    if (desc) {
      allItems.sort((a, b) => (a.favTime ?? 0).compareTo(b.favTime ?? 0));
    } else {
      allItems.sort((a, b) => (b.favTime ?? 0).compareTo(a.favTime ?? 0));
    }

    // Find the starting index based on oid (cursor)
    int startIndex = 0;
    if (oid != null) {
      final cursorIndex = allItems.indexWhere((item) => item.id == oid);
      if (cursorIndex != -1) {
        startIndex = isLoadPrevious ? cursorIndex - ps : cursorIndex + 1;
        if (startIndex < 0) startIndex = 0;
      }
    }

    // Apply pagination
    final endIndex = (startIndex + ps).clamp(0, allItems.length);
    final paginatedItems = allItems.sublist(startIndex.clamp(0, allItems.length), endIndex);

    // Convert to MediaListItemModel
    return paginatedItems.map((item) {
      return MediaListItemModel(
        aid: item.id,
        bvid: item.bvid,
        title: item.title ?? '',
        cover: item.cover,
        duration: item.duration,
        pubtime: item.pubtime,
        upper: Owner(
          mid: item.upper?.mid,
          name: item.upper?.name ?? '',
          face: item.upper?.face,
        ),
        type: item.type ?? 2, // archive type
        cntInfo: CntInfo(
          play: item.cntInfo?.play ?? 0,
          danmaku: item.cntInfo?.danmaku ?? 0,
          collect: item.cntInfo?.collect ?? 0,
        ),
        pages: item.ugc?.firstCid != null
            ? [media_page.Page(id: item.ugc!.firstCid)]
            : null,
      );
    }).toList();
  }
}

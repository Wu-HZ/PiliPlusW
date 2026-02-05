import 'package:PiliMinus/common/widgets/dialog/dialog.dart';
import 'package:PiliMinus/http/loading_state.dart';
import 'package:PiliMinus/models/common/video/source_type.dart';
import 'package:PiliMinus/models_new/fav/fav_detail/data.dart';
import 'package:PiliMinus/models_new/fav/fav_detail/media.dart';
import 'package:PiliMinus/models_new/fav/fav_folder/list.dart';
import 'package:PiliMinus/pages/common/common_list_controller.dart';
import 'package:PiliMinus/pages/common/multi_select/base.dart';
import 'package:PiliMinus/pages/common/multi_select/multi_select_controller.dart';
import 'package:PiliMinus/pages/fav_sort/view.dart';
import 'package:PiliMinus/services/local_favorites_service.dart';
import 'package:PiliMinus/utils/extension/scroll_controller_ext.dart';
import 'package:PiliMinus/utils/page_utils.dart';
import 'package:PiliMinus/utils/storage.dart';
import 'package:PiliMinus/utils/storage_key.dart';
import 'package:PiliMinus/utils/storage_pref.dart';
import 'package:flutter/services.dart' show ValueChanged;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

mixin BaseFavController
    on
        CommonListController<FavDetailData, FavDetailItemModel>,
        DeleteItemMixin<FavDetailData, FavDetailItemModel> {
  int get mediaId;

  ValueChanged<int>? updateCount;

  void onViewFav(FavDetailItemModel item, int? index);

  Future<void> onCancelFav(int index, int id, int type) async {
    await LocalFavoritesService.removeFromFolder(
      folderId: mediaId,
      videoId: id,
    );
    loadingState
      ..value.data!.removeAt(index)
      ..refresh();
    updateCount?.call(1);
    SmartDialog.showToast('取消收藏');
  }

  @override
  void onRemove() {
    showConfirmDialog(
      context: Get.context!,
      content: '确认删除所选收藏吗？',
      title: '提示',
      onConfirm: () async {
        final removeList = allChecked.toSet();
        await LocalFavoritesService.deleteMultipleFromFolder(
          folderId: mediaId,
          videoIds: removeList.map((item) => item.id!).toList(),
        );
        updateCount?.call(removeList.length);
        afterDelete(removeList);
        SmartDialog.showToast('取消收藏');
      },
    );
  }
}

class FavDetailController
    extends MultiSelectController<FavDetailData, FavDetailItemModel>
    with BaseFavController {
  @override
  late int mediaId;
  late String heroTag;
  final Rx<FavFolderInfo> folderInfo = FavFolderInfo().obs;

  late double dx = 0;
  late final RxBool isPlayAll = Pref.enablePlayAll.obs;

  void setIsPlayAll(bool isPlayAll) {
    if (this.isPlayAll.value == isPlayAll) return;
    this.isPlayAll.value = isPlayAll;
    GStorage.setting.put(SettingBoxKey.enablePlayAll, isPlayAll);
  }

  @override
  void onInit() {
    super.onInit();

    mediaId = int.parse(Get.parameters['mediaId']!);
    heroTag = Get.parameters['heroTag']!;

    queryData();
  }

  @override
  bool? get hasFooter => true;

  @override
  List<FavDetailItemModel>? getDataList(FavDetailData response) {
    if (response.hasMore == false) {
      isEnd = true;
    }
    return response.medias;
  }

  @override
  void checkIsEnd(int length) {
    if (length >= folderInfo.value.mediaCount) {
      isEnd = true;
    }
  }

  @override
  bool customHandleResponse(bool isRefresh, Success<FavDetailData> response) {
    if (isRefresh) {
      FavDetailData data = response.response;
      folderInfo.value = data.info!;
    }
    return false;
  }

  @override
  ValueChanged<int>? get updateCount =>
      (count) => folderInfo
        ..value.mediaCount -= count
        ..refresh();

  @override
  Future<LoadingState<FavDetailData>> customGetData() async {
    // Get folder info
    final folder = LocalFavoritesService.getFolder(mediaId);
    if (folder == null) {
      return Error('收藏夹不存在');
    }

    // Get videos in folder with pagination
    final videos = LocalFavoritesService.getVideosInFolder(
      folderId: mediaId,
      page: page,
      pageSize: 20,
    );

    final totalCount = LocalFavoritesService.getVideoCountInFolder(mediaId);

    return Success(FavDetailData(
      info: folder,
      medias: videos,
      hasMore: (page * 20) < totalCount,
    ));
  }

  void toViewPlayAll() {
    if (loadingState.value case Success(:final response)) {
      if (response == null || response.isEmpty) return;

      for (FavDetailItemModel element in response) {
        if (element.ugc?.firstCid == null) {
          continue;
        } else {
          onViewFav(element, null);
          break;
        }
      }
    }
  }

  @override
  Future<void> onReload() {
    scrollController.jumpToTop();
    return super.onReload();
  }

  void onSort() {
    if (loadingState.value case Success(:final response)) {
      if (response != null && response.isNotEmpty) {
        if (folderInfo.value.mediaCount > 1000) {
          SmartDialog.showToast('内容太多啦！超过1000不支持排序');
          return;
        }
        Get.to(FavSortPage(favDetailController: this));
      }
    }
  }

  @override
  void onViewFav(FavDetailItemModel item, int? index) {
    final folder = folderInfo.value;
    PageUtils.toVideoPage(
      bvid: item.bvid,
      cid: item.ugc!.firstCid!,
      cover: item.cover,
      title: item.title,
      extraArguments: isPlayAll.value
          ? {
              'sourceType': SourceType.fav,
              'mediaId': folder.id,
              'oid': item.id,
              'favTitle': folder.title,
              'count': folder.mediaCount,
              'desc': true,
              if (index != null) 'isContinuePlaying': index != 0,
            }
          : null,
    );
  }
}

import 'package:PiliMinus/http/loading_state.dart';
import 'package:PiliMinus/models/common/video/source_type.dart';
import 'package:PiliMinus/models_new/fav/fav_detail/data.dart';
import 'package:PiliMinus/models_new/fav/fav_detail/media.dart';
import 'package:PiliMinus/pages/common/multi_select/base.dart';
import 'package:PiliMinus/pages/common/search/common_search_controller.dart';
import 'package:PiliMinus/pages/fav_detail/controller.dart';
import 'package:PiliMinus/services/local_favorites_service.dart';
import 'package:PiliMinus/utils/page_utils.dart';
import 'package:get/get.dart';

class FavSearchController
    extends CommonSearchController<FavDetailData, FavDetailItemModel>
    with
        CommonMultiSelectMixin<FavDetailItemModel>,
        DeleteItemMixin,
        BaseFavController {
  int type = Get.arguments['type'];
  @override
  int mediaId = Get.arguments['mediaId'];
  dynamic count = Get.arguments['count'];
  dynamic title = Get.arguments['title'];

  @override
  Future<LoadingState<FavDetailData>> customGetData() async {
    final keyword = editController.text.toLowerCase();

    // Get all videos in folder
    final allVideos = LocalFavoritesService.getVideosInFolder(
      folderId: mediaId,
      page: 1,
      pageSize: 10000, // Get all to search
    );

    // Filter by keyword
    final filtered = keyword.isEmpty
        ? allVideos
        : allVideos.where((item) {
            final titleMatch = item.title?.toLowerCase().contains(keyword) ?? false;
            final upperMatch = item.upper?.name?.toLowerCase().contains(keyword) ?? false;
            return titleMatch || upperMatch;
          }).toList();

    // Apply pagination
    final startIndex = ((page - 1) * 20).clamp(0, filtered.length);
    final endIndex = (startIndex + 20).clamp(0, filtered.length);
    final pageItems = filtered.sublist(startIndex, endIndex);

    final folder = LocalFavoritesService.getFolder(mediaId);

    return Success(FavDetailData(
      info: folder,
      medias: pageItems,
      hasMore: endIndex < filtered.length,
    ));
  }

  @override
  List<FavDetailItemModel>? getDataList(FavDetailData response) {
    if (response.hasMore == false) {
      isEnd = true;
    }
    return response.medias;
  }

  @override
  void onViewFav(FavDetailItemModel item, int? index) => PageUtils.toVideoPage(
    bvid: item.bvid,
    cid: item.ugc!.firstCid!,
    cover: item.cover,
    title: item.title,
    extraArguments: {
      'sourceType': SourceType.fav,
      'mediaId': mediaId,
      'oid': item.id,
      'favTitle': title,
      'count': count,
      'desc': true,
      'isContinuePlaying': true,
    },
  );
}

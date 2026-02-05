import 'dart:async' show FutureOr, Timer;

import 'package:PiliMinus/http/loading_state.dart';
import 'package:PiliMinus/http/user.dart';
import 'package:PiliMinus/http/video.dart';
import 'package:PiliMinus/models/common/video/source_type.dart';
import 'package:PiliMinus/models_new/fav/fav_folder/data.dart';
import 'package:PiliMinus/models_new/video/video_detail/data.dart';
import 'package:PiliMinus/models_new/video/video_detail/stat_detail.dart';
import 'package:PiliMinus/models_new/video/video_tag/data.dart';
import 'package:PiliMinus/pages/video/controller.dart';
import 'package:PiliMinus/pages/video/introduction/ugc/widgets/triple_mixin.dart';
import 'package:PiliMinus/services/local_favorites_service.dart';
import 'package:PiliMinus/services/local_watch_later_service.dart';
import 'package:PiliMinus/utils/accounts.dart';
import 'package:PiliMinus/utils/global_data.dart';
import 'package:PiliMinus/utils/id_utils.dart';
import 'package:PiliMinus/utils/page_utils.dart';
import 'package:PiliMinus/utils/storage.dart';
import 'package:PiliMinus/utils/storage_key.dart';
import 'package:PiliMinus/utils/storage_pref.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

abstract class CommonIntroController extends GetxController
    with GetSingleTickerProviderStateMixin, TripleMixin, FavMixin {
  late final String heroTag;
  late String bvid;

  // 是否稍后再看
  final RxBool hasLater = false.obs;

  final Rx<List<VideoTagItem>?> videoTags = Rx<List<VideoTagItem>?>(null);

  bool isProcessing = false;
  Future<void> handleAction(FutureOr Function() action) async {
    if (!isProcessing) {
      isProcessing = true;
      await action();
      isProcessing = false;
    }
  }

  StatDetail? getStat();

  late final isLogin = Accounts.main.isLogin;

  @override
  void updateFavCount(int count) {
    getStat()?.favorite += count;
  }

  final Rx<VideoDetailData> videoDetail = VideoDetailData().obs;

  void queryVideoIntro();

  bool prevPlay();
  bool nextPlay();

  void actionCoinVideo();
  void actionShareVideo(BuildContext context);

  // 同时观看
  final bool isShowOnlineTotal = Pref.enableOnlineTotal;
  late final RxString total = '1'.obs;
  Timer? timer;

  late final RxInt cid;

  late final videoDetailCtr = Get.find<VideoDetailController>(tag: heroTag);

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    heroTag = args['heroTag'];
    bvid = args['bvid'];
    cid = RxInt(args['cid']);
    hasLater.value = args['sourceType'] == SourceType.watchLater ||
        LocalWatchLaterService.contains(bvid: bvid);

    queryVideoIntro();
    startTimer();
  }

  void startTimer() {
    if (isShowOnlineTotal) {
      queryOnlineTotal();
      timer ??= Timer.periodic(const Duration(seconds: 10), (Timer timer) {
        queryOnlineTotal();
      });
    }
  }

  void cancelTimer() {
    timer?.cancel();
    timer = null;
  }

  // 查看同时在看人数
  Future<void> queryOnlineTotal() async {
    if (!isShowOnlineTotal) {
      return;
    }
    final result = await VideoHttp.onlineTotal(
      aid: IdUtils.bv2av(bvid),
      bvid: bvid,
      cid: cid.value,
    );
    if (result case Success(:final response)) {
      total.value = response;
    }
  }

  @override
  void onClose() {
    cancelTimer();
    super.onClose();
  }

  Future<void> coinVideo(int coin, [bool selectLike = false]) async {
    final stat = getStat();
    if (stat == null) {
      return;
    }
    final res = await VideoHttp.coinVideo(
      bvid: bvid,
      multiply: coin,
      selectLike: selectLike ? 1 : 0,
    );
    if (res.isSuccess) {
      SmartDialog.showToast('投币成功');
      coinNum.value += coin;
      GlobalData().afterCoin(coin);
      stat.coin += coin;
      if (selectLike && !hasLike.value) {
        stat.like++;
        hasLike.value = true;
      }
    } else {
      res.toast();
    }
  }

  Future<void> queryVideoTags() async {
    final result = await UserHttp.videoTags(bvid: bvid, cid: cid.value);
    videoTags.value = result.dataOrNull;
  }

  Future<void> viewLater() async {
    final aid = IdUtils.bv2av(bvid);
    if (hasLater.value) {
      await LocalWatchLaterService.delete(aid: aid, bvid: bvid);
      hasLater.value = false;
    } else {
      final detail = videoDetail.value;
      await LocalWatchLaterService.addFromVideo(
        aid: aid,
        bvid: bvid,
        cid: cid.value,
        title: detail.title,
        cover: detail.pic,
        duration: detail.duration,
        authorName: detail.owner?.name,
        authorMid: detail.owner?.mid,
        authorFace: detail.owner?.face,
      );
      hasLater.value = true;
      SmartDialog.showToast('已添加到稍后再看');
    }
  }
}

mixin FavMixin on TripleMixin {
  Set<int>? favIds;
  int? quickFavId;
  late final enableQuickFav = Pref.enableQuickFav;
  final Rx<FavFolderData> favFolderData = FavFolderData().obs;

  (Object, int) get getFavRidType;

  // These must be provided by the implementing class for local storage
  int get videoId;
  String? get videoBvid;
  String? get videoTitle;
  String? get videoCover;
  int? get videoDuration;
  int? get videoCid;

  Future<LoadingState<FavFolderData>> queryVideoInFolder() async {
    favIds = null;
    final (rid, _) = getFavRidType;
    final videoIdInt = rid is int ? rid : int.tryParse(rid.toString()) ?? 0;

    // Use local service to get folders with video state
    final data = LocalFavoritesService.getFoldersWithVideoState(videoIdInt);
    favFolderData.value = data;
    favIds = data.list
        ?.where((item) => item.favState == 1)
        .map((item) => item.id)
        .whereType<int>()
        .toSet();

    return Success(data);
  }

  int get favFolderId {
    if (this.quickFavId != null) {
      return this.quickFavId!;
    }
    final quickFavId = Pref.quickFavId;
    final list = favFolderData.value.list!;
    if (quickFavId != null) {
      final folderInfo = list.where((e) => e.id == quickFavId).firstOrNull;
      if (folderInfo != null) {
        return this.quickFavId = quickFavId;
      } else {
        GStorage.setting.delete(SettingBoxKey.quickFavId);
      }
    }
    return this.quickFavId = list.first.id;
  }

  // 收藏
  void showFavBottomSheet(BuildContext context, {bool isLongPress = false}) {
    // 快速收藏 &
    // 点按 收藏至默认文件夹
    // 长按选择文件夹
    if (enableQuickFav) {
      if (!isLongPress) {
        actionFavVideo(isQuick: true);
      } else {
        PageUtils.showFavBottomSheet(context: context, ctr: this);
      }
    } else if (!isLongPress) {
      PageUtils.showFavBottomSheet(context: context, ctr: this);
    }
  }

  void updateFavCount(int count);

  Future<void> actionFavVideo({bool isQuick = false}) async {
    final (rid, _) = getFavRidType;
    final videoIdInt = rid is int ? rid : int.tryParse(rid.toString()) ?? 0;

    // 收藏至默认文件夹
    if (isQuick) {
      SmartDialog.showLoading(msg: '请求中');
      await queryVideoInFolder();
      final hasFav = this.hasFav.value;

      if (hasFav) {
        // Remove from all folders
        await LocalFavoritesService.removeFromAllFolders(videoIdInt);
      } else {
        // Add to default folder
        await LocalFavoritesService.addToFolder(
          folderId: favFolderId,
          videoId: videoIdInt,
          bvid: videoBvid,
          title: videoTitle,
          cover: videoCover,
          duration: videoDuration,
          cid: videoCid,
        );
      }

      SmartDialog.dismiss();
      updateFavCount(hasFav ? -1 : 1);
      this.hasFav.value = !hasFav;
      SmartDialog.showToast(hasFav ? '已取消收藏' : '已收藏');
      return;
    }

    // Handle folder selection changes
    Set<int> addToFolders = {};
    Set<int> removeFromFolders = {};

    try {
      for (final folder in favFolderData.value.list!) {
        bool wasFaved = favIds?.contains(folder.id) == true;
        bool nowFaved = folder.favState == 1;

        if (nowFaved && !wasFaved) {
          addToFolders.add(folder.id);
        } else if (!nowFaved && wasFaved) {
          removeFromFolders.add(folder.id);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint(e.toString());
    }

    SmartDialog.showLoading(msg: '请求中');
    await LocalFavoritesService.updateVideoFavorites(
      videoId: videoIdInt,
      bvid: videoBvid,
      title: videoTitle,
      cover: videoCover,
      duration: videoDuration,
      cid: videoCid,
      addToFolders: addToFolders,
      removeFromFolders: removeFromFolders,
    );
    SmartDialog.dismiss();

    Get.back();
    final newVal = addToFolders.isNotEmpty ||
        (favIds != null && favIds!.length != removeFromFolders.length);
    if (hasFav.value != newVal) {
      updateFavCount(newVal ? 1 : -1);
      hasFav.value = newVal;
    }
    SmartDialog.showToast('操作成功');
  }
}

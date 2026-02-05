import 'package:PiliMinus/common/widgets/dialog/dialog.dart';
import 'package:PiliMinus/http/loading_state.dart';
import 'package:PiliMinus/models/common/later_view_type.dart';
import 'package:PiliMinus/models/common/video/source_type.dart';
import 'package:PiliMinus/models_new/later/data.dart';
import 'package:PiliMinus/models_new/later/list.dart';
import 'package:PiliMinus/pages/common/multi_select/base.dart';
import 'package:PiliMinus/pages/common/multi_select/multi_select_controller.dart';
import 'package:PiliMinus/pages/later/base_controller.dart';
import 'package:PiliMinus/services/local_watch_later_service.dart';
import 'package:PiliMinus/utils/extension/scroll_controller_ext.dart';
import 'package:PiliMinus/utils/page_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

mixin BaseLaterController
    on
        CommonMultiSelectMixin<LaterItemModel>,
        DeleteItemMixin<LaterData, LaterItemModel> {
  ValueChanged<int>? updateCount;

  @override
  void onRemove() {
    showConfirmDialog(
      context: Get.context!,
      content: '确认删除所选稍后再看吗？',
      title: '提示',
      onConfirm: () async {
        final removeList = allChecked.toSet();
        SmartDialog.showLoading(msg: '请求中');
        await LocalWatchLaterService.deleteMultiple(removeList);
        updateCount?.call(removeList.length);
        afterDelete(removeList);
        SmartDialog.dismiss();
      },
    );
  }

  // single
  void toViewDel(
    BuildContext context,
    int index,
    LaterItemModel item,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提示'),
        content: const Text('即将移除该视频，确定是否移除'),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(
              '取消',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await LocalWatchLaterService.delete(
                  aid: item.aid, bvid: item.bvid);
              loadingState
                ..value.data!.removeAt(index)
                ..refresh();
              updateCount?.call(1);
            },
            child: const Text('确认移除'),
          ),
        ],
      ),
    );
  }
}

class LaterController extends MultiSelectController<LaterData, LaterItemModel>
    with BaseLaterController {
  LaterController(this.laterViewType);
  final LaterViewType laterViewType;

  final RxBool asc = false.obs;

  final LaterBaseController baseCtr = Get.put(LaterBaseController());

  static const int _pageSize = 20;

  @override
  RxBool get enableMultiSelect => baseCtr.enableMultiSelect;

  @override
  RxInt get rxCount => baseCtr.checkedCount;

  @override
  Future<LoadingState<LaterData>> customGetData() async {
    final offset = (page - 1) * _pageSize;
    final items = LocalWatchLaterService.getAll(
      viewType: laterViewType.type,
      limit: _pageSize,
      offset: offset,
    );

    final count = LocalWatchLaterService.getCount(
      viewType: laterViewType.type,
    );

    return Success(LaterData(count: count, list: items));
  }

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  List<LaterItemModel>? getDataList(response) {
    baseCtr.counts[laterViewType.index] = response.count ?? 0;
    return response.list;
  }

  @override
  void checkIsEnd(int length) {
    if (length >= baseCtr.counts[laterViewType.index]) {
      isEnd = true;
    }
  }

  // 一键清空
  void toViewClear(BuildContext context, [int? cleanType]) {
    String content = switch (cleanType) {
      _ => '确定清空稍后再看列表吗？',
    };
    showConfirmDialog(
      context: context,
      title: '确认',
      content: content,
      onConfirm: () async {
        await LocalWatchLaterService.clear();
        onReload();
        final restTypes = List<LaterViewType>.from(LaterViewType.values)
          ..remove(laterViewType);
        for (final item in restTypes) {
          try {
            Get.find<LaterController>(tag: item.type.toString()).onReload();
          } catch (_) {}
        }
        SmartDialog.showToast('操作成功');
      },
    );
  }

  // 稍后再看播放全部
  void toViewPlayAll() {
    if (loadingState.value case Success(:final response)) {
      if (response == null || response.isEmpty) return;

      for (LaterItemModel item in response) {
        if (item.cid == null || item.pgcLabel?.isNotEmpty == true) {
          continue;
        } else {
          PageUtils.toVideoPage(
            bvid: item.bvid,
            cid: item.cid!,
            cover: item.pic,
            title: item.title,
            extraArguments: {
              'sourceType': SourceType.watchLater,
              'count': baseCtr.counts[LaterViewType.all.index],
              'favTitle': '稍后再看',
              'desc': asc.value,
            },
          );
          break;
        }
      }
    }
  }

  @override
  ValueChanged<int>? get updateCount =>
      (count) => baseCtr.counts[laterViewType.index] -= count;

  @override
  Future<void> onReload() {
    scrollController.jumpToTop();
    return super.onReload();
  }
}

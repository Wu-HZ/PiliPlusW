import 'package:PiliMinus/common/widgets/dialog/dialog.dart';
import 'package:PiliMinus/http/loading_state.dart';
import 'package:PiliMinus/models_new/history/list.dart';
import 'package:PiliMinus/models_new/history/tab.dart';
import 'package:PiliMinus/pages/common/multi_select/multi_select_controller.dart';
import 'package:PiliMinus/pages/history/base_controller.dart';
import 'package:PiliMinus/services/local_history_service.dart';
import 'package:PiliMinus/utils/extension/scroll_controller_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class HistoryController
    extends MultiSelectController<List<HistoryItemModel>, HistoryItemModel>
    with GetSingleTickerProviderStateMixin {
  HistoryController(this.type);

  late final baseCtr = Get.put(HistoryBaseController());

  final String? type;
  TabController? tabController;
  late RxList<HistoryTab> tabs = <HistoryTab>[].obs;

  // Offset-based pagination
  int _offset = 0;
  static const int _pageSize = 20;

  @override
  RxInt get rxCount => baseCtr.checkedCount;

  @override
  RxBool get enableMultiSelect => baseCtr.enableMultiSelect;

  @override
  void onInit() {
    super.onInit();
    _initTabs();
    queryData();
  }

  void _initTabs() {
    // Static tabs for local history (no API response needed)
    if (type == null) {
      tabs.value = [
        HistoryTab(type: 'archive', name: '视频'),
        HistoryTab(type: 'pgc', name: '番剧'),
        HistoryTab(type: 'live', name: '直播'),
      ];
      tabController = TabController(
        length: tabs.length + 1,
        vsync: this,
      );
    }
  }

  @override
  Future<void> onRefresh() {
    _offset = 0;
    return super.onRefresh();
  }

  @override
  List<HistoryItemModel>? getDataList(List<HistoryItemModel> response) {
    return response;
  }

  @override
  bool customHandleResponse(bool isRefresh, Success<List<HistoryItemModel>> response) {
    List<HistoryItemModel> data = response.response;
    isEnd = data.length < _pageSize;
    _offset += data.length;
    return false;
  }

  // 删除某条历史记录
  void delHistory(HistoryItemModel item) {
    _onDelete({item});
  }

  // 删除已看历史记录
  void onDelViewedHistory() {
    final viewedList = loadingState.value.dataOrNull
        ?.where((e) => e.progress == -1)
        .toSet();
    if (viewedList != null && viewedList.isNotEmpty) {
      _onDelete(viewedList);
    } else {
      SmartDialog.showToast('无已看记录');
    }
  }

  Future<void> _onDelete(Set<HistoryItemModel> removeList) async {
    SmartDialog.showLoading(msg: '删除中');
    final keys = removeList
        .map((item) => '${item.history.business}_${item.history.oid}')
        .toList();
    await LocalHistoryService.deleteMultiple(keys);
    SmartDialog.dismiss();
    afterDelete(removeList);
    SmartDialog.showToast('已删除');
  }

  // 删除选中的记录
  @override
  void onRemove() {
    showConfirmDialog(
      context: Get.context!,
      content: '确认删除所选历史记录吗？',
      title: '提示',
      onConfirm: () => _onDelete(allChecked.toSet()),
    );
  }

  @override
  Future<LoadingState<List<HistoryItemModel>>> customGetData() async {
    // Simulate async behavior for consistency
    await Future.delayed(Duration.zero);

    final items = LocalHistoryService.getAll(
      type: type ?? 'all',
      limit: _pageSize,
      offset: loadingState.value is Success ? _offset : 0,
    );

    return Success(items);
  }

  @override
  void onClose() {
    tabController?.dispose();
    super.onClose();
  }

  @override
  Future<void> onReload() {
    scrollController.jumpToTop();
    return super.onReload();
  }
}

import 'package:PiliMinus/common/widgets/dialog/dialog.dart';
import 'package:PiliMinus/http/loading_state.dart';
import 'package:PiliMinus/models_new/history/list.dart';
import 'package:PiliMinus/pages/common/multi_select/base.dart';
import 'package:PiliMinus/pages/common/search/common_search_controller.dart';
import 'package:PiliMinus/services/local_history_service.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class HistorySearchController
    extends CommonSearchController<List<HistoryItemModel>, HistoryItemModel>
    with CommonMultiSelectMixin<HistoryItemModel>, DeleteItemMixin {

  static const int _pageSize = 20;

  @override
  Future<LoadingState<List<HistoryItemModel>>> customGetData() async {
    // Simulate async behavior for consistency
    await Future.delayed(Duration.zero);

    final keyword = editController.value.text;
    final offset = (page - 1) * _pageSize;

    final items = LocalHistoryService.search(
      keyword,
      limit: _pageSize,
      offset: offset,
    );

    return Success(items);
  }

  @override
  List<HistoryItemModel>? getDataList(List<HistoryItemModel> response) {
    return response;
  }

  Future<void> onDelHistory(int index, kid, String business) async {
    final key = '${business}_$kid';
    await LocalHistoryService.delete(key);
    loadingState
      ..value.data!.removeAt(index)
      ..refresh();
    SmartDialog.showToast('已删除');
  }

  @override
  void onRemove() {
    showConfirmDialog(
      context: Get.context!,
      content: '确认删除所选历史记录吗？',
      title: '提示',
      onConfirm: () async {
        SmartDialog.showLoading(msg: '删除中');
        final removeList = allChecked.toSet();
        final keys = removeList
            .map((item) => '${item.history.business}_${item.history.oid}')
            .toList();
        await LocalHistoryService.deleteMultiple(keys);
        afterDelete(removeList);
        SmartDialog.showToast('已删除');
        SmartDialog.dismiss();
      },
    );
  }
}

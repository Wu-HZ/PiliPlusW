import 'package:PiliMinus/pages/common/common_list_controller.dart';
import 'package:PiliMinus/pages/common/multi_select/base.dart';

abstract class MultiSelectController<
  R,
  T extends MultiSelectData
> = CommonListController<R, T>
    with CommonMultiSelectMixin<T>, DeleteItemMixin;

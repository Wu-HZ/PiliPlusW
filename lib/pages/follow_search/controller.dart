import 'package:PiliMinus/http/loading_state.dart';
import 'package:PiliMinus/http/member.dart';
import 'package:PiliMinus/models_new/follow/data.dart';
import 'package:PiliMinus/models_new/follow/list.dart';
import 'package:PiliMinus/pages/common/search/common_search_controller.dart';

class FollowSearchController
    extends CommonSearchController<FollowData, FollowItemModel> {
  FollowSearchController(this.mid);
  final int mid;

  @override
  Future<LoadingState<FollowData>> customGetData() =>
      MemberHttp.getfollowSearch(
        mid: mid,
        ps: 20,
        pn: page,
        name: editController.value.text,
      );

  @override
  List<FollowItemModel>? getDataList(FollowData response) {
    return response.list;
  }
}

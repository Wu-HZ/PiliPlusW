import 'package:PiliMinus/http/loading_state.dart';
import 'package:PiliMinus/http/user.dart';
import 'package:PiliMinus/models_new/follow/data.dart';
import 'package:PiliMinus/pages/follow_type/controller.dart';

class FollowSameController extends FollowTypeController {
  @override
  Future<LoadingState<FollowData>> customGetData() =>
      UserHttp.sameFollowing(mid: mid, pn: page);
}

import 'package:PiliMinus/http/loading_state.dart';
import 'package:PiliMinus/http/user.dart';
import 'package:PiliMinus/models_new/follow/data.dart';
import 'package:PiliMinus/pages/follow_type/controller.dart';

class FollowedController extends FollowTypeController {
  @override
  Future<LoadingState<FollowData>> customGetData() =>
      UserHttp.followedUp(mid: mid, pn: page);
}

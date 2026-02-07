import 'package:PiliMinus/http/loading_state.dart';
import 'package:PiliMinus/http/video.dart';
import 'package:PiliMinus/pages/common/common_list_controller.dart';

class ZoneController extends CommonListController {
  ZoneController({this.rid});

  int? rid;

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  Future<LoadingState> customGetData() {
    return VideoHttp.getRankVideoList(rid!);
  }
}

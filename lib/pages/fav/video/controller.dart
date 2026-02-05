import 'package:PiliMinus/http/loading_state.dart';
import 'package:PiliMinus/models_new/fav/fav_folder/data.dart';
import 'package:PiliMinus/models_new/fav/fav_folder/list.dart';
import 'package:PiliMinus/pages/common/common_list_controller.dart';
import 'package:PiliMinus/services/local_favorites_service.dart';

class FavController extends CommonListController<FavFolderData, FavFolderInfo> {
  @override
  void onInit() {
    super.onInit();
    // Ensure default folder exists
    LocalFavoritesService.ensureDefaultFolder().then((_) => queryData());
  }

  @override
  Future<void> queryData([bool isRefresh = true]) {
    return super.queryData(isRefresh);
  }

  @override
  List<FavFolderInfo>? getDataList(FavFolderData response) {
    // Local storage doesn't have pagination, so always end
    isEnd = true;
    return response.list;
  }

  @override
  Future<LoadingState<FavFolderData>> customGetData() async {
    // Use local favorites service instead of remote API
    final data = LocalFavoritesService.getFolderData();
    return Success(data);
  }
}

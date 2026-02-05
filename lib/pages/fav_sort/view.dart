import 'package:PiliMinus/http/loading_state.dart';
import 'package:PiliMinus/models_new/fav/fav_detail/media.dart';
import 'package:PiliMinus/pages/fav_detail/controller.dart';
import 'package:PiliMinus/pages/fav_detail/widget/fav_video_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class FavSortPage extends StatefulWidget {
  const FavSortPage({super.key, required this.favDetailController});

  final FavDetailController favDetailController;

  @override
  State<FavSortPage> createState() => _FavSortPageState();
}

class _FavSortPageState extends State<FavSortPage> {
  FavDetailController get _favDetailController => widget.favDetailController;

  final GlobalKey _key = GlobalKey();
  late List<FavDetailItemModel> sortList = List<FavDetailItemModel>.from(
    _favDetailController.loadingState.value.data!,
  );
  bool _hasChanges = false;

  void onLoadMore() {
    if (_favDetailController.isEnd) {
      return;
    }
    _favDetailController.onLoadMore().whenComplete(() {
      try {
        if (_favDetailController.loadingState.value case Success(
          :final response,
        )) {
          sortList.addAll(response!.skip(sortList.length));
          if (mounted) {
            setState(() {});
          }
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('排序: ${_favDetailController.folderInfo.value.title}'),
        actions: [
          TextButton(
            onPressed: () {
              if (!_hasChanges) {
                Get.back();
                return;
              }
              // Update local state (UI-only sorting)
              _favDetailController.loadingState.value = Success(sortList);
              SmartDialog.showToast('排序完成');
              Get.back();
            },
            child: const Text('完成'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _buildBody,
    );
  }

  void onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final tabsItem = sortList.removeAt(oldIndex);
    sortList.insert(newIndex, tabsItem);
    _hasChanges = true;

    setState(() {});
  }

  Widget get _buildBody {
    final child = ReorderableListView.builder(
      key: _key,
      onReorder: onReorder,
      physics: const AlwaysScrollableScrollPhysics(),
      padding:
          MediaQuery.viewPaddingOf(context).copyWith(top: 0) +
          const EdgeInsets.only(bottom: 100),
      itemCount: sortList.length,
      itemBuilder: (context, index) {
        final item = sortList[index];
        return SizedBox(
          key: Key(item.id.toString()),
          height: 98,
          child: FavVideoCardH(item: item),
        );
      },
    );
    if (!_favDetailController.isEnd) {
      return NotificationListener<ScrollEndNotification>(
        onNotification: (notification) {
          final metrics = notification.metrics;
          if (metrics.pixels >= metrics.maxScrollExtent - 300) {
            onLoadMore();
          }
          return false;
        },
        child: child,
      );
    }
    return child;
  }
}

import 'package:PiliMinus/common/widgets/appbar/appbar.dart';
import 'package:PiliMinus/common/widgets/flutter/page/tabs.dart';
import 'package:PiliMinus/common/widgets/gesture/horizontal_drag_gesture_recognizer.dart';
import 'package:PiliMinus/common/widgets/scroll_physics.dart';
import 'package:PiliMinus/common/widgets/view_safe_area.dart';
import 'package:PiliMinus/models/common/later_view_type.dart';
import 'package:PiliMinus/pages/fav_detail/view.dart';
import 'package:PiliMinus/pages/later/base_controller.dart';
import 'package:PiliMinus/pages/later/controller.dart';
import 'package:PiliMinus/utils/extension/get_ext.dart';
import 'package:PiliMinus/utils/extension/scroll_controller_ext.dart';
import 'package:flutter/material.dart' hide TabBarView;
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class LaterPage extends StatefulWidget {
  const LaterPage({super.key});

  @override
  State<LaterPage> createState() => _LaterPageState();
}

class _LaterPageState extends State<LaterPage>
    with SingleTickerProviderStateMixin {
  final LaterBaseController _baseCtr = Get.put(LaterBaseController());
  late final TabController _tabController;

  LaterController currCtr([int? index]) {
    final type = LaterViewType.values[index ?? _tabController.index];
    return Get.putOrFind(
      () => LaterController(type),
      tag: type.type.toString(),
    );
  }

  final _sortKey = GlobalKey();
  void listener() {
    (_sortKey.currentContext as Element?)?.markNeedsBuild();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: LaterViewType.values.length,
      vsync: this,
    )..addListener(listener);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(listener)
      ..dispose();
    Get.delete<LaterBaseController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final enableMultiSelect = _baseCtr.enableMultiSelect.value;
        return PopScope(
          canPop: !enableMultiSelect,
          onPopInvokedWithResult: (didPop, result) {
            if (enableMultiSelect) {
              currCtr().handleSelect();
            }
          },
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: _buildAppbar(enableMultiSelect),
            floatingActionButtonLocation: const CustomFabLocation(),
            floatingActionButton: Padding(
              padding: const .only(right: kFloatingActionButtonMargin),
              child: Obx(
                () => currCtr().loadingState.value.isSuccess
                    ? AnimatedSlide(
                        offset: _baseCtr.isPlayAll.value
                            ? Offset.zero
                            : const Offset(0.75, 0),
                        duration: const Duration(milliseconds: 120),
                        child: GestureDetector(
                          onHorizontalDragDown: (details) =>
                              _baseCtr.dx = details.localPosition.dx,
                          onHorizontalDragStart: (details) =>
                              _baseCtr.setIsPlayAll(
                                details.localPosition.dx < _baseCtr.dx,
                              ),
                          child: FloatingActionButton.extended(
                            onPressed: () {
                              if (_baseCtr.isPlayAll.value) {
                                currCtr().toViewPlayAll();
                              } else {
                                _baseCtr.setIsPlayAll(true);
                              }
                            },
                            label: const Text('播放全部'),
                            icon: const Icon(Icons.playlist_play),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            body: ViewSafeArea(
              child: Column(
                children: [
                  TabBar(
                    // isScrollable: true,
                    // tabAlignment: TabAlignment.start,
                    controller: _tabController,
                    tabs: LaterViewType.values.map((item) {
                      final count = _baseCtr.counts[item.index];
                      return Tab(
                        text: '${item.title}${count != -1 ? '($count)' : ''}',
                      );
                    }).toList(),
                    onTap: (_) {
                      if (!_tabController.indexIsChanging) {
                        currCtr().scrollController.animToTop();
                      } else if (enableMultiSelect) {
                        currCtr(_tabController.previousIndex).handleSelect();
                      }
                    },
                  ),
                  Expanded(
                    child: TabBarView<CustomHorizontalDragGestureRecognizer>(
                      physics: enableMultiSelect
                          ? const NeverScrollableScrollPhysics()
                          : const CustomTabBarViewScrollPhysics(),
                      controller: _tabController,
                      horizontalDragGestureRecognizer:
                          CustomHorizontalDragGestureRecognizer.new,
                      children: LaterViewType.values
                          .map((item) => item.page)
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppbar(bool enableMultiSelect) {
    final theme = Theme.of(context);
    Color color = theme.colorScheme.secondary;
    return MultiSelectAppBarWidget(
      visible: enableMultiSelect,
      ctr: currCtr(),
      child: AppBar(
        title: const Text('稍后再看'),
        actions: [
          Builder(
            key: _sortKey,
            builder: (context) {
              final value = currCtr().asc.value;
              return PopupMenuButton(
                initialValue: value,
                tooltip: '排序',
                onSelected: (value) => currCtr()
                  ..asc.value = value
                  ..onReload(),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text.rich(
                    style: TextStyle(fontSize: 14, height: 1, color: color),
                    strutStyle: const StrutStyle(
                      leading: 0,
                      height: 1,
                      fontSize: 14,
                    ),
                    TextSpan(
                      children: [
                        TextSpan(text: value ? '最早添加' : '最近添加'),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(
                            size: 14,
                            MdiIcons.unfoldMoreHorizontal,
                            color: color,
                          ),
                        ),
                      ],
                      style: TextStyle(color: color),
                    ),
                  ),
                ),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: false,
                    child: Text('最近添加'),
                  ),
                  const PopupMenuItem(
                    value: true,
                    child: Text('最早添加'),
                  ),
                ],
              );
            },
          ),
          IconButton(
            tooltip: '清空全部',
            onPressed: () => currCtr().toViewClear(context),
            icon: const Icon(Icons.delete_outline),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

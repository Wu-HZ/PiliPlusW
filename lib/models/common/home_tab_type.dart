import 'package:PiliMinus/models/common/enum_with_label.dart';
import 'package:PiliMinus/pages/common/common_controller.dart';
import 'package:PiliMinus/pages/hot/controller.dart';
import 'package:PiliMinus/pages/hot/view.dart';
import 'package:PiliMinus/pages/live/controller.dart';
import 'package:PiliMinus/pages/live/view.dart';
import 'package:PiliMinus/pages/rank/controller.dart';
import 'package:PiliMinus/pages/rank/view.dart';
import 'package:PiliMinus/pages/rcmd/controller.dart';
import 'package:PiliMinus/pages/rcmd/view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum HomeTabType implements EnumWithLabel {
  live('直播'),
  rcmd('推荐'),
  hot('热门'),
  rank('分区'),
  ;

  @override
  final String label;
  const HomeTabType(this.label);

  ScrollOrRefreshMixin Function() get ctr => switch (this) {
    HomeTabType.live => Get.find<LiveController>,
    HomeTabType.rcmd => Get.find<RcmdController>,
    HomeTabType.hot => Get.find<HotController>,
    HomeTabType.rank => Get.find<RankController>,
  };

  Widget get page => switch (this) {
    HomeTabType.live => const LivePage(),
    HomeTabType.rcmd => const RcmdPage(),
    HomeTabType.hot => const HotPage(),
    HomeTabType.rank => const RankPage(),
  };
}

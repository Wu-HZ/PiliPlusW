import 'package:PiliMinus/common/widgets/flutter/selectable_text/text.dart';
import 'package:PiliMinus/common/widgets/stat/stat.dart';
import 'package:PiliMinus/models/common/stat_type.dart';
import 'package:PiliMinus/models_new/pgc/pgc_info_model/result.dart';
import 'package:PiliMinus/models_new/video/video_tag/data.dart';
import 'package:PiliMinus/pages/common/slide/common_slide_page.dart';
import 'package:PiliMinus/pages/search/widgets/search_text.dart';
import 'package:PiliMinus/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PgcIntroPanel extends CommonSlidePage {
  final PgcInfoModel item;
  final List<VideoTagItem>? videoTags;

  const PgcIntroPanel({
    super.key,
    required this.item,
    super.enableSlide,
    this.videoTags,
  });

  @override
  State<PgcIntroPanel> createState() => _IntroDetailState();
}

class _IntroDetailState extends State<PgcIntroPanel>
    with SingleTickerProviderStateMixin, CommonSlideMixin {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget buildPage(ThemeData theme) {
    return Material(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Row(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  '详情',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: '关闭',
                icon: const Icon(Icons.close, size: 20),
                onPressed: Get.back,
              ),
              const SizedBox(width: 2),
            ],
          ),
          Expanded(
            child: enableSlide ? slideList(theme) : buildList(theme),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildList(ThemeData theme) {
    return _buildInfo(theme);
    return TabBarView<TabBarDragGestureRecognizer>(
      controller: _tabController,
      physics: const CustomTabBarViewScrollPhysics(),
      horizontalDragGestureRecognizer: () =>
          TabBarDragGestureRecognizer(isDxAllowed: isDxAllowed),
      children: [
        KeepAliveWrapper(builder: (context) => _buildInfo(theme)),
        PgcReviewPage(
          name: widget.item.title!,
          mediaId: widget.item.mediaId,
        ),
      ],
    );
  }

  Widget _buildInfo(ThemeData theme) {
    final TextStyle smallTitle = TextStyle(
      fontSize: 12,
      color: theme.colorScheme.onSurface,
    );
    final TextStyle textStyle = TextStyle(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return ListView(
      controller: _controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        top: 14,
        bottom: MediaQuery.viewPaddingOf(context).bottom + 100,
      ),
      children: [
        selectableText(
          widget.item.title!,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 4),
        Row(
          spacing: 6,
          children: [
            StatWidget(
              type: StatType.play,
              value: widget.item.stat!.view,
            ),
            StatWidget(
              type: StatType.danmaku,
              value: widget.item.stat!.danmaku,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              widget.item.areas!.first.name!,
              style: smallTitle,
            ),
            const SizedBox(width: 6),
            Text(
              widget.item.publish!.pubTimeShow!,
              style: smallTitle,
            ),
            const SizedBox(width: 6),
            Text(
              widget.item.newEp!.desc!,
              style: smallTitle,
            ),
          ],
        ),
        if (widget.item.evaluate?.isNotEmpty == true) ...[
          const SizedBox(height: 20),
          Text(
            '简介：',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          selectableText(
            widget.item.evaluate!,
            style: textStyle,
          ),
        ],
        if (widget.item.actors?.isNotEmpty == true) ...[
          const SizedBox(height: 20),
          Text(
            '演职人员：',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            widget.item.actors!,
            style: textStyle,
          ),
        ],
        if (widget.videoTags?.isNotEmpty == true) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.videoTags!
                .map(
                  (item) => SearchText(
                    fontSize: 13,
                    text: item.tagName!,
                    onTap: (tagName) => Get.toNamed(
                      '/searchResult',
                      parameters: {'keyword': tagName},
                    ),
                    onLongPress: Utils.copyText,
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

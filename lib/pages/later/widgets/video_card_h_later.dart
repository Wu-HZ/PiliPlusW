import 'package:PiliMinus/common/constants.dart';
import 'package:PiliMinus/common/widgets/badge.dart';
import 'package:PiliMinus/common/widgets/image/network_img_layer.dart';
import 'package:PiliMinus/common/widgets/progress_bar/video_progress_indicator.dart';
import 'package:PiliMinus/common/widgets/select_mask.dart';
import 'package:PiliMinus/http/search.dart';
import 'package:PiliMinus/models/common/badge_type.dart';
import 'package:PiliMinus/models_new/later/list.dart';
import 'package:PiliMinus/pages/later/controller.dart';
import 'package:PiliMinus/utils/date_utils.dart';
import 'package:PiliMinus/utils/duration_utils.dart';
import 'package:PiliMinus/utils/page_utils.dart';
import 'package:PiliMinus/utils/platform_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// Watch Later item widget - matches HistoryItem design
class VideoCardHLater extends StatelessWidget {
  const VideoCardHLater({
    super.key,
    required this.ctr,
    required this.index,
    required this.videoItem,
    required this.onViewLater,
  });

  final int index;
  final BaseLaterController ctr;
  final LaterItemModel videoItem;
  final ValueChanged<int> onViewLater;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDuration = videoItem.duration != null && videoItem.duration != 0;
    final enableMultiSelect = ctr.enableMultiSelect.value;

    final onLongPress = enableMultiSelect
        ? null
        : () => ctr
            ..enableMultiSelect.value = true
            ..onSelect(videoItem);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: enableMultiSelect
            ? () => ctr.onSelect(videoItem)
            : () async {
                if (videoItem.isPugv ?? false) {
                  PageUtils.viewPugv(seasonId: videoItem.aid);
                  return;
                }
                if (videoItem.isPgc ?? false) {
                  if (videoItem.bangumi?.epId != null) {
                    // Convert progress from seconds to milliseconds
                    final progressMs =
                        (videoItem.progress != null && videoItem.progress! > 0)
                            ? videoItem.progress! * 1000
                            : null;
                    PageUtils.viewPgc(
                        epId: videoItem.bangumi!.epId, progress: progressMs);
                  } else if (videoItem.redirectUrl?.isNotEmpty == true) {
                    PageUtils.viewPgcFromUri(videoItem.redirectUrl!);
                  }
                  return;
                }
                try {
                  final int? cid =
                      videoItem.cid ??
                      await SearchHttp.ab2c(
                        aid: videoItem.aid,
                        bvid: videoItem.bvid,
                      );
                  if (cid != null) {
                    onViewLater(cid);
                  }
                } catch (err) {
                  SmartDialog.showToast(err.toString());
                }
              },
        onLongPress: onLongPress,
        onSecondaryTap: PlatformUtils.isMobile ? null : onLongPress,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: StyleString.safeSpace,
                vertical: 5,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: StyleString.aspectRatio,
                    child: LayoutBuilder(
                      builder: (context, boxConstraints) {
                        double maxWidth = boxConstraints.maxWidth;
                        double maxHeight = boxConstraints.maxHeight;
                        num? progress = videoItem.progress;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            NetworkImgLayer(
                              src: videoItem.pic,
                              width: maxWidth,
                              height: maxHeight,
                              cacheWidth: videoItem.dimension?.cacheWidth,
                            ),
                            if (hasDuration && progress != null && progress != 0)
                              PBadge(
                                text: progress == -1
                                    ? '已看完'
                                    : '${DurationUtils.formatDuration(progress)}/${DurationUtils.formatDuration(videoItem.duration)}',
                                right: 6.0,
                                bottom: 8.0,
                                type: PBadgeType.gray,
                              )
                            else if (hasDuration)
                              PBadge(
                                text: DurationUtils.formatDuration(
                                    videoItem.duration),
                                right: 6.0,
                                bottom: 8.0,
                                type: PBadgeType.gray,
                              ),
                            if (videoItem.pgcLabel?.isNotEmpty == true)
                              PBadge(
                                text: videoItem.pgcLabel,
                                top: 6.0,
                                right: 6.0,
                                type: PBadgeType.primary,
                              )
                            else if (videoItem.isPugv ?? false)
                              const PBadge(
                                text: '课堂',
                                top: 6.0,
                                right: 6.0,
                              ),
                            if (hasDuration &&
                                progress != null &&
                                progress != 0)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: VideoProgressIndicator(
                                  color: theme.colorScheme.primary,
                                  backgroundColor:
                                      theme.colorScheme.secondaryContainer,
                                  progress: progress == -1
                                      ? 1
                                      : progress / (videoItem.duration ?? 1),
                                ),
                              ),
                            Positioned.fill(
                              child: selectMask(theme, videoItem.checked),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  _content(theme),
                ],
              ),
            ),
            Positioned(
              right: 12,
              bottom: 0,
              width: 29,
              height: 29,
              child: PopupMenuButton(
                padding: EdgeInsets.zero,
                tooltip: '功能菜单',
                icon: Icon(
                  Icons.more_vert_outlined,
                  color: theme.colorScheme.outline,
                  size: 18,
                ),
                position: PopupMenuPosition.under,
                itemBuilder: (context) => [
                  if (videoItem.owner?.mid != null &&
                      videoItem.owner?.name?.isNotEmpty == true)
                    PopupMenuItem(
                      onTap: () =>
                          Get.toNamed('/member?mid=${videoItem.owner!.mid}'),
                      height: 38,
                      child: Row(
                        children: [
                          const Icon(
                            MdiIcons.accountCircleOutline,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '访问：${videoItem.owner!.name}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    onTap: () => ctr.toViewDel(context, index, videoItem),
                    height: 38,
                    child: const Row(
                      children: [
                        Icon(Icons.close_outlined, size: 16),
                        SizedBox(width: 6),
                        Text('移除', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(ThemeData theme) {
    final isPgc = videoItem.isPgc == true && videoItem.bangumi != null;
    return Expanded(
      child: Column(
        spacing: 2,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPgc
                ? (videoItem.bangumi?.season?.title ?? videoItem.title ?? '')
                : (videoItem.title ?? ''),
            style: TextStyle(
              fontSize: theme.textTheme.bodyMedium!.fontSize,
              height: 1.42,
              letterSpacing: 0.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (isPgc && videoItem.subtitle?.isNotEmpty == true)
            Text(
              videoItem.subtitle!,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.outline,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const Spacer(),
          if (videoItem.owner?.name?.isNotEmpty == true)
            Text(
              videoItem.owner!.name!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: theme.textTheme.labelMedium!.fontSize,
                color: theme.colorScheme.outline,
              ),
            ),
          if (videoItem.pubdate != null)
            Text(
              DateFormatUtils.chatFormat(videoItem.pubdate!),
              style: TextStyle(
                fontSize: theme.textTheme.labelMedium!.fontSize,
                color: theme.colorScheme.outline,
              ),
            ),
        ],
      ),
    );
  }
}

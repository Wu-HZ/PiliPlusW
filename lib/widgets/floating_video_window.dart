import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_status.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// A reusable widget for floating video windows
/// Displays a small video player with control buttons
class FloatingVideoWindow extends StatefulWidget {
  final String windowId;
  final PlPlayerController playerController;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final bool isLive;
  final double floatingWidth;
  final double floatingHeight;
  final double controlBarHeight;
  final Offset initialPosition;
  final ValueChanged<Offset>? onPositionChanged;

  const FloatingVideoWindow({
    super.key,
    required this.windowId,
    required this.playerController,
    required this.onTap,
    required this.onClose,
    this.isLive = false,
    this.floatingWidth = 240.0,
    this.floatingHeight = 175.0,
    this.controlBarHeight = 40.0,
    this.initialPosition = const Offset(20.0, 100.0),
    this.onPositionChanged,
  });

  /// Calculate dimensions based on video aspect ratio
  /// Returns a Size object with width and height
  static Size calculateDimensions(
    PlPlayerController controller, {
    double controlBarHeight = 40.0,
  }) {
    double? videoHeight =
        controller.videoPlayerController?.state.height?.toDouble();
    double? videoWidth =
        controller.videoPlayerController?.state.width?.toDouble();

    // Calculate aspect ratio based on video orientation
    double aspectRatio =
        !controller.isVertical ? 9.0 / 16.0 : 16.0 / 9.0;

    if (videoWidth != null && videoHeight != null) {
      if ((videoWidth > videoHeight) ^ controller.isVertical) {
        aspectRatio = videoHeight / videoWidth;
      }
    }

    double floatingWidth = aspectRatio > 1 ? 150.0 : 240.0;
    double floatingHeight = floatingWidth * aspectRatio + controlBarHeight;

    return Size(floatingWidth, floatingHeight);
  }

  @override
  State<FloatingVideoWindow> createState() => _FloatingVideoWindowState();
}

class _FloatingVideoWindowState extends State<FloatingVideoWindow> {
  late Offset _position;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
  }

  Widget _buildIconButton(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed,
  ) {
    final theme = Theme.of(context);
    return Expanded(
      child: IconButton(
        constraints: const BoxConstraints(),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) {
              return theme.colorScheme.surface.withValues(alpha: 0.9);
            },
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, color: theme.colorScheme.onSurface, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final videoAreaHeight = widget.floatingHeight - widget.controlBarHeight;
    final screenSize = MediaQuery.sizeOf(context);

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              (_position.dx + details.delta.dx).clamp(
                0.0,
                screenSize.width - widget.floatingWidth,
              ),
              (_position.dy + details.delta.dy).clamp(
                0.0,
                screenSize.height - widget.floatingHeight,
              ),
            );
          });
        },
        onPanEnd: (_) {
          widget.onPositionChanged?.call(_position);
        },
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: widget.floatingWidth,
            height: widget.floatingHeight,
            child: Column(
              children: [
                // Video area
                SizedBox(
                  width: widget.floatingWidth,
                  height: videoAreaHeight,
                  child: InkWell(
                    onTap: widget.onTap,
                    child: widget.playerController.videoController != null
                        ? Video(
                            controller:
                                widget.playerController.videoController!,
                            controls: NoVideoControls,
                            pauseUponEnteringBackgroundMode: !widget
                                .playerController
                                .continuePlayInBackground
                                .value,
                            resumeUponEnteringForegroundMode: true,
                            subtitleViewConfiguration:
                                widget.playerController.subtitleConfig.value,
                            fit: BoxFit.contain,
                          )
                        : const ColoredBox(
                            color: Colors.black,
                            child: Center(
                              child:
                                  Icon(Icons.video_library, color: Colors.white54),
                            ),
                          ),
                  ),
                ),
                // Control bar
                SizedBox(
                  width: widget.floatingWidth,
                  height: widget.controlBarHeight,
                  child: Row(
                    children: [
                      if (!widget.isLive)
                        _buildIconButton(
                          context,
                          MdiIcons.rewind10,
                          () => widget.playerController.seekTo(
                            widget.playerController.position.value -
                                const Duration(seconds: 10),
                          ),
                        ),
                      if (!widget.isLive)
                        Obx(
                          () => _buildIconButton(
                            context,
                            widget.playerController.playerStatus.value ==
                                    PlayerStatus.playing
                                ? Icons.pause
                                : Icons.play_arrow,
                            () => widget.playerController
                                .videoPlayerController?.playOrPause(),
                          ),
                        ),
                      if (!widget.isLive)
                        _buildIconButton(
                          context,
                          MdiIcons.fastForward10,
                          () => widget.playerController.seekTo(
                            widget.playerController.position.value +
                                const Duration(seconds: 10),
                          ),
                        ),
                      _buildIconButton(context, Icons.close, widget.onClose),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

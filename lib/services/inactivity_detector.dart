import 'dart:async';

import 'package:PiliMinus/plugin/pl_player/controller.dart';
import 'package:PiliMinus/plugin/pl_player/models/play_status.dart';
import 'package:PiliMinus/utils/storage.dart';
import 'package:PiliMinus/utils/storage_key.dart';
import 'package:PiliMinus/utils/storage_pref.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InactivityDetector extends StatefulWidget {
  const InactivityDetector({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<InactivityDetector> createState() => _InactivityDetectorState();
}

class _InactivityDetectorState extends State<InactivityDetector>
    with WidgetsBindingObserver {
  Timer? _inactivityTimer;
  bool _isEnabled = Pref.antiDistraction;
  int _timeoutSeconds = Pref.antiDistractionTimeout;
  bool _isOnSearchOnlyPage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshSettings();
      _resetTimer();
    } else if (state == AppLifecycleState.paused) {
      _inactivityTimer?.cancel();
    }
  }

  void _refreshSettings() {
    _isEnabled = GStorage.setting.get(
      SettingBoxKey.antiDistraction,
      defaultValue: false,
    );
    _timeoutSeconds = GStorage.setting.get(
      SettingBoxKey.antiDistractionTimeout,
      defaultValue: 30,
    );
  }

  void _startTimer() {
    if (!_isEnabled) return;

    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(Duration(seconds: _timeoutSeconds), _onInactive);
  }

  void _resetTimer() {
    if (!_isEnabled) return;
    _startTimer();
  }

  void _onInactive() {
    if (!_isEnabled || _isOnSearchOnlyPage) return;

    // Check if video is playing
    final playerController = PlPlayerController.instance;
    if (playerController != null) {
      final status = playerController.playerStatus.value;
      if (status == PlayerStatus.playing) {
        // Video is playing, reset timer and don't navigate
        _resetTimer();
        return;
      }
    }

    // Check current route to avoid navigating if already on search-only page
    final currentRoute = Get.currentRoute;
    if (currentRoute == '/searchOnly') {
      _isOnSearchOnlyPage = true;
      return;
    }

    // Navigate to search-only page
    _isOnSearchOnlyPage = true;
    Get.toNamed('/searchOnly', arguments: {'fromInactivity': true});
  }

  void _onUserInteraction() {
    _refreshSettings();

    // If user is back from search-only page
    final currentRoute = Get.currentRoute;
    if (currentRoute != '/searchOnly') {
      _isOnSearchOnlyPage = false;
    }

    _resetTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _onUserInteraction(),
      onPointerMove: (_) => _onUserInteraction(),
      onPointerUp: (_) => _onUserInteraction(),
      child: widget.child,
    );
  }
}

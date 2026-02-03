import 'package:PiliPlus/services/audio_handler.dart';
import 'package:PiliPlus/services/audio_session.dart';
import 'package:PiliPlus/services/floating_window_manager.dart';
import 'package:PiliPlus/utils/storage_pref.dart';

// Re-export floating window manager for easy access
export 'package:PiliPlus/services/floating_window_manager.dart';

VideoPlayerServiceHandler? videoPlayerServiceHandler;
AudioSessionHandler? audioSessionHandler;

Future<void> setupServiceLocator() async {
  final audio = await initAudioService();
  videoPlayerServiceHandler = audio;
  audioSessionHandler = AudioSessionHandler();

  // Initialize floating window manager settings
  floatingWindowManager.maxWindows = Pref.floatingWindowMaxCount;
}

import 'package:PiliMinus/services/audio_handler.dart';
import 'package:PiliMinus/services/audio_session.dart';
import 'package:PiliMinus/services/floating_window_manager.dart';

// Re-export floating window manager for easy access
export 'package:PiliMinus/services/floating_window_manager.dart';

VideoPlayerServiceHandler? videoPlayerServiceHandler;
AudioSessionHandler? audioSessionHandler;

Future<void> setupServiceLocator() async {
  final audio = await initAudioService();
  videoPlayerServiceHandler = audio;
  audioSessionHandler = AudioSessionHandler();
}

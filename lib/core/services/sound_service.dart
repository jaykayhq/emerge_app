import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SoundService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playCompletionSound() async {
    try {
      // Ensure the file exists in assets/sounds/completion.mp3
      await _player.play(AssetSource('sounds/completion.mp3'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  Future<void> playLevelUpSound() async {
    try {
      await _player.play(AssetSource('sounds/level_up.mp3'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }
}

final soundServiceProvider = Provider<SoundService>((ref) => SoundService());

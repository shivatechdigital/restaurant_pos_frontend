import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _newOrderPlayer = AudioPlayer();
  final AudioPlayer _readyPlayer = AudioPlayer();
  final AudioPlayer _urgentPlayer = AudioPlayer();

  bool _isMuted = false;
  bool get isMuted => _isMuted;

  // Initialize karo (app start par call karo)
  Future<void> init() async {
    try {
      // Yeh sounds aapko assets folder mein rakhne honge
      // Ya fir online hosted sounds use kar sakte ho
      await _newOrderPlayer.setSource(
        UrlSource('https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3'),
      );
      await _readyPlayer.setSource(
        UrlSource('https://assets.mixkit.co/active_storage/sfx/2868/2868-preview.mp3'),
      );
      await _urgentPlayer.setSource(
        UrlSource('https://assets.mixkit.co/active_storage/sfx/2867/2867-preview.mp3'),
      );

      // Volume set karo
      await _newOrderPlayer.setVolume(1.0);
      await _readyPlayer.setVolume(0.8);
      await _urgentPlayer.setVolume(1.0);

      debugPrint('🔊 Sound Service Initialized');
    } catch (e) {
      debugPrint('⚠️ Sound init error: $e');
    }
  }

  // Naya order aaya — BEEP!
  Future<void> playNewOrderAlert() async {
    if (_isMuted) return;
    try {
      await _newOrderPlayer.stop();
      await _newOrderPlayer.play(
        UrlSource('https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3'),
      );
      _vibrate();
    } catch (e) {
      debugPrint('Sound error: $e');
    }
  }

  // Order ready hai
  Future<void> playReadyAlert() async {
    if (_isMuted) return;
    try {
      await _readyPlayer.stop();
      await _readyPlayer.play(
        UrlSource('https://assets.mixkit.co/active_storage/sfx/2868/2868-preview.mp3'),
      );
    } catch (e) {
      debugPrint('Sound error: $e');
    }
  }

  // Urgent alert (10+ min late)
  Future<void> playUrgentAlert() async {
    if (_isMuted) return;
    try {
      await _urgentPlayer.stop();
      await _urgentPlayer.play(
        UrlSource('https://assets.mixkit.co/active_storage/sfx/2867/2867-preview.mp3'),
      );
      _vibrate();
      _vibrate(); // Double vibration for urgent
    } catch (e) {
      debugPrint('Sound error: $e');
    }
  }

  // Vibration (Mobile ke liye)
  void _vibrate() {
    if (!kIsWeb) {
      HapticFeedback.heavyImpact();
    }
  }

  // Mute / Unmute
  void toggleMute() {
    _isMuted = !_isMuted;
  }

  void dispose() {
    _newOrderPlayer.dispose();
    _readyPlayer.dispose();
    _urgentPlayer.dispose();
  }
}

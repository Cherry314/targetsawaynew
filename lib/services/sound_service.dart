// lib/services/sound_service.dart
// Centralized sound effects service for the app with pre-loaded audio for low latency

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Sound types used throughout the app
enum SoundType {
  heart, // Looping heartbeat sound for home screen
  compStart, // Competition start sound
  compWin, // Competition win/end sound
}

/// Centralized service for managing sound effects throughout the app
/// Pre-loads all sounds for minimal latency
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  // Audio players for different sound types
  final Map<SoundType, AudioPlayer> _players = {};

  // Pre-loaded audio sources
  final Map<SoundType, AssetSource> _sources = {};

  // Pre-initialization flag
  bool _initialized = false;

  // Settings
  bool _soundsEnabled = true;
  static const String _prefsKey = 'sounds_enabled';

  // Volume levels for each sound type (heart is louder)
  static const Map<SoundType, double> _soundVolumes = {
    SoundType.heart: 1.6, // 20% louder
    SoundType.compStart: 1.0,
    SoundType.compWin: 1.0,
  };

  // Fade timers for smooth looping
  Timer? _heartFadeTimer;
  static const int _heartFadeDurationMs = 800; // fade in/out duration
  static const int _heartLoopDurationMs = 2400; // total loop cycle time

  // Sound file paths
  static const Map<SoundType, String> _soundFiles = {
    SoundType.heart: 'audio/heart.wav',
    SoundType.compStart: 'audio/compstart.wav',
    SoundType.compWin: 'audio/compwin.wav',
  };

  /// Initialize the sound service - pre-loads all sounds
  Future<void> initialize() async {
    if (_initialized) return;

    await _loadSettings();

    if (_soundsEnabled) {
      await _preloadAllSounds();
    }

    _initialized = true;
    debugPrint('SoundService initialized with pre-loaded sounds');
  }

  /// Pre-load all sound sources for minimal latency
  Future<void> _preloadAllSounds() async {
    for (final entry in _soundFiles.entries) {
      try {
        final type = entry.key;
        final path = entry.value;

        // Create and configure player
        final player = AudioPlayer();
        await player.setPlayerMode(PlayerMode.lowLatency);
        
        // Set volume based on sound type (heart is louder)
        final volume = _soundVolumes[type] ?? 1.0;
        await player.setVolume(volume);

        // Pre-load the source
        final source = AssetSource(path);

        // Load the source once to cache it
        await player.setSource(source);

        _players[type] = player;
        _sources[type] = source;

        debugPrint('Pre-loaded sound: $type from $path at volume $volume');
      } catch (e) {
        debugPrint('Error pre-loading sound ${entry.key}: $e');
      }
    }
  }

  /// Load sound settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _soundsEnabled = prefs.getBool(_prefsKey) ?? true;
  }

  /// Save sound settings to SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, _soundsEnabled);
  }

  /// Check if sounds are enabled
  bool get soundsEnabled => _soundsEnabled;

  /// Toggle sounds on/off
  Future<void> setSoundsEnabled(bool enabled) async {
    _soundsEnabled = enabled;
    await _saveSettings();

    if (!enabled) {
      await stopAllSounds();
    } else if (!_initialized) {
      await _preloadAllSounds();
    }
  }

  /// Get or create an audio player for a sound type
  AudioPlayer _getPlayer(SoundType type) {
    if (!_players.containsKey(type)) {
      _players[type] = AudioPlayer();
      _players[type]!.setPlayerMode(PlayerMode.lowLatency);
    }
    return _players[type]!;
  }

  /// Play a sound effect (if sounds are enabled)
  /// Uses pre-loaded source for minimal latency
  void playSound(SoundType type) {
    if (!_soundsEnabled) return;

    try {
      final player = _getPlayer(type);
      final source = _sources[type];

      if (source != null) {
        // Fire and forget - seek to beginning and play
        player.seek(Duration.zero).then((_) {
          player.resume();
        });
      } else {
        // Fallback: load and play
        final filePath = _soundFiles[type];
        if (filePath != null) {
          player.play(AssetSource(filePath));
        }
      }
    } catch (e) {
      debugPrint('Error playing sound $type: $e');
    }
  }

  /// Play a sound in a loop (for heartbeat on home screen)
  Future<void> playSoundLoop(SoundType type) async {
    if (!_soundsEnabled) return;

    try {
      final player = _getPlayer(type);
      final source = _sources[type];

      if (source != null) {
        await player.setReleaseMode(ReleaseMode.loop);
        await player.resume();
      } else {
        final filePath = _soundFiles[type];
        if (filePath != null) {
          await player.setReleaseMode(ReleaseMode.loop);
          await player.play(AssetSource(filePath));
        }
      }
    } catch (e) {
      debugPrint('Error playing sound loop $type: $e');
    }
  }

  /// Stop a specific sound
  Future<void> stopSound(SoundType type) async {
    try {
      if (_players.containsKey(type)) {
        await _players[type]!.stop();
      }
    } catch (e) {
      debugPrint('Error stopping sound $type: $e');
    }
  }

  /// Stop all sounds
  Future<void> stopAllSounds() async {
    for (final player in _players.values) {
      try {
        await player.stop();
      } catch (e) {
        // Ignore errors when stopping
      }
    }
  }

  /// Dispose all audio players
  Future<void> dispose() async {
    _heartFadeTimer?.cancel();
    _heartFadeTimer = null;
    for (final player in _players.values) {
      try {
        await player.dispose();
      } catch (e) {
        // Ignore errors when disposing
      }
    }
    _players.clear();
    _sources.clear();
    _initialized = false;
  }

  // Convenience methods for specific sound types

  /// Play competition start sound
  void playCompStart() => playSound(SoundType.compStart);

  /// Play competition win sound
  void playCompWin() => playSound(SoundType.compWin);

  /// Start heart beat loop with fade in/out for smooth looping (home screen)
  Future<void> startHeartBeat() async {
    if (!_soundsEnabled) return;

    try {
      // Cancel any existing fade timer
      _heartFadeTimer?.cancel();
      _heartFadeTimer = null;

      final player = _getPlayer(SoundType.heart);
      var source = _sources[SoundType.heart];
      final maxVolume = _soundVolumes[SoundType.heart] ?? 1.0;

      // If not pre-loaded, load it now (fallback)
      if (source == null) {
        final filePath = _soundFiles[SoundType.heart];
        if (filePath == null) return;
        source = AssetSource(filePath);
        _sources[SoundType.heart] = source;
        await player.setSource(source);
      }

      // Set to not loop - we'll handle looping manually with fades
      await player.setReleaseMode(ReleaseMode.release);

      // Start with zero volume and begin fade in
      await player.setVolume(0.0);
      await player.setSource(source);
      await player.resume();

      // Start the fade cycle
      _startHeartFadeCycle(player, source, maxVolume);

      debugPrint('Started heartbeat with fade in/out');
    } catch (e) {
      debugPrint('Error starting heartbeat: $e');
    }
  }

  /// Manage the fade in/out cycle for smooth heartbeat looping
  void _startHeartFadeCycle(AudioPlayer player, AssetSource source, double maxVolume) {
    const fadeSteps = 20; // Number of volume steps for smooth fade
    const fadeStepDuration = Duration(milliseconds: _heartFadeDurationMs ~/ fadeSteps);
    const holdDuration = Duration(milliseconds: _heartLoopDurationMs - (_heartFadeDurationMs * 2));

    var currentStep = 0;
    var isFadingIn = true;
    var isHolding = false;

    _heartFadeTimer = Timer.periodic(fadeStepDuration, (timer) async {
      if (!_soundsEnabled) {
        timer.cancel();
        return;
      }

      try {
        if (isFadingIn) {
          // Fade in phase
          currentStep++;
          final volume = (currentStep / fadeSteps) * maxVolume;
          await player.setVolume(volume.clamp(0.0, maxVolume));

          if (currentStep >= fadeSteps) {
            isFadingIn = false;
            isHolding = true;
            currentStep = 0;
            // Switch to hold timing
            timer.cancel();
            _heartFadeTimer = Timer(holdDuration, () {
              _startHeartFadeOut(player, source, maxVolume, fadeSteps, fadeStepDuration);
            });
          }
        }
      } catch (e) {
        debugPrint('Error in heart fade cycle: $e');
        timer.cancel();
      }
    });
  }

  /// Fade out and restart the heartbeat
  void _startHeartFadeOut(AudioPlayer player, AssetSource source, double maxVolume, int fadeSteps, Duration fadeStepDuration) {
    var currentStep = fadeSteps;

    _heartFadeTimer = Timer.periodic(fadeStepDuration, (timer) async {
      if (!_soundsEnabled) {
        timer.cancel();
        return;
      }

      try {
        currentStep--;
        final volume = (currentStep / fadeSteps) * maxVolume;
        await player.setVolume(volume.clamp(0.0, maxVolume));

        if (currentStep <= 0) {
          // Fade complete, restart the sound
          timer.cancel();
          await player.stop();
          await player.setSource(source);
          await player.setVolume(0.0);
          await player.resume();
          _startHeartFadeCycle(player, source, maxVolume);
        }
      } catch (e) {
        debugPrint('Error in heart fade out: $e');
        timer.cancel();
      }
    });
  }

  /// Stop heart beat loop
  Future<void> stopHeartBeat() async {
    _heartFadeTimer?.cancel();
    _heartFadeTimer = null;
    await stopSound(SoundType.heart);
  }
}

/// Provider for sound settings to allow UI updates
class SoundSettingsProvider extends ChangeNotifier {
  bool _enabled = true;
  final SoundService _soundService = SoundService();

  bool get enabled => _enabled;

  Future<void> initialize() async {
    await _soundService.initialize();
    _enabled = _soundService.soundsEnabled;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    await _soundService.setSoundsEnabled(value);
    notifyListeners();
  }
}

import 'package:flutter_tts/flutter_tts.dart';

/// Service that handles text-to-speech functionality for Darija.
///
/// Uses the flutter_tts package to speak text aloud with Arabic language
/// configuration optimized for Darija (Moroccan Arabic).
class TTSService {
  final FlutterTts _tts = FlutterTts();

  bool _isInitialized = false;
  bool _isSpeaking = false;

  /// Whether the TTS engine is currently speaking.
  bool get isSpeaking => _isSpeaking;

  /// Configures the TTS engine for Darija language output.
  ///
  /// Sets the language to Arabic (Mordia) or falls back to Arabic (Saudi).
  /// Adjusts speech rate and pitch for natural-sounding Darija.
  ///
  /// Returns true if configuration succeeded, false otherwise.
  Future<bool> configureForDarija() async {
    try {
      // Try Moroccan Arabic first, fall back to Saudi Arabic.
      bool languageSet = false;

      final languages = await _tts.getLanguages;
      if (languages.contains('ar-MA')) {
        await _tts.setLanguage('ar-MA');
        languageSet = true;
      } else if (languages.contains('ar-SA')) {
        await _tts.setLanguage('ar-SA');
        languageSet = true;
      } else if (languages.contains('ar')) {
        await _tts.setLanguage('ar');
        languageSet = true;
      }

      if (!languageSet) {
        return false;
      }

      // Slightly slower rate for clarity, natural pitch.
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setStartHandler(() {
        _isSpeaking = true;
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
      });

      _isInitialized = true;
      return true;
    } catch (e) {
      _isInitialized = false;
      return false;
    }
  }

  /// Speaks the given [text] aloud.
  ///
  /// If TTS is not initialized, it will attempt to configure first.
  /// Returns true if speech started successfully.
  Future<bool> speak(String text) async {
    if (text.trim().isEmpty) return false;

    try {
      if (!_isInitialized) {
        final configured = await configureForDarija();
        if (!configured) return false;
      }

      await _tts.speak(text);
      return true;
    } catch (e) {
      _isSpeaking = false;
      return false;
    }
  }

  /// Stops any ongoing speech immediately.
  ///
  /// Returns true if stop was successful.
  Future<bool> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Pauses any ongoing speech.
  ///
  /// Returns true if pause was successful.
  Future<bool> pause() async {
    try {
      await _tts.pause();
      _isSpeaking = false;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Disposes of the TTS engine resources.
  void dispose() {
    _tts.stop();
    _isSpeaking = false;
    _isInitialized = false;
  }
}

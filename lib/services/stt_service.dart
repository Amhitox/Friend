import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

/// Service that handles speech-to-text functionality.
///
/// Uses the speech_to_text package to listen to the user's voice and convert
/// it to text. Handles microphone permissions and provides callbacks for
/// recognized speech.
class STTService {
  final SpeechToText _speech = SpeechToText();

  bool _isInitialized = false;
  bool _isListening = false;

  /// Whether the STT engine is currently listening.
  bool get isListening => _isListening;

  /// Whether the STT engine has been initialized.
  bool get isInitialized => _isInitialized;

  /// Initializes the speech-to-text engine.
  ///
  /// Requests microphone permission from the user. Returns true if
  /// initialization succeeded and permission was granted.
  ///
  /// Returns false if permission was denied or initialization failed.
  Future<bool> initialize() async {
    try {
      _isInitialized = await _speech.initialize(
        onError: (error) {
          _isListening = false;
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );
      return _isInitialized;
    } catch (e) {
      _isInitialized = false;
      return false;
    }
  }

  /// Starts listening for speech and calls [onResult] with recognized text.
  ///
  /// The [onResult] callback receives a [String] containing the recognized
  /// speech. It may be called multiple times as the engine refines its
  /// recognition (partial results).
  ///
  /// [localeId] defaults to Moroccan Arabic ('ar_MA') but can be overridden.
  ///
  /// Returns true if listening started successfully.
  Future<bool> startListening(
    void Function(String result) onResult, {
    String localeId = 'ar_MA',
  }) async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) return false;
      }

      if (_isListening) {
        await stopListening();
      }

      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          onResult(result.recognizedWords);
        },
        localeId: localeId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        listenMode: ListenMode.dictation,
      );

      _isListening = true;
      return true;
    } catch (e) {
      _isListening = false;
      return false;
    }
  }

  /// Stops listening for speech.
  ///
  /// Returns true if stop was successful.
  Future<bool> stopListening() async {
    try {
      await _speech.stop();
      _isListening = false;
      return true;
    } catch (e) {
      _isListening = false;
      return false;
    }
  }

  /// Cancels the current listening session.
  ///
  /// Unlike [stopListening], this discards any partial results.
  Future<bool> cancel() async {
    try {
      await _speech.cancel();
      _isListening = false;
      return true;
    } catch (e) {
      _isListening = false;
      return false;
    }
  }

  /// Returns a list of available locale identifiers for speech recognition.
  Future<List<String>> getAvailableLocales() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      final locales = await _speech.locales();
      return locales.map((locale) => locale.localeId).toList();
    } catch (e) {
      return [];
    }
  }

  /// Disposes of the STT engine resources.
  void dispose() {
    _speech.stop();
    _isListening = false;
    _isInitialized = false;
  }
}

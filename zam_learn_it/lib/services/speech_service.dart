import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;
  String _lastRecognizedText = '';

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get lastRecognizedText => _lastRecognizedText;

  /// Initializes speech recognition and requests microphone permissions.
  Future<bool> initialize() async {
    if (_isAvailable) return true;

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      print('❌ Microphone permission denied');
      return false;
    }

    try {
      _isAvailable = await _speech.initialize(
        onStatus: (status) {
          print('Speech Status: $status');
          _isListening = (status == 'listening');
        },
        onError: (error) {
          print('Speech Error: $error');
          _isListening = false;
        },
      );
      return _isAvailable;
    } catch (e) {
      print('❌ Speech Init Exception: $e');
      return false;
    }
  }

  /// Helper to ensure the service is ready before use.
  Future<bool> _ensureInitialized() async {
    if (!_isAvailable) return await initialize();
    return true;
  }

  /// Starts a continuous listening session (streaming results).
  Future<void> startListening({
    required Function(String) onResult,
    required Function(String) onError,
  }) async {
    if (!await _ensureInitialized()) {
      onError('Speech recognition not available');
      return;
    }

    await stopListening();

    await _speech.listen(
      onResult: (result) {
        if (result.recognizedWords.isNotEmpty) {
          _lastRecognizedText = result.recognizedWords;
          onResult(_lastRecognizedText);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
    );
  }

  /// Captures a single phrase and returns the transcribed text.
  Future<String?> recordAndTranslate({Duration limit = const Duration(seconds: 8)}) async {
    if (!await _ensureInitialized()) return null;

    print('🎤 Recording started... Speak now');
    String recognizedText = '';

    await _speech.listen(
      onResult: (result) {
        if (result.recognizedWords.isNotEmpty) {
          recognizedText = result.recognizedWords;
        }
      },
      listenFor: limit,
      pauseFor: const Duration(seconds: 2),
      partialResults: false,
    );

    // Wait for the listener to naturally time out or stop it manually
    await Future.delayed(limit);
    await _speech.stop();

    return recognizedText.isNotEmpty ? recognizedText : null;
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
    }
  }

  Future<void> cancelListening() async {
    if (_isListening) {
      await _speech.cancel();
    }
  }
}
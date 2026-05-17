import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;
  String _lastRecognizedText = '';
  
  // Initialize speech recognition
  Future<bool> initialize() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      print('❌ Microphone permission denied');
      return false;
    }
    
    _isAvailable = await _speech.initialize(
      onStatus: (status) {
        print('Speech status: $status');
        if (status == 'notListening') {
          _isListening = false;
        }
      },
      onError: (error) {
        print('Speech error: $error');
        _isListening = false;
      },
    );
    
    print('Speech available: $_isAvailable');
    return _isAvailable;
  }
  
  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  
  // WhatsApp-style: Record with visual feedback
  Future<String?> recordAndTranslate({
    Function(double)? onSoundLevel,
    Function()? onRecordingStart,
    Function()? onRecordingStop,
  }) async {
    if (!_isAvailable) {
      await initialize();
    }
    
    if (!_isAvailable) {
      return null;
    }
    
    // Notify recording started
    if (onRecordingStart != null) onRecordingStart();
    
    _isListening = true;
    String recognizedText = '';
    
    // Start listening with sound level monitoring
    await _speech.listen(
      onResult: (result) {
        if (result.recognizedWords.isNotEmpty) {
          recognizedText = result.recognizedWords;
        }
        // Provide sound level for animation (0-100)
        if (onSoundLevel != null) {
          // Simulate sound level based on confidence or random for demo
          final level = (result.confidence ?? 0.5) * 100;
          onSoundLevel(level);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
      onSoundLevelChange: (level) {
        if (onSoundLevel != null) {
          onSoundLevel(level * 100);
        }
      },
    );
    
    // Wait for user to finish speaking (user releases button)
    await Future.delayed(const Duration(seconds: 2));
    await _speech.stop();
    _isListening = false;
    
    // Notify recording stopped
    if (onRecordingStop != null) onRecordingStop();
    
    return recognizedText.isNotEmpty ? recognizedText : null;
  }
  
  // Simple record method (press and hold style)
  Future<void> startListening({
    required Function(String) onResult,
    required Function(String) onError,
    Function(double)? onSoundLevel,
  }) async {
    if (!_isAvailable) {
      onError('Speech recognition not available');
      return;
    }
    
    if (_isListening) {
      await stopListening();
    }
    
    _isListening = true;
    
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
      onSoundLevelChange: (level) {
        if (onSoundLevel != null) {
          onSoundLevel(level);
        }
      },
    );
  }
  
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }
  
  String get lastRecognizedText => _lastRecognizedText;
}
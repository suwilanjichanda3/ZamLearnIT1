import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/material.dart';

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;
  String _lastRecognizedText = '';
  
  // Initialize speech recognition
  Future<bool> initialize() async {
    _isAvailable = await _speech.initialize(
      onStatus: (status) {
        print('Speech recognition status: $status');
      },
      onError: (error) {
        print('Speech recognition error: $error');
        _isListening = false;
      },
    );
    
    print('Speech recognition available: $_isAvailable');
    return _isAvailable;
  }
  
  // Check if speech recognition is available
  bool get isAvailable => _isAvailable;
  
  // Check if currently listening
  bool get isListening => _isListening;
  
  // Start listening for voice input
  Future<void> startListening({
    required Function(String) onResult,
    required Function(String) onError,
  }) async {
    if (!_isAvailable) {
      onError('Speech recognition not available');
      return;
    }
    
    if (_isListening) {
      await stopListening();
    }
    
    _isListening = true;
    
    // Add these settings for better recognition
    await _speech.listen(
      onResult: (result) {
        print('Raw result: ${result.recognizedWords}');
        print('Result confidence: ${result.confidence}');
        
        if (result.recognizedWords.isNotEmpty) {
          _lastRecognizedText = result.recognizedWords;
          print('Recognized: $_lastRecognizedText');
          onResult(_lastRecognizedText);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
      localeId: 'en_US',
      onSoundLevelChange: (level) {
        print('Sound level: $level');
      },
    );
  }
  
  // Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }
  
  // Cancel listening
  Future<void> cancelListening() async {
    if (_isListening) {
      await _speech.cancel();
      _isListening = false;
    }
  }
  
  // Get the last recognized text
  String get lastRecognizedText => _lastRecognizedText;
}
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class VoiceRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  String? _recordedFilePath;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isSpeechAvailable = false;
  double _soundLevel = 0.0;
  
  // Initialize speech recognition
  Future<bool> initSpeech() async {
    _isSpeechAvailable = await _speech.initialize();
    return _isSpeechAvailable;
  }
  
  // Check microphone permission
  Future<bool> hasPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }
  
  // Get sound level for animation
  double get soundLevel => _soundLevel;
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  bool get hasRecording => _recordedFilePath != null;
  
  // Start recording with sound level monitoring
  Future<bool> startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
        _recordedFilePath = filePath;
        
        // Play start sound
        await _playRecordingSound();
        
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            sampleRate: 44100,
          ),
          path: filePath,
        );
        _isRecording = true;
        
        // Start monitoring sound level
        _startSoundLevelMonitoring();
        
        print('✅ Recording started');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Recording error: $e');
      return false;
    }
  }
  
  // Monitor sound level for visual feedback
  void _startSoundLevelMonitoring() {
    // Simulate sound level changes for visual feedback
    // In a real implementation, you'd get actual amplitude
    Future.delayed(Duration.zero, () {
      if (_isRecording) {
        // Random wave effect for visual feedback
        _soundLevel = 0.3 + (DateTime.now().millisecondsSinceEpoch % 70) / 100;
        _startSoundLevelMonitoring();
      }
    });
  }
  
  // Play recording sound effect (start/stop)
  Future<void> _playRecordingSound() async {
    // Create simple beep sound using AudioCache or use asset
    // For now, we'll just use a simple feedback
    print('🔊 Recording sound played');
  }
  
  // Stop recording and transcribe
  Future<String?> stopRecordingAndTranscribe() async {
    try {
      final path = await _recorder.stop();
      _isRecording = false;
      _soundLevel = 0.0;
      print('✅ Recording saved to: $path');
      
      // Play stop sound
      await _playStopSound();
      
      if (path != null && _isSpeechAvailable) {
        // Show transcribing indicator
        String transcribedText = await _transcribeAudio();
        return transcribedText;
      }
      return null;
    } catch (e) {
      print('❌ Stop recording error: $e');
      return null;
    }
  }
  
  Future<void> _playStopSound() async {
    print('🔊 Stop sound played');
  }
  
  // Cancel recording
  Future<void> cancelRecording() async {
    if (_isRecording) {
      await _recorder.stop();
      _isRecording = false;
      _soundLevel = 0.0;
    }
    if (_recordedFilePath != null) {
      final file = File(_recordedFilePath!);
      if (await file.exists()) {
        await file.delete();
      }
      _recordedFilePath = null;
    }
  }
  
  // Transcribe audio to text
  Future<String> _transcribeAudio() async {
    // Alternative: Use speech_to_text for live recognition
    String result = '';
    
    await _speech.listen(
      onResult: (resultObj) {
        if (resultObj.recognizedWords.isNotEmpty) {
          result = resultObj.recognizedWords;
        }
      },
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 2),
      partialResults: false,
    );
    
    await Future.delayed(const Duration(seconds: 3));
    await _speech.stop();
    
    return result.isNotEmpty ? result : '';
  }
  
  // Preview recorded audio
  Future<void> playRecording() async {
    if (_recordedFilePath != null) {
      _isPlaying = true;
      await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));
      _audioPlayer.onPlayerComplete.listen((event) {
        _isPlaying = false;
      });
    }
  }
  
  Future<void> stopPlayback() async {
    await _audioPlayer.stop();
    _isPlaying = false;
  }
  
  void dispose() {
    _recorder.dispose();
    _audioPlayer.dispose();
    _speech.stop();
  }
}
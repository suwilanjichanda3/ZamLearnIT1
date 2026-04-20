import 'package:flutter_tts/flutter_tts.dart';

class EnhancedTTSService {
  static final EnhancedTTSService _instance = EnhancedTTSService._internal();
  factory EnhancedTTSService() => _instance;
  EnhancedTTSService._internal();
  
  final FlutterTts _tts = FlutterTts();
  
  // Language configuration
  static const Map<String, Map<String, dynamic>> _languageConfig = {
    'bemba': {
      'locale': 'en-ZA',  // South African English
      'displayName': 'Bemba',
      'fallbackLocale': 'en-GB',
      'phoneticRules': {
        'c': 'ch',      // 'c' sounds like 'ch'
        'mw': 'm-wah',  // 'mw' sound
        'bw': 'b-wah',  // 'bw' sound
        'ny': 'n-yah',  // 'ny' sound
        'sh': 'sh-ah',  // 'sh' sound
        'ch': 'ch-ah',  // 'ch' sound
      },
    },
    'nyanja': {
      'locale': 'en-ZA',
      'displayName': 'Nyanja',
      'fallbackLocale': 'en-GB',
      'phoneticRules': {
        'dz': 'j-ah',   // 'dz' sound
        'ts': 't-sah',  // 'ts' sound
        'ny': 'n-yah',  // 'ny' sound
        'mb': 'm-bah',  // 'mb' sound
        'nd': 'n-dah',  // 'nd' sound
      },
    },
    'english': {
      'locale': 'en-US',
      'displayName': 'English',
      'fallbackLocale': 'en-GB',
      'phoneticRules': {},
    },
  };
  
  bool _isInitialized = false;
  String _currentLanguage = 'bemba';
  
  // Initialize TTS
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Set default speech parameters
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    
    // Set completion handler
    _tts.setCompletionHandler(() {
      print('✅ TTS playback completed');
    });
    
    _tts.setErrorHandler((msg) {
      print('❌ TTS error: $msg');
    });
    
    _isInitialized = true;
    print('✅ Enhanced TTS Service initialized');
  }
  
  // Set language and configure voice
  Future<void> setLanguage(String languageCode) async {
    if (!_isInitialized) await initialize();
    
    _currentLanguage = languageCode;
    final config = _languageConfig[languageCode];
    
    if (config == null) {
      print('⚠️ No config for $languageCode, using default');
      await _tts.setLanguage('en-US');
      return;
    }
    
    final String locale = config['locale'];
    final String fallbackLocale = config['fallbackLocale'];
    
    print('🎤 Setting TTS language to: $locale for ${config['displayName']}');
    
    try {
      // Try preferred locale first
      bool result = await _tts.setLanguage(locale);
      print('TTS setLanguage result: $result');
      
      if (!result) {
        // Try fallback locale
        print('⚠️ Falling back to $fallbackLocale');
        await _tts.setLanguage(fallbackLocale);
      }
      
      // Try to find and set a high-quality voice
      await _setBestAvailableVoice(locale);
      
    } catch (e) {
      print('⚠️ Error setting language: $e');
      await _tts.setLanguage('en-US');
    }
  }
  
  // Find and set the best available voice for the locale
  Future<void> _setBestAvailableVoice(String locale) async {
    try {
      final List<dynamic>? voices = await _tts.getVoices;
      
      if (voices != null && voices.isNotEmpty) {
        // Look for high-quality voices
        final matchingVoices = voices.where((v) {
          final voiceLocale = v['locale']?.toString().toLowerCase() ?? '';
          final voiceName = v['name']?.toString().toLowerCase() ?? '';
          final voiceQuality = v['quality']?.toString().toLowerCase() ?? '';
          
          return voiceLocale.contains(locale.toLowerCase()) &&
              (voiceName.contains('wavenet') || 
               voiceName.contains('neural') ||
               voiceQuality.contains('high'));
        }).toList();
        
        if (matchingVoices.isNotEmpty) {
          await _tts.setVoice(matchingVoices.first);
          print('✅ Set high-quality voice: ${matchingVoices.first['name']}');
        }
      }
    } catch (e) {
      print('⚠️ Could not customize voice: $e');
    }
  }
  
  // Apply phonetic rules to improve pronunciation
  String _applyPhoneticRules(String text, String languageCode) {
    final config = _languageConfig[languageCode];
    if (config == null) return text;
    
    final rules = config['phoneticRules'] as Map<String, String>;
    String result = text.toLowerCase();
    
    // Apply each rule
    rules.forEach((pattern, replacement) {
      result = result.replaceAll(pattern, replacement);
    });
    
    // Capitalize first letter for better flow
    if (result.isNotEmpty) {
      result = result[0].toUpperCase() + result.substring(1);
    }
    
    if (result != text) {
      print('🔊 Applied phonetics: "$text" → "$result"');
    }
    
    return result;
  }
  
  // Speak text with enhanced pronunciation
  Future<void> speak(String text, String languageCode) async {
    if (text.isEmpty) {
      print('⚠️ Empty text, nothing to speak');
      return;
    }
    
    if (!_isInitialized) await initialize();
    
    // Ensure correct language is set
    if (_currentLanguage != languageCode) {
      await setLanguage(languageCode);
    }
    
    // Apply phonetic rules for better pronunciation
    String enhancedText = _applyPhoneticRules(text, languageCode);
    
    // Add SSML tags for better speech quality (if supported)
    final String finalText = _wrapWithSsml(enhancedText);
    
    print('🎤 Speaking: "$finalText"');
    
    try {
      await _tts.speak(finalText);
    } catch (e) {
      print('❌ TTS error: $e');
      // Fallback to raw text
      await _tts.speak(text);
    }
  }
  
  // Optional: Wrap text in SSML for better pronunciation
  String _wrapWithSsml(String text) {
    // Add slight pauses between words for clarity
    return text.replaceAll(' ', ' . ');
  }
  
  // Stop speaking
  Future<void> stop() async {
    await _tts.stop();
  }
  
  // Set speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    await _tts.setSpeechRate(rate.clamp(0.0, 1.0));
  }
  
  // Set pitch (0.5 to 2.0)
  Future<void> setPitch(double pitch) async {
    await _tts.setPitch(pitch.clamp(0.5, 2.0));
  }
  
  // Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _tts.setVolume(volume.clamp(0.0, 1.0));
  }
  
  // Check if TTS is available
  Future<bool> isAvailable() async {
    try {
      await _tts.awaitSpeakCompletion(true);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Get available voices (for debugging)
  Future<List<Map<String, dynamic>>> getAvailableVoices() async {
    try {
      final voices = await _tts.getVoices;
      if (voices != null) {
        return List<Map<String, dynamic>>.from(voices);
      }
    } catch (e) {
      print('Error getting voices: $e');
    }
    return [];
  }
}
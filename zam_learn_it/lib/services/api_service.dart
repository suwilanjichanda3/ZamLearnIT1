import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Update this with your actual backend URL
 static const String baseUrl =  'https://freddy-nonvisualized-improvably.ngrok-free.dev'; // For Android emulator

  // Check if server is healthy
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  // Get available languages
  static Future<List<String>> getLanguages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/languages'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['languages']);
      }
      return ['bemba', 'nyanja'];
    } catch (e) {
      print('Error loading languages: $e');
      return ['bemba', 'nyanja'];
    }
  }

  // Translate text
  static Future<Map<String, dynamic>> translateText(String text, String language) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'target_language': language,
        }),
      ).timeout(const Duration(seconds: 20));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'error': 'Translation failed'};
    } catch (e) {
      print('Translation error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get translation history
  static Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/history'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['history']);
      }
      return [];
    } catch (e) {
      print('Error loading history: $e');
      return [];
    }
  }

  // Submit translation suggestion for training (OPTIONAL - doesn't block if fails)
  static Future<Map<String, dynamic>> submitTranslationSuggestion({
    required String originalText,
    required String currentTranslation,
    required String suggestedTranslation,
    required String language,
    required String note,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/submit-suggestion'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'original': originalText,
          'current_translation': currentTranslation,
          'suggested_translation': suggestedTranslation,
          'language': language,
          'note': note,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 3)); // Short timeout so it doesn't hang
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Suggestion submitted to backend');
        return jsonDecode(response.body);
      } else {
        print('⚠️ Backend returned ${response.statusCode}, but continuing...');
        return {'success': true, 'local_only': true, 'message': 'Saved locally only'};
      }
    } catch (e) {
      // Don't throw - this is optional. Just log and continue.
      print('⚠️ Could not reach backend for suggestion: $e');
      return {'success': true, 'local_only': true, 'message': 'Saved locally only'};
    }
  }

  // Save improved translation to user's history (OPTIONAL - doesn't block if fails)
  static Future<Map<String, dynamic>> saveImprovedTranslation({
    required String originalText,
    required String improvedTranslation,
    required String language,
    required String originalTranslation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/save-improved-translation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'original': originalText,
          'translated': improvedTranslation,
          'language': language,
          'original_translation': originalTranslation,
          'is_improved': true,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Improved translation saved to backend');
        return jsonDecode(response.body);
      } else {
        print('⚠️ Backend returned ${response.statusCode}, but continuing...');
        return {'success': true, 'local_only': true};
      }
    } catch (e) {
      // Don't throw - this is optional. Just log and continue.
      print('⚠️ Could not reach backend for improved translation: $e');
      return {'success': true, 'local_only': true};
    }
  }
}
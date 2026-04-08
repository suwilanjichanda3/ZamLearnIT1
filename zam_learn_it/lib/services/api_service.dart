import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiService {
  static String? _baseUrl;
  
  static Future<String> getBaseUrl() async {
    _baseUrl ??= await ApiConfig.getBaseUrl();
    return _baseUrl!;
  }
  
  static Future<void> setBaseUrl(String url) async {
    await ApiConfig.saveBaseUrl(url);
    _baseUrl = url;
  }
  
  static Future<bool> checkHealth() async {
    try {
      final baseUrl = await getBaseUrl();
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
  
  // Update all other methods to use await getBaseUrl()
  static Future<Map<String, dynamic>> translateText(String text, String targetLanguage) async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'target_language': targetLanguage,
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Translation error: $e');
      return {
        'success': false,
        'error': 'Connection error: $e'
      };
    }
  }
  
  // Similarly update getHistory, deleteHistoryItem, etc.
}
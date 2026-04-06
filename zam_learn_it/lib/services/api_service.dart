import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this to your backend IP address
  // For Android emulator: 10.0.2.2
  // For physical device: Your computer's IP address (e.g., 192.168.1.100)
  static const String baseUrl = 'http://localhost:8000'; 
  
  // Check if backend is healthy/running
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
  
  // Get list of supported languages
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
      return ['bemba', 'nyanja']; // Default fallback
    } catch (e) {
      print('Error loading languages: $e');
      return ['bemba', 'nyanja'];
    }
  }
  
  // Translate text
  static Future<Map<String, dynamic>> translateText(String text, String targetLanguage) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'target_language': targetLanguage,
        }),
      ).timeout(const Duration(seconds: 30)); // Translation might take a few seconds
      
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
  
  // Get all translation history
  static Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/history'),
        headers: {'Content-Type': 'application/json'},
      );
      
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
  
  // Delete a single history item by ID
  static Future<bool> deleteHistoryItem(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/history/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting history item: $e');
      return false;
    }
  }
  
  // Clear all history
  static Future<bool> clearAllHistory() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/history/all'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error clearing history: $e');
      return false;
    }
  }
  
  // Get a single history item by ID
  static Future<Map<String, dynamic>?> getHistoryItem(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/history/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting history item: $e');
      return null;
    }
  }
}
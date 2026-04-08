import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String defaultUrl = 'http://192.168.43.52:8000'; // Fallback
  static const String adbUrl = 'http://localhost:8000';
  
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    
    // First, check if we have a saved URL
    String? savedUrl = prefs.getString('api_base_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      return savedUrl;
    }
    
    // Second, try localhost (works with ADB reverse)
    if (await _testConnection(adbUrl)) {
      await saveBaseUrl(adbUrl);
      return adbUrl;
    }
    
    // Finally, fall back to default
    await saveBaseUrl(defaultUrl);
    return defaultUrl;
  }
  
  static Future<void> saveBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', url);
  }
  
  static Future<bool> _testConnection(String url) async {
    try {
      final response = await http.get(
        Uri.parse('$url/health'),
        timeout: const Duration(seconds: 2),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
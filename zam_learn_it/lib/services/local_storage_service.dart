import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();
  
  static const String _improvedTranslationsKey = 'improved_translations';
  
  Future<void> saveImprovedTranslation({
    required String original,
    required String improvedTranslation,
    required String language,
    required String originalTranslation,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> improvedList = await getImprovedTranslations();
    
    improvedList.add({
      'original': original,
      'translated': improvedTranslation,
      'language': language,
      'original_translation': originalTranslation,
      'is_improved': true,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    await prefs.setString(
      _improvedTranslationsKey,
      jsonEncode(improvedList),
    );
    
    print("✅ Improved translation saved locally: $original -> $improvedTranslation");
  }
  
  Future<List<Map<String, dynamic>>> getImprovedTranslations() async {
    final prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_improvedTranslationsKey);
    
    if (saved == null || saved.isEmpty) {
      return [];
    }
    
    try {
      List<dynamic> decoded = jsonDecode(saved);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print("Error loading improved translations: $e");
      return [];
    }
  }
}
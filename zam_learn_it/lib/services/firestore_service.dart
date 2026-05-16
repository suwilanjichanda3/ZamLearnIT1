import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String get _userId => 'anonymous_user';
  
  // Save a translation to Firestore
  Future<void> saveTranslation({
    required String original,
    required String translated,
    required String language,
    bool isUserSuggestion = false,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('translations')
          .add({
        'original': original,
        'translated': translated,
        'language': language,
        'timestamp': FieldValue.serverTimestamp(),
        'is_user_suggestion': isUserSuggestion,
      });
      print('✅ Translation saved to Firebase');
    } catch (e) {
      print('❌ Error saving translation: $e');
    }
  }
  
  // Get user-suggested translation (personal)
  Future<String?> getUserSuggestion(String original, String language) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('suggestions')
          .where('original', isEqualTo: original.toLowerCase().trim())
          .where('language', isEqualTo: language)
          .where('verified', isEqualTo: true)
          .orderBy('confidence', descending: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data()['suggested'];
      }
      return null;
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }
  
  // COMMUNITY LEARNING: Get suggestions from ALL users (TEMPORARY FIX - removed orderBy)
  Future<String?> getGlobalSuggestion(String original, String language) async {
    try {
      print('🌍 Checking community suggestions for "$original" in $language');
      
      // TEMPORARY FIX: Removed orderBy to avoid index requirement
      final snapshot = await _firestore
          .collection('global_suggestions')
          .where('original', isEqualTo: original.toLowerCase().trim())
          .where('language', isEqualTo: language)
          .where('verified', isEqualTo: true)
          // .orderBy('confidence', descending: true)  // Commented out - add back after index created
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final suggestion = snapshot.docs.first.data()['suggested'];
        final confidence = snapshot.docs.first.data()['confidence'] ?? 0;
        print('🌍 Found community suggestion: "$suggestion" (confidence: $confidence)');
        return suggestion;
      }
      print('🌍 No community suggestion found for "$original"');
      return null;
    } catch (e) {
      print('❌ Error checking community suggestions: $e');
      return null;
    }
  }
  
  // COMMUNITY LEARNING: Save suggestion that benefits ALL users
  Future<Map<String, dynamic>> saveGlobalSuggestion({
    required String original,
    required String currentTranslation,
    required String suggestedTranslation,
    required String language,
    required String note,
  }) async {
    try {
      print('🌍 Saving community suggestion for "$original" → "$suggestedTranslation"');
      
      // Check if this suggestion already exists in global_suggestions
      final existing = await _firestore
          .collection('global_suggestions')
          .where('original', isEqualTo: original.toLowerCase().trim())
          .where('language', isEqualTo: language)
          .get();
      
      if (existing.docs.isNotEmpty) {
        // Update existing suggestion - increase confidence
        final doc = existing.docs.first;
        final currentConfidence = doc.data()['confidence'] ?? 1;
        final newConfidence = currentConfidence + 1;
        
        await doc.reference.update({
          'suggested': suggestedTranslation,
          'confidence': newConfidence,
          'times_suggested': FieldValue.increment(1),
          'last_used': FieldValue.serverTimestamp(),
        });
        print('🌍 Updated existing community suggestion (confidence: $newConfidence)');
      } else {
        // Create new suggestion
        await _firestore
            .collection('global_suggestions')
            .add({
          'original': original.toLowerCase().trim(),
          'original_case': original,
          'current_translation': currentTranslation,
          'suggested': suggestedTranslation,
          'language': language,
          'note': note,
          'confidence': 1,
          'times_suggested': 1,
          'verified': true,
          'suggested_by': _userId,
          'created_at': FieldValue.serverTimestamp(),
        });
        print('🌍 Created new community suggestion');
      }
      
      // Also save to personal history
      await saveTranslation(
        original: original,
        translated: suggestedTranslation,
        language: language,
        isUserSuggestion: true,
      );
      
      print('🌍 Community suggestion saved successfully!');
      return {'success': true};
    } catch (e) {
      print('❌ Error saving community suggestion: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Get ALL community suggestions for the History page
  Future<List<Map<String, dynamic>>> getGlobalSuggestions() async {
    try {
      print('📚 Fetching all community suggestions...');
      
      final snapshot = await _firestore
          .collection('global_suggestions')
          .orderBy('confidence', descending: true)
          .limit(50)
          .get();
      
      final suggestions = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'original': data['original'] ?? '',
          'suggested': data['suggested'] ?? '',
          'language': data['language'] ?? '',
          'confidence': data['confidence'] ?? 0,
          'times_suggested': data['times_suggested'] ?? 0,
        };
      }).toList();
      
      print('📚 Found ${suggestions.length} community suggestions');
      return suggestions;
    } catch (e) {
      print('❌ Error getting community suggestions: $e');
      return [];
    }
  }
  
  // Get translation history
  Future<List<Map<String, dynamic>>> getHistoryOnce() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('translations')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'original': data['original'] ?? 'Unknown',
          'translated': data['translated'] ?? '',
          'language': data['language'] ?? '',
          'timestamp': data['timestamp']?.toDate().toString() ?? '',
          'is_user_suggestion': data['is_user_suggestion'] == true,
        };
      }).toList();
    } catch (e) {
      print('Error getting history: $e');
      return [];
    }
  }
  
  // Delete a translation
  Future<void> deleteTranslation(String docId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('translations')
          .doc(docId)
          .delete();
      print('✅ Translation deleted');
    } catch (e) {
      print('Error deleting: $e');
    }
  }
  
  // Clear all history
  Future<void> clearAllHistory() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('translations')
          .get();
      
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      print('✅ All history cleared');
    } catch (e) {
      print('Error clearing: $e');
    }
  }
}
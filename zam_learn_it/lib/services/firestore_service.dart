import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Using 'anonymous' for now (we can add user login later)
  String get _userId => 'anonymous_user';
  
  // Save a translation to Firestore
  Future<void> saveTranslation({
    required String original,
    required String translated,
    required String language,
  }) async {
    try {
      print('💾 Saving to Firestore: "$original" -> "$translated"');
      final docRef = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('translations')
          .add({
        'original': original,
        'translated': translated,
        'language': language,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('✅ Translation saved to Firebase with ID: ${docRef.id}');
    } catch (e) {
      print('❌ Error saving translation: $e');
    }
  }
  
  // Get translation history as a stream (real-time updates)
  Stream<List<Map<String, dynamic>>> getHistoryStream() {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('translations')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          print('📡 Stream update: ${snapshot.docs.length} documents');
          return snapshot.docs.map((doc) {
            return {
              'id': doc.id,
              'original': doc['original'] ?? '',
              'translated': doc['translated'] ?? '',
              'language': doc['language'] ?? '',
              'timestamp': doc['timestamp']?.toDate().toString() ?? '',
            };
          }).toList();
        });
  }
  
  // Get translation history once (non-streaming, for one-time fetch)
  Future<List<Map<String, dynamic>>> getHistoryOnce() async {
    try {
      print('📡 Fetching history from Firestore once...');
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('translations')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();
      
      print('📦 Firestore returned ${snapshot.docs.length} documents');
      
      // Print each document for debugging
      for (var doc in snapshot.docs) {
        print('   - ${doc.id}: ${doc['original']} -> ${doc['translated']} (${doc['language']})');
      }
      
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'original': doc['original'] ?? '',
          'translated': doc['translated'] ?? '',
          'language': doc['language'] ?? '',
          'timestamp': doc['timestamp']?.toDate().toString() ?? '',
        };
      }).toList();
    } catch (e) {
      print('❌ Error getting history from Firestore: $e');
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
      print('✅ Translation deleted from Firebase: $docId');
    } catch (e) {
      print('❌ Error deleting translation: $e');
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
      
      print('🗑️ Clearing ${snapshot.docs.length} translations...');
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      print('✅ All history cleared from Firebase');
    } catch (e) {
      print('❌ Error clearing history: $e');
    }
  }
}
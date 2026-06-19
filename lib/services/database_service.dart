import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_result.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

  Future<void> saveScan({
    required String type,
    required String input,
    required ScanResult result,
  }) async {
    final timestamp = DateTime.now().toIso8601String();

    // 1. Always save locally to SharedPreferences for offline-first, zero-lag personal history
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? localScansJson = prefs.getString('local_scans_history');
      List<dynamic> localScans = [];
      if (localScansJson != null) {
        localScans = jsonDecode(localScansJson);
      }
      localScans.insert(0, {
        'type': type,
        'input': input,
        'risk_level': result.riskLevel.name,
        'risk_score': result.score,
        'advice': result.advice,
        'timestamp': timestamp,
      });
      // Limit local history to top 50 items
      if (localScans.length > 50) {
        localScans = localScans.sublist(0, 50);
      }
      await prefs.setString('local_scans_history', jsonEncode(localScans));
    } catch (e) {
      debugPrint("Failed to save local scan history: $e");
    }

    // 2. Save to Firestore cloud database only if we have a valid unique user session (not anonymous placeholder)
    if (_uid != 'anonymous') {
      try {
        await _db
            .collection('users')
            .doc(_uid)
            .collection('scans')
            .add({
          'type': type,
          'input': input,
          'risk_level': result.riskLevel.name,
          'risk_score': result.score,
          'advice': result.advice,
          'scam_type': result.riskLevel.name,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint("Failed to sync scan to Firestore: $e");
      }
    }
  }

  /// Returns a stream of scan records.
  /// If the user is authenticated (uid != 'anonymous'), it streams from Firestore.
  /// If the user is unauthenticated or offline, it streams their local personal history.
  Stream<List<Map<String, dynamic>>> getScanHistoryStream() async* {
    if (_uid == 'anonymous') {
      yield* _getLocalScansStream();
    } else {
      yield* _db
          .collection('users')
          .doc(_uid)
          .collection('scans')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'type': data['type'] ?? 'SCAN',
                'input': data['input'] ?? '',
                'risk_level': data['risk_level'] ?? 'safe',
                'risk_score': (data['risk_score'] as num?)?.toDouble() ?? 0.0,
                'advice': data['advice'] ?? '',
                'timestamp': data['timestamp'] != null 
                    ? (data['timestamp'] as Timestamp).toDate().toIso8601String()
                    : DateTime.now().toIso8601String(),
              };
            }).toList();
          });
    }
  }

  Stream<List<Map<String, dynamic>>> _getLocalScansStream() async* {
    final prefs = await SharedPreferences.getInstance();
    final String? localScansJson = prefs.getString('local_scans_history');
    if (localScansJson != null) {
      final List<dynamic> decoded = jsonDecode(localScansJson);
      yield decoded.cast<Map<String, dynamic>>();
    } else {
      yield [];
    }
  }

  Future<void> saveUserProfile(String name, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_phone', phone);

    if (_uid != 'anonymous') {
      await _db.collection('users').doc(_uid).set({
        'name': name,
        'phone': phone,
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}
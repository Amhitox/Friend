import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Service for managing user referrals and rewards.
///
/// Referral rewards:
/// - Referrer: 3 days Premium access
/// - Referred: 7 days free trial
class ReferralService {
  static const String _referralCodeKey = 'user_referral_code';
  static const String _referralCountKey = 'referral_count';
  static const int _referrerRewardDays = 3;
  static const int _referredRewardDays = 7;
  static const String _codePrefix = 'DOSTOK';
  static const int _codeLength = 8;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Generates a unique referral code for the current user.
  ///
  /// Format: DOSTOK + 8 random alphanumeric characters
  /// Stores in Firestore under users/{uid}/referral/code
  Future<String> generateReferralCode() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check if user already has a code
    final existingCode = await _getExistingCode(user.uid);
    if (existingCode != null) return existingCode;

    // Generate unique code
    final code = _generateUniqueCode();

    // Store in Firestore
    await _firestore.collection('users').doc(user.uid).collection('referral').doc('code').set({
      'code': code,
      'createdAt': FieldValue.serverTimestamp(),
      'totalReferrals': 0,
      'successfulReferrals': 0,
    });

    // Store code lookup for validation
    await _firestore.collection('referral_codes').doc(code).set({
      'uid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });

    // Cache locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_referralCodeKey, code);

    return code;
  }

  /// Shares the referral link via platform share sheet.
  ///
  /// Uses share_plus for native sharing on both Android and iOS.
  Future<void> shareReferral() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final code = await generateReferralCode();
    final userName = user.displayName ?? 'Sahbek';

    final message = '''
Salam! $userName kay hdak b Dostok! 🇲🇦

T3allam Darija m3a AI companion dyalna - hadchi li 3jbni bzaf!

 استخدم كودي: $code

📱 Download Dostok:
https://play.google.com/store/apps/details?id=com.dostok.darija_friend

#Dostok #Darija #Morocco #تعلم_الدارجة
''';

    try {
      await Share.share(
        message,
        subject: 'Join me on Dostok - Learn Darija!',
      );

      // Track share event
      await _trackShareEvent(user.uid);
    } catch (e) {
      debugPrint('Error sharing referral: $e');
      rethrow;
    }
  }

  /// Applies a referral code for the current user.
  ///
  /// Returns true if successful, throws on validation failure.
  /// Rewards:
  /// - Referrer: 3 days Premium added to their account
  /// - Referred (current user): 7 days trial
  Future<bool> applyReferralCode(String code) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Validate code format
    if (!_isValidCodeFormat(code)) {
      throw ReferralException('Kod mashi s7i7. T2kkd mn l kod.');
    }

    // Check if user already used a referral
    final hasUsedReferral = await _hasUsedReferral(user.uid);
    if (hasUsedReferral) {
      throw ReferralException('Sst3malti kod mn 9bl. Ma ymknch t3awd.');
    }

    // Look up code in Firestore
    final codeDoc = await _firestore.collection('referral_codes').doc(code).get();
    if (!codeDoc.exists) {
      throw ReferralException('Kod mashi s7i7 aw ma kaynch.');
    }

    final codeData = codeDoc.data()!;
    final referrerUid = codeData['uid'] as String;
    final isActive = codeData['isActive'] as bool;

    if (!isActive) {
      throw ReferralException('Had l kod ma3adch khdem.');
    }

    // Cannot refer yourself
    if (referrerUid == user.uid) {
      throw ReferralException('Ma ymknch tsta3ml kod dyalek nta!');
    }

    // Apply rewards in transaction
    await _firestore.runTransaction((transaction) async {
      // Record the referral
      final referralRef = _firestore.collection('referrals').doc();
      transaction.set(referralRef, {
        'referrerUid': referrerUid,
        'referredUid': user.uid,
        'code': code,
        'createdAt': FieldValue.serverTimestamp(),
        'referrerRewardDays': _referrerRewardDays,
        'referredRewardDays': _referredRewardDays,
        'status': 'completed',
      });

      // Update referrer's stats
      final referrerRef = _firestore.collection('users').doc(referrerUid).collection('referral').doc('code');
      transaction.update(referrerRef, {
        'totalReferrals': FieldValue.increment(1),
        'successfulReferrals': FieldValue.increment(1),
      });

      // Record in user's referral history
      final userReferralRef = _firestore.collection('users').doc(user.uid).collection('referral').doc('used');
      transaction.set(userReferralRef, {
        'usedCode': code,
        'referredBy': referrerUid,
        'usedAt': FieldValue.serverTimestamp(),
        'rewardDays': _referredRewardDays,
      });
    });

    // Apply rewards
    await _applyReferrerReward(referrerUid);
    await _applyReferredReward(user.uid);

    // Track analytics
    await _trackReferralApplied(user.uid, referrerUid);

    return true;
  }

  /// Gets the current user's referral code (cached or from Firestore).
  Future<String?> getMyReferralCode() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // Check cache first
    final prefs = await SharedPreferences.getInstance();
    final cachedCode = prefs.getString(_referralCodeKey);
    if (cachedCode != null) return cachedCode;

    // Fetch from Firestore
    return _getExistingCode(user.uid);
  }

  /// Gets the count of successful referrals by the current user.
  Future<int> getReferralCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('referral')
          .doc('code')
          .get();

      if (doc.exists) {
        return doc.data()?['successfulReferrals'] as int? ?? 0;
      }
    } catch (e) {
      debugPrint('Error getting referral count: $e');
    }

    return 0;
  }

  /// Gets the referral chain (who referred whom).
  Future<List<Map<String, dynamic>>> getReferralChain() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('referrals')
          .where('referrerUid', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'referredUid': data['referredUid'],
          'createdAt': data['createdAt'],
          'status': data['status'],
          'rewardDays': data['referrerRewardDays'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting referral chain: $e');
      return [];
    }
  }

  /// Checks if the current user can apply a referral code.
  Future<bool> canApplyReferralCode() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    return !(await _hasUsedReferral(user.uid));
  }

  // Private helpers

  Future<String?> _getExistingCode(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).collection('referral').doc('code').get();
      if (doc.exists) {
        return doc.data()?['code'] as String?;
      }
    } catch (e) {
      debugPrint('Error getting existing code: $e');
    }
    return null;
  }

  String _generateUniqueCode() {
    final random = Random.secure();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final randomPart = List.generate(
      _codeLength,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
    return '$_codePrefix$randomPart';
  }

  bool _isValidCodeFormat(String code) {
    final pattern = RegExp(r'^DOSTOK[A-Z0-9]{8}$');
    return pattern.hasMatch(code.toUpperCase());
  }

  Future<bool> _hasUsedReferral(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).collection('referral').doc('used').get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking referral usage: $e');
      return false;
    }
  }

  Future<void> _applyReferrerReward(String referrerUid) async {
    try {
      // Get current subscription end date or now
      final userDoc = await _firestore.collection('users').doc(referrerUid).get();
      final userData = userDoc.data();

      DateTime startDate;
      if (userData != null && userData['premiumExpiresAt'] != null) {
        final expiry = (userData['premiumExpiresAt'] as Timestamp).toDate();
        startDate = expiry.isAfter(DateTime.now()) ? expiry : DateTime.now();
      } else {
        startDate = DateTime.now();
      }

      final newExpiry = startDate.add(const Duration(days: _referrerRewardDays));

      await _firestore.collection('users').doc(referrerUid).update({
        'premiumExpiresAt': Timestamp.fromDate(newExpiry),
        'isPremium': true,
        'lastReferralReward': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error applying referrer reward: $e');
    }
  }

  Future<void> _applyReferredReward(String referredUid) async {
    try {
      final now = DateTime.now();
      final trialEnd = now.add(const Duration(days: _referredRewardDays));

      await _firestore.collection('users').doc(referredUid).update({
        'trialExpiresAt': Timestamp.fromDate(trialEnd),
        'isPremium': true,
        'subscriptionSource': 'referral',
        'referralTrialStart': Timestamp.fromDate(now),
      });
    } catch (e) {
      debugPrint('Error applying referred reward: $e');
    }
  }

  Future<void> _trackShareEvent(String uid) async {
    try {
      await _firestore.collection('analytics').add({
        'event': 'referral_shared',
        'uid': uid,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.toString(),
      });
    } catch (e) {
      debugPrint('Error tracking share event: $e');
    }
  }

  Future<void> _trackReferralApplied(String referredUid, String referrerUid) async {
    try {
      await _firestore.collection('analytics').add({
        'event': 'referral_applied',
        'referredUid': referredUid,
        'referrerUid': referrerUid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error tracking referral applied: $e');
    }
  }
}

/// Custom exception for referral-related errors.
class ReferralException implements Exception {
  final String message;
  const ReferralException(this.message);

  @override
  String toString() => message;
}

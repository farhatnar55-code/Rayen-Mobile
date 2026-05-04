import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rayen_mobile/core/utils/app_timestamp.dart';

abstract class SubscriptionRepository {
  Future<void> activateSubscription({
    required String userId,
    required String planId,
    required String paymentId,
    required DateTime expiryDate,
  });

  Future<bool> checkSubscriptionStatus(String userId);
}

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> activateSubscription({
    required String userId,
    required String planId,
    required String paymentId,
    required DateTime expiryDate,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'isSubscribed': true,
      'subscriptionPlan': planId,
      'subscriptionPaymentId': paymentId,
      'subscriptionExpiry': AppTimestamp.toFirestore(expiryDate),
      'subscriptionActivatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<bool> checkSubscriptionStatus(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return false;

    final data = doc.data()!;
    final isSubscribed = data['isSubscribed'] as bool? ?? false;
    if (!isSubscribed) return false;

    final expiry = AppTimestamp.fromFirestore(data['subscriptionExpiry']);
    if (expiry == null) return false;

    return expiry.isAfter(DateTime.now());
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rayen_mobile/core/utils/app_timestamp.dart';
import 'package:rayen_mobile/features/notifications/domain/models/app_notification_model.dart';
import 'package:uuid/uuid.dart';

class NotificationRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('notifications');

  Future<AppNotificationModel> createNotification(
    AppNotificationModel notification,
  ) async {
    final id = notification.id.isEmpty ? _uuid.v4() : notification.id;
    final map = notification.toMap();
    await _collection.doc(id).set(map);
    return AppNotificationModel.fromMap(map, id);
  }

  Future<List<AppNotificationModel>> getNotifications(String userId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => AppNotificationModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<int> getUnreadCount(String userId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    return snapshot.size;
  }

  Future<void> markAsRead(String notificationId) async {
    await _collection.doc(notificationId).update({
      'isRead': true,
      'readAt': AppTimestamp.toFirestore(DateTime.now()),
    });
  }

  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': AppTimestamp.toFirestore(DateTime.now()),
      });
    }
    await batch.commit();
  }
}

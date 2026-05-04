import 'package:flutter_test/flutter_test.dart';
import 'package:rayen_mobile/features/notifications/domain/models/app_notification_model.dart';
import 'package:rayen_mobile/features/notifications/domain/repositories/notification_repository.dart';
import 'package:rayen_mobile/features/notifications/presentation/providers/notification_provider.dart';

class _FakeNotificationRepository implements NotificationRepository {
  final List<AppNotificationModel> notifications = [];

  @override
  Future<AppNotificationModel> createNotification(
    AppNotificationModel notification,
  ) async {
    final created = notification;
    notifications.insert(0, created);
    return created;
  }

  @override
  Future<List<AppNotificationModel>> getNotifications(String userId) async =>
      notifications.where((n) => n.userId == userId).toList();

  @override
  Future<int> getUnreadCount(String userId) async =>
      notifications.where((n) => n.userId == userId && !n.isRead).length;

  @override
  Future<void> markAsRead(String notificationId) async {
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    for (var i = 0; i < notifications.length; i++) {
      if (notifications[i].userId == userId) {
        notifications[i] = notifications[i].copyWith(isRead: true);
      }
    }
  }
}

void main() {
  test('tracks unread notifications', () async {
    final repo = _FakeNotificationRepository();
    final provider = NotificationProvider(repo);

    await provider.createNotification(
      AppNotificationModel(
        id: '1',
        userId: 'u1',
        type: AppNotificationType.enrollmentRequested,
        title: 'New request',
        body: 'body',
        isRead: false,
        createdAt: DateTime.now(),
      ),
    );

    expect(provider.unreadCount, 1);
    expect(provider.notifications, hasLength(1));
  });
}

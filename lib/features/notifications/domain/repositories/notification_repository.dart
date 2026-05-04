import 'package:rayen_mobile/features/notifications/domain/models/app_notification_model.dart';

abstract class NotificationRepository {
  Future<AppNotificationModel> createNotification(
    AppNotificationModel notification,
  );
  Future<List<AppNotificationModel>> getNotifications(String userId);
  Future<int> getUnreadCount(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
}

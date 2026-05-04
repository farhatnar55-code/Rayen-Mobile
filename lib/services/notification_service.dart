import 'package:rayen_mobile/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:rayen_mobile/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:rayen_mobile/features/notifications/domain/models/app_notification_model.dart';

class NotificationService {
  final NotificationRepositoryImpl _repository;

  NotificationService()
      : _repository = NotificationRepositoryImpl(
          NotificationRemoteDataSource(),
        );

  Future<AppNotificationModel?> notifyUser({
    required String userId,
    required AppNotificationType type,
    required String title,
    required String body,
    String? targetRoute,
    Map<String, dynamic>? metadata,
  }) {
    return _repository.createNotification(
      AppNotificationModel(
        id: '',
        userId: userId,
        type: type,
        title: title,
        body: body,
        isRead: false,
        createdAt: DateTime.now(),
        targetRoute: targetRoute,
        metadata: metadata,
      ),
    );
  }

  Future<List<AppNotificationModel>> getNotifications(String userId) =>
      _repository.getNotifications(userId);

  Future<int> getUnreadCount(String userId) => _repository.getUnreadCount(userId);

  Future<void> markAsRead(String notificationId) =>
      _repository.markAsRead(notificationId);

  Future<void> markAllAsRead(String userId) => _repository.markAllAsRead(userId);
}

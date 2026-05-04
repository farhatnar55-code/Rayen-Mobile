import 'package:rayen_mobile/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:rayen_mobile/features/notifications/domain/models/app_notification_model.dart';
import 'package:rayen_mobile/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _dataSource;

  NotificationRepositoryImpl(this._dataSource);

  @override
  Future<AppNotificationModel> createNotification(
    AppNotificationModel notification,
  ) => _dataSource.createNotification(notification);

  @override
  Future<List<AppNotificationModel>> getNotifications(String userId) =>
      _dataSource.getNotifications(userId);

  @override
  Future<int> getUnreadCount(String userId) =>
      _dataSource.getUnreadCount(userId);

  @override
  Future<void> markAsRead(String notificationId) =>
      _dataSource.markAsRead(notificationId);

  @override
  Future<void> markAllAsRead(String userId) =>
      _dataSource.markAllAsRead(userId);
}

import 'package:flutter/material.dart';
import 'package:rayen_mobile/features/notifications/domain/models/app_notification_model.dart';
import 'package:rayen_mobile/features/notifications/domain/repositories/notification_repository.dart';

enum NotificationLoadStatus { initial, loading, loaded, error }

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;

  NotificationProvider(this._repository);

  NotificationLoadStatus _status = NotificationLoadStatus.initial;
  List<AppNotificationModel> _notifications = [];
  int _unreadCount = 0;
  String? _errorMessage;

  NotificationLoadStatus get status => _status;
  List<AppNotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  String? get errorMessage => _errorMessage;

  Future<void> loadNotifications(String userId) async {
    _status = NotificationLoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await _repository.getNotifications(userId);
      _unreadCount = await _repository.getUnreadCount(userId);
      _status = NotificationLoadStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = NotificationLoadStatus.error;
    }

    notifyListeners();
  }

  Future<AppNotificationModel?> createNotification(
    AppNotificationModel notification,
  ) async {
    try {
      final created = await _repository.createNotification(notification);
      _notifications = [created, ..._notifications];
      if (!created.isRead) {
        _unreadCount += 1;
      }
      notifyListeners();
      return created;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        if (_unreadCount > 0) _unreadCount -= 1;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await _repository.markAllAsRead(userId);
      _notifications = [
        for (final notification in _notifications)
          notification.copyWith(isRead: true),
      ];
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}

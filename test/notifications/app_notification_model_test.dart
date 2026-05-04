import 'package:flutter_test/flutter_test.dart';
import 'package:rayen_mobile/features/notifications/domain/models/app_notification_model.dart';

void main() {
  test('parses notification type from map', () {
    final model = AppNotificationModel.fromMap({
      'userId': 'u1',
      'type': 'enrollment_approved',
      'title': 'Approved',
      'body': 'Your request was approved',
      'isRead': false,
      'createdAt': DateTime(2026),
      'targetRoute': '/student/home',
      'metadata': const {'sessionId': 's1'},
    }, 'n1');

    expect(model.id, 'n1');
    expect(model.userId, 'u1');
    expect(model.type, AppNotificationType.enrollmentApproved);
    expect(model.targetRoute, '/student/home');
  });

  test('serializes notification type to map', () {
    final model = AppNotificationModel(
      id: 'n1',
      userId: 'u1',
      type: AppNotificationType.sessionCancelled,
      title: 'Cancelled',
      body: 'Session cancelled',
      isRead: true,
      createdAt: DateTime(2026),
      targetRoute: '/student/home',
    );

    final map = model.toMap();

    expect(map['type'], 'session_cancelled');
    expect(map['isRead'], true);
    expect(map['targetRoute'], '/student/home');
  });
}

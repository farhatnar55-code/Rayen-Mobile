import 'package:equatable/equatable.dart';
import 'package:rayen_mobile/core/utils/app_timestamp.dart';

enum AppNotificationType {
  enrollmentRequested,
  enrollmentApproved,
  enrollmentRejected,
  sessionCancelled,
  sessionRescheduled,
  meetingLinkUpdated,
  certificateIssued,
}

extension AppNotificationTypeExtension on AppNotificationType {
  String get value {
    switch (this) {
      case AppNotificationType.enrollmentRequested:
        return 'enrollment_requested';
      case AppNotificationType.enrollmentApproved:
        return 'enrollment_approved';
      case AppNotificationType.enrollmentRejected:
        return 'enrollment_rejected';
      case AppNotificationType.sessionCancelled:
        return 'session_cancelled';
      case AppNotificationType.sessionRescheduled:
        return 'session_rescheduled';
      case AppNotificationType.meetingLinkUpdated:
        return 'meeting_link_updated';
      case AppNotificationType.certificateIssued:
        return 'certificate_issued';
    }
  }

  static AppNotificationType fromString(String? value) {
    switch (value) {
      case 'enrollment_approved':
        return AppNotificationType.enrollmentApproved;
      case 'enrollment_rejected':
        return AppNotificationType.enrollmentRejected;
      case 'session_cancelled':
        return AppNotificationType.sessionCancelled;
      case 'session_rescheduled':
        return AppNotificationType.sessionRescheduled;
      case 'meeting_link_updated':
        return AppNotificationType.meetingLinkUpdated;
      case 'certificate_issued':
        return AppNotificationType.certificateIssued;
      case 'enrollment_requested':
      default:
        return AppNotificationType.enrollmentRequested;
    }
  }
}

class AppNotificationModel extends Equatable {
  final String id;
  final String userId;
  final AppNotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String? targetRoute;
  final Map<String, dynamic>? metadata;

  const AppNotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.targetRoute,
    this.metadata,
  });

  factory AppNotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return AppNotificationModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      type: AppNotificationTypeExtension.fromString(map['type'] as String?),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      isRead: map['isRead'] as bool? ?? false,
      createdAt: AppTimestamp.fromFirestore(map['createdAt']) ?? DateTime.now(),
      targetRoute: map['targetRoute'] as String?,
      metadata: (map['metadata'] as Map?)?.cast<String, dynamic>(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.value,
      'title': title,
      'body': body,
      'isRead': isRead,
      'createdAt': AppTimestamp.toFirestore(createdAt),
      'targetRoute': targetRoute,
      'metadata': metadata,
    };
  }

  AppNotificationModel copyWith({
    bool? isRead,
    String? title,
    String? body,
    String? targetRoute,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotificationModel(
      id: id,
      userId: userId,
      type: type,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      targetRoute: targetRoute ?? this.targetRoute,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    title,
    body,
    isRead,
    createdAt,
    targetRoute,
    metadata,
  ];
}

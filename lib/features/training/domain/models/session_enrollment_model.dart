import 'package:equatable/equatable.dart';
import 'package:rayen_mobile/core/utils/app_timestamp.dart';

enum EnrollmentRequestStatus { pending, approved, rejected }

extension EnrollmentRequestStatusExtension on EnrollmentRequestStatus {
  String get value {
    switch (this) {
      case EnrollmentRequestStatus.pending:
        return 'pending';
      case EnrollmentRequestStatus.approved:
        return 'approved';
      case EnrollmentRequestStatus.rejected:
        return 'rejected';
    }
  }

  static EnrollmentRequestStatus fromString(String? value) {
    switch (value) {
      case 'approved':
        return EnrollmentRequestStatus.approved;
      case 'rejected':
        return EnrollmentRequestStatus.rejected;
      default:
        return EnrollmentRequestStatus.pending;
    }
  }
}

class SessionEnrollmentModel extends Equatable {
  final String id;
  final String sessionId;
  final String sessionTitle;
  final String userId;
  final String userFullName;
  final String userEmail;
  final EnrollmentRequestStatus status;
  final DateTime requestedAt;
  final DateTime? respondedAt;
  final bool certificateIssued;

  const SessionEnrollmentModel({
    required this.id,
    required this.sessionId,
    required this.sessionTitle,
    required this.userId,
    required this.userFullName,
    required this.userEmail,
    required this.status,
    required this.requestedAt,
    required this.certificateIssued,
    this.respondedAt,
  });

  bool get isPending => status == EnrollmentRequestStatus.pending;
  bool get isApproved => status == EnrollmentRequestStatus.approved;
  bool get isRejected => status == EnrollmentRequestStatus.rejected;

  factory SessionEnrollmentModel.fromMap(Map<String, dynamic> map, String id) {
    return SessionEnrollmentModel(
      id: id,
      sessionId: map['sessionId'] as String? ?? '',
      sessionTitle: map['sessionTitle'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userFullName: map['userFullName'] as String? ?? '',
      userEmail: map['userEmail'] as String? ?? '',
      status: EnrollmentRequestStatusExtension.fromString(
        map['status'] as String?,
      ),
      requestedAt:
          AppTimestamp.fromFirestore(map['requestedAt']) ?? DateTime.now(),
      respondedAt: AppTimestamp.fromFirestore(map['respondedAt']),
      certificateIssued: map['certificateIssued'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'sessionTitle': sessionTitle,
      'userId': userId,
      'userFullName': userFullName,
      'userEmail': userEmail,
      'status': status.value,
      'requestedAt': AppTimestamp.toFirestore(requestedAt),
      'respondedAt': AppTimestamp.toFirestore(respondedAt),
      'certificateIssued': certificateIssued,
    };
  }

  SessionEnrollmentModel copyWith({
    EnrollmentRequestStatus? status,
    DateTime? respondedAt,
    bool? certificateIssued,
  }) {
    return SessionEnrollmentModel(
      id: id,
      sessionId: sessionId,
      sessionTitle: sessionTitle,
      userId: userId,
      userFullName: userFullName,
      userEmail: userEmail,
      status: status ?? this.status,
      requestedAt: requestedAt,
      respondedAt: respondedAt ?? this.respondedAt,
      certificateIssued: certificateIssued ?? this.certificateIssued,
    );
  }

  @override
  List<Object?> get props => [id, sessionId, userId, status, certificateIssued];
}

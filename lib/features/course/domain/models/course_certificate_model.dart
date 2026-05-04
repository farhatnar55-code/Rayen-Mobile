import 'package:equatable/equatable.dart';
import 'package:rayen_mobile/core/utils/app_timestamp.dart';

class CourseCertificateModel extends Equatable {
  final String id;
  final String userId;
  final String courseId;
  final String studentName;
  final String courseTitle;
  final String certificateUrl;
  final String certificateNumber;
  final DateTime issuedAt;

  const CourseCertificateModel({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.studentName,
    required this.courseTitle,
    required this.certificateUrl,
    required this.certificateNumber,
    required this.issuedAt,
  });

  factory CourseCertificateModel.fromMap(Map<String, dynamic> map, String id) {
    return CourseCertificateModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      courseId: map['courseId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      courseTitle: map['courseTitle'] as String? ?? '',
      certificateUrl: map['certificateUrl'] as String? ?? '',
      certificateNumber: map['certificateNumber'] as String? ?? '',
      issuedAt: AppTimestamp.fromFirestore(map['issuedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'courseId': courseId,
      'studentName': studentName,
      'courseTitle': courseTitle,
      'certificateUrl': certificateUrl,
      'certificateNumber': certificateNumber,
      'issuedAt': AppTimestamp.toFirestore(issuedAt),
    };
  }

  @override
  List<Object?> get props => [id, userId, courseId, certificateUrl];
}

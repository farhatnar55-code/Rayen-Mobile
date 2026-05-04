import 'package:equatable/equatable.dart';
import 'package:rayen_mobile/core/utils/app_timestamp.dart';

class EnrollmentModel extends Equatable {
  final String id;
  final String studentId;
  final String courseId;
  final String courseTitle;
  final String? courseThumbnailUrl;
  final DateTime enrolledAt;

  const EnrollmentModel({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.courseTitle,
    required this.enrolledAt,
    this.courseThumbnailUrl,
  });

  factory EnrollmentModel.fromMap(Map<String, dynamic> map, String id) {
    return EnrollmentModel(
      id: id,
      studentId: map['studentId'] as String? ?? '',
      courseId: map['courseId'] as String? ?? '',
      courseTitle: map['courseTitle'] as String? ?? '',
      courseThumbnailUrl: map['courseThumbnailUrl'] as String?,
      enrolledAt:
          AppTimestamp.fromFirestore(map['enrolledAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'courseId': courseId,
      'courseTitle': courseTitle,
      'courseThumbnailUrl': courseThumbnailUrl,
      'enrolledAt': AppTimestamp.toFirestore(enrolledAt),
    };
  }

  @override
  List<Object?> get props => [id, studentId, courseId, enrolledAt];
}

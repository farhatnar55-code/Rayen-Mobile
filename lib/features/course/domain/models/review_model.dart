import 'package:equatable/equatable.dart';
import 'package:rayen_mobile/core/utils/app_timestamp.dart';

class ReviewModel extends Equatable {
  final String id;
  final String studentId;
  final String studentName;
  final String? studentAvatarUrl;
  final String courseId;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.rating,
    required this.createdAt,
    this.studentAvatarUrl,
    this.comment,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      id: id,
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      studentAvatarUrl: map['studentAvatarUrl'] as String?,
      courseId: map['courseId'] as String? ?? '',
      rating: (map['rating'] as num? ?? 0).toDouble(),
      comment: map['comment'] as String?,
      createdAt: AppTimestamp.fromFirestore(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'studentAvatarUrl': studentAvatarUrl,
      'courseId': courseId,
      'rating': rating,
      'comment': comment,
      'createdAt': AppTimestamp.toFirestore(createdAt),
    };
  }

  @override
  List<Object?> get props => [id, studentId, courseId, rating, createdAt];
}

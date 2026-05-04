import 'package:equatable/equatable.dart';
import 'package:rayen_mobile/core/utils/app_timestamp.dart';

class ProgressModel extends Equatable {
  final String studentId;
  final String courseId;
  final List<String> completedLessons;
  final String? lastLessonId;
  final double percent;
  final DateTime updatedAt;

  const ProgressModel({
    required this.studentId,
    required this.courseId,
    required this.completedLessons,
    required this.percent,
    required this.updatedAt,
    this.lastLessonId,
  });

  bool get isCompleted => percent >= 100;

  factory ProgressModel.fromMap(Map<String, dynamic> map) {
    return ProgressModel(
      studentId: map['studentId'] as String? ?? '',
      courseId: map['courseId'] as String? ?? '',
      completedLessons: List<String>.from(map['completedLessons'] ?? []),
      lastLessonId: map['lastLessonId'] as String?,
      percent: (map['percent'] as num? ?? 0).toDouble(),
      updatedAt: AppTimestamp.fromFirestore(map['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'courseId': courseId,
      'completedLessons': completedLessons,
      'lastLessonId': lastLessonId,
      'percent': percent,
      'updatedAt': AppTimestamp.toFirestore(updatedAt),
    };
  }

  ProgressModel copyWith({
    List<String>? completedLessons,
    String? lastLessonId,
    double? percent,
  }) {
    return ProgressModel(
      studentId: studentId,
      courseId: courseId,
      completedLessons: completedLessons ?? this.completedLessons,
      lastLessonId: lastLessonId ?? this.lastLessonId,
      percent: percent ?? this.percent,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [studentId, courseId, percent, completedLessons];
}

import 'package:equatable/equatable.dart';
import 'package:rayen_mobile/core/utils/app_timestamp.dart';

class CourseProgressModel extends Equatable {
  final String id;
  final String userId;
  final String courseId;
  final List<String> completedLessonIds;
  final int totalLessons;
  final double progressPercent;
  final bool isFinished;
  final DateTime updatedAt;
  final DateTime? finishedAt;

  const CourseProgressModel({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.completedLessonIds,
    required this.totalLessons,
    required this.progressPercent,
    required this.isFinished,
    required this.updatedAt,
    this.finishedAt,
  });

  factory CourseProgressModel.fromMap(Map<String, dynamic> map, String id) {
    return CourseProgressModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      courseId: map['courseId'] as String? ?? '',
      completedLessonIds: List<String>.from(
        map['completedLessonIds'] ?? const [],
      ),
      totalLessons: map['totalLessons'] as int? ?? 0,
      progressPercent: (map['progressPercent'] as num? ?? 0).toDouble(),
      isFinished: map['isFinished'] as bool? ?? false,
      updatedAt: AppTimestamp.fromFirestore(map['updatedAt']) ?? DateTime.now(),
      finishedAt: AppTimestamp.fromFirestore(map['finishedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'courseId': courseId,
      'completedLessonIds': completedLessonIds,
      'totalLessons': totalLessons,
      'progressPercent': progressPercent,
      'isFinished': isFinished,
      'updatedAt': AppTimestamp.toFirestore(updatedAt),
      'finishedAt': AppTimestamp.toFirestore(finishedAt),
    };
  }

  CourseProgressModel copyWith({
    List<String>? completedLessonIds,
    int? totalLessons,
    double? progressPercent,
    bool? isFinished,
    DateTime? finishedAt,
  }) {
    return CourseProgressModel(
      id: id,
      userId: userId,
      courseId: courseId,
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
      totalLessons: totalLessons ?? this.totalLessons,
      progressPercent: progressPercent ?? this.progressPercent,
      isFinished: isFinished ?? this.isFinished,
      updatedAt: DateTime.now(),
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    courseId,
    progressPercent,
    isFinished,
  ];
}

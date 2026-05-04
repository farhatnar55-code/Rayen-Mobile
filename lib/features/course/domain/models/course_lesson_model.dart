import 'package:equatable/equatable.dart';

class CourseLessonModel extends Equatable {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final String videoUrl;
  final int order;
  final int? durationMinutes;
  final bool isPreview;

  const CourseLessonModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.order,
    this.durationMinutes,
    this.isPreview = false,
  });

  factory CourseLessonModel.fromMap(Map<String, dynamic> map, String id) {
    return CourseLessonModel(
      id: id,
      courseId: map['courseId'] as String? ?? map['course_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      videoUrl: map['videoUrl'] as String? ?? map['video_url'] as String? ?? '',
      order: map['order'] as int? ?? 0,
      durationMinutes:
          map['durationMinutes'] as int? ?? map['duration_minutes'] as int?,
      isPreview:
          map['isPreview'] as bool? ?? map['is_preview'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'order': order,
      'durationMinutes': durationMinutes,
      'isPreview': isPreview,
    };
  }

  CourseLessonModel copyWith({
    String? title,
    String? description,
    String? videoUrl,
    int? order,
    int? durationMinutes,
    bool? isPreview,
  }) {
    return CourseLessonModel(
      id: id,
      courseId: courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      order: order ?? this.order,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isPreview: isPreview ?? this.isPreview,
    );
  }

  @override
  List<Object?> get props => [id, courseId, title, order, videoUrl];
}

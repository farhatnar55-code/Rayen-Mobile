import 'package:equatable/equatable.dart';

class InstructorModel extends Equatable {
  final String userId;
  final String name;
  final String slug;
  final String? avatarUrl;
  final int studentsCount;
  final int coursesCount;
  final String? education;
  final String? experience;
  final String? about;

  const InstructorModel({
    required this.userId,
    required this.name,
    required this.slug,
    required this.studentsCount,
    required this.coursesCount,
    this.avatarUrl,
    this.education,
    this.experience,
    this.about,
  });

  factory InstructorModel.fromMap(Map<String, dynamic> map, String id) {
    return InstructorModel(
      userId:        id,
      name:          map['name']          as String? ?? '',
      slug:          map['slug']          as String? ?? '',
      avatarUrl:     map['avatarUrl']     as String?,
      studentsCount: map['studentsCount'] as int?    ?? 0,
      coursesCount:  map['coursesCount']  as int?    ?? 0,
      education:     map['education']     as String?,
      experience:    map['experience']    as String?,
      about:         map['about']         as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId':        userId,
      'name':          name,
      'slug':          slug,
      'avatarUrl':     avatarUrl,
      'studentsCount': studentsCount,
      'coursesCount':  coursesCount,
      'education':     education,
      'experience':    experience,
      'about':         about,
    };
  }

  @override
  List<Object?> get props => [userId, name, slug, studentsCount, coursesCount];
}

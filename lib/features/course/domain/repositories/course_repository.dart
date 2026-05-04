import 'package:rayen_mobile/features/course/domain/models/course_certificate_model.dart';
import 'package:rayen_mobile/features/course/domain/models/course_lesson_model.dart';
import 'package:rayen_mobile/features/course/domain/models/course_model.dart';
import 'package:rayen_mobile/features/course/domain/models/course_progress_model.dart';
import 'package:rayen_mobile/features/course/domain/models/enrollment_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rayen_mobile/core/models/paginated_result.dart';

abstract class CourseRepository {
  Future<List<CourseModel>> getCourses({
    String? categoryId,
    String? subcategoryId,
    bool? isFree,
    int limit = 20,
  });
  Future<PaginatedResult<CourseModel>> getCoursesPage({
    String? categoryId,
    String? subcategoryId,
    bool? isFree,
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<List<CourseModel>> searchCourses(String query);
  Future<CourseModel?> getCourseById(String id);
  Future<List<CourseLessonModel>> getLessons(String courseId);
  Future<CourseProgressModel?> getProgress(String userId, String courseId);
  Future<CourseProgressModel> markLessonCompleted({
    required String userId,
    required String userFullName,
    required String courseId,
    required String courseTitle,
    required String lessonId,
    required int totalLessons,
  });
  Future<CourseCertificateModel?> getCertificate(
    String userId,
    String courseId,
  );
  Future<EnrollmentModel?> getEnrollment(String userId, String courseId);
  Future<EnrollmentModel> enrollFreeCourse({
    required String userId,
    required String userFullName,
    required String courseId,
    required String courseTitle,
  });
  Future<void> recordPaidEnrollment({
    required String userId,
    required String userFullName,
    required String courseId,
    required String courseTitle,
    required String transactionId,
  });
  Future<CourseModel> createCourse(CourseModel course);
  Future<CourseModel> updateCourse(CourseModel course);
  Future<void> deleteCourse(String courseId);
  Future<CourseLessonModel> addLesson(CourseLessonModel lesson);
  Future<void> updateLesson(CourseLessonModel lesson);
  Future<void> deleteLesson(String courseId, String lessonId);
}

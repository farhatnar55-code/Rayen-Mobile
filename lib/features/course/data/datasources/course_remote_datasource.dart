import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:rayen_mobile/core/models/paginated_result.dart';
import 'package:rayen_mobile/services/supabase_storage_service.dart';
import 'package:rayen_mobile/core/utils/app_timestamp.dart';
import 'package:rayen_mobile/features/course/domain/models/course_certificate_model.dart';
import 'package:rayen_mobile/features/course/domain/models/course_lesson_model.dart';
import 'package:rayen_mobile/features/course/domain/models/course_model.dart';
import 'package:rayen_mobile/features/course/domain/models/course_progress_model.dart';
import 'package:rayen_mobile/features/course/domain/models/enrollment_model.dart';
import 'package:uuid/uuid.dart';

class CourseRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  static const String _defaultCertificateUrl =
      'https://rykvdlhfxvqymiwwxdkx.supabase.co/storage/v1/object/public/Rayen-Bucket/course-pdfs/certificate.pdf';

  Future<List<CourseModel>> getCourses({
    String? categoryId,
    String? subcategoryId,
    bool? isFree,
    int limit = 200,
  }) async {
    Query query = _firestore.collection('courses').limit(limit);

    if (categoryId != null) {
      query = query.where('category_id', isEqualTo: categoryId);
    }
    if (subcategoryId != null) {
      query = query.where('subcategory_id', isEqualTo: subcategoryId);
    }
    if (isFree != null) {
      query = query.where('is_free', isEqualTo: isFree);
    }

    final snapshot = await query.get();

    return snapshot.docs
        .map(
          (doc) =>
              CourseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  Future<PaginatedResult<CourseModel>> getCoursesPage({
    String? categoryId,
    String? subcategoryId,
    bool? isFree,
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('courses')
        .orderBy(FieldPath.documentId)
        .limit(limit);

    if (categoryId != null) {
      query = query.where('category_id', isEqualTo: categoryId);
    }
    if (subcategoryId != null) {
      query = query.where('subcategory_id', isEqualTo: subcategoryId);
    }
    if (isFree != null) {
      query = query.where('is_free', isEqualTo: isFree);
    }
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final items = snapshot.docs
        .map((doc) => CourseModel.fromMap(doc.data(), doc.id))
        .toList();

    return PaginatedResult(
      items: items,
      lastDocument: snapshot.docs.isEmpty ? null : snapshot.docs.last,
    );
  }

  Future<List<CourseModel>> searchCourses(String query) async {
    final snapshot = await _firestore.collection('courses').get();

    final lower = query.toLowerCase();
    return snapshot.docs
        .map((doc) => CourseModel.fromMap(doc.data(), doc.id))
        .where(
          (course) =>
              course.title.toLowerCase().contains(lower) ||
              (course.instructorName?.toLowerCase().contains(lower) ?? false) ||
              (course.categoryName?.toLowerCase().contains(lower) ?? false),
        )
        .toList();
  }

  Future<CourseModel?> getCourseById(String id) async {
    final doc = await _firestore.collection('courses').doc(id).get();
    if (!doc.exists) return null;
    return CourseModel.fromMap(doc.data()!, doc.id);
  }

  Future<List<CourseLessonModel>> getLessons(String courseId) async {
    final snapshot = await _firestore
        .collection('courses')
        .doc(courseId)
        .collection('lessons')
        .orderBy('order')
        .get();
    return snapshot.docs
        .map((doc) => CourseLessonModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<CourseProgressModel?> getProgress(
    String userId,
    String courseId,
  ) async {
    final id = '${userId}_$courseId';
    final doc = await _firestore.collection('course_progress').doc(id).get();
    if (!doc.exists) return null;
    return CourseProgressModel.fromMap(doc.data()!, doc.id);
  }

  Future<CourseProgressModel> markLessonCompleted({
    required String userId,
    required String userFullName,
    required String courseId,
    required String courseTitle,
    required String lessonId,
    required int totalLessons,
  }) async {
    final id = '${userId}_$courseId';
    final docRef = _firestore.collection('course_progress').doc(id);
    final doc = await docRef.get();
    final current = doc.exists
        ? CourseProgressModel.fromMap(doc.data()!, doc.id)
        : CourseProgressModel(
            id: id,
            userId: userId,
            courseId: courseId,
            completedLessonIds: const [],
            totalLessons: totalLessons,
            progressPercent: 0,
            isFinished: false,
            updatedAt: DateTime.now(),
          );

    final completed = {...current.completedLessonIds, lessonId}.toList();
    final progress = totalLessons == 0
        ? 0.0
        : (completed.length / totalLessons) * 100;
    final finished = progress >= 100;
    final updated = current.copyWith(
      completedLessonIds: completed,
      totalLessons: totalLessons,
      progressPercent: progress,
      isFinished: finished,
      finishedAt: finished ? DateTime.now() : current.finishedAt,
    );

    await docRef.set(updated.toMap(), SetOptions(merge: true));

    if (finished) {
      final certificateId = id;
      final certRef = _firestore.collection('certificates').doc(certificateId);
      final courseDoc = await _firestore
          .collection('courses')
          .doc(courseId)
          .get();
      final courseData = courseDoc.data() ?? <String, dynamic>{};
      final usesCourseCertificate =
          courseData['certificateEnabled'] as bool? ??
          courseData['certificate_enabled'] as bool? ??
          false;
      final certificateTemplateUrl =
          courseData['certificatePdfUrl'] as String? ??
          courseData['certificate_pdf_url'] as String? ??
          '';
      final hasUploadedTemplate = certificateTemplateUrl.trim().isNotEmpty;
      final certificateUrl = usesCourseCertificate
          ? (hasUploadedTemplate
                ? certificateTemplateUrl
                : _defaultCertificateUrl)
          : null;

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Certificat de réussite',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text(userFullName, style: const pw.TextStyle(fontSize: 22)),
                pw.SizedBox(height: 12),
                pw.Text(
                  'a terminé le cours',
                  style: const pw.TextStyle(fontSize: 18),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  courseTitle,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text('Numéro: ${_uuid.v4().substring(0, 8).toUpperCase()}'),
              ],
            ),
          ),
        ),
      );
      final issuedCertificateUrl =
          certificateUrl ??
          await SupabaseStorageService.uploadCertificatePdf(
            userId: userId,
            courseId: courseId,
            bytes: Uint8List.fromList(await pdf.save()),
          );
      await certRef.set({
        'userId': userId,
        'courseId': courseId,
        'studentName': userFullName,
        'courseTitle': courseTitle,
        'certificateUrl': issuedCertificateUrl,
        'certificateNumber': _uuid.v4(),
        'issuedAt': AppTimestamp.toFirestore(DateTime.now()),
      }, SetOptions(merge: true));
    }

    return updated;
  }

  Future<CourseCertificateModel?> getCertificate(
    String userId,
    String courseId,
  ) async {
    final id = '${userId}_$courseId';
    final doc = await _firestore.collection('certificates').doc(id).get();
    if (!doc.exists) return null;
    return CourseCertificateModel.fromMap(doc.data()!, doc.id);
  }

  Future<CourseModel> createCourse(CourseModel course) async {
    final id = course.id.isEmpty ? _uuid.v4() : course.id;
    final map = course.toMap();
    await _firestore.collection('courses').doc(id).set(map);
    return CourseModel.fromMap(map, id);
  }

  Future<CourseModel> updateCourse(CourseModel course) async {
    await _firestore
        .collection('courses')
        .doc(course.id)
        .update(course.toMap());
    return course;
  }

  Future<void> deleteCourse(String courseId) async {
    final lessons = await _firestore
        .collection('courses')
        .doc(courseId)
        .collection('lessons')
        .get();
    for (final doc in lessons.docs) {
      await doc.reference.delete();
    }
    await _firestore.collection('courses').doc(courseId).delete();
  }

  Future<CourseLessonModel> addLesson(CourseLessonModel lesson) async {
    final id = lesson.id.isEmpty ? _uuid.v4() : lesson.id;
    final map = lesson.toMap();
    await _firestore
        .collection('courses')
        .doc(lesson.courseId)
        .collection('lessons')
        .doc(id)
        .set(map);
    return CourseLessonModel.fromMap(map, id);
  }

  Future<void> updateLesson(CourseLessonModel lesson) async {
    await _firestore
        .collection('courses')
        .doc(lesson.courseId)
        .collection('lessons')
        .doc(lesson.id)
        .update(lesson.toMap());
  }

  Future<void> deleteLesson(String courseId, String lessonId) async {
    await _firestore
        .collection('courses')
        .doc(courseId)
        .collection('lessons')
        .doc(lessonId)
        .delete();
  }

  Future<EnrollmentModel?> getEnrollment(String userId, String courseId) async {
    final snapshot = await _firestore
        .collection('enrollments')
        .where('studentId', isEqualTo: userId)
        .where('courseId', isEqualTo: courseId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return EnrollmentModel.fromMap(
      snapshot.docs.first.data(),
      snapshot.docs.first.id,
    );
  }

  Future<EnrollmentModel> enrollFreeCourse({
    required String userId,
    required String userFullName,
    required String courseId,
    required String courseTitle,
  }) async {
    final existing = await getEnrollment(userId, courseId);
    if (existing != null) return existing;

    final id = _uuid.v4();
    final courseDoc = await _firestore
        .collection('courses')
        .doc(courseId)
        .get();
    final thumbnailUrl = courseDoc.data()?['thumbnailUrl'] as String? ?? '';

    final enrollment = EnrollmentModel(
      id: id,
      studentId: userId,
      courseId: courseId,
      courseTitle: courseTitle,
      courseThumbnailUrl: thumbnailUrl,
      enrolledAt: DateTime.now(),
    );

    await _firestore.collection('enrollments').doc(id).set(enrollment.toMap());
    return enrollment;
  }

  Future<void> recordPaidEnrollment({
    required String userId,
    required String userFullName,
    required String courseId,
    required String courseTitle,
    required String transactionId,
  }) async {
    final existing = await getEnrollment(userId, courseId);
    if (existing != null) return;

    final id = _uuid.v4();
    final courseDoc = await _firestore
        .collection('courses')
        .doc(courseId)
        .get();
    final thumbnailUrl = courseDoc.data()?['thumbnailUrl'] as String? ?? '';

    final enrollment = EnrollmentModel(
      id: id,
      studentId: userId,
      courseId: courseId,
      courseTitle: courseTitle,
      courseThumbnailUrl: thumbnailUrl,
      enrolledAt: DateTime.now(),
    );

    await _firestore.collection('enrollments').doc(id).set(enrollment.toMap());
  }
}

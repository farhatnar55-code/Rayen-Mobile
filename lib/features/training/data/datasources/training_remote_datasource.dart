import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rayen_mobile/core/models/paginated_result.dart';
import 'package:rayen_mobile/core/utils/app_timestamp.dart';
import 'package:rayen_mobile/features/training/domain/models/session_enrollment_model.dart';
import 'package:rayen_mobile/features/training/domain/models/training_session_model.dart';
import 'package:uuid/uuid.dart';

class TrainingRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Future<List<TrainingSessionModel>> getPublishedSessions() async {
    final snapshot = await _firestore
        .collection('training_sessions')
        .where('status', isEqualTo: 'published')
        .orderBy('sessionDate')
        .get();
    return snapshot.docs
        .map((doc) => TrainingSessionModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<PaginatedResult<TrainingSessionModel>> getPublishedSessionsPage({
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('training_sessions')
        .where('status', isEqualTo: 'published')
        .orderBy('sessionDate')
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final items = snapshot.docs
        .map((doc) => TrainingSessionModel.fromMap(doc.data(), doc.id))
        .toList();

    return PaginatedResult(
      items: items,
      lastDocument: snapshot.docs.isEmpty ? null : snapshot.docs.last,
    );
  }

  Future<List<TrainingSessionModel>> getSessionsByOrganizer(
    String organizerId,
  ) async {
    final snapshot = await _firestore
        .collection('training_sessions')
        .where('organizerId', isEqualTo: organizerId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => TrainingSessionModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<TrainingSessionModel>> getSessionsByTrainer(
    String trainerId,
  ) async {
    final snapshot = await _firestore
        .collection('training_sessions')
        .where('trainerId', isEqualTo: trainerId)
        .orderBy('sessionDate')
        .get();
    return snapshot.docs
        .map((doc) => TrainingSessionModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<TrainingSessionModel> createSession(
    TrainingSessionModel session,
  ) async {
    final id = _uuid.v4();
    final map = session.toMap();
    await _firestore.collection('training_sessions').doc(id).set(map);
    return TrainingSessionModel.fromMap(map, id);
  }

  Future<void> updateSession(TrainingSessionModel session) async {
    await _firestore
        .collection('training_sessions')
        .doc(session.id)
        .update(session.toMap());
  }

  Future<void> deleteSession(String sessionId) async {
    await _firestore.collection('training_sessions').doc(sessionId).delete();
  }

  Future<void> updateSessionStatus(
    String sessionId,
    SessionStatus status,
  ) async {
    await _firestore.collection('training_sessions').doc(sessionId).update({
      'status': status.value,
    });
  }

  Future<SessionEnrollmentModel> requestEnrollment(
    SessionEnrollmentModel enrollment,
  ) async {
    final id = _uuid.v4();
    final map = enrollment.toMap();
    await _firestore.collection('session_enrollments').doc(id).set(map);
    return SessionEnrollmentModel.fromMap(map, id);
  }

  Future<void> respondToEnrollment(
    String enrollmentId,
    EnrollmentRequestStatus status,
  ) async {
    await _firestore.collection('session_enrollments').doc(enrollmentId).update(
      {'status': status.value, 'respondedAt': AppTimestamp.now()},
    );

    if (status == EnrollmentRequestStatus.approved) {
      final doc = await _firestore
          .collection('session_enrollments')
          .doc(enrollmentId)
          .get();
      final sessionId = doc.data()?['sessionId'] as String?;
      if (sessionId != null) {
        await _firestore.collection('training_sessions').doc(sessionId).update({
          'enrolledCount': FieldValue.increment(1),
        });
      }
    }
  }

  Future<List<SessionEnrollmentModel>> getEnrollmentsBySession(
    String sessionId,
  ) async {
    final snapshot = await _firestore
        .collection('session_enrollments')
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('requestedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => SessionEnrollmentModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<SessionEnrollmentModel>> getEnrollmentsByUser(
    String userId,
  ) async {
    final snapshot = await _firestore
        .collection('session_enrollments')
        .where('userId', isEqualTo: userId)
        .orderBy('requestedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => SessionEnrollmentModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> issueCertificate(String enrollmentId) async {
    await _firestore.collection('session_enrollments').doc(enrollmentId).update(
      {'certificateIssued': true},
    );
  }
}

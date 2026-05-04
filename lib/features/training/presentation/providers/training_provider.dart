import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rayen_mobile/features/training/domain/models/session_enrollment_model.dart';
import 'package:rayen_mobile/features/training/domain/models/training_session_model.dart';
import 'package:rayen_mobile/features/training/domain/repositories/training_repository.dart';
import 'package:intl/intl.dart';
import 'package:rayen_mobile/services/email_service.dart';
import 'package:rayen_mobile/services/notification_service.dart';
import 'package:rayen_mobile/features/notifications/domain/models/app_notification_model.dart';

enum TrainingLoadStatus { initial, loading, loaded, error }

class TrainingProvider extends ChangeNotifier {
  final TrainingRepository _repository;
  final NotificationService _notificationService;

  TrainingProvider(this._repository, this._notificationService);

  TrainingLoadStatus _sessionsStatus = TrainingLoadStatus.initial;
  TrainingLoadStatus _enrollmentsStatus = TrainingLoadStatus.initial;

  List<TrainingSessionModel> _sessions = [];
  List<SessionEnrollmentModel> _enrollments = [];
  String? _errorMessage;
  DocumentSnapshot<Map<String, dynamic>>? _lastPublishedSessionDoc;
  bool _hasMorePublishedSessions = true;
  bool _isLoadingMorePublishedSessions = false;
  static const int _sessionsPageSize = 20;

  TrainingLoadStatus get sessionsStatus => _sessionsStatus;
  TrainingLoadStatus get enrollmentsStatus => _enrollmentsStatus;
  List<TrainingSessionModel> get sessions => _sessions;
  List<SessionEnrollmentModel> get enrollments => _enrollments;
  String? get errorMessage => _errorMessage;
  bool get hasMorePublishedSessions => _hasMorePublishedSessions;
  bool get isLoadingMorePublishedSessions => _isLoadingMorePublishedSessions;

  List<SessionEnrollmentModel> pendingEnrollments(String sessionId) =>
      _enrollments
          .where(
            (e) =>
                e.sessionId == sessionId &&
                e.status == EnrollmentRequestStatus.pending,
          )
          .toList();

  Future<void> loadPublishedSessions() async {
    if (_sessionsStatus == TrainingLoadStatus.loading) return;
    _sessionsStatus = TrainingLoadStatus.loading;
    _sessions = [];
    _lastPublishedSessionDoc = null;
    _hasMorePublishedSessions = true;
    notifyListeners();
    try {
      await _fetchPublishedSessionsPage(reset: true);
      _sessionsStatus = TrainingLoadStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _sessionsStatus = TrainingLoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadMorePublishedSessions() async {
    if (_isLoadingMorePublishedSessions || !_hasMorePublishedSessions) return;
    await _fetchPublishedSessionsPage();
    notifyListeners();
  }

  Future<void> _fetchPublishedSessionsPage({bool reset = false}) async {
    _isLoadingMorePublishedSessions = true;
    try {
      final result = await _repository.getPublishedSessionsPage(
        limit: _sessionsPageSize,
        startAfter: reset ? null : _lastPublishedSessionDoc,
      );
      if (reset) {
        _sessions = result.items;
      } else {
        _sessions = [..._sessions, ...result.items];
      }
      _lastPublishedSessionDoc = result.lastDocument;
      _hasMorePublishedSessions = result.items.length == _sessionsPageSize;
    } finally {
      _isLoadingMorePublishedSessions = false;
    }
  }

  Future<void> loadSessionsByOrganizer(String organizerId) async {
    if (_sessionsStatus == TrainingLoadStatus.loading) return;
    _sessionsStatus = TrainingLoadStatus.loading;
    notifyListeners();
    try {
      _sessions = await _repository.getSessionsByOrganizer(organizerId);
      _sessionsStatus = TrainingLoadStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _sessionsStatus = TrainingLoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadEnrollmentsByUser(String userId) async {
    if (_enrollmentsStatus == TrainingLoadStatus.loading) return;
    _enrollmentsStatus = TrainingLoadStatus.loading;
    notifyListeners();

    try {
      final enrollments = await _repository.getEnrollmentsByUser(userId);
      _enrollments = enrollments;
      _enrollmentsStatus = TrainingLoadStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _enrollmentsStatus = TrainingLoadStatus.error;
    }

    notifyListeners();
  }

  Future<void> loadSessionsByTrainer(String trainerId) async {
    _sessionsStatus = TrainingLoadStatus.loading;
    notifyListeners();
    try {
      _sessions = await _repository.getSessionsByTrainer(trainerId);
      _sessionsStatus = TrainingLoadStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _sessionsStatus = TrainingLoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadEnrollmentsBySession(String sessionId) async {
    _enrollmentsStatus = TrainingLoadStatus.loading;
    notifyListeners();
    try {
      _enrollments = await _repository.getEnrollmentsBySession(sessionId);
      _enrollmentsStatus = TrainingLoadStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _enrollmentsStatus = TrainingLoadStatus.error;
    }
    notifyListeners();
  }

  Future<bool> createSession(TrainingSessionModel session) async {
    try {
      await _repository.createSession(session);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> updateSessionStatus(
    String sessionId,
    SessionStatus status,
  ) async {
    await _repository.updateSessionStatus(sessionId, status);
    final i = _sessions.indexWhere((s) => s.id == sessionId);
    if (i != -1) {
      _sessions[i] = _sessions[i].copyWith(status: status);
      notifyListeners();
    }
  }

  Future<void> deleteSession(String sessionId) async {
    await _repository.deleteSession(sessionId);
    _sessions.removeWhere((s) => s.id == sessionId);
    notifyListeners();
  }

  Future<bool> requestEnrollment({
    required String sessionId,
    required String sessionTitle,
    required String userId,
    required String userFullName,
    required String userEmail,
  }) async {
    try {
      final enrollment = SessionEnrollmentModel(
        id: '',
        sessionId: sessionId,
        sessionTitle: sessionTitle,
        userId: userId,
        userFullName: userFullName,
        userEmail: userEmail,
        status: EnrollmentRequestStatus.pending,
        requestedAt: DateTime.now(),
        certificateIssued: false,
      );
      final created = await _repository.requestEnrollment(enrollment);
      _enrollments.insert(0, created);
      await _notificationService.notifyUser(
        userId: userId,
        type: AppNotificationType.enrollmentRequested,
        title: 'Demande envoyée',
        body: 'Votre demande pour "$sessionTitle" a été envoyée.',
        targetRoute: '/student/home',
        metadata: {
          'sessionId': sessionId,
          'sessionTitle': sessionTitle,
        },
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> respondToEnrollment(
    String enrollmentId,
    EnrollmentRequestStatus status,
  ) async {
    await _repository.respondToEnrollment(enrollmentId, status);

    final index = _enrollments.indexWhere((e) => e.id == enrollmentId);
    if (index != -1) {
      _enrollments[index] = _enrollments[index].copyWith(
        status: status,
        respondedAt: DateTime.now(),
      );
      notifyListeners();

      final enrollment = _enrollments[index];
      final session = _sessions.firstWhere(
        (s) => s.id == enrollment.sessionId,
        orElse: () => throw Exception('Session not found'),
      );
      final formattedDate = DateFormat(
        'dd MMMM yyyy',
        'fr',
      ).format(session.sessionDate);

      if (status == EnrollmentRequestStatus.approved) {
        await EmailService.sendEnrollmentApproved(
          toEmail: enrollment.userEmail,
          studentName: enrollment.userFullName,
          sessionTitle: enrollment.sessionTitle,
          sessionDate: formattedDate,
          meetingLink: session.meetingLink,
        );
        await _notificationService.notifyUser(
          userId: enrollment.userId,
          type: AppNotificationType.enrollmentApproved,
          title: 'Inscription approuvée',
          body:
              'Votre inscription à "${enrollment.sessionTitle}" a été approuvée.',
          targetRoute: '/student/home',
          metadata: {
            'sessionId': enrollment.sessionId,
            'enrollmentId': enrollment.id,
          },
        );
      } else if (status == EnrollmentRequestStatus.rejected) {
        await EmailService.sendEnrollmentRejected(
          toEmail: enrollment.userEmail,
          studentName: enrollment.userFullName,
          sessionTitle: enrollment.sessionTitle,
        );
        await _notificationService.notifyUser(
          userId: enrollment.userId,
          type: AppNotificationType.enrollmentRejected,
          title: 'Inscription refusée',
          body:
              'Votre inscription à "${enrollment.sessionTitle}" a été refusée.',
          targetRoute: '/student/home',
          metadata: {
            'sessionId': enrollment.sessionId,
            'enrollmentId': enrollment.id,
          },
        );
      }
    }
  }

  Future<void> issueCertificate(String enrollmentId) async {
    await _repository.issueCertificate(enrollmentId);
    final i = _enrollments.indexWhere((e) => e.id == enrollmentId);
    if (i != -1) {
      _enrollments[i] = _enrollments[i].copyWith(certificateIssued: true);
      notifyListeners();

      final enrollment = _enrollments[i];
      await _notificationService.notifyUser(
        userId: enrollment.userId,
        type: AppNotificationType.certificateIssued,
        title: 'Certificat disponible',
        body:
            'Votre certificat pour "${enrollment.sessionTitle}" est maintenant disponible.',
        targetRoute: '/student/home',
        metadata: {
          'enrollmentId': enrollmentId,
          'sessionId': enrollment.sessionId,
        },
      );
    }
  }

  Future<void> cancelSessionWithNotification(String sessionId) async {
    await _repository.updateSessionStatus(sessionId, SessionStatus.cancelled);

    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex != -1) {
      _sessions[sessionIndex] = _sessions[sessionIndex].copyWith(
        status: SessionStatus.cancelled,
      );
      notifyListeners();

      final session = _sessions[sessionIndex];
      final formattedDate = DateFormat(
        'dd MMMM yyyy',
        'fr',
      ).format(session.sessionDate);

      final approvedEnrollments = _enrollments
          .where(
            (e) =>
                e.sessionId == sessionId &&
                e.status == EnrollmentRequestStatus.approved,
          )
          .toList();

      for (final enrollment in approvedEnrollments) {
        await EmailService.sendSessionCancelled(
          toEmail: enrollment.userEmail,
          studentName: enrollment.userFullName,
          sessionTitle: session.title,
          sessionDate: formattedDate,
        );
        await _notificationService.notifyUser(
          userId: enrollment.userId,
          type: AppNotificationType.sessionCancelled,
          title: 'Session annulée',
          body:
              'La session "${session.title}" prévue le $formattedDate a été annulée.',
          targetRoute: '/student/home',
          metadata: {
            'sessionId': session.id,
            'sessionTitle': session.title,
          },
        );
      }
    }
  }
}

import 'package:emailjs/emailjs.dart' as emailjs;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailService {
  static String get _serviceId => dotenv.env['EMAILJS_SERVICE_ID'] ?? '';
  static String get _templateId => dotenv.env['EMAILJS_TEMPLATE_ID'] ?? '';
  static String get _publicKey => dotenv.env['EMAILJS_PUBLIC_KEY'] ?? '';

  static Future<void> sendEnrollmentApproved({
    required String toEmail,
    required String studentName,
    required String sessionTitle,
    required String sessionDate,
    required String? meetingLink,
  }) async {
    final message = meetingLink != null
        ? 'Votre demande d\'inscription à la session "$sessionTitle" '
              'du $sessionDate a été approuvée.\n\n'
              'Lien de la session : $meetingLink\n\n'
              'Nous vous souhaitons une excellente formation.'
        : 'Votre demande d\'inscription à la session "$sessionTitle" '
              'du $sessionDate a été approuvée.\n\n'
              'Le lien de la session vous sera communiqué prochainement.';

    await _send(
      toEmail: toEmail,
      studentName: studentName,
      subject: 'Inscription approuvée — $sessionTitle',
      message: message,
    );
  }

  static Future<void> sendEnrollmentRejected({
    required String toEmail,
    required String studentName,
    required String sessionTitle,
  }) async {
    await _send(
      toEmail: toEmail,
      studentName: studentName,
      subject: 'Inscription refusée — $sessionTitle',
      message:
          'Nous vous informons que votre demande d\'inscription '
          'à la session "$sessionTitle" n\'a pas pu être acceptée.\n\n'
          'N\'hésitez pas à consulter nos autres sessions disponibles '
          'sur Rayen Academy.',
    );
  }

  static Future<void> sendSessionCancelled({
    required String toEmail,
    required String studentName,
    required String sessionTitle,
    required String sessionDate,
  }) async {
    await _send(
      toEmail: toEmail,
      studentName: studentName,
      subject: 'Session annulée — $sessionTitle',
      message:
          'Nous vous informons que la session "$sessionTitle" '
          'prévue le $sessionDate a été annulée.\n\n'
          'Nous nous excusons pour la gêne occasionnée. '
          'De nouvelles sessions seront bientôt disponibles '
          'sur Rayen Academy.',
    );
  }

  static Future<void> _send({
    required String toEmail,
    required String studentName,
    required String subject,
    required String message,
  }) async {
    try {
      await emailjs.send(_serviceId, _templateId, {
        'to_email': toEmail,
        'student_name': studentName,
        'subject': subject,
        'message': message,
      }, emailjs.Options(publicKey: _publicKey));
    } catch (e) {
      assert(() {
        debugPrint('EmailJS error: $e');
        return true;
      }());
    }
  }
}

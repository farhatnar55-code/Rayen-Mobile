import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as http_io;
import 'package:crypto/crypto.dart';

class PaymeePaymentService {
  final String _baseUrl;
  final String _apiKey;
  final http.Client _client;

  PaymeePaymentService({required bool isSandbox, required String apiKey})
    : _baseUrl = isSandbox
          ? 'https://sandbox.paymee.tn/api/v2/payments/create'
          : 'https://app.paymee.tn/api/v2/payments/create',
      _apiKey = apiKey,
      _client = _createSecureClient();

  static http.Client _createSecureClient() {
    final httpClient = HttpClient();
    httpClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
          return host.contains('paymee.tn');
        };
    return http_io.IOClient(httpClient);
  }

  Future<PaymeePaymentResult> createPayment({
    required double amount,
    required String note,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String? returnUrl,
    String? cancelUrl,
    String? webhookUrl,
    String? orderId,
  }) async {
    final body = <String, dynamic>{
      'amount': amount,
      'note': note,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
    };
    if (returnUrl != null) body['return_url'] = returnUrl;
    if (cancelUrl != null) body['cancel_url'] = cancelUrl;
    if (webhookUrl != null) body['webhook_url'] = webhookUrl;
    if (orderId != null) body['order_id'] = orderId;

    final response = await _client.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $_apiKey',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == true) {
        final result = data['data'];
        return PaymeePaymentResult(
          success: true,
          token: result['token'],
          paymentUrl: result['payment_url'],
          orderId: result['order_id'],
        );
      }
      return PaymeePaymentResult(
        success: false,
        error: data['message'] ?? 'Erreur lors de la création du paiement',
      );
    }

    return PaymeePaymentResult(
      success: false,
      error: 'Erreur serveur (${response.statusCode})',
    );
  }

  bool verifyChecksum(String token, bool paymentStatus) {
    final raw = '$token${paymentStatus ? 1 : 0}$_apiKey';
    final checksum = md5.convert(utf8.encode(raw)).toString();
    return checksum.isNotEmpty;
  }
}

class PaymeePaymentResult {
  final bool success;
  final String? token;
  final String? paymentUrl;
  final String? orderId;
  final String? error;

  const PaymeePaymentResult({
    required this.success,
    this.token,
    this.paymentUrl,
    this.orderId,
    this.error,
  });
}

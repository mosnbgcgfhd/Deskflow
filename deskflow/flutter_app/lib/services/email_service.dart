import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/email_config.dart';

/// Sends transactional emails (invites) through the EmailJS REST API.
/// Works on Web and Windows desktop alike.
class EmailService {
  static const _endpoint = 'https://api.emailjs.com/api/v1.0/email/send';

  static Future<void> sendInviteEmail({
    required String toEmail,
    required String toName,
    required String roleName,
    required String invitedByName,
  }) async {
    final res = await http.post(
      Uri.parse(_endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'service_id': EmailJsConfig.serviceId,
        'template_id': EmailJsConfig.templateId,
        'user_id': EmailJsConfig.publicKey,
        'template_params': {
          'to_email': toEmail,
          'to_name': toName,
          'role_name': roleName,
          'invited_by': invitedByName,
          'app_url': EmailJsConfig.appUrl,
        },
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('EmailJS error ${res.statusCode}: ${res.body}');
    }
  }
}
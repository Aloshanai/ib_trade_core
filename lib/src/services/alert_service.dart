import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/alert.dart';

/// Service adapting price and order alert management endpoints for IBKR Client Portal API.
class AlertService {
  final http.Client client;
  final String baseUrl;

  /// Creates an [AlertService] instance.
  AlertService({
    required this.client,
    required this.baseUrl,
  });

  String _cleanUrl(String endpoint) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$base$path';
  }

  /// Lists active account alerts (`GET /iserver/account/alerts`).
  Future<List<AlertItem>> getAlerts(String accountId) async {
    final uri = Uri.parse(_cleanUrl('/iserver/account/alerts')).replace(
      queryParameters: {'accountId': accountId},
    );
    final response = await client.get(uri);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((json) => AlertItem.fromJson(json))
            .toList();
      }
    }
    return const [];
  }

  /// Creates or modifies an alert (`POST /iserver/account/alert`).
  Future<bool> createOrUpdateAlert(
    String accountId,
    CreateAlertRequest alert, {
    int? alertId,
  }) async {
    final payload = {
      ...alert.toJson(),
      'account': accountId,
      if (alertId != null) 'alertId': alertId,
    };

    final response = await client.post(
      Uri.parse(_cleanUrl('/iserver/account/alert')),
      headers: {'content-type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['status'] == 200 ||
          json['success'] == true ||
          json['order_id'] != null ||
          json['alert_id'] != null;
    }
    return false;
  }

  /// Activates or deactivates an alert (`POST /iserver/account/alert/activate`).
  Future<bool> toggleAlert(String accountId, int alertId, bool active) async {
    final response = await client.post(
      Uri.parse(_cleanUrl('/iserver/account/alert/activate')),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'account': accountId,
        'alertId': alertId,
        'alertActive': active ? 1 : 0,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['status'] == 200 || json['success'] == true;
    }
    return false;
  }

  /// Deletes an alert (`POST /iserver/account/alert/activate` with alertActive: -1 or DELETE).
  Future<bool> deleteAlert(String accountId, int alertId) async {
    final response = await client.post(
      Uri.parse(_cleanUrl('/iserver/account/alert/activate')),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'account': accountId,
        'alertId': alertId,
        'alertActive': -1,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['status'] == 200 || json['success'] == true;
    }
    return false;
  }

  /// Retrieves specific alert details (`GET /iserver/account/alert/details/{id}`).
  Future<AlertDetails> getAlertDetails(int alertId) async {
    final response = await client
        .get(Uri.parse(_cleanUrl('/iserver/account/alert/details/$alertId')));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AlertDetails.fromJson(json);
    }
    return AlertDetails.fromJson({'alertId': alertId});
  }
}

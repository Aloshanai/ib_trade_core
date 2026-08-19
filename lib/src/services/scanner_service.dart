import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/scanner.dart';

/// Service adapting market scanner parameters and query execution endpoints for IBKR Client Portal API.
class ScannerService {
  final http.Client client;
  final String baseUrl;

  /// Creates a [ScannerService] instance.
  ScannerService({
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

  /// Retrieves available market scanner metadata parameters (`GET /hmds/scanner/params`).
  Future<ScannerParams> getScannerParams() async {
    final response =
        await client.get(Uri.parse(_cleanUrl('/hmds/scanner/params')));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ScannerParams.fromJson(json);
    }
    return ScannerParams.fromJson({});
  }

  /// Executes a market scan query (`POST /hmds/scanner/run`).
  Future<ScannerResult> runScanner(ScannerRequest request) async {
    final response = await client.post(
      Uri.parse(_cleanUrl('/hmds/scanner/run')),
      headers: {'content-type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return ScannerResult.fromJson(decoded);
    }
    return ScannerResult.fromJson({});
  }
}

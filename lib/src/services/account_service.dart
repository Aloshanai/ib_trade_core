import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/portfolio.dart';

/// Service adapting account and portfolio management endpoints for IBKR Client Portal API.
class AccountService {
  final http.Client client;
  final String baseUrl;

  /// Creates an [AccountService] instance.
  AccountService({
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

  /// Lists accessible trading accounts (`GET /portfolio/accounts` or `/iserver/accounts`).
  Future<List<AccountInfo>> getAccounts() async {
    final response =
        await client.get(Uri.parse(_cleanUrl('/portfolio/accounts')));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((json) => AccountInfo.fromJson(json))
            .toList();
      }
    }
    return const [];
  }

  /// Lists sub-accounts (`GET /portfolio/subaccounts`).
  Future<List<SubAccount>> getSubAccounts() async {
    final response =
        await client.get(Uri.parse(_cleanUrl('/portfolio/subaccounts')));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((json) => SubAccount.fromJson(json))
            .toList();
      }
    }
    return const [];
  }

  /// Fetches account summary (`GET /portfolio/{accountId}/summary`).
  Future<AccountSummary> getAccountSummary(String accountId) async {
    final response =
        await client.get(Uri.parse(_cleanUrl('/portfolio/$accountId/summary')));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AccountSummary.fromJson(json);
    }
    return AccountSummary.fromJson({});
  }

  /// Queries cash ledger breakdown by currency (`GET /portfolio/{accountId}/ledger`).
  Future<List<LedgerEntry>> getLedger(String accountId) async {
    final response =
        await client.get(Uri.parse(_cleanUrl('/portfolio/$accountId/ledger')));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final entries = <LedgerEntry>[];
        decoded.forEach((currency, data) {
          if (data is Map<String, dynamic>) {
            entries.add(LedgerEntry.fromJson(currency, data));
          }
        });
        return entries;
      }
    }
    return const [];
  }

  /// Queries open portfolio positions (`GET /portfolio/{accountId}/positions/{pageId}`).
  Future<List<Position>> getPositions(String accountId,
      {int pageId = 0}) async {
    final response = await client
        .get(Uri.parse(_cleanUrl('/portfolio/$accountId/positions/$pageId')));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((json) => Position.fromJson(json))
            .toList();
      }
    }
    return const [];
  }

  /// Queries details for a specific position (`GET /portfolio/{accountId}/position/{conid}`).
  Future<PositionDetail> getPositionDetail(String accountId, int conid) async {
    final response = await client
        .get(Uri.parse(_cleanUrl('/portfolio/$accountId/position/$conid')));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List &&
          decoded.isNotEmpty &&
          decoded.first is Map<String, dynamic>) {
        return PositionDetail.fromJson(decoded.first as Map<String, dynamic>);
      } else if (decoded is Map<String, dynamic>) {
        return PositionDetail.fromJson(decoded);
      }
    }
    return PositionDetail.fromJson({});
  }

  /// Retrieves asset allocation breakdown for a single account (`GET /portfolio/{accountId}/allocation`).
  Future<PortfolioAllocation> getAccountAllocation(String accountId) async {
    final response = await client
        .get(Uri.parse(_cleanUrl('/portfolio/$accountId/allocation')));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PortfolioAllocation.fromJson(json);
    }
    return PortfolioAllocation.fromJson({});
  }

  /// Retrieves multi-account portfolio allocation breakdown (`POST /portfolio/allocation`).
  Future<PortfolioAllocation> getPortfolioAllocation(
      List<String> accountIds) async {
    final response = await client.post(
      Uri.parse(_cleanUrl('/portfolio/allocation')),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'acctIds': accountIds}),
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return PortfolioAllocation.fromJson(json);
    }
    return PortfolioAllocation.fromJson({});
  }
}

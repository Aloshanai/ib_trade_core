import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/contract.dart';

/// Service adapting contract lookup, security definitions, and option/futures specs for IBKR Client Portal API.
class ContractService {
  final http.Client client;
  final String baseUrl;

  /// Creates a [ContractService] instance.
  ContractService({
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

  /// Searches financial contracts by symbol or description (`POST /iserver/secdef/search`).
  Future<List<ContractSearchHit>> searchContracts(
    String symbol, {
    SecurityType? secType,
    String? month,
    bool name = false,
  }) async {
    final payload = <String, dynamic>{
      'symbol': symbol,
      'name': name,
      if (secType != null) 'secType': secType.code,
      if (month != null) 'month': month,
    };

    final response = await client.post(
      Uri.parse(_cleanUrl('/iserver/secdef/search')),
      headers: {'content-type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((json) => ContractSearchHit.fromJson(json))
            .toList();
      }
    }
    return const [];
  }

  /// Retrieves detailed contract specifications (`GET /iserver/contract/{conid}/info`).
  Future<ContractDetails> getContractInfo(int conid) async {
    final response =
        await client.get(Uri.parse(_cleanUrl('/iserver/contract/$conid/info')));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ContractDetails.fromJson(json);
    }
    return ContractDetails.fromJson({});
  }

  /// Retrieves option strike grid and expiration dates (`GET /iserver/secdef/strikes`).
  Future<OptionChainStrikes> getOptionStrikes(
    int conid,
    SecurityType secType,
    String month, {
    String? exchange,
  }) async {
    final uri = Uri.parse(_cleanUrl('/iserver/secdef/strikes')).replace(
      queryParameters: {
        'conid': conid.toString(),
        'secType': secType.code,
        'month': month,
        if (exchange != null) 'exchange': exchange,
      },
    );

    final response = await client.get(uri);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return OptionChainStrikes.fromJson({'conid': conid, ...json});
    }
    return OptionChainStrikes.fromJson({'conid': conid});
  }

  /// Retrieves futures contract details (`GET /iserver/secdef/info`).
  Future<FuturesContractInfo> getFuturesInfo(int conid) async {
    final uri = Uri.parse(_cleanUrl('/iserver/secdef/info')).replace(
      queryParameters: {
        'conid': conid.toString(),
        'secType': SecurityType.FUT.code,
      },
    );

    final response = await client.get(uri);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List &&
          decoded.isNotEmpty &&
          decoded.first is Map<String, dynamic>) {
        return FuturesContractInfo.fromJson(
            decoded.first as Map<String, dynamic>);
      } else if (decoded is Map<String, dynamic>) {
        return FuturesContractInfo.fromJson(decoded);
      }
    }
    return FuturesContractInfo.fromJson({'conid': conid});
  }
}

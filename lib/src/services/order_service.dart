import 'dart:convert';
import 'package:http/http.dart' as http;
import '../client/challenge_handler.dart';
import '../models/order.dart';

/// Service adapting order management and lifecycle endpoints for IBKR Client Portal API.
class OrderService {
  final http.Client client;
  final String baseUrl;
  final ChallengeHandler? challengeHandler;

  /// Creates an [OrderService] instance.
  OrderService({
    required this.client,
    required this.baseUrl,
    this.challengeHandler,
  });

  String _cleanUrl(String endpoint) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$base$path';
  }

  /// Queries all live open orders across accounts (`GET /iserver/account/orders`).
  Future<List<OrderStatus>> getLiveOrders() async {
    final response =
        await client.get(Uri.parse(_cleanUrl('/iserver/account/orders')));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final list = decoded is Map && decoded.containsKey('orders')
          ? decoded['orders']
          : decoded;
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map((json) => OrderStatus.fromJson(json))
            .toList();
      }
    }
    return const [];
  }

  /// Places single, bracket, OCO, or combo orders (`POST /iserver/account/{accountId}/orders`).
  Future<List<OrderResponse>> placeOrders(
      String accountId, List<OrderRequest> orders) async {
    final body = jsonEncode({'orders': orders.map((o) => o.toJson()).toList()});
    final response = await client.post(
      Uri.parse(_cleanUrl('/iserver/account/$accountId/orders')),
      headers: {'content-type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final results = <OrderResponse>[];
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            final orderRes = OrderResponse.fromJson(item);
            if (orderRes.replyId != null && challengeHandler != null) {
              await challengeHandler!.handleChallenge(IbChallenge(
                id: orderRes.replyId!,
                messages: orderRes.challengeMessages,
                type: 'warning',
              ));
            } else if (orderRes.replyId != null) {
              await replyToChallenge(orderRes.replyId!, true);
            }
            results.add(orderRes);
          }
        }
      }
      return results;
    }
    return const [];
  }

  /// Simulates order execution and margin impact (`POST /iserver/account/{accountId}/orders/whatif`).
  Future<OrderPreview> previewOrder(
      String accountId, OrderRequest order) async {
    final body = jsonEncode({
      'orders': [order.toJson()]
    });
    final response = await client.post(
      Uri.parse(_cleanUrl('/iserver/account/$accountId/orders/whatif')),
      headers: {'content-type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return OrderPreview.fromJson(json);
    }
    return OrderPreview.fromJson({});
  }

  /// Modifies an active open order (`POST /iserver/account/{accountId}/order/{origCustomerOrderId}`).
  Future<OrderResponse> modifyOrder(String accountId,
      String origCustomerOrderId, OrderModification modification) async {
    final response = await client.post(
      Uri.parse(
          _cleanUrl('/iserver/account/$accountId/order/$origCustomerOrderId')),
      headers: {'content-type': 'application/json'},
      body: jsonEncode(modification.toJson()),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List &&
          decoded.isNotEmpty &&
          decoded.first is Map<String, dynamic>) {
        return OrderResponse.fromJson(decoded.first as Map<String, dynamic>);
      } else if (decoded is Map<String, dynamic>) {
        return OrderResponse.fromJson(decoded);
      }
    }
    return OrderResponse(
        raw: {'statusCode': response.statusCode, 'body': response.body});
  }

  /// Cancels an open order (`DELETE /iserver/account/{accountId}/order/{orderId}`).
  Future<OrderResponse> cancelOrder(String accountId, String orderId) async {
    final response = await client.delete(
      Uri.parse(_cleanUrl('/iserver/account/$accountId/order/$orderId')),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return OrderResponse.fromJson(json);
    }
    return OrderResponse(
        raw: {'statusCode': response.statusCode, 'body': response.body});
  }

  /// Queries the status of a specific order (`GET /iserver/account/order/status/{orderId}`).
  Future<OrderStatus> getOrderStatus(String orderId) async {
    final response = await client
        .get(Uri.parse(_cleanUrl('/iserver/account/order/status/$orderId')));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return OrderStatus.fromJson(json);
    }
    return OrderStatus.fromJson({});
  }

  /// Confirms or rejects an order compliance challenge (`POST /iserver/reply/{replyId}`).
  Future<bool> replyToChallenge(String replyId, bool confirmed) async {
    final response = await client.post(
      Uri.parse(_cleanUrl('/iserver/reply/$replyId')),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'confirmed': confirmed}),
    );
    return response.statusCode == 200;
  }
}

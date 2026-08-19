import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_fyi.dart';

/// Service adapting user profile, system notification bulletins (FYIs), and settings endpoints for IBKR Client Portal API.
class UserService {
  final http.Client client;
  final String baseUrl;

  /// Creates a [UserService] instance.
  UserService({
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

  /// Retrieves current user profile info (`GET /one/user`).
  Future<UserInfo> getUserInfo() async {
    final response = await client.get(Uri.parse(_cleanUrl('/one/user')));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return UserInfo.fromJson(json);
    }
    return UserInfo.fromJson({});
  }

  /// Fetches system notifications and bulletins (`GET /fyi/notifications`).
  Future<List<FyiNotification>> getNotifications(
      {bool more = false, int amount = 10}) async {
    final uri = Uri.parse(_cleanUrl('/fyi/notifications')).replace(
      queryParameters: {
        'more': more.toString(),
        'amount': amount.toString(),
      },
    );

    final response = await client.get(uri);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((json) => FyiNotification.fromJson(json))
            .toList();
      }
    }
    return const [];
  }

  /// Queries current unread notifications counter (`GET /fyi/unreadnumber`).
  Future<FyiUnreadCount> getUnreadCount() async {
    final response =
        await client.get(Uri.parse(_cleanUrl('/fyi/unreadnumber')));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return FyiUnreadCount.fromJson(json);
    }
    return FyiUnreadCount.fromJson({});
  }

  /// Retrieves FYI notification preferences (`GET /fyi/settings`).
  Future<List<FyiSettings>> getFyiSettings() async {
    final response = await client.get(Uri.parse(_cleanUrl('/fyi/settings')));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((json) => FyiSettings.fromJson(json))
            .toList();
      }
    }
    return const [];
  }

  /// Updates FYI notification preferences (`POST /fyi/settings`).
  Future<bool> updateFyiSettings(List<FyiSettings> settings) async {
    final response = await client.post(
      Uri.parse(_cleanUrl('/fyi/settings')),
      headers: {'content-type': 'application/json'},
      body: jsonEncode(settings.map((s) => s.toJson()).toList()),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['status'] == 200 ||
          json['success'] == true ||
          json['confirmed'] == true;
    }
    return false;
  }

  /// Retrieves user gateway settings (`GET /iserver/user/settings`).
  Future<UserSettings> getUserSettings() async {
    final response =
        await client.get(Uri.parse(_cleanUrl('/iserver/user/settings')));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return UserSettings.fromJson(json);
    }
    return UserSettings.fromJson({});
  }
}

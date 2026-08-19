/// User profile information from `/one/user`.
class UserInfo {
  final int userId;
  final String userName;
  final String email;
  final bool isPaper;
  final Map<String, dynamic> features;
  final Map<String, dynamic> raw;

  UserInfo({
    required this.userId,
    required this.userName,
    required this.email,
    required this.isPaper,
    required this.features,
    required this.raw,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    int i(dynamic val) =>
        val is int ? val : int.tryParse(val?.toString() ?? '0') ?? 0;
    final paperVal = json['isPaper'] ?? json['paper'];
    return UserInfo(
      userId: i(json['userId'] ?? json['user_id'] ?? json['id']),
      userName:
          (json['userName'] ?? json['user_name'] ?? json['username'] ?? '')
              .toString(),
      email: (json['email'] ?? '').toString(),
      isPaper: paperVal == true || paperVal == 1 || paperVal == 'true',
      features: json['features'] is Map<String, dynamic>
          ? json['features'] as Map<String, dynamic>
          : const {},
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}

/// FYI bulletin or system notification entry.
class FyiNotification {
  final String id;
  final String code;
  final String title;
  final String body;
  final int timestamp;
  final bool read;
  final Map<String, dynamic> raw;

  FyiNotification({
    required this.id,
    required this.code,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.read,
    required this.raw,
  });

  factory FyiNotification.fromJson(Map<String, dynamic> json) {
    int i(dynamic val) =>
        val is int ? val : int.tryParse(val?.toString() ?? '0') ?? 0;
    final readVal = json['read'] ?? json['R'] ?? json['isRead'];
    return FyiNotification(
      id: (json['id'] ?? json['id'] ?? json['A'] ?? '').toString(),
      code: (json['code'] ?? json['FC'] ?? '').toString(),
      title: (json['title'] ?? json['T'] ?? '').toString(),
      body: (json['body'] ?? json['B'] ?? json['MS'] ?? '').toString(),
      timestamp: i(json['timestamp'] ?? json['D'] ?? json['time']),
      read: readVal == true || readVal == 1 || readVal == '1',
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}

/// Unread notification counter object.
class FyiUnreadCount {
  final int unreadNumber;

  FyiUnreadCount({required this.unreadNumber});

  factory FyiUnreadCount.fromJson(Map<String, dynamic> json) {
    final num =
        json['unreadNumber'] ?? json['BN'] ?? json['count'] ?? json['unread'];
    final i = num is int ? num : int.tryParse(num?.toString() ?? '0') ?? 0;
    return FyiUnreadCount(unreadNumber: i);
  }

  Map<String, dynamic> toJson() => {'unreadNumber': unreadNumber};
}

/// FYI notification subscription preference item.
class FyiSettings {
  final String type;
  final bool enabled;
  final String device;
  final Map<String, dynamic> raw;

  FyiSettings({
    required this.type,
    required this.enabled,
    required this.device,
    required this.raw,
  });

  factory FyiSettings.fromJson(Map<String, dynamic> json) {
    final enVal = json['enabled'] ?? json['E'] ?? json['A'];
    return FyiSettings(
      type: (json['type'] ?? json['FC'] ?? '').toString(),
      enabled: enVal == true || enVal == 1 || enVal == '1',
      device: (json['device'] ?? json['D'] ?? '').toString(),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'enabled': enabled,
        'device': device,
      };
}

/// User gateway configuration settings.
class UserSettings {
  final String timeZone;
  final String language;
  final bool paperMode;
  final Map<String, dynamic> raw;

  UserSettings({
    required this.timeZone,
    required this.language,
    required this.paperMode,
    required this.raw,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    final paperVal = json['paperMode'] ?? json['paper'];
    return UserSettings(
      timeZone: (json['timeZone'] ?? json['timezone'] ?? json['tz'] ?? 'EST')
          .toString(),
      language: (json['language'] ?? json['lang'] ?? 'en').toString(),
      paperMode: paperVal == true || paperVal == 1 || paperVal == 'true',
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}

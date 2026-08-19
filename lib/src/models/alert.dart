/// Summary item of an account price/order alert.
class AlertItem {
  final int alertId;
  final String alertName;
  final String orderId;
  final String account;
  final bool alertActive;
  final String orderTime;
  final Map<String, dynamic> raw;

  AlertItem({
    required this.alertId,
    required this.alertName,
    required this.orderId,
    required this.account,
    required this.alertActive,
    required this.orderTime,
    required this.raw,
  });

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    int i(dynamic val) {
      if (val is int) return val;
      return int.tryParse(val?.toString() ?? '0') ?? 0;
    }

    final activeVal = json['alertActive'] ?? json['active'];
    return AlertItem(
      alertId: i(json['alertId'] ?? json['id'] ?? json['alert_id']),
      alertName: (json['alertName'] ?? json['name'] ?? '').toString(),
      orderId: (json['orderId'] ?? json['order_id'] ?? '').toString(),
      account: (json['account'] ?? json['acctId'] ?? '').toString(),
      alertActive: activeVal == true || activeVal == 1 || activeVal == '1',
      orderTime: (json['orderTime'] ?? json['time'] ?? '').toString(),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}

/// Trigger condition for an alert.
class AlertCondition {
  final int type; // 1: Price, 2: Time, 3: Margin, 4: Volume, 5: MarketCap
  final int conid;
  final String operator; // '>=', '<='
  final dynamic value;
  final String logicBind; // 'a' (AND), 'o' (OR)

  AlertCondition({
    required this.type,
    required this.conid,
    required this.operator,
    required this.value,
    this.logicBind = 'a',
  });

  factory AlertCondition.fromJson(Map<String, dynamic> json) {
    int i(dynamic val) =>
        val is int ? val : int.tryParse(val?.toString() ?? '0') ?? 0;
    return AlertCondition(
      type: i(json['type']),
      conid: i(json['conid']),
      operator: (json['operator'] ?? '>=').toString(),
      value: json['value'],
      logicBind: (json['logicBind'] ?? 'a').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'conid': conid,
        'operator': operator,
        'value': value,
        'logicBind': logicBind,
      };
}

/// Request structure for creating or updating an alert.
class CreateAlertRequest {
  final String alertName;
  final String account;
  final bool alertRepeatable;
  final bool sendMessage;
  final bool emailMessage;
  final List<AlertCondition> conditions;

  CreateAlertRequest({
    required this.alertName,
    required this.account,
    this.alertRepeatable = false,
    this.sendMessage = true,
    this.emailMessage = false,
    required this.conditions,
  });

  Map<String, dynamic> toJson() => {
        'alertName': alertName,
        'account': account,
        'alertRepeatable': alertRepeatable ? 1 : 0,
        'sendMessage': sendMessage ? 1 : 0,
        'emailMessage': emailMessage ? 1 : 0,
        'conditions': conditions.map((c) => c.toJson()).toList(),
      };
}

/// Detailed alert specs with conditions and action rules.
class AlertDetails {
  final int alertId;
  final String alertName;
  final String account;
  final List<AlertCondition> conditions;
  final List<dynamic> actions;
  final String timeZone;
  final Map<String, dynamic> raw;

  AlertDetails({
    required this.alertId,
    required this.alertName,
    required this.account,
    required this.conditions,
    required this.actions,
    required this.timeZone,
    required this.raw,
  });

  factory AlertDetails.fromJson(Map<String, dynamic> json) {
    int i(dynamic val) =>
        val is int ? val : int.tryParse(val?.toString() ?? '0') ?? 0;
    final rawConds = json['conditions'] ?? json['conditionList'];
    final condList = <AlertCondition>[];
    if (rawConds is List) {
      for (final c in rawConds) {
        if (c is Map<String, dynamic>) {
          condList.add(AlertCondition.fromJson(c));
        }
      }
    }

    return AlertDetails(
      alertId: i(json['alertId'] ?? json['id']),
      alertName: (json['alertName'] ?? json['name'] ?? '').toString(),
      account: (json['account'] ?? json['acctId'] ?? '').toString(),
      conditions: condList,
      actions: json['actions'] is List ? json['actions'] as List : const [],
      timeZone: (json['timeZone'] ?? json['time_zone'] ?? '').toString(),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}

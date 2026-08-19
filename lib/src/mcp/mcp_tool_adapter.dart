import 'package:meta/meta.dart';
import '../ib_trade_core_client.dart';

/// Function signature for an MCP tool execution handler.
typedef McpToolHandler = Future<dynamic> Function(
    IbTradeCoreClient client, Map<String, dynamic> arguments);

/// Contract specification for an MCP Tool.
@immutable
class McpToolContract {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;
  final McpToolHandler handler;

  const McpToolContract({
    required this.name,
    required this.description,
    required this.inputSchema,
    required this.handler,
  });
}

/// Registry adapter defining Model Context Protocol (MCP) tool contracts for IBKR domain services.
class McpToolRegistryAdapter {
  final Map<String, McpToolContract> _registry = {};

  McpToolRegistryAdapter() {
    _registerDefaultTools();
  }

  /// Registered tool contracts list.
  List<McpToolContract> get tools => List.unmodifiable(_registry.values);

  /// Look up a registered tool contract by name.
  McpToolContract? getTool(String name) => _registry[name];

  /// Register a custom or overridden tool contract.
  void registerTool(McpToolContract contract) {
    _registry[contract.name] = contract;
  }

  void _registerDefaultTools() {
    registerTool(McpToolContract(
      name: 'get_auth_status',
      description: 'Get current authentication and gateway connection status.',
      inputSchema: {
        'type': 'object',
        'properties': {},
      },
      handler: (client, args) async =>
          (await client.session.getAuthStatus()).toJson(),
    ));

    registerTool(McpToolContract(
      name: 'get_accounts',
      description: 'List accessible trading accounts.',
      inputSchema: {
        'type': 'object',
        'properties': {},
      },
      handler: (client, args) async {
        final accounts = await client.account.getAccounts();
        return accounts.map((a) => a.toJson()).toList();
      },
    ));

    registerTool(McpToolContract(
      name: 'get_portfolio_summary',
      description: 'Get key portfolio summary metrics for an account.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'accountId': {'type': 'string', 'description': 'Target account ID'},
        },
        'required': ['accountId'],
      },
      handler: (client, args) async {
        final summary = await client.account
            .getAccountSummary(args['accountId'].toString());
        return summary.toJson();
      },
    ));

    registerTool(McpToolContract(
      name: 'search_contracts',
      description: 'Search financial contracts by symbol.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'symbol': {
            'type': 'string',
            'description': 'Ticker symbol to search'
          },
        },
        'required': ['symbol'],
      },
      handler: (client, args) async {
        final hits =
            await client.contracts.searchContracts(args['symbol'].toString());
        return hits.map((h) => h.toJson()).toList();
      },
    ));

    registerTool(McpToolContract(
      name: 'get_market_snapshot',
      description: 'Get real-time market data snapshot for contract IDs.',
      inputSchema: {
        'type': 'object',
        'properties': {
          'conids': {
            'type': 'array',
            'items': {'type': 'integer'},
            'description': 'List of contract IDs',
          },
        },
        'required': ['conids'],
      },
      handler: (client, args) async {
        final rawConids = args['conids'] as List?;
        final conids =
            rawConids?.map((e) => int.parse(e.toString())).toList() ?? [];
        final snapshots = await client.marketData.getMarketDataSnapshot(conids);
        return snapshots.map((s) => s.toJson()).toList();
      },
    ));

    registerTool(McpToolContract(
      name: 'get_live_orders',
      description: 'Get list of active live open orders.',
      inputSchema: {
        'type': 'object',
        'properties': {},
      },
      handler: (client, args) async {
        final orders = await client.orders.getLiveOrders();
        return orders.map((o) => o.toJson()).toList();
      },
    ));
  }
}

import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/exception.dart';

/// Represents a safety or compliance challenge prompt from the IBKR Gateway.
class IbChallenge {
  /// The unique ID of the reply (used in /iserver/reply/{id}).
  final String id;

  /// The prompt messages/warnings displayed to the user.
  final List<String> messages;

  /// The type of prompt (e.g. 'warning', 'question').
  final String type;

  /// Creates an [IbChallenge] instance.
  IbChallenge({
    required this.id,
    required this.messages,
    required this.type,
  });

  /// Factory constructor to parse a challenge from a JSON map.
  factory IbChallenge.fromJson(Map<String, dynamic> json) {
    final messagesJson = json['message'] ?? json['messages'];
    final List<String> parsedMessages = [];
    if (messagesJson is List) {
      parsedMessages.addAll(messagesJson.map((e) => e.toString()));
    } else if (messagesJson is String) {
      parsedMessages.add(messagesJson);
    }

    return IbChallenge(
      id: json['id']?.toString() ?? '',
      messages: parsedMessages,
      type: json['type']?.toString() ?? 'warning',
    );
  }
}

/// Defines the contract for resolving a compliance or safety challenge.
abstract class ChallengeResolver {
  /// Decides if this resolver can handle the given [challenge].
  bool canResolve(IbChallenge challenge);

  /// Resolves the given [challenge], returning true if confirmed, false otherwise.
  Future<bool> resolve(IbChallenge challenge);
}

/// A default resolver that automatically confirms all challenges.
class AutoConfirmChallengeResolver implements ChallengeResolver {
  @override
  bool canResolve(IbChallenge challenge) => true;

  @override
  Future<bool> resolve(IbChallenge challenge) async => true;
}

/// Manages a registry of challenge resolvers and handles executing replies.
class ChallengeHandler {
  final http.Client _client;
  final Uri _baseUrl;
  final List<ChallengeResolver> _resolvers = [];

  /// Creates a [ChallengeHandler] with the given [_client] and [_baseUrl].
  ChallengeHandler(this._client, this._baseUrl) {
    // Add default auto-confirm resolver
    registerResolver(AutoConfirmChallengeResolver());
  }

  /// Registered resolvers list (unmodifiable).
  List<ChallengeResolver> get resolvers => List.unmodifiable(_resolvers);

  /// Registers a new [ChallengeResolver] at the beginning of the list
  /// (giving it higher precedence).
  void registerResolver(ChallengeResolver resolver) {
    _resolvers.insert(0, resolver);
  }

  /// Removes a registered [ChallengeResolver].
  void unregisterResolver(ChallengeResolver resolver) {
    _resolvers.remove(resolver);
  }

  /// Processes a single challenge by finding the first matching resolver.
  ///
  /// Submits the confirmed response (true/false) to the gateway.
  /// Returns the result of the submission.
  Future<bool> handleChallenge(IbChallenge challenge) async {
    for (final resolver in _resolvers) {
      if (resolver.canResolve(challenge)) {
        final confirmed = await resolver.resolve(challenge);
        return await submitReply(challenge.id, confirmed);
      }
    }
    throw IbException(
        'No challenge resolver found to handle challenge ID: ${challenge.id}');
  }

  /// Helper to submit the reply back to the gateway.
  Future<bool> submitReply(String replyId, bool confirmed) async {
    final replyUrl = _baseUrl.resolve('iserver/reply/$replyId');
    try {
      final response = await _client.post(
        replyUrl,
        body: '{"confirmed": $confirmed}',
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw IbException(
          'Failed to submit reply: Gateway responded with status ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is IbException) rethrow;
      throw IbException('Failed to submit reply: $e');
    }
  }
}

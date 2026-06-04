import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../config/firebase_config.dart';
import '../models/message.dart';

/// Manages the chat state between the user and the Dostok AI.
///
/// Handles message persistence via Hive, optimistic UI updates for user
/// messages, and communication with the AI backend. Widgets consume this
/// provider to render the message list and show loading/typing indicators.
class ChatProvider extends ChangeNotifier {
  static const String _boxName = 'conversations';
  static const String _messagesKey = 'messages';
  static const String _apiBaseUrl = 'https://api.dostok.app/v1';

  final Uuid _uuid = const Uuid();

  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;
  String? _error;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// All messages in the current conversation, ordered chronologically.
  List<Message> get messages => List.unmodifiable(_messages);

  /// Whether an API call is in progress (loading state for send button, etc.).
  bool get isLoading => _isLoading;

  /// Whether the AI is composing a response (typing indicator).
  bool get isTyping => _isTyping;

  /// The last error message, if any. Cleared on the next successful action.
  String? get error => _error;

  /// Number of messages in the conversation.
  int get messageCount => _messages.length;

  /// Whether the conversation is empty.
  bool get isEmpty => _messages.isEmpty;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Loads persisted messages from Hive. Call once during app startup.
  Future<void> loadMessages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final box = await Hive.openBox(_boxName);
      final raw = box.get(_messagesKey);

      if (raw != null && raw is List) {
        _messages = raw.map((item) {
          if (item is Map) {
            return Message(
              id: item['id'] as String? ?? _uuid.v4(),
              content: item['content'] as String? ?? '',
              isFromUser: item['isFromUser'] as bool? ?? false,
              timestamp: item['timestamp'] is DateTime
                  ? item['timestamp'] as DateTime
                  : DateTime.tryParse(item['timestamp']?.toString() ?? '') ??
                      DateTime.now(),
              type: MessageType.values.firstWhere(
                (t) => t.name == item['type'],
                orElse: () => MessageType.text,
              ),
              audioPath: item['audioPath'] as String?,
              isRead: item['isRead'] as bool? ?? false,
            );
          }
          // If the object is already a deserialized Message (via Hive adapter).
          if (item is Message) return item;
          throw FormatException('Cannot deserialize message: $item');
        }).toList();
      }
    } catch (e, st) {
      dev.log('ChatProvider.loadMessages failed', error: e, stackTrace: st);
      _error = 'Failed to load conversation history.';
      _messages = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Sending messages
  // ---------------------------------------------------------------------------

  /// Sends a text message from the user and requests an AI response.
  ///
  /// Uses optimistic UI: the user message is immediately appended to the list
  /// and persisted. The AI response is then fetched asynchronously. If the
  /// request fails the user message remains but an error is surfaced.
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _error = null;

    // 1. Optimistic UI -- add user message immediately.
    final userMessage = Message(
      id: _uuid.v4(),
      content: trimmed,
      isFromUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    _persistMessage(userMessage);
    notifyListeners();

    // 2. Show typing indicator and fetch AI response.
    _isTyping = true;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _fetchAiResponse(trimmed);

      final aiMessage = Message(
        id: _uuid.v4(),
        content: response,
        isFromUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(aiMessage);
      _persistMessage(aiMessage);
    } catch (e, st) {
      dev.log('ChatProvider.sendMessage failed', error: e, stackTrace: st);
      _error = 'Could not get a response. Please try again.';

      // Add a system message so the user sees the failure context.
      final errorMessage = Message(
        id: _uuid.v4(),
        content: 'Sorry, I had trouble responding. Please try again!',
        isFromUser: false,
        timestamp: DateTime.now(),
        type: MessageType.system,
      );
      _messages.add(errorMessage);
      _persistMessage(errorMessage);
    } finally {
      _isTyping = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sends a voice message (audio path stored, transcription sent as text).
  Future<void> sendVoiceMessage(String audioPath, String transcription) async {
    final trimmed = transcription.trim();
    if (trimmed.isEmpty) return;

    _error = null;

    final voiceMessage = Message(
      id: _uuid.v4(),
      content: trimmed,
      isFromUser: true,
      timestamp: DateTime.now(),
      type: MessageType.audio,
      audioPath: audioPath,
    );
    _messages.add(voiceMessage);
    _persistMessage(voiceMessage);
    notifyListeners();

    _isTyping = true;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _fetchAiResponse(trimmed);
      final aiMessage = Message(
        id: _uuid.v4(),
        content: response,
        isFromUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(aiMessage);
      _persistMessage(aiMessage);
    } catch (e, st) {
      dev.log('ChatProvider.sendVoiceMessage failed',
          error: e, stackTrace: st);
      _error = 'Could not get a response. Please try again.';
    } finally {
      _isTyping = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Conversation management
  // ---------------------------------------------------------------------------

  /// Deletes all messages in the current conversation.
  Future<void> clearChat() async {
    _messages.clear();
    _error = null;
    notifyListeners();

    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_messagesKey, <Map<String, dynamic>>[]);
    } catch (e, st) {
      dev.log('ChatProvider.clearChat failed', error: e, stackTrace: st);
    }
  }

  /// Marks all messages as read.
  Future<void> markAllAsRead() async {
    bool changed = false;
    for (var i = 0; i < _messages.length; i++) {
      if (!_messages[i].isRead) {
        _messages[i] = _messages[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
      await _saveAll();
    }
  }

  /// Deletes a single message by its [id].
  Future<void> deleteMessage(String id) async {
    _messages.removeWhere((m) => m.id == id);
    notifyListeners();
    await _saveAll();
  }

  /// Retries the last failed message by re-sending the last user message.
  Future<void> retryLastMessage() async {
    // Find the last user message.
    final lastUserMsg = _messages.lastWhere(
      (m) => m.isFromUser,
      orElse: () => Message(
        id: '',
        content: '',
        isFromUser: true,
        timestamp: DateTime.now(),
      ),
    );
    if (lastUserMsg.id.isEmpty) return;

    // Remove the error/system message that follows, if present.
    if (_messages.isNotEmpty && !_messages.last.isFromUser) {
      _messages.removeLast();
      notifyListeners();
    }

    await sendMessage(lastUserMsg.content);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Returns a random canned Darija response for demo mode.
  String _getDemoResponse() {
    final responses = [
      'Ahlan! Ana Dostok, sadiqek. Kifach n3awnek l-youm?',
      'Safi, fhemtek! Chno bghiti nzidou?',
      'Mzyan bzzaf! Kanbghi nhsdr m3ak darija.',
      'Hada mzyan! Jrb tani, ghadi yzid yji mzyan.',
      'Waxxa sadiq, ana hna m3ak. Gouliya chno bghiti!',
      'Lah y3tik ssa7a! Jrb ntmarnaw m3a b3d.',
      'Ah, hadchi bzzaf interesting! Zid koul li 3andek.',
      'Safi safi, koulchi mzyan. Ana m3ak f kol wa9t!',
    ];
    return responses[Random().nextInt(responses.length)];
  }

  /// Calls the AI backend to get a response for the given user [input].
  Future<String> _fetchAiResponse(String input) async {
    // In demo mode, return a canned response after a short delay.
    if (FirebaseConfig.isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 1200));
      return _getDemoResponse();
    }
    // Build the conversation context from recent messages (last 20).
    final recentMessages =
        _messages.length > 20 ? _messages.sublist(_messages.length - 20) : _messages;
    final contextMessages = recentMessages
        .map((m) => {
              'role': m.isFromUser ? 'user' : 'assistant',
              'content': m.content,
            })
        .toList();

    final response = await http
        .post(
          Uri.parse('$_apiBaseUrl/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'messages': contextMessages,
            'language': 'darija',
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['response'] as String? ?? '...';
    } else {
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }
  }

  /// Persists a single message to Hive.
  Future<void> _persistMessage(Message message) async {
    try {
      final box = await Hive.openBox(_boxName);
      final List<dynamic> existing = (box.get(_messagesKey) as List?) ?? [];
      existing.add({
        'id': message.id,
        'content': message.content,
        'isFromUser': message.isFromUser,
        'timestamp': message.timestamp.toIso8601String(),
        'type': message.type.name,
        'audioPath': message.audioPath,
        'isRead': message.isRead,
      });
      await box.put(_messagesKey, existing);
    } catch (e, st) {
      dev.log('ChatProvider._persistMessage failed', error: e, stackTrace: st);
    }
  }

  /// Overwrites the persisted message list with the current in-memory state.
  Future<void> _saveAll() async {
    try {
      final box = await Hive.openBox(_boxName);
      final serialized = _messages
          .map((m) => {
                'id': m.id,
                'content': m.content,
                'isFromUser': m.isFromUser,
                'timestamp': m.timestamp.toIso8601String(),
                'type': m.type.name,
                'audioPath': m.audioPath,
                'isRead': m.isRead,
              })
          .toList();
      await box.put(_messagesKey, serialized);
    } catch (e, st) {
      dev.log('ChatProvider._saveAll failed', error: e, stackTrace: st);
    }
  }
}

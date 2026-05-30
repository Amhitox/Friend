import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

import 'ai_service.dart';

/// Service that manages local data persistence using Hive.
///
/// Provides methods to save and load messages, user profiles, and
/// conversation threads. Each data type is stored in its own Hive box
/// for clean organization and independent access.
class StorageService {
  static const String _messagesBoxName = 'messages';
  static const String _profileBoxName = 'profile';
  static const String _conversationsBoxName = 'conversations';

  Box<String>? _messagesBox;
  Box<String>? _profileBox;
  Box<String>? _conversationsBox;

  /// Initializes all Hive boxes required by the service.
  ///
  /// Must be called before using any other methods. Opens boxes for
  /// messages, profile, and conversations storage.
  ///
  /// Returns true if all boxes opened successfully.
  Future<bool> initialize() async {
    try {
      await Hive.initFlutter();
      _messagesBox = await Hive.openBox<String>(_messagesBoxName);
      _profileBox = await Hive.openBox<String>(_profileBoxName);
      _conversationsBox = await Hive.openBox<String>(_conversationsBoxName);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  /// Saves a list of messages to local storage.
  ///
  /// [conversationId] identifies which conversation the messages belong to.
  /// Messages are serialized as JSON and stored under the conversation key.
  Future<bool> saveMessages(
    String conversationId,
    List<Message> messages,
  ) async {
    try {
      final box = _messagesBox;
      if (box == null) return false;

      final jsonList = messages
          .map((m) => jsonEncode({
                'role': m.role,
                'content': m.content,
                'timestamp': m.timestamp.toIso8601String(),
              }))
          .toList();

      await box.put(conversationId, jsonEncode(jsonList));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Loads messages for a given [conversationId] from local storage.
  ///
  /// Returns an empty list if no messages are found or if an error occurs.
  Future<List<Message>> loadMessages(String conversationId) async {
    try {
      final box = _messagesBox;
      if (box == null) return [];

      final raw = box.get(conversationId);
      if (raw == null) return [];

      final jsonList = jsonDecode(raw) as List<dynamic>;
      return jsonList.map((item) {
        final map = jsonDecode(item as String) as Map<String, dynamic>;
        return Message(
          role: map['role'] as String,
          content: map['content'] as String,
          timestamp: DateTime.parse(map['timestamp'] as String),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Deletes all messages for a given [conversationId].
  Future<bool> deleteMessages(String conversationId) async {
    try {
      final box = _messagesBox;
      if (box == null) return false;
      await box.delete(conversationId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  /// Saves the user profile as a JSON-encodable map.
  ///
  /// [profile] should contain serializable values (strings, numbers, bools,
  /// lists, and maps).
  Future<bool> saveProfile(Map<String, dynamic> profile) async {
    try {
      final box = _profileBox;
      if (box == null) return false;
      await box.put('user_profile', jsonEncode(profile));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Loads the user profile from local storage.
  ///
  /// Returns an empty map if no profile is saved or if an error occurs.
  Future<Map<String, dynamic>> loadProfile() async {
    try {
      final box = _profileBox;
      if (box == null) return {};

      final raw = box.get('user_profile');
      if (raw == null) return {};

      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  // ── Conversations ─────────────────────────────────────────────────────────

  /// Saves a conversation thread with metadata.
  ///
  /// [conversationId] is the unique identifier for the conversation.
  /// [title] is a human-readable name (e.g., first message snippet).
  /// [createdAt] is the conversation start time.
  /// [lastMessagePreview] is a short snippet of the last message.
  Future<bool> saveConversation({
    required String conversationId,
    required String title,
    required DateTime createdAt,
    String? lastMessagePreview,
  }) async {
    try {
      final box = _conversationsBox;
      if (box == null) return false;

      final data = {
        'id': conversationId,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'lastMessagePreview': lastMessagePreview ?? '',
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await box.put(conversationId, jsonEncode(data));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Loads all saved conversations, sorted by most recently updated.
  ///
  /// Returns a list of conversation metadata maps. Each map contains:
  /// - `id`: conversation identifier
  /// - `title`: conversation title
  /// - `createdAt`: when the conversation started
  /// - `lastMessagePreview`: snippet of the last message
  /// - `updatedAt`: when the conversation was last updated
  Future<List<Map<String, dynamic>>> loadConversations() async {
    try {
      final box = _conversationsBox;
      if (box == null) return [];

      final conversations = <Map<String, dynamic>>[];
      for (final key in box.keys) {
        final raw = box.get(key);
        if (raw != null) {
          conversations.add(jsonDecode(raw) as Map<String, dynamic>);
        }
      }

      // Sort by updatedAt descending (most recent first).
      conversations.sort((a, b) {
        final aDate = DateTime.parse(a['updatedAt'] as String);
        final bDate = DateTime.parse(b['updatedAt'] as String);
        return bDate.compareTo(aDate);
      });

      return conversations;
    } catch (e) {
      return [];
    }
  }

  /// Deletes a conversation and its associated messages.
  Future<bool> deleteConversation(String conversationId) async {
    try {
      await deleteMessages(conversationId);
      final box = _conversationsBox;
      if (box == null) return false;
      await box.delete(conversationId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clears all data from all boxes.
  ///
  /// Use with caution. This permanently deletes all messages, profiles,
  /// and conversations.
  Future<bool> clearAll() async {
    try {
      await _messagesBox?.clear();
      await _profileBox?.clear();
      await _conversationsBox?.clear();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Closes all Hive boxes and releases resources.
  Future<void> dispose() async {
    await _messagesBox?.close();
    await _profileBox?.close();
    await _conversationsBox?.close();
  }
}

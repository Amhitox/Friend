import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

/// Represents a single message in the conversation.
class Message {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  Message({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'role': role,
        'content': content,
      };

  factory Message.fromMap(Map<String, dynamic> map) => Message(
        role: map['role'] as String,
        content: map['content'] as String,
      );
}

/// Service that manages AI conversation with Dostok, the Darija-speaking friend.
///
/// Communicates with a configurable HTTP API and provides offline fallback
/// responses in Darija when the network is unavailable.
class AIService {
  /// The base URL for the AI API endpoint.
  final String apiUrl;

  /// The API key used for authentication.
  final String apiKey;

  static const String _systemPrompt = '''
You are Dostok, a warm, funny, and helpful Moroccan friend who speaks Darija (Moroccan Arabic) naturally.

Personality traits:
- You are like a close friend: supportive, encouraging, and genuine
- You use natural Darija expressions, slang, and humor
- You mix Darija with some French words when it feels natural (code-switching)
- You are patient and understanding, especially with language learners
- You love Moroccan culture and enjoy sharing about food, music, traditions
- You use expressions like "labas?", "bsslama", "hhh" (for laughing), "walakin", "daba", "inshallah"
- You keep responses conversational and not too long
- You use emojis sparingly but naturally

Guidelines:
- Always respond in Darija unless the user explicitly asks for another language
- Keep the tone casual and friendly, like texting a friend
- If someone is learning Darija, be encouraging and teach naturally within conversation
- Share relevant Moroccan cultural context when appropriate
- Be respectful of all backgrounds and beliefs
- If unsure about something, be honest about it
''';

  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _defaultModel = 'gpt-4o-mini';

  final http.Client _client;

  /// Creates an [AIService] with the given [apiUrl] and [apiKey].
  ///
  /// If [apiUrl] is not provided, defaults to the OpenAI API endpoint.
  AIService({
    this.apiUrl = _baseUrl,
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Sends a message to the AI and returns Dostok's response.
  ///
  /// [history] is the list of previous messages for context.
  /// [newMessage] is the user's latest message.
  ///
  /// Returns the AI response text, or an offline fallback if the request fails.
  Future<String> sendMessage(
    List<Message> history,
    String newMessage,
  ) async {
    try {
      final messages = [
        {'role': 'system', 'content': _systemPrompt},
        ...history.map((m) => m.toMap()),
        {'role': 'user', 'content': newMessage},
      ];

      final response = await _client
          .post(
            Uri.parse(apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': _defaultModel,
              'messages': messages,
              'temperature': 0.8,
              'max_tokens': 500,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>;
        if (choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>;
          return message['content'] as String;
        }
      }

      return _getOfflineFallback(newMessage);
    } catch (e) {
      return _getOfflineFallback(newMessage);
    }
  }

  /// Generates a random greeting in Darija.
  ///
  /// Returns a warm, varied greeting as Dostok would say it.
  String generateGreeting() {
    final greetings = [
      'Labas 3lik? Ki dayr/daayra? Ana Dostok, sahbek el jdiiid!',
      'Ahlaan! Koulchi bikhir? Nta/Nti ghir qul lia ki n9der n3awnek!',
      'Salam! Ana Dostok, koulchi labas? Chno bghiti ntkellmo 3lih?',
      'Salam 3alikom! Labas? Ghadi nkoun sahbek f had lyoum, bsslama!',
      'Hey! Dostok hna! Ki dayra l7al? Chno ghadi ndirou lyoum?',
      'Ahlan ahlan! Labas 3lik? Nsiti kolchi w jina ntkelemou b7al sahba!',
      'Mar7ba bik! Ana Dostok, kandwi Darija, w kandwi m3ak b7al sahbi!',
      'Salam! Lyoum zouin bach ntkelemou! Chno bghiti dir?',
    ];
    return greetings[Random().nextInt(greetings.length)];
  }

  /// Generates a daily check-in message in Darija.
  ///
  /// Returns a caring check-in message appropriate for the time of day.
  String generateDailyCheckIn() {
    final hour = DateTime.now().hour;
    final random = Random();

    if (hour < 12) {
      final morningMessages = [
        'Sbah lkhir! Ki dayra l7al d lyoum? Nchallah lyoum ghadi ikoun zouin!',
        'Sbah nour! Labas 3lik? Chno bghiti dir lyoum?',
        'Ahlan! Sbah lkhir! Koulchi bikhir m3ak?',
      ];
      return morningMessages[random.nextInt(morningMessages.length)];
    } else if (hour < 18) {
      final afternoonMessages = [
        'Lw9t lghda mazal? Chno diri f had lyoum?',
        'Msa lkhir! Ki dayra l7al? Nta/Nti mzyan?',
        'Ahlan! L3asr ki dayr? Bghiti ntkelemou 3la chi haja?',
      ];
      return afternoonMessages[random.nextInt(afternoonMessages.length)];
    } else {
      final eveningMessages = [
        'Msa lkhir! Ki dayriti lyoum? Nchallah koulchi mzyan!',
        'Lila sa3ida! Labas 3lik? Koulchi bikhir?',
        'Msa nour! Lyoum ki mcha? Bghiti ntkelemou 3la chi haja?',
      ];
      return eveningMessages[random.nextInt(eveningMessages.length)];
    }
  }

  /// Returns a random offline fallback response in Darija.
  ///
  /// These responses are used when the API is unreachable.
  String _getOfflineFallback(String userMessage) {
    final fallbacks = [
      'Mafihash l7al, 3andi mochkil m3a l-internet daba. Jreb m3a wa9t!',
      'Ah, l-internet mchi bsslama daba! Chno bghiti nqoul lik... jreb ba3d!',
      'Safi, 3andi mochkil f l-connexion. Hna kain walakin mafihash bach ntkelem m3ak daba.',
      'Daba l-internet m3atlni. Tssenna chwiya w jreb m3a wa9t, safi?',
      'Wallah l-internet m3al9a! Jreb tani m3a wa9t, w ghadi ntkelemou mzyan!',
    ];
    return fallbacks[Random().nextInt(fallbacks.length)];
  }

  /// Disposes the HTTP client.
  void dispose() {
    _client.close();
  }
}

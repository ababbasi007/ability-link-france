import 'ai_action.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.isError = false,
    this.citations = const [],
    this.flags = const [],
    this.safetyScore = 100,
    this.actions = const [],
  });

  final String id;
  final ChatRole role;
  final String text;
  final DateTime createdAt;
  final bool isError;
  final List<String> citations;
  final List<String> flags;
  final int safetyScore;
  final List<AiAction> actions;

  bool get isUser => role == ChatRole.user;
  bool get isAssistant => role == ChatRole.assistant;

  Map<String, dynamic> toMap() => {
    'id': id,
    'role': role.name,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'isError': isError,
    'actions': actions.map((a) => a.toMap()).toList(),
  };

  factory ChatMessage.fromMap(Map<String, dynamic> data) {
    final rawActions = data['actions'];
    final actions = <AiAction>[];
    if (rawActions is List) {
      for (final item in rawActions) {
        if (item is Map) {
          actions.add(AiAction.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }
    return ChatMessage(
      id:
          (data['id'] as String?) ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      role: ChatRole.values.firstWhere(
        (r) => r.name == data['role'],
        orElse: () => ChatRole.assistant,
      ),
      text: (data['text'] as String?) ?? '',
      createdAt:
          DateTime.tryParse(data['createdAt'] as String? ?? '') ??
          DateTime.now(),
      isError: data['isError'] == true,
      actions: actions,
    );
  }
}

enum ChatRole { user, assistant, system }

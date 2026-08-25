class SafetyScan {
  const SafetyScan({
    this.citations = const [],
    this.flags = const [],
    this.score = 100,
  });

  final List<String> citations;
  final List<String> flags;
  final int score;

  bool get needsOversight => flags.isNotEmpty || score < 70;
}

class OversightCase {
  const OversightCase({
    required this.id,
    required this.uid,
    required this.prompt,
    required this.reply,
    required this.flags,
    required this.status,
    required this.createdAt,
    this.citations = const [],
  });

  final String id;
  final String uid;
  final String prompt;
  final String reply;
  final List<String> flags;
  final String status;
  final DateTime createdAt;
  final List<String> citations;
}

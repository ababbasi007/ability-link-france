import '../models/ai_safety.dart';
import '../models/place.dart';

class AiSafetyService {
  SafetyScan scan({
    required String reply,
    required List<AccessiblePlace> places,
  }) {
    final text = reply.toLowerCase();
    final flags = <String>[];
    final citations = <String>[
      for (final p in places)
        if (text.contains(p.name.toLowerCase())) p.name,
    ];

    const ableist = [
      'wheelchair-bound',
      'confined to a wheelchair',
      'suffers from',
      'cripple',
      'retard',
      'vegetable',
      'invalid person',
    ];
    for (final w in ableist) {
      if (text.contains(w)) flags.add('bias:$w');
    }

    const medical = [
      'you have cancer',
      'i diagnose',
      'you are diagnosed',
      'stop your medication',
      'prescribed dose',
    ];
    for (final w in medical) {
      if (text.contains(w)) flags.add('medical:$w');
    }

    final looksLikePlaceAdvice =
        text.contains('go to') ||
        text.contains('visit ') ||
        text.contains('restaurant') ||
        text.contains('hospital');
    if (looksLikePlaceAdvice && citations.isEmpty && places.isNotEmpty) {
      flags.add('hallucination:no-cited-place');
    }

    var score = 100 - (flags.length * 18);
    if (citations.isNotEmpty) score += 5;
    score = score.clamp(0, 100);

    return SafetyScan(
      citations: citations.take(6).toList(),
      flags: flags,
      score: score,
    );
  }
}

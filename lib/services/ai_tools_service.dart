import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';

import '../models/place.dart';
import '../models/user_profile.dart';
import 'ai_recommendations_service.dart';
import 'location_service.dart';
import 'places_service.dart';

enum AiToolKind {
  placeSummary,
  plainLanguage,
  translate,
  checklist,
  ocr,
  scorePrediction,
  recommendations,
  routePlan,
}

class AiToolResult {
  const AiToolResult({
    required this.title,
    required this.text,
    required this.usedLiveModel,
    this.predictedScore,
  });

  final String title;
  final String text;
  final bool usedLiveModel;

  /// Present when [AiToolKind.scorePrediction] succeeds.
  final AiAccessibilityScorePrediction? predictedScore;
}

/// Structured AI (or heuristic) accessibility score for a place.
class AiAccessibilityScorePrediction {
  const AiAccessibilityScorePrediction({
    required this.score,
    required this.confidence,
    required this.summary,
    this.breakdown = const {},
    this.gaps = const [],
    this.usedLiveModel = false,
  });

  /// Predicted accessibility score 0–100.
  final int score;

  /// Model/heuristic confidence 0–1.
  final double confidence;

  final String summary;
  final Map<String, int> breakdown;
  final List<String> gaps;
  final bool usedLiveModel;

  String get confidenceLabel {
    if (confidence >= 0.75) return 'High confidence';
    if (confidence >= 0.45) return 'Medium confidence';
    return 'Low confidence';
  }

  String get formattedText {
    final buf = StringBuffer()
      ..writeln('Predicted accessibility score: $score / 100')
      ..writeln(confidenceLabel)
      ..writeln()
      ..writeln(summary);
    if (breakdown.isNotEmpty) {
      buf.writeln();
      buf.writeln('Breakdown:');
      for (final e in breakdown.entries) {
        buf.writeln('· ${e.key}: ${e.value}');
      }
    }
    if (gaps.isNotEmpty) {
      buf.writeln();
      buf.writeln('Gaps to verify:');
      for (final g in gaps) {
        buf.writeln('· $g');
      }
    }
    return buf.toString().trim();
  }

  factory AiAccessibilityScorePrediction.fromJson(
    Map<String, dynamic> json, {
    bool usedLiveModel = true,
  }) {
    final rawBreakdown = json['breakdown'];
    final breakdown = <String, int>{};
    if (rawBreakdown is Map) {
      for (final e in rawBreakdown.entries) {
        final v = e.value;
        if (v is num) breakdown['${e.key}'] = v.round().clamp(0, 100);
      }
    }
    final rawGaps = json['gaps'];
    final gaps = <String>[];
    if (rawGaps is List) {
      for (final g in rawGaps) {
        if (g is String && g.trim().isNotEmpty) gaps.add(g.trim());
      }
    }
    return AiAccessibilityScorePrediction(
      score: ((json['score'] as num?)?.round() ?? 0).clamp(0, 100),
      confidence: ((json['confidence'] as num?)?.toDouble() ?? 0.5).clamp(
        0.0,
        1.0,
      ),
      summary: (json['summary'] as String?)?.trim().isNotEmpty == true
          ? (json['summary'] as String).trim()
          : 'Predicted from available place data.',
      breakdown: breakdown,
      gaps: gaps,
      usedLiveModel: usedLiveModel,
    );
  }
}

/// Step 6 accessibility utilities on top of Gemini + local fallbacks.
class AiToolsService {
  AiToolsService({PlacesService? places, LocationService? location})
    : _placesOverride = places,
      _locationOverride = location;

  PlacesService? _placesOverride;
  LocationService? _locationOverride;

  PlacesService get _places => _placesOverride ??= PlacesService();
  LocationService get _location =>
      _locationOverride ??= LocationService.instance;

  Future<String?> _geminiText(String prompt) async {
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.0-flash',
        generationConfig: GenerationConfig(
          temperature: 0.4,
          maxOutputTokens: 900,
        ),
      );
      final res = await model.generateContent([Content.text(prompt)]);
      final text = res.text?.trim();
      if (text == null || text.isEmpty) return null;
      return text;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _geminiJson(String prompt) async {
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.0-flash',
        generationConfig: GenerationConfig(
          temperature: 0.2,
          maxOutputTokens: 700,
          responseMimeType: 'application/json',
        ),
      );
      final res = await model.generateContent([Content.text(prompt)]);
      final text = res.text?.trim();
      if (text == null || text.isEmpty) return null;
      return text;
    } catch (_) {
      // Some builds reject responseMimeType — retry as plain text JSON.
      return _geminiText(
        '$prompt\n\nRespond with JSON only. No markdown fences.',
      );
    }
  }

  Future<String?> _geminiVision({
    required String prompt,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.0-flash',
        generationConfig: GenerationConfig(
          temperature: 0.2,
          maxOutputTokens: 900,
        ),
      );
      final res = await model.generateContent([
        Content.multi([TextPart(prompt), InlineDataPart(mimeType, bytes)]),
      ]);
      final text = res.text?.trim();
      if (text == null || text.isEmpty) return null;
      return text;
    } catch (_) {
      return null;
    }
  }

  Future<List<AccessiblePlace>> _placesNear() async {
    try {
      await _places.ensureSeeded();
      final all = await _places.watchPlaces().first;
      final o = _location.current;
      return _places.search(
        all,
        sort: PlaceSort.distance,
        originLat: o.lat,
        originLng: o.lng,
      );
    } catch (_) {
      return const [];
    }
  }

  Future<AiToolResult> summarizePlace(
    AccessiblePlace place, {
    UserProfile? profile,
  }) async {
    final prompt =
        '''
Summarize this place for an accessibility app user.
Focus on access features, supported needs, open status, and practical tips.
Keep it under 120 words. Plain language.

Place:
name=${place.name}
category=${place.categoryLabel}
address=${place.address}
score=${place.score}
rating=${place.rating}
openNow=${place.openNow}
verified=${place.verified}
features=${place.features.join(', ')}
needs=${place.needs.join(', ')}
description=${place.description}

User needs: ${profile?.accessibilityProfiles.join(', ') ?? 'general'}
Mobility aid: ${profile?.mobilityAid ?? 'n/a'}
Preferred language: ${profile?.preferredLanguage ?? 'English'}
''';

    final live = await _geminiText(prompt);
    if (live != null) {
      return AiToolResult(
        title: 'Place summary · ${place.name}',
        text: live,
        usedLiveModel: true,
      );
    }

    final o = _location.current;
    final text = StringBuffer()
      ..writeln('${place.name} (${place.categoryLabel})')
      ..writeln(place.address)
      ..writeln(
        '${place.distanceLabel(o.lat, o.lng)} away · score ${place.score} · '
        '${place.openNow ? 'Open now' : 'Closed'}'
        '${place.verified ? ' · Verified' : ''}',
      )
      ..writeln()
      ..writeln(
        place.description.isEmpty
            ? 'No long description yet.'
            : place.description,
      )
      ..writeln()
      ..writeln(
        'Features: ${place.features.isEmpty ? 'n/a' : place.features.join(', ')}',
      )
      ..writeln(
        'Supports: ${place.needs.isEmpty ? 'n/a' : place.needs.join(', ')}',
      );

    if (profile?.mobilityAid.isNotEmpty == true) {
      text.writeln(
        '\nFor your ${profile!.mobilityAid}: check step-free entrance and '
        '${place.features.contains('elevator') ? 'elevator access looks available.' : 'elevator availability on arrival.'}',
      );
    }

    return AiToolResult(
      title: 'Place summary · ${place.name}',
      text: text.toString().trim(),
      usedLiveModel: false,
    );
  }

  Future<AiToolResult> summarizeNearestPlace({UserProfile? profile}) async {
    final places = await _placesNear();
    if (places.isEmpty) {
      return const AiToolResult(
        title: 'Place summary',
        text: 'No places found yet. Open Ability Map and try again.',
        usedLiveModel: false,
      );
    }
    return summarizePlace(places.first, profile: profile);
  }

  /// Predicts an accessibility score (0–100) from place metadata / audit tags.
  ///
  /// Used for unrated or sparsely audited venues. Prefer Gemini when available;
  /// otherwise a transparent local heuristic.
  Future<AiToolResult> predictAccessibilityScore(
    AccessiblePlace place, {
    UserProfile? profile,
  }) async {
    final prediction = await scorePlace(place, profile: profile);
    return AiToolResult(
      title: 'AI score · ${place.name}',
      text: prediction.formattedText,
      usedLiveModel: prediction.usedLiveModel,
      predictedScore: prediction,
    );
  }

  Future<AiToolResult> predictNearestAccessibilityScore({
    UserProfile? profile,
  }) async {
    final places = await _placesNear();
    if (places.isEmpty) {
      return const AiToolResult(
        title: 'AI accessibility score',
        text: 'No places found yet. Open Ability Map and try again.',
        usedLiveModel: false,
      );
    }
    // Prefer an unrated / low-score place when available.
    AccessiblePlace target = places.first;
    for (final p in places.take(12)) {
      if (p.score <= 0 || p.score < 40) {
        target = p;
        break;
      }
    }
    return predictAccessibilityScore(target, profile: profile);
  }

  Future<AiToolResult> personalizedRecommendations({
    UserProfile? profile,
  }) async {
    final pack = await AiRecommendationsService(
      places: _placesOverride,
      location: _locationOverride,
    ).recommend(profile: profile);
    return AiToolResult(
      title: 'Recommendations for you',
      text: pack.formattedText,
      usedLiveModel: pack.usedLiveModel,
    );
  }

  Future<AiToolResult> planAccessibleRoute({
    required String query,
    UserProfile? profile,
  }) async {
    final pack = await AiRecommendationsService(
      places: _placesOverride,
      location: _locationOverride,
    ).planAccessibleRoute(query: query, profile: profile);
    return AiToolResult(
      title: 'Accessible route plan',
      text: pack.formattedText,
      usedLiveModel: pack.usedLiveModel,
    );
  }

  Future<AiAccessibilityScorePrediction> scorePlace(
    AccessiblePlace place, {
    UserProfile? profile,
  }) async {
    final prompt =
        '''
You are an accessibility scoring assistant for Ability Link.
Predict an accessibility score from 0 to 100 for this place using ONLY the
structured data provided. Do not invent photos or audits that are not listed.

Scoring guidance:
- 90–100: excellent step-free access, toilet, parking/elevator as relevant, verified signals
- 70–89: solid core access with a few gaps
- 40–69: partial access; important barriers likely
- 1–39: major barriers or almost no access data
- 0: insufficient data to score

Return JSON with this exact shape:
{
  "score": <int 0-100>,
  "confidence": <number 0-1>,
  "summary": "<2-3 plain sentences>",
  "breakdown": {
    "entrance": <int 0-100>,
    "interior": <int 0-100>,
    "restroom": <int 0-100>,
    "parking_transit": <int 0-100>,
    "sensory_communication": <int 0-100>
  },
  "gaps": ["<what to verify on-site>", "..."]
}

Place data:
name=${place.name}
category=${place.categoryLabel}
address=${place.address}
existingScore=${place.score}
lastAuditScore=${place.lastAuditScore}
rating=${place.rating}
reviewCount=${place.reviewCount}
openNow=${place.openNow}
verified=${place.verified}
governmentCertified=${place.governmentCertified}
features=${place.features.join(', ')}
needs=${place.needs.join(', ')}
description=${place.description}
photoCount=${place.labeledPhotos.length}
hours=${place.hours}
phone=${place.phone}

User context (personalize gaps only, do not overfit the score):
profiles=${profile?.accessibilityProfiles.join(', ') ?? 'general'}
mobilityAid=${profile?.mobilityAid ?? 'n/a'}
''';

    final live = await _geminiJson(prompt);
    if (live != null) {
      final parsed = _parseScoreJson(live);
      if (parsed != null) return parsed;
    }

    return heuristicScore(place, profile: profile);
  }

  AiAccessibilityScorePrediction? _parseScoreJson(String raw) {
    try {
      var text = raw.trim();
      if (text.startsWith('```')) {
        text = text
            .replaceFirst(RegExp(r'^```(?:json)?\s*', multiLine: false), '')
            .replaceFirst(RegExp(r'\s*```$'), '')
            .trim();
      }
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start < 0 || end <= start) return null;
      final map = jsonDecode(text.substring(start, end + 1));
      if (map is! Map) return null;
      return AiAccessibilityScorePrediction.fromJson(
        Map<String, dynamic>.from(map),
        usedLiveModel: true,
      );
    } catch (_) {
      return null;
    }
  }

  /// Transparent local fallback when Gemini is unavailable.
  AiAccessibilityScorePrediction heuristicScore(
    AccessiblePlace place, {
    UserProfile? profile,
  }) {
    final features = place.features.toSet();

    int entrance = 35;
    if (features.contains(PlaceAmenities.stepFree) ||
        features.contains(PlaceAmenities.ramp)) {
      entrance += 35;
    }
    if (features.contains(PlaceAmenities.elevator)) entrance += 15;
    if (features.contains(PlaceAmenities.dropOff)) entrance += 5;
    entrance = entrance.clamp(0, 100);

    int interior = 30;
    if (features.contains(PlaceAmenities.elevator)) interior += 20;
    if (features.contains(PlaceAmenities.receptionDesk)) interior += 15;
    if (features.contains(PlaceAmenities.calmWaitingRoom)) interior += 15;
    if (features.contains(PlaceAmenities.serviceAnimal)) interior += 10;
    interior = interior.clamp(0, 100);

    int restroom = features.contains(PlaceAmenities.toilet) ? 85 : 25;

    int parkingTransit = 30;
    if (features.contains(PlaceAmenities.parking)) parkingTransit += 35;
    if (features.contains(PlaceAmenities.accessibleTransit)) {
      parkingTransit += 25;
    }
    parkingTransit = parkingTransit.clamp(0, 100);

    int sensory = 30;
    if (features.contains(PlaceAmenities.hearing) ||
        features.contains(PlaceAmenities.signLanguage)) {
      sensory += 25;
    }
    if (features.contains(PlaceAmenities.braille) ||
        features.contains(PlaceAmenities.visual)) {
      sensory += 20;
    }
    if (features.contains(PlaceAmenities.quiet) ||
        features.contains(PlaceAmenities.captions)) {
      sensory += 15;
    }
    sensory = sensory.clamp(0, 100);

    var score =
        ((entrance * 0.3) +
                (interior * 0.2) +
                (restroom * 0.2) +
                (parkingTransit * 0.15) +
                (sensory * 0.15))
            .round();

    if (place.verified) score += 4;
    if (place.governmentCertified) score += 4;
    if (place.lastAuditScore > 0) {
      score = ((score * 0.45) + (place.lastAuditScore * 0.55)).round();
    } else if (place.score > 0) {
      score = ((score * 0.55) + (place.score * 0.45)).round();
    }
    score = score.clamp(0, 100);

    final knownSignals = features.length + place.needs.length;
    final confidence =
        (0.25 + (knownSignals * 0.06) + (place.verified ? 0.1 : 0))
            .clamp(0.2, 0.85);

    final gaps = <String>[];
    if (!features.contains(PlaceAmenities.stepFree) &&
        !features.contains(PlaceAmenities.ramp)) {
      gaps.add('Confirm step-free / ramp entrance on arrival');
    }
    if (!features.contains(PlaceAmenities.toilet)) {
      gaps.add('Check for an accessible toilet');
    }
    if (!features.contains(PlaceAmenities.elevator) &&
        place.category.toLowerCase().contains('hospital')) {
      gaps.add('Verify elevator access between floors');
    }
    if (profile?.mobilityAid.toLowerCase().contains('wheelchair') == true &&
        !features.contains(PlaceAmenities.parking)) {
      gaps.add('Look for accessible parking or drop-off');
    }
    if (gaps.isEmpty) {
      gaps.add('Spot-check door width and staff assistance if needed');
    }

    final summary = StringBuffer()
      ..write(
        place.score <= 0
            ? 'No published score yet — estimate from listed access features. '
            : 'Cross-checked listed features against the published score. ',
      )
      ..write(
        score >= 85
            ? 'Looks strongly accessible from available data.'
            : score >= 70
            ? 'Looks mostly accessible, with a few items to confirm.'
            : score >= 40
            ? 'Partial access signals — verify key barriers before relying on it.'
            : 'Limited access data or likely barriers; treat this as a rough estimate.',
      );

    return AiAccessibilityScorePrediction(
      score: score,
      confidence: confidence.toDouble(),
      summary: summary.toString(),
      breakdown: {
        'entrance': entrance,
        'interior': interior,
        'restroom': restroom,
        'parking_transit': parkingTransit,
        'sensory_communication': sensory,
      },
      gaps: gaps,
      usedLiveModel: false,
    );
  }

  Future<AiToolResult> toPlainLanguage(
    String input, {
    UserProfile? profile,
  }) async {
    final source = input.trim();
    if (source.isEmpty) {
      return const AiToolResult(
        title: 'Plain language',
        text: 'Paste or type text to simplify.',
        usedLiveModel: false,
      );
    }

    final prompt =
        '''
Rewrite the following into plain language for accessibility.
- Short sentences
- Common words
- Keep meaning accurate
- Language: ${profile?.preferredLanguage ?? 'English'}

TEXT:
$source
''';
    final live = await _geminiText(prompt);
    if (live != null) {
      return AiToolResult(
        title: 'Plain language',
        text: live,
        usedLiveModel: true,
      );
    }

    // Simple local cleanup.
    var t = source
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('utilize', 'use')
        .replaceAll('commence', 'start')
        .replaceAll('terminate', 'end')
        .replaceAll('approximately', 'about')
        .replaceAll('individuals', 'people')
        .replaceAll('facilitate', 'help');
    if (!t.endsWith('.') && !t.endsWith('!') && !t.endsWith('?')) {
      t = '$t.';
    }
    return AiToolResult(
      title: 'Plain language',
      text: 'Simplified draft:\n\n$t',
      usedLiveModel: false,
    );
  }

  Future<AiToolResult> translate(
    String input, {
    required String targetLanguage,
    UserProfile? profile,
  }) async {
    final source = input.trim();
    if (source.isEmpty) {
      return const AiToolResult(
        title: 'Translation',
        text: 'Enter text to translate.',
        usedLiveModel: false,
      );
    }

    final prompt =
        '''
Translate the text into $targetLanguage.
Keep accessibility meaning clear. Return only the translation.

TEXT:
$source
''';
    final live = await _geminiText(prompt);
    if (live != null) {
      return AiToolResult(
        title: 'Translation · $targetLanguage',
        text: live,
        usedLiveModel: true,
      );
    }

    return AiToolResult(
      title: 'Translation · $targetLanguage',
      text:
          'Live translation needs Gemini enabled in Firebase AI Logic.\n\n'
          'Your text:\n$source\n\n'
          'Tip: set Preferred Language in your Passport to $targetLanguage for assistant replies.',
      usedLiveModel: false,
    );
  }

  Future<AiToolResult> generateChecklist({
    required String situation,
    UserProfile? profile,
  }) async {
    final topic = situation.trim().isEmpty
        ? 'everyday accessible outing'
        : situation.trim();

    final prompt =
        '''
Create a short accessibility checklist for: "$topic".
Personalize for:
profiles=${profile?.accessibilityProfiles.join(', ') ?? 'general'}
mobilityAid=${profile?.mobilityAid ?? 'n/a'}
language=${profile?.preferredLanguage ?? 'English'}
caregiver=${profile?.needCaregiver == true ? 'yes' : 'no'}

Return 6-10 checkbox-style lines starting with "- [ ]".
''';

    final live = await _geminiText(prompt);
    if (live != null) {
      return AiToolResult(
        title: 'Checklist · $topic',
        text: live,
        usedLiveModel: true,
      );
    }

    final aid = profile?.mobilityAid;
    final lines = <String>[
      '- [ ] Confirm step-free entrance / ramp',
      '- [ ] Check accessible toilet availability',
      if (aid != null && aid.isNotEmpty) '- [ ] Confirm space for $aid',
      '- [ ] Save emergency contact on phone',
      '- [ ] Share live location with caregiver if needed',
      '- [ ] Pack medications / assistive devices',
      '- [ ] Plan quieter travel times if sensory needs',
      '- [ ] Screenshot map / place details for offline use',
      '- [ ] Confirm open hours before leaving',
    ];

    return AiToolResult(
      title: 'Checklist · $topic',
      text: 'Accessibility checklist for $topic:\n\n${lines.join('\n')}',
      usedLiveModel: false,
    );
  }

  Future<AiToolResult> ocrImage({
    required Uint8List bytes,
    required String mimeType,
    UserProfile? profile,
  }) async {
    final prompt =
        '''
You are an accessibility OCR tool.
1) Extract all readable text from the image.
2) Then rewrite it in plain language.
Language: ${profile?.preferredLanguage ?? 'English'}
Format:
Extracted text:
...
Plain language:
...
''';

    final live = await _geminiVision(
      prompt: prompt,
      bytes: bytes,
      mimeType: mimeType,
    );
    if (live != null) {
      return AiToolResult(
        title: 'OCR + plain language',
        text: live,
        usedLiveModel: true,
      );
    }

    return const AiToolResult(
      title: 'OCR + plain language',
      text:
          'Could not read this image with Gemini yet.\n\n'
          'Enable Firebase AI Logic for OCR, or paste the text into Plain Language tool.',
      usedLiveModel: false,
    );
  }
}

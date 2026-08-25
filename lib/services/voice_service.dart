import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Text-to-speech and speech-to-text helpers for accessibility.
class VoiceService {
  VoiceService._();
  static final VoiceService instance = VoiceService._();

  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();

  bool _ttsReady = false;
  bool _sttReady = false;
  bool get isListening => _stt.isListening;
  bool get speechAvailable => _sttReady;

  Future<void> _ensureTts() async {
    if (_ttsReady) return;
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _ttsReady = true;
  }

  Future<bool> _ensureStt() async {
    if (_sttReady) return true;
    _sttReady = await _stt.initialize(onError: (_) {}, onStatus: (_) {});
    return _sttReady;
  }

  Future<void> speak(String text, {String? languageCode}) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;
    await _ensureTts();
    await stopSpeaking();
    if (languageCode != null && languageCode.isNotEmpty) {
      await _tts.setLanguage(languageCode);
    } else {
      await _tts.setLanguage('en-US');
    }
    await _tts.speak(cleaned);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  /// Starts listening and returns the final recognized phrase (or null).
  Future<String?> listenOnce({
    Duration listenFor = const Duration(seconds: 12),
    String localeId = 'en_US',
  }) async {
    final ok = await _ensureStt();
    if (!ok) return null;

    String? result;
    await _stt.listen(
      onResult: (value) {
        if (value.finalResult) {
          result = value.recognizedWords;
        } else if (value.recognizedWords.trim().isNotEmpty) {
          result = value.recognizedWords;
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenFor: listenFor,
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
      ),
    );

    // Wait until listening stops or timeout.
    final deadline = DateTime.now().add(listenFor + const Duration(seconds: 2));
    while (_stt.isListening && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    if (_stt.isListening) await _stt.stop();
    final text = result?.trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  Future<void> stopListening() async {
    if (_stt.isListening) await _stt.stop();
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Circular mint tile + forest-green glyph matching the Ability Link home mock.
class HomeServiceGlyph extends StatelessWidget {
  const HomeServiceGlyph({
    super.key,
    required this.kind,
    this.size = 52,
  });

  final String kind;
  final double size;

  static const _mint = Color(0xFFE8F5EE);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: _mint,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: CustomPaint(
        size: Size.square(size * 0.52),
        painter: _GlyphPainter(kind: kind, color: AppColors.primary),
      ),
    );
  }
}

class HomeQuickGlyph extends StatelessWidget {
  const HomeQuickGlyph({super.key, required this.kind, this.size = 28});

  final String kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _GlyphPainter(kind: kind, color: AppColors.primary),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter({required this.kind, required this.color});

  final String kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final s = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (kind) {
      case 'health':
        _heartBeat(canvas, size, p, s);
      case 'rehab':
        _runner(canvas, size, p, s);
      case 'tourism':
        _suitcase(canvas, size, p, s);
      case 'education':
        _cap(canvas, size, p);
      case 'jobs':
        _briefcase(canvas, size, p);
      case 'services':
        _handPeople(canvas, size, p);
      case 'community':
        _people(canvas, size, p);
      case 'transport':
        _bus(canvas, size, p);
      case 'caregiver':
        _handsHeart(canvas, size, p, s);
      case 'tech':
        _ear(canvas, size, s, p);
      case 'benefits':
        _clipboard(canvas, size, p, s);
      case 'legal':
        _scales(canvas, size, p, s);
      case 'passport':
        _idCard(canvas, size, p, s);
      case 'bookings':
        _calendarCheck(canvas, size, p, s);
      case 'messages':
        _chat(canvas, size, p);
      case 'saved':
        _handsHeart(canvas, size, p, s);
      default:
        canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          size.width * 0.2,
          p,
        );
    }
  }

  void _heartBeat(Canvas canvas, Size s, Paint p, Paint stroke) {
    final heart = Path()
      ..moveTo(s.width * 0.5, s.height * 0.82)
      ..cubicTo(
        s.width * 0.05,
        s.height * 0.5,
        s.width * 0.12,
        s.height * 0.05,
        s.width * 0.5,
        s.height * 0.28,
      )
      ..cubicTo(
        s.width * 0.88,
        s.height * 0.05,
        s.width * 0.95,
        s.height * 0.5,
        s.width * 0.5,
        s.height * 0.82,
      )
      ..close();
    canvas.drawPath(heart, p);
    final beat = Path()
      ..moveTo(s.width * 0.22, s.height * 0.48)
      ..lineTo(s.width * 0.38, s.height * 0.48)
      ..lineTo(s.width * 0.45, s.height * 0.32)
      ..lineTo(s.width * 0.55, s.height * 0.62)
      ..lineTo(s.width * 0.62, s.height * 0.48)
      ..lineTo(s.width * 0.78, s.height * 0.48);
    canvas.drawPath(
      beat,
      stroke
        ..color = Colors.white
        ..strokeWidth = s.width * 0.09,
    );
  }

  void _runner(Canvas canvas, Size s, Paint p, Paint stroke) {
    canvas.drawCircle(Offset(s.width * 0.58, s.height * 0.18), s.width * 0.12, p);
    final body = Path()
      ..moveTo(s.width * 0.55, s.height * 0.28)
      ..lineTo(s.width * 0.42, s.height * 0.52)
      ..moveTo(s.width * 0.5, s.height * 0.36)
      ..lineTo(s.width * 0.78, s.height * 0.28)
      ..moveTo(s.width * 0.5, s.height * 0.36)
      ..lineTo(s.width * 0.28, s.height * 0.46)
      ..moveTo(s.width * 0.42, s.height * 0.52)
      ..lineTo(s.width * 0.7, s.height * 0.72)
      ..moveTo(s.width * 0.42, s.height * 0.52)
      ..lineTo(s.width * 0.22, s.height * 0.86);
    canvas.drawPath(body, stroke..strokeWidth = s.width * 0.11);
  }

  void _suitcase(Canvas canvas, Size s, Paint p, Paint stroke) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.14, s.height * 0.34, s.width * 0.72, s.height * 0.52),
        Radius.circular(s.width * 0.08),
      ),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.34, s.height * 0.14, s.width * 0.32, s.height * 0.22),
        Radius.circular(s.width * 0.05),
      ),
      stroke..strokeWidth = s.width * 0.1,
    );
  }

  void _cap(Canvas canvas, Size s, Paint p) {
    final cap = Path()
      ..moveTo(s.width * 0.08, s.height * 0.42)
      ..lineTo(s.width * 0.5, s.height * 0.18)
      ..lineTo(s.width * 0.92, s.height * 0.42)
      ..lineTo(s.width * 0.5, s.height * 0.62)
      ..close();
    canvas.drawPath(cap, p);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s.width * 0.5, s.height * 0.7),
        width: s.width * 0.62,
        height: s.height * 0.18,
      ),
      p,
    );
  }

  void _briefcase(Canvas canvas, Size s, Paint p) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.1, s.height * 0.34, s.width * 0.8, s.height * 0.52),
        Radius.circular(s.width * 0.1),
      ),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.34, s.height * 0.14, s.width * 0.32, s.height * 0.22),
        Radius.circular(s.width * 0.06),
      ),
      p,
    );
  }

  void _handPeople(Canvas canvas, Size s, Paint p) {
    canvas.drawCircle(Offset(s.width * 0.35, s.height * 0.22), s.width * 0.1, p);
    canvas.drawCircle(Offset(s.width * 0.55, s.height * 0.18), s.width * 0.1, p);
    canvas.drawCircle(Offset(s.width * 0.72, s.height * 0.24), s.width * 0.09, p);
    final palm = Path()
      ..moveTo(s.width * 0.12, s.height * 0.92)
      ..quadraticBezierTo(s.width * 0.1, s.height * 0.55, s.width * 0.42, s.height * 0.48)
      ..lineTo(s.width * 0.88, s.height * 0.58)
      ..quadraticBezierTo(s.width * 0.95, s.height * 0.72, s.width * 0.82, s.height * 0.92)
      ..close();
    canvas.drawPath(palm, p);
  }

  void _people(Canvas canvas, Size s, Paint p) {
    canvas.drawCircle(Offset(s.width * 0.5, s.height * 0.2), s.width * 0.12, p);
    canvas.drawCircle(Offset(s.width * 0.22, s.height * 0.28), s.width * 0.1, p);
    canvas.drawCircle(Offset(s.width * 0.78, s.height * 0.28), s.width * 0.1, p);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s.width * 0.5, s.height * 0.7),
        width: s.width * 0.4,
        height: s.height * 0.48,
      ),
      p,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s.width * 0.22, s.height * 0.76),
        width: s.width * 0.3,
        height: s.height * 0.4,
      ),
      p,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s.width * 0.78, s.height * 0.76),
        width: s.width * 0.3,
        height: s.height * 0.4,
      ),
      p,
    );
  }

  void _bus(Canvas canvas, Size s, Paint p) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.12, s.height * 0.18, s.width * 0.76, s.height * 0.58),
        Radius.circular(s.width * 0.12),
      ),
      p,
    );
    final w = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.22, s.height * 0.28, s.width * 0.24, s.height * 0.18),
        Radius.circular(s.width * 0.04),
      ),
      w,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.54, s.height * 0.28, s.width * 0.24, s.height * 0.18),
        Radius.circular(s.width * 0.04),
      ),
      w,
    );
    canvas.drawCircle(Offset(s.width * 0.3, s.height * 0.86), s.width * 0.1, p);
    canvas.drawCircle(Offset(s.width * 0.7, s.height * 0.86), s.width * 0.1, p);
  }

  void _handsHeart(Canvas canvas, Size s, Paint p, Paint stroke) {
    final heart = Path()
      ..moveTo(s.width * 0.5, s.height * 0.55)
      ..cubicTo(
        s.width * 0.15,
        s.height * 0.32,
        s.width * 0.2,
        s.height * 0.05,
        s.width * 0.5,
        s.height * 0.2,
      )
      ..cubicTo(
        s.width * 0.8,
        s.height * 0.05,
        s.width * 0.85,
        s.height * 0.32,
        s.width * 0.5,
        s.height * 0.55,
      )
      ..close();
    canvas.drawPath(heart, p);
    final hands = Path()
      ..moveTo(s.width * 0.1, s.height * 0.92)
      ..quadraticBezierTo(s.width * 0.12, s.height * 0.62, s.width * 0.4, s.height * 0.58)
      ..lineTo(s.width * 0.5, s.height * 0.68)
      ..lineTo(s.width * 0.6, s.height * 0.58)
      ..quadraticBezierTo(s.width * 0.88, s.height * 0.62, s.width * 0.9, s.height * 0.92)
      ..close();
    canvas.drawPath(hands, p);
  }

  void _ear(Canvas canvas, Size s, Paint stroke, Paint p) {
    canvas.drawArc(
      Rect.fromLTWH(s.width * 0.22, s.height * 0.12, s.width * 0.56, s.height * 0.76),
      -1.2,
      2.4,
      false,
      stroke..strokeWidth = s.width * 0.12,
    );
    canvas.drawArc(
      Rect.fromLTWH(s.width * 0.38, s.height * 0.28, s.width * 0.28, s.height * 0.4),
      -1.0,
      2.0,
      false,
      stroke..strokeWidth = s.width * 0.09,
    );
    canvas.drawCircle(Offset(s.width * 0.72, s.height * 0.72), s.width * 0.1, p);
  }

  void _clipboard(Canvas canvas, Size s, Paint p, Paint stroke) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.18, s.height * 0.18, s.width * 0.64, s.height * 0.72),
        Radius.circular(s.width * 0.08),
      ),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.32, s.height * 0.08, s.width * 0.36, s.height * 0.16),
        Radius.circular(s.width * 0.04),
      ),
      p,
    );
    final check = Path()
      ..moveTo(s.width * 0.34, s.height * 0.52)
      ..lineTo(s.width * 0.46, s.height * 0.64)
      ..lineTo(s.width * 0.68, s.height * 0.38);
    canvas.drawPath(
      check,
      stroke
        ..color = Colors.white
        ..strokeWidth = s.width * 0.1,
    );
  }

  void _scales(Canvas canvas, Size s, Paint p, Paint stroke) {
    canvas.drawLine(
      Offset(s.width * 0.5, s.height * 0.12),
      Offset(s.width * 0.5, s.height * 0.88),
      stroke..strokeWidth = s.width * 0.1,
    );
    canvas.drawLine(
      Offset(s.width * 0.18, s.height * 0.28),
      Offset(s.width * 0.82, s.height * 0.28),
      stroke..strokeWidth = s.width * 0.1,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s.width * 0.28, s.height * 0.58),
        width: s.width * 0.28,
        height: s.height * 0.22,
      ),
      stroke..strokeWidth = s.width * 0.08,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s.width * 0.72, s.height * 0.58),
        width: s.width * 0.28,
        height: s.height * 0.22,
      ),
      stroke..strokeWidth = s.width * 0.08,
    );
    canvas.drawRect(
      Rect.fromLTWH(s.width * 0.34, s.height * 0.84, s.width * 0.32, s.height * 0.08),
      p,
    );
  }

  void _idCard(Canvas canvas, Size s, Paint p, Paint stroke) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.08, s.height * 0.22, s.width * 0.84, s.height * 0.56),
        Radius.circular(s.width * 0.1),
      ),
      stroke..strokeWidth = s.width * 0.1,
    );
    canvas.drawCircle(Offset(s.width * 0.32, s.height * 0.42), s.width * 0.12, p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.5, s.height * 0.34, s.width * 0.32, s.height * 0.08),
        Radius.circular(s.width * 0.03),
      ),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.5, s.height * 0.48, s.width * 0.26, s.height * 0.06),
        Radius.circular(s.width * 0.03),
      ),
      p,
    );
  }

  void _calendarCheck(Canvas canvas, Size s, Paint p, Paint stroke) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.14, s.height * 0.18, s.width * 0.72, s.height * 0.68),
        Radius.circular(s.width * 0.1),
      ),
      stroke..strokeWidth = s.width * 0.1,
    );
    canvas.drawRect(
      Rect.fromLTWH(s.width * 0.14, s.height * 0.18, s.width * 0.72, s.height * 0.2),
      p,
    );
    canvas.drawCircle(Offset(s.width * 0.78, s.height * 0.78), s.width * 0.16, p);
    final check = Path()
      ..moveTo(s.width * 0.7, s.height * 0.78)
      ..lineTo(s.width * 0.76, s.height * 0.84)
      ..lineTo(s.width * 0.86, s.height * 0.72);
    canvas.drawPath(
      check,
      stroke
        ..color = Colors.white
        ..strokeWidth = s.width * 0.08,
    );
  }

  void _chat(Canvas canvas, Size s, Paint p) {
    final bubble = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(s.width * 0.12, s.height * 0.12, s.width * 0.76, s.height * 0.58),
          Radius.circular(s.width * 0.16),
        ),
      )
      ..moveTo(s.width * 0.28, s.height * 0.7)
      ..lineTo(s.width * 0.22, s.height * 0.9)
      ..lineTo(s.width * 0.46, s.height * 0.7);
    canvas.drawPath(bubble, p);
    final d = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(s.width * 0.35, s.height * 0.4), s.width * 0.06, d);
    canvas.drawCircle(Offset(s.width * 0.5, s.height * 0.4), s.width * 0.06, d);
    canvas.drawCircle(Offset(s.width * 0.65, s.height * 0.4), s.width * 0.06, d);
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}

/// Soft ripple rings behind the SOS button (mock).
class SosRipplePainter extends CustomPainter {
  const SosRipplePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final maxR = math.min(size.width, size.height) / 2;
    for (var i = 3; i >= 1; i--) {
      canvas.drawCircle(
        c,
        maxR * (0.55 + i * 0.14),
        Paint()
          ..color = color.withValues(alpha: 0.08 + (3 - i) * 0.04)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SosRipplePainter oldDelegate) =>
      oldDelegate.color != color;
}

import 'package:flutter/material.dart';

/// Illustrative service glyphs matching the Ability Link homepage mock.
class GridServiceIcon extends StatelessWidget {
  const GridServiceIcon({
    super.key,
    required this.kind,
    required this.color,
    this.size = 44,
  });

  final String kind;
  final Color color;
  final double size;

  static const _assets = {
    'map': 'assets/images/grid_icon_map.png',
    'rehab': 'assets/images/grid_icon_rehab.png',
    'tourism': 'assets/images/grid_icon_tourism.png',
    'education': 'assets/images/grid_icon_education.png',
    'tech': 'assets/images/grid_icon_ai.png',
    'health': 'assets/images/grid_icon_telehealth.png',
    'assist': 'assets/images/grid_icon_benefits.png',
    'benefits': 'assets/images/grid_icon_benefits.png',
    'caregiver': 'assets/images/grid_icon_caregiver.png',
  };

  @override
  Widget build(BuildContext context) {
    if (kind == 'legal') {
      return Icon(Icons.balance_rounded, size: size * 0.72, color: color);
    }
    final asset = _assets[kind];
    if (asset != null) {
      return Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => CustomPaint(
          size: Size.square(size),
          painter: _GridIconPainter(kind: kind, color: color),
        ),
      );
    }
    return CustomPaint(
      size: Size.square(size),
      painter: _GridIconPainter(kind: kind, color: color),
    );
  }
}

class _GridIconPainter extends CustomPainter {
  const _GridIconPainter({required this.kind, required this.color});

  final String kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (kind) {
      case 'map':
        _map(canvas, size, fill);
      case 'rehab':
        _rehab(canvas, size, fill);
      case 'tourism':
        _tourism(canvas, size, fill);
      case 'education':
        _education(canvas, size, fill);
      case 'tech':
        _headset(canvas, size, fill);
      case 'health':
        _heartHand(canvas, size, fill);
      case 'assist':
        _handshake(canvas, size, fill);
      case 'jobs':
        _briefcase(canvas, size, fill);
      case 'services':
        _calendar(canvas, size, fill);
      case 'community':
        _people(canvas, size, fill);
      case 'transport':
        _bus(canvas, size, fill);
      case 'caregiver':
        _caregiver(canvas, size, fill);
      case 'legal':
        _legal(canvas, size, fill);
    }
  }

  Paint get _stroke => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.2
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _map(Canvas canvas, Size s, Paint p) {
    final pin = Path()
      ..moveTo(s.width * 0.5, s.height * 0.96)
      ..cubicTo(
        s.width * 0.08,
        s.height * 0.58,
        s.width * 0.08,
        s.height * 0.18,
        s.width * 0.5,
        s.height * 0.08,
      )
      ..cubicTo(
        s.width * 0.92,
        s.height * 0.18,
        s.width * 0.92,
        s.height * 0.58,
        s.width * 0.5,
        s.height * 0.96,
      )
      ..close();
    canvas.drawPath(pin, p);
    canvas.drawCircle(
      Offset(s.width * 0.5, s.height * 0.38),
      s.width * 0.16,
      Paint()..color = Colors.white,
    );
  }

  void _rehab(Canvas canvas, Size s, Paint p) {
    final screen = RRect.fromRectAndRadius(
      Rect.fromLTWH(s.width * 0.08, s.height * 0.08, s.width * 0.84, s.height * 0.58),
      Radius.circular(s.width * 0.1),
    );
    canvas.drawRRect(screen, _stroke..strokeWidth = s.width * 0.07);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.18, s.height * 0.72, s.width * 0.64, s.height * 0.1),
        Radius.circular(s.width * 0.04),
      ),
      p,
    );
    canvas.drawCircle(Offset(s.width * 0.5, s.height * 0.22), s.width * 0.07, p);
    final person = Path()
      ..moveTo(s.width * 0.5, s.height * 0.3)
      ..lineTo(s.width * 0.5, s.height * 0.46)
      ..moveTo(s.width * 0.5, s.height * 0.34)
      ..lineTo(s.width * 0.32, s.height * 0.42)
      ..moveTo(s.width * 0.5, s.height * 0.34)
      ..lineTo(s.width * 0.7, s.height * 0.28)
      ..moveTo(s.width * 0.5, s.height * 0.46)
      ..lineTo(s.width * 0.36, s.height * 0.58)
      ..moveTo(s.width * 0.5, s.height * 0.46)
      ..lineTo(s.width * 0.68, s.height * 0.58);
    canvas.drawPath(person, _stroke..strokeWidth = s.width * 0.065);
  }

  void _tourism(Canvas canvas, Size s, Paint p) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.08, s.height * 0.4, s.width * 0.58, s.height * 0.48),
        Radius.circular(s.width * 0.08),
      ),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.2, s.height * 0.26, s.width * 0.34, s.height * 0.16),
        Radius.circular(s.width * 0.05),
      ),
      p,
    );
    final trunk = Paint()
      ..color = color
      ..strokeWidth = s.width * 0.06
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(s.width * 0.82, s.height * 0.92),
      Offset(s.width * 0.82, s.height * 0.42),
      trunk,
    );
    final frond = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(s.width * 0.72, s.height * 0.38),
        width: s.width * 0.36,
        height: s.height * 0.32,
      ),
      3.4,
      2.2,
      false,
      frond,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(s.width * 0.9, s.height * 0.38),
        width: s.width * 0.28,
        height: s.height * 0.28,
      ),
      3.6,
      2.0,
      false,
      frond,
    );
  }

  void _education(Canvas canvas, Size s, Paint p) {
    final cap = Path()
      ..moveTo(s.width * 0.08, s.height * 0.4)
      ..lineTo(s.width * 0.5, s.height * 0.18)
      ..lineTo(s.width * 0.92, s.height * 0.4)
      ..lineTo(s.width * 0.5, s.height * 0.58)
      ..close();
    canvas.drawPath(cap, p);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s.width * 0.5, s.height * 0.62),
        width: s.width * 0.58,
        height: s.height * 0.16,
      ),
      p,
    );
    canvas.drawLine(
      Offset(s.width * 0.8, s.height * 0.4),
      Offset(s.width * 0.8, s.height * 0.78),
      Paint()
        ..color = color
        ..strokeWidth = s.width * 0.07
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(s.width * 0.8, s.height * 0.84), s.width * 0.07, p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.16, s.height * 0.72, s.width * 0.5, s.height * 0.1),
        Radius.circular(s.width * 0.03),
      ),
      p,
    );
  }

  void _headset(Canvas canvas, Size s, Paint p) {
    final stroke = _stroke..strokeWidth = s.width * 0.1;
    canvas.drawArc(
      Rect.fromLTWH(s.width * 0.14, s.height * 0.1, s.width * 0.72, s.height * 0.7),
      3.4,
      2.5,
      false,
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.08, s.height * 0.42, s.width * 0.22, s.height * 0.32),
        Radius.circular(s.width * 0.08),
      ),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.7, s.height * 0.42, s.width * 0.22, s.height * 0.32),
        Radius.circular(s.width * 0.08),
      ),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.38, s.height * 0.78, s.width * 0.24, s.height * 0.14),
        Radius.circular(s.width * 0.05),
      ),
      p,
    );
  }

  void _heartHand(Canvas canvas, Size s, Paint p) {
    final heart = Path()
      ..moveTo(s.width * 0.5, s.height * 0.58)
      ..cubicTo(
        s.width * 0.08,
        s.height * 0.28,
        s.width * 0.18,
        s.height * 0.0,
        s.width * 0.5,
        s.height * 0.18,
      )
      ..cubicTo(
        s.width * 0.82,
        s.height * 0.0,
        s.width * 0.92,
        s.height * 0.28,
        s.width * 0.5,
        s.height * 0.58,
      )
      ..close();
    canvas.drawPath(heart, p);
    final palm = Path()
      ..moveTo(s.width * 0.18, s.height * 0.92)
      ..quadraticBezierTo(s.width * 0.18, s.height * 0.62, s.width * 0.42, s.height * 0.6)
      ..lineTo(s.width * 0.78, s.height * 0.68)
      ..quadraticBezierTo(s.width * 0.9, s.height * 0.74, s.width * 0.82, s.height * 0.92)
      ..close();
    canvas.drawPath(palm, p);
  }

  void _handshake(Canvas canvas, Size s, Paint p) {
    canvas.drawCircle(Offset(s.width * 0.28, s.height * 0.22), s.width * 0.13, p);
    canvas.drawCircle(Offset(s.width * 0.72, s.height * 0.22), s.width * 0.13, p);
    final left = Path()
      ..moveTo(s.width * 0.08, s.height * 0.92)
      ..quadraticBezierTo(s.width * 0.08, s.height * 0.48, s.width * 0.36, s.height * 0.42)
      ..lineTo(s.width * 0.52, s.height * 0.58)
      ..lineTo(s.width * 0.4, s.height * 0.92)
      ..close();
    final right = Path()
      ..moveTo(s.width * 0.92, s.height * 0.92)
      ..quadraticBezierTo(s.width * 0.92, s.height * 0.48, s.width * 0.64, s.height * 0.42)
      ..lineTo(s.width * 0.48, s.height * 0.58)
      ..lineTo(s.width * 0.6, s.height * 0.92)
      ..close();
    canvas.drawPath(left, p);
    canvas.drawPath(right, p);
  }

  void _briefcase(Canvas canvas, Size s, Paint p) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.08, s.height * 0.34, s.width * 0.84, s.height * 0.54),
        Radius.circular(s.width * 0.1),
      ),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.32, s.height * 0.14, s.width * 0.36, s.height * 0.22),
        Radius.circular(s.width * 0.06),
      ),
      p,
    );
    canvas.drawRect(
      Rect.fromLTWH(s.width * 0.08, s.height * 0.52, s.width * 0.84, s.height * 0.08),
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );
  }

  void _calendar(Canvas canvas, Size s, Paint p) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.12, s.height * 0.18, s.width * 0.76, s.height * 0.72),
        Radius.circular(s.width * 0.1),
      ),
      p,
    );
    canvas.drawRect(
      Rect.fromLTWH(s.width * 0.12, s.height * 0.18, s.width * 0.76, s.height * 0.22),
      Paint()..color = color,
    );
    final white = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(s.width * 0.3, s.height * 0.16), s.width * 0.05, p);
    canvas.drawCircle(Offset(s.width * 0.7, s.height * 0.16), s.width * 0.05, p);
    for (var r = 0; r < 2; r++) {
      for (var c = 0; c < 3; c++) {
        canvas.drawCircle(
          Offset(s.width * (0.3 + c * 0.2), s.height * (0.56 + r * 0.18)),
          s.width * 0.045,
          white,
        );
      }
    }
  }

  void _people(Canvas canvas, Size s, Paint p) {
    canvas.drawCircle(Offset(s.width * 0.5, s.height * 0.18), s.width * 0.12, p);
    canvas.drawCircle(Offset(s.width * 0.22, s.height * 0.28), s.width * 0.1, p);
    canvas.drawCircle(Offset(s.width * 0.78, s.height * 0.28), s.width * 0.1, p);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s.width * 0.5, s.height * 0.72),
        width: s.width * 0.42,
        height: s.height * 0.48,
      ),
      p,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s.width * 0.22, s.height * 0.78),
        width: s.width * 0.32,
        height: s.height * 0.4,
      ),
      p,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s.width * 0.78, s.height * 0.78),
        width: s.width * 0.32,
        height: s.height * 0.4,
      ),
      p,
    );
  }

  void _bus(Canvas canvas, Size s, Paint p) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.1, s.height * 0.18, s.width * 0.8, s.height * 0.62),
        Radius.circular(s.width * 0.12),
      ),
      p,
    );
    final win = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.2, s.height * 0.28, s.width * 0.26, s.height * 0.2),
        Radius.circular(s.width * 0.04),
      ),
      win,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.54, s.height * 0.28, s.width * 0.26, s.height * 0.2),
        Radius.circular(s.width * 0.04),
      ),
      win,
    );
    canvas.drawCircle(Offset(s.width * 0.3, s.height * 0.88), s.width * 0.1, p);
    canvas.drawCircle(Offset(s.width * 0.7, s.height * 0.88), s.width * 0.1, p);
    canvas.drawCircle(Offset(s.width * 0.3, s.height * 0.88), s.width * 0.045, win);
    canvas.drawCircle(Offset(s.width * 0.7, s.height * 0.88), s.width * 0.045, win);
  }

  void _caregiver(Canvas canvas, Size s, Paint p) {
    canvas.drawCircle(Offset(s.width * 0.42, s.height * 0.22), s.width * 0.16, p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.14, s.height * 0.44, s.width * 0.56, s.height * 0.5),
        Radius.circular(s.width * 0.22),
      ),
      p,
    );
    canvas.drawCircle(Offset(s.width * 0.78, s.height * 0.78), s.width * 0.2, p);
    final plus = Paint()
      ..color = Colors.white
      ..strokeWidth = s.width * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(s.width * 0.78, s.height * 0.68),
      Offset(s.width * 0.78, s.height * 0.88),
      plus,
    );
    canvas.drawLine(
      Offset(s.width * 0.68, s.height * 0.78),
      Offset(s.width * 0.88, s.height * 0.78),
      plus,
    );
  }

  void _legal(Canvas canvas, Size s, Paint p) {
    final bar = Paint()
      ..color = color
      ..strokeWidth = s.width * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(s.width * 0.5, s.height * 0.12),
      Offset(s.width * 0.5, s.height * 0.88),
      bar,
    );
    canvas.drawLine(
      Offset(s.width * 0.18, s.height * 0.28),
      Offset(s.width * 0.82, s.height * 0.28),
      bar,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s.width * 0.32, s.height * 0.58),
        width: s.width * 0.28,
        height: s.height * 0.22,
      ),
      p,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s.width * 0.68, s.height * 0.58),
        width: s.width * 0.28,
        height: s.height * 0.22,
      ),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _GridIconPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}

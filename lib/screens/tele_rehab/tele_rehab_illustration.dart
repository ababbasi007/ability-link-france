import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Hand-drawn vector illustration matching the Tele-Rehab mockup.
/// Depicts a patient doing a resistance-band exercise in front of a laptop
/// showing a live video call with a therapist.
class TeleRehabIllustration extends StatelessWidget {
  const TeleRehabIllustration({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width ?? 320, height ?? 200),
      painter: _IllustrationPainter(),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  // ── palette ───────────────────────────────────────────────────────────
  static const _bg = Color(0xFFEAF6EF);
  static const _forest = Color(0xFF006D44);
  static const _mat = Color(0xFF3A9E7A);
  static const _matShadow = Color(0xFF2D7D60);
  static const _skin = Color(0xFFF5CBA7);
  static const _skinDark = Color(0xFFE8B18A);
  static const _hair = Color(0xFF2C1810);
  static const _shirtGreen = Color(0xFF006D44);
  static const _pantsGray = Color(0xFF374151);
  static const _laptopBody = Color(0xFFD1D5DB);
  static const _laptopDark = Color(0xFF6B7280);
  static const _laptopScreen = Color(0xFF1A1A2E);
  static const _screenBg = Color(0xFFE8F5EE);
  static const _bandGreen = Color(0xFF4ADE80);
  static const _bandDark = Color(0xFF16A34A);
  static const _plantPot = Color(0xFFE07B5A);
  static const _plantGreen = Color(0xFF15803D);
  static const _plantLight = Color(0xFF22C55E);
  // ── paints ────────────────────────────────────────────────────────────

  Paint _fill(Color c) => Paint()
    ..style = PaintingStyle.fill
    ..color = c;

  Paint _stroke(Color c, double w) => Paint()
    ..style = PaintingStyle.stroke
    ..color = c
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  // ── helpers ───────────────────────────────────────────────────────────

  void _oval(Canvas c, Rect r, Color col) {
    c.drawOval(r, _fill(col));
  }

  void _rrect(Canvas c, RRect rr, Color col) {
    c.drawRRect(rr, _fill(col));
  }

  void _circ(Canvas c, Offset o, double r, Color col) {
    c.drawCircle(o, r, _fill(col));
  }

  // ── main paint ────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    final sw = size.width;
    final sh = size.height;
    final s = sw / 320; // scale factor

    canvas.save();

    // ── background bubble ─────────────────────────────────────────────
    final bgPath = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(sw * 0.62, sh * 0.38),
        width: sw * 0.78,
        height: sh * 0.82,
      ));
    canvas.drawPath(bgPath, _fill(_bg));

    // ── yoga mat ──────────────────────────────────────────────────────
    // Slightly angled ellipse for perspective
    canvas.save();
    canvas.translate(sw * 0.52, sh * 0.82);
    canvas.scale(1.0, 0.22);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: sw * 0.72, height: sh * 1.0),
      _fill(_mat),
    );
    canvas.restore();

    // Mat highlight stripe
    canvas.save();
    canvas.translate(sw * 0.47, sh * 0.79);
    canvas.scale(1.0, 0.18);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: sw * 0.40, height: sh * 0.6),
      Paint()
        ..style = PaintingStyle.fill
        ..color = _matShadow.withValues(alpha: 0.3),
    );
    canvas.restore();

    // ── plant ─────────────────────────────────────────────────────────
    _drawPlant(canvas, sw, sh, s);

    // ── laptop ────────────────────────────────────────────────────────
    _drawLaptop(canvas, sw, sh, s);

    // ── patient (sitting cross-legged with resistance band) ───────────
    _drawPatient(canvas, sw, sh, s);

    canvas.restore();
  }

  void _drawPlant(Canvas canvas, double sw, double sh, double s) {
    // pot
    final potX = sw * 0.875;
    final potY = sh * 0.62;
    final pw = 28 * s;
    final ph = 22 * s;
    final potPath = Path()
      ..moveTo(potX - pw * 0.4, potY)
      ..lineTo(potX - pw * 0.5, potY + ph)
      ..quadraticBezierTo(potX, potY + ph * 1.15, potX + pw * 0.5, potY + ph)
      ..lineTo(potX + pw * 0.4, potY)
      ..close();
    canvas.drawPath(potPath, _fill(_plantPot));
    // pot rim
    _oval(canvas, Rect.fromCenter(center: Offset(potX, potY), width: pw * 0.9, height: ph * 0.28), _plantPot.withValues(alpha: 0.8));

    // soil
    _oval(canvas, Rect.fromCenter(center: Offset(potX, potY - 2 * s), width: pw * 0.75, height: ph * 0.22), const Color(0xFF5C3D1E));

    // stems
    final stemP = _stroke(_plantGreen, 1.8 * s);
    // left leaf stem
    canvas.drawLine(Offset(potX, potY - 4 * s), Offset(potX - 18 * s, potY - 36 * s), stemP);
    // center stem
    canvas.drawLine(Offset(potX, potY - 4 * s), Offset(potX + 2 * s, potY - 42 * s), stemP);
    // right stem
    canvas.drawLine(Offset(potX, potY - 4 * s), Offset(potX + 16 * s, potY - 32 * s), stemP);

    // leaves
    _drawLeaf(canvas, s, potX - 18 * s, potY - 36 * s, -0.4);
    _drawLeaf(canvas, s, potX + 2 * s, potY - 42 * s, 0.1);
    _drawLeaf(canvas, s, potX + 16 * s, potY - 32 * s, 0.5);
    _drawLeaf(canvas, s, potX - 10 * s, potY - 28 * s, -0.9);
    _drawLeaf(canvas, s, potX + 10 * s, potY - 26 * s, 0.8);
  }

  void _drawLeaf(Canvas canvas, double s, double x, double y, double angle) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);
    final lw = 18 * s;
    final lh = 28 * s;
    final leaf = Path()
      ..moveTo(0, 0)
      ..cubicTo(-lw * 0.5, -lh * 0.3, -lw * 0.6, -lh * 0.7, 0, -lh)
      ..cubicTo(lw * 0.6, -lh * 0.7, lw * 0.5, -lh * 0.3, 0, 0);
    canvas.drawPath(leaf, _fill(_plantLight));
    // midrib
    canvas.drawLine(Offset(0, 0), Offset(0, -lh * 0.85), _stroke(_plantGreen, 0.8 * s));
    canvas.restore();
  }

  void _drawLaptop(Canvas canvas, double sw, double sh, double s) {
    // Laptop positioned right-center
    final lx = sw * 0.56;
    final ly = sh * 0.12;
    final lw = 145 * s;
    final lh = 92 * s;
    final cornerR = 6 * s;

    // ── screen lid ────────────────────────────────────────────────────
    // Slight perspective tilt
    canvas.save();
    canvas.translate(lx, ly);
    // slight skew for 3-quarter view
    final skew = Matrix4.identity()
      ..setEntry(1, 0, -0.02)
      ..setEntry(0, 1, 0.01);
    canvas.transform(skew.storage);

    final screenRect = Rect.fromLTWH(-lw / 2, 0, lw, lh);
    // outer frame
    _rrect(canvas, RRect.fromRectAndRadius(screenRect, Radius.circular(cornerR)), _laptopBody);
    // dark bezel inside
    final bezelInset = 5 * s;
    final screenInner = Rect.fromLTWH(
      -lw / 2 + bezelInset,
      bezelInset,
      lw - bezelInset * 2,
      lh - bezelInset * 2,
    );
    _rrect(canvas, RRect.fromRectAndRadius(screenInner, Radius.circular(cornerR - 2 * s)), _laptopScreen);

    // screen content: video call background
    _rrect(canvas, RRect.fromRectAndRadius(screenInner, Radius.circular(cornerR - 2 * s)), _screenBg);

    // therapist figure on screen
    _drawTherapistOnScreen(canvas, s, screenInner);

    // video call controls bar at bottom of screen
    final barH = 12 * s;
    final barRect = Rect.fromLTWH(screenInner.left, screenInner.bottom - barH, screenInner.width, barH);
    canvas.drawRect(barRect, _fill(const Color(0xFF1A2B22)));
    // call buttons
    _circ(canvas, Offset(barRect.center.dx - 16 * s, barRect.center.dy), 4 * s, const Color(0xFFEF4444));
    _circ(canvas, Offset(barRect.center.dx, barRect.center.dy), 4 * s, const Color(0xFF22C55E));
    _circ(canvas, Offset(barRect.center.dx + 16 * s, barRect.center.dy), 4 * s, const Color(0xFF3B82F6));

    // webcam dot
    _circ(canvas, Offset(0, bezelInset * 0.5), 2.5 * s, _laptopDark);

    canvas.restore();

    // ── laptop base (keyboard) ────────────────────────────────────────
    canvas.save();
    canvas.translate(lx, ly + lh);

    final baseH = 10 * s;
    final basePath = Path()
      ..moveTo(-lw / 2 - 10 * s, 0)
      ..lineTo(-lw / 2 - 14 * s, baseH)
      ..quadraticBezierTo(0, baseH + 4 * s, lw / 2 + 14 * s, baseH)
      ..lineTo(lw / 2 + 10 * s, 0)
      ..close();
    canvas.drawPath(basePath, _fill(_laptopBody));

    // trackpad hint
    final tpW = 30 * s;
    final tpH = 10 * s;
    _rrect(canvas, RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0, baseH * 0.55), width: tpW, height: tpH), Radius.circular(3 * s)), _laptopDark.withValues(alpha: 0.25));

    canvas.restore();
  }

  void _drawTherapistOnScreen(Canvas canvas, double s, Rect screen) {
    final cx = screen.center.dx;
    final cy = screen.top + screen.height * 0.38;

    // body
    final torsoPath = Path()
      ..moveTo(cx - 14 * s, cy + 4 * s)
      ..lineTo(cx - 16 * s, cy + 34 * s)
      ..quadraticBezierTo(cx, cy + 38 * s, cx + 16 * s, cy + 34 * s)
      ..lineTo(cx + 14 * s, cy + 4 * s)
      ..quadraticBezierTo(cx, cy - 2 * s, cx - 14 * s, cy + 4 * s)
      ..close();
    canvas.drawPath(torsoPath, _fill(_shirtGreen));

    // head
    _circ(canvas, Offset(cx, cy - 10 * s), 10 * s, _skin);

    // hair
    final hairPath = Path()
      ..addOval(Rect.fromCenter(center: Offset(cx, cy - 12 * s), width: 22 * s, height: 14 * s));
    canvas.drawPath(hairPath, _fill(_hair));

    // hair side detail
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy - 10 * s), width: 20 * s, height: 12 * s),
      math.pi,
      math.pi,
      false,
      _fill(_hair),
    );

    // waving arm
    final armPath = Path()
      ..moveTo(cx + 12 * s, cy + 6 * s)
      ..quadraticBezierTo(cx + 22 * s, cy - 8 * s, cx + 20 * s, cy - 16 * s);
    canvas.drawPath(armPath, _stroke(_shirtGreen, 7 * s));
    // hand
    _circ(canvas, Offset(cx + 20 * s, cy - 17 * s), 4 * s, _skin);

    // face details
    // eyes
    _circ(canvas, Offset(cx - 3 * s, cy - 11 * s), 1.2 * s, const Color(0xFF2C1810));
    _circ(canvas, Offset(cx + 3 * s, cy - 11 * s), 1.2 * s, const Color(0xFF2C1810));
    // smile
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy - 8.5 * s), width: 7 * s, height: 5 * s),
      0.2,
      math.pi - 0.4,
      false,
      _stroke(const Color(0xFF8B4513), 1.2 * s),
    );

    // logo on shirt
    _circ(canvas, Offset(cx, cy + 14 * s), 4 * s, const Color(0xFFD5F2E8));
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy + 14 * s), width: 5 * s, height: 5 * s),
      math.pi * 0.8,
      math.pi * 1.4,
      false,
      _stroke(_forest, 1.0 * s),
    );
  }

  void _drawPatient(Canvas canvas, double sw, double sh, double s) {
    // Patient sits cross-legged in front-center, slightly right
    final px = sw * 0.42;
    final py = sh * 0.62;

    // ── shadow under body ─────────────────────────────────────────────
    canvas.save();
    canvas.translate(px + 4 * s, py + 44 * s);
    canvas.scale(1.0, 0.2);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 90 * s, height: 60 * s),
      Paint()
        ..color = _matShadow.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill,
    );
    canvas.restore();

    // ── crossed legs ──────────────────────────────────────────────────
    // Right leg (back)
    final legR = Path()
      ..moveTo(px - 2 * s, py + 22 * s)
      ..quadraticBezierTo(px + 28 * s, py + 30 * s, px + 44 * s, py + 44 * s)
      ..quadraticBezierTo(px + 34 * s, py + 48 * s, px + 24 * s, py + 46 * s)
      ..quadraticBezierTo(px + 10 * s, py + 34 * s, px - 8 * s, py + 30 * s)
      ..close();
    canvas.drawPath(legR, _fill(_pantsGray));

    // Left leg (front)
    final legL = Path()
      ..moveTo(px - 2 * s, py + 20 * s)
      ..quadraticBezierTo(px - 30 * s, py + 30 * s, px - 46 * s, py + 44 * s)
      ..quadraticBezierTo(px - 36 * s, py + 48 * s, px - 26 * s, py + 46 * s)
      ..quadraticBezierTo(px - 12 * s, py + 34 * s, px + 4 * s, py + 28 * s)
      ..close();
    canvas.drawPath(legL, _fill(_pantsGray));

    // feet (bare, skin)
    _oval(canvas, Rect.fromCenter(center: Offset(px + 46 * s, py + 46 * s), width: 14 * s, height: 8 * s), _skin);
    _oval(canvas, Rect.fromCenter(center: Offset(px - 46 * s, py + 46 * s), width: 14 * s, height: 8 * s), _skin);

    // ── torso ─────────────────────────────────────────────────────────
    final torso = Path()
      ..moveTo(px - 18 * s, py + 22 * s)
      ..lineTo(px - 16 * s, py - 14 * s)
      ..quadraticBezierTo(px, py - 22 * s, px + 16 * s, py - 14 * s)
      ..lineTo(px + 18 * s, py + 22 * s)
      ..quadraticBezierTo(px, py + 28 * s, px - 18 * s, py + 22 * s)
      ..close();
    canvas.drawPath(torso, _fill(_shirtGreen));

    // shirt collar V
    final collarPath = Path()
      ..moveTo(px - 6 * s, py - 12 * s)
      ..lineTo(px, py - 6 * s)
      ..lineTo(px + 6 * s, py - 12 * s);
    canvas.drawPath(collarPath, _stroke(const Color(0xFF004D32), 1.5 * s));

    // ── resistance band ───────────────────────────────────────────────
    // Band wraps around feet, both arms pull back
    // Left arm + band
    final bandLeft = Path()
      ..moveTo(px - 46 * s, py + 42 * s) // foot anchor
      ..cubicTo(px - 50 * s, py + 20 * s, px - 42 * s, py - 4 * s, px - 30 * s, py - 18 * s);
    canvas.drawPath(bandLeft, _stroke(_bandDark, 5 * s));
    canvas.drawPath(bandLeft, _stroke(_bandGreen, 3 * s));

    // Right arm + band
    final bandRight = Path()
      ..moveTo(px + 46 * s, py + 42 * s) // foot anchor
      ..cubicTo(px + 50 * s, py + 20 * s, px + 42 * s, py - 4 * s, px + 30 * s, py - 18 * s);
    canvas.drawPath(bandRight, _stroke(_bandDark, 5 * s));
    canvas.drawPath(bandRight, _stroke(_bandGreen, 3 * s));

    // center band loop across chest
    final bandCenter = Path()
      ..moveTo(px - 30 * s, py - 18 * s)
      ..cubicTo(px - 14 * s, py - 8 * s, px + 14 * s, py - 8 * s, px + 30 * s, py - 18 * s);
    canvas.drawPath(bandCenter, _stroke(_bandDark, 5 * s));
    canvas.drawPath(bandCenter, _stroke(_bandGreen, 3 * s));

    // ── arms ──────────────────────────────────────────────────────────
    // Left arm (pulling band backward)
    final armL = Path()
      ..moveTo(px - 16 * s, py - 6 * s)
      ..quadraticBezierTo(px - 32 * s, py - 10 * s, px - 30 * s, py - 18 * s);
    canvas.drawPath(armL, _stroke(_shirtGreen, 10 * s));
    canvas.drawPath(armL, _stroke(_shirtGreen, 9 * s));
    // forearm skin
    final foreL = Path()
      ..moveTo(px - 30 * s, py - 18 * s)
      ..quadraticBezierTo(px - 34 * s, py - 22 * s, px - 32 * s, py - 26 * s);
    canvas.drawPath(foreL, _stroke(_skin, 7 * s));

    // Right arm
    final armR = Path()
      ..moveTo(px + 16 * s, py - 6 * s)
      ..quadraticBezierTo(px + 32 * s, py - 10 * s, px + 30 * s, py - 18 * s);
    canvas.drawPath(armR, _stroke(_shirtGreen, 10 * s));
    final foreR = Path()
      ..moveTo(px + 30 * s, py - 18 * s)
      ..quadraticBezierTo(px + 34 * s, py - 22 * s, px + 32 * s, py - 26 * s);
    canvas.drawPath(foreR, _stroke(_skin, 7 * s));

    // hands
    _circ(canvas, Offset(px - 32 * s, py - 26 * s), 5 * s, _skin);
    _circ(canvas, Offset(px + 32 * s, py - 26 * s), 5 * s, _skin);

    // ── neck ──────────────────────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(px - 5 * s, py - 30 * s, 10 * s, 12 * s),
      _fill(_skin),
    );

    // ── head ──────────────────────────────────────────────────────────
    // head shape
    canvas.drawOval(
      Rect.fromCenter(center: Offset(px, py - 42 * s), width: 30 * s, height: 34 * s),
      _fill(_skin),
    );

    // hair
    final hairPath = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(px, py - 46 * s),
        width: 32 * s,
        height: 22 * s,
      ));
    canvas.drawPath(hairPath, _fill(_hair));

    // hair side (covers sides of head)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(px - 14 * s, py - 40 * s), width: 8 * s, height: 16 * s),
      _fill(_hair),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(px + 14 * s, py - 40 * s), width: 8 * s, height: 16 * s),
      _fill(_hair),
    );

    // ear
    _oval(canvas, Rect.fromCenter(center: Offset(px + 15 * s, py - 40 * s), width: 6 * s, height: 9 * s), _skinDark);

    // ── face ──────────────────────────────────────────────────────────
    // eyes
    _circ(canvas, Offset(px - 6 * s, py - 42 * s), 1.8 * s, const Color(0xFF1C1009));
    _circ(canvas, Offset(px + 6 * s, py - 42 * s), 1.8 * s, const Color(0xFF1C1009));
    // eyebrows (slight effort/focus)
    canvas.drawLine(
      Offset(px - 9 * s, py - 47 * s),
      Offset(px - 3 * s, py - 46 * s),
      _stroke(const Color(0xFF2C1810), 1.8 * s),
    );
    canvas.drawLine(
      Offset(px + 3 * s, py - 46 * s),
      Offset(px + 9 * s, py - 47 * s),
      _stroke(const Color(0xFF2C1810), 1.8 * s),
    );
    // nose
    canvas.drawArc(
      Rect.fromCenter(center: Offset(px, py - 38 * s), width: 6 * s, height: 4 * s),
      0,
      math.pi,
      false,
      _stroke(_skinDark, 1.2 * s),
    );
    // slight smile
    canvas.drawArc(
      Rect.fromCenter(center: Offset(px, py - 35 * s), width: 9 * s, height: 5 * s),
      0.2,
      math.pi - 0.4,
      false,
      _stroke(const Color(0xFFB05A2A), 1.5 * s),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

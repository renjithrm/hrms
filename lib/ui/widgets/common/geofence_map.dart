// lib/ui/widgets/common/geofence_map.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../tools/app_text_style.dart';

/// A schematic map: the office's allowed area and where the person is,
/// drawn to scale along one line. Not a real map, so it works offline.
class GeofenceMap extends StatelessWidget {
  /// Creates the map.
  const GeofenceMap({
    super.key,
    required this.distanceMetres,
    required this.radiusMetres,
    required this.officeLabel,
    required this.youLabel,
  });

  /// Distance from the office centre.
  final double distanceMetres;

  /// Allowed radius.
  final double radiusMetres;

  /// Label under the office area.
  final String officeLabel;

  /// Label next to the person's pin.
  final String youLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$officeLabel. $youLabel: ${distanceMetres.round()} m',
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: SizedBox(
          height: 96,
          child: CustomPaint(
            painter: _GeofencePainter(
              distanceMetres: distanceMetres,
              radiusMetres: radiusMetres,
              officeLabel: officeLabel,
              youLabel: youLabel,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _GeofencePainter extends CustomPainter {
  _GeofencePainter({
    required this.distanceMetres,
    required this.radiusMetres,
    required this.officeLabel,
    required this.youLabel,
  });

  final double distanceMetres;
  final double radiusMetres;
  final String officeLabel;
  final String youLabel;

  static const double _zoneRadius = 28;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Palette.background);

    final streets = Paint()
      ..color = Palette.surface
      ..strokeWidth = 3;
    for (var x = -size.height; x < size.width; x += 26) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height * 0.7, 0),
        streets,
      );
    }

    final office = Offset(16 + _zoneRadius, size.height / 2 - 6);
    canvas.drawCircle(
      office,
      _zoneRadius,
      Paint()..color = Palette.brand.withValues(alpha: 0.12),
    );
    _drawDashedCircle(canvas, office, _zoneRadius);
    _drawPin(canvas, office, Palette.brand);

    final scale = radiusMetres == 0 ? 1.0 : _zoneRadius / radiusMetres;
    final maxX = size.width - 18;
    final you = Offset(
      math.min(office.dx + distanceMetres * scale, maxX),
      office.dy + 8,
    );
    _drawPin(canvas, you, Palette.danger);

    _label(canvas, officeLabel, Offset(8, size.height - 18), Palette.brand);
    _label(canvas, youLabel, Offset(you.dx - 24, you.dy + 9), Palette.danger);
  }

  void _drawDashedCircle(Canvas canvas, Offset centre, double radius) {
    final paint = Paint()
      ..color = Palette.brand
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dashes = 24;
    for (var i = 0; i < dashes; i += 2) {
      final start = i * 2 * math.pi / dashes;
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: radius),
        start,
        2 * math.pi / dashes,
        false,
        paint,
      );
    }
  }

  void _drawPin(Canvas canvas, Offset at, Color color) {
    canvas.drawCircle(at, 7, Paint()..color = Palette.surface);
    canvas.drawCircle(at, 5, Paint()..color = color);
  }

  void _label(Canvas canvas, String text, Offset at, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: AppTextStyle.chip.copyWith(color: color, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_GeofencePainter old) =>
      old.distanceMetres != distanceMetres ||
      old.radiusMetres != radiusMetres ||
      old.officeLabel != officeLabel ||
      old.youLabel != youLabel;
}

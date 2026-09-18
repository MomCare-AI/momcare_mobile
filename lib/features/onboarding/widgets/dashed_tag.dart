import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashedTag extends StatelessWidget {
  const DashedTag({
    super.key,
    required this.label,
    this.isEmoji = false,
    this.backgroundColor = Colors.white,
  });

  final String label;
  final bool isEmoji;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: Colors.black,
        strokeWidth: 1.0,
        dashWidth: 4.0,
        dashSpace: 3.0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
        ),
        padding: isEmoji
            ? const EdgeInsets.all(12)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          label,
          style: isEmoji
              ? const TextStyle(fontSize: 16)
              : GoogleFonts.playfairDisplay(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.height / 2),
    );

    final path = Path()..addRRect(rRect);
    final dashedPath = _createDashedPath(path);
    canvas.drawPath(dashedPath, paint);
  }

  Path _createDashedPath(Path source) {
    final Path dest = Path();
    for (final pathMetric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final double len = min(dashWidth, pathMetric.length - distance);
        dest.addPath(
          pathMetric.extractPath(distance, distance + len),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

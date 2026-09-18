import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Stands in for a real map (Google Maps / Mapbox / etc. — not decided,
/// not added this phase). Visually suggests the intended layout (a map
/// area with hospital pins) without pretending to be live data — the
/// "Static preview" badge is deliberate and should stay visible in any
/// future iteration of this widget until a real map provider is wired in.
///
/// Swapping in a real map later means replacing the body of this widget
/// only — nothing that renders it (HospitalDiscoveryScreen) needs to change.
class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 220,
          width: double.infinity,
          child: Stack(
            children: [
              // Subtle grid suggesting map tiles — not a real map render.
              CustomPaint(size: Size.infinite, painter: _GridPainter()),
              const Positioned(top: 40, left: 60, child: _PinIcon()),
              const Positioned(
                top: 110,
                left: 140,
                child: _PinIcon(active: true),
              ),
              const Positioned(top: 70, right: 50, child: _PinIcon()),
              const Positioned(bottom: 30, left: 90, child: _PinIcon()),
              Positioned(top: 12, left: 12, child: _PreviewBadge()),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Static preview — not live map data',
        style: TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }
}

class _PinIcon extends StatelessWidget {
  const _PinIcon({this.active = false});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.location_on,
      color: active ? AppColors.brand : AppColors.faint,
      size: active ? 34 : 26,
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.brandWash, Colors.white, Color(0xFFFFEDEE)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final line = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

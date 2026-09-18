import 'dart:math';
import 'package:flutter/material.dart';

class ParticleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Duration animationDuration;
  final Color particleColor;
  final int particleCount;

  const ParticleButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.animationDuration = const Duration(milliseconds: 1000),
    this.particleColor = Colors.black,
    this.particleCount = 40,
  });

  @override
  State<ParticleButton> createState() => _ParticleButtonState();
}

class _ParticleButtonState extends State<ParticleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_Particle> _particles = [];
  bool _isDisintegrating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onPressed();
        // Reset after navigation so it's ready if they come back
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _isDisintegrating = false;
              _particles.clear();
            });
            _controller.reset();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerAnimation(Size size) {
    if (_isDisintegrating) return;

    setState(() {
      _isDisintegrating = true;
      _particles = List.generate(
        widget.particleCount,
        (_) => _Particle.random(size, widget.particleColor),
      );
    });

    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: () {
            final size = context.size ?? const Size(200, 60);
            _triggerAnimation(size);
          },
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final progress = _controller.value;

              // Button shrinks and fades
              final buttonScale = 1.0 - (progress * 1.5).clamp(0.0, 1.0);
              final buttonOpacity = 1.0 - (progress * 2).clamp(0.0, 1.0);

              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // The original button
                  Transform.scale(
                    scale: buttonScale,
                    child: Opacity(
                      opacity: buttonOpacity,
                      child: IgnorePointer(
                        ignoring: _isDisintegrating,
                        child: widget.child,
                      ),
                    ),
                  ),

                  // The particles
                  if (_isDisintegrating)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ParticlePainter(_particles, progress),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double angle;
  final double speed;
  final double size;
  final Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });

  factory _Particle.random(Size bounds, Color baseColor) {
    final random = Random();
    // Start at a random position inside the button
    final startX = random.nextDouble() * bounds.width;
    final startY = random.nextDouble() * bounds.height;

    // Move outwards in any direction
    final angle = random.nextDouble() * 2 * pi;
    final speed = random.nextDouble() * 150 + 50; // pixels per second
    final size = random.nextDouble() * 6 + 2;

    // Add slight opacity variation
    final opacity = random.nextDouble() * 0.5 + 0.5;

    return _Particle(
      x: startX,
      y: startY,
      angle: angle,
      speed: speed,
      size: size,
      color: baseColor.withValues(alpha: opacity),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // Calculate current position based on progress
      // progress goes from 0.0 to 1.0 over the duration
      final distance = p.speed * progress;
      final currentX = p.x + cos(p.angle) * distance;
      final currentY = p.y + sin(p.angle) * distance;

      // Fade out towards the end
      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withValues(alpha: p.color.a * opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(currentX, currentY), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

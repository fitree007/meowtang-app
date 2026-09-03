import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../state/expense_controller.dart';
import '../theme/app_theme_model.dart';

class SeasonalEffectOverlay extends StatefulWidget {
  final ExpenseController controller;
  final Widget child;

  const SeasonalEffectOverlay({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<SeasonalEffectOverlay> createState() => _SeasonalEffectOverlayState();
}

class _SeasonalEffectOverlayState extends State<SeasonalEffectOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();
  SeasonalEffect _currentEffect = SeasonalEffect.none;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _currentEffect = widget.controller.currentTheme.seasonalEffect;
    _initParticles(_currentEffect);
  }

  @override
  void didUpdateWidget(covariant SeasonalEffectOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newEffect = widget.controller.currentTheme.seasonalEffect;
    if (newEffect != _currentEffect) {
      _currentEffect = newEffect;
      _initParticles(newEffect);
    }
  }

  void _initParticles(SeasonalEffect effect) {
    _particles.clear();
    if (effect == SeasonalEffect.none) return;

    final count = effect == SeasonalEffect.cozyRain ? 40 : 28;
    for (int i = 0; i < count; i++) {
      _particles.add(_Particle.random(_random, effect));
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effect = widget.controller.currentTheme.seasonalEffect;
    final isEnabled = widget.controller.isSeasonalEffectEnabled;

    if (effect == SeasonalEffect.none || !isEnabled) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _SeasonalParticlePainter(
                    particles: _particles,
                    effect: effect,
                    random: _random,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _Particle {
  double x;
  double y;
  double size;
  double speedY;
  double speedX;
  double rotation;
  double rotationSpeed;
  double opacity;
  Color color;
  double swayOffset;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedY,
    required this.speedX,
    required this.rotation,
    required this.rotationSpeed,
    required this.opacity,
    required this.color,
    required this.swayOffset,
  });

  factory _Particle.random(math.Random random, SeasonalEffect effect) {
    final x = random.nextDouble();
    final y = random.nextDouble();

    switch (effect) {
      case SeasonalEffect.sakura:
        final pinkTones = [
          const Color(0xFFFFB7C5),
          const Color(0xFFFFC0CB),
          const Color(0xFFFF9EAA),
          const Color(0xFFFFD1DC),
          const Color(0xFFFB7185),
        ];
        return _Particle(
          x: x,
          y: y,
          size: random.nextDouble() * 7 + 6,
          speedY: random.nextDouble() * 0.0018 + 0.0012,
          speedX: (random.nextDouble() - 0.5) * 0.0008 + 0.0004,
          rotation: random.nextDouble() * math.pi * 2,
          rotationSpeed: (random.nextDouble() - 0.5) * 0.03,
          opacity: random.nextDouble() * 0.45 + 0.35,
          color: pinkTones[random.nextInt(pinkTones.length)],
          swayOffset: random.nextDouble() * math.pi * 2,
        );

      case SeasonalEffect.snow:
        final snowColors = [
          Colors.white,
          const Color(0xFFE0F2FE),
          const Color(0xFFBAE6FD),
        ];
        return _Particle(
          x: x,
          y: y,
          size: random.nextDouble() * 4 + 2,
          speedY: random.nextDouble() * 0.002 + 0.0008,
          speedX: (random.nextDouble() - 0.5) * 0.0005,
          rotation: 0,
          rotationSpeed: 0,
          opacity: random.nextDouble() * 0.5 + 0.3,
          color: snowColors[random.nextInt(snowColors.length)],
          swayOffset: random.nextDouble() * math.pi * 2,
        );

      case SeasonalEffect.autumnLeaves:
        final autumnTones = [
          const Color(0xFFEA580C),
          const Color(0xFFC2410C),
          const Color(0xFFD97706),
          const Color(0xFFB45309),
          const Color(0xFFE11D48),
        ];
        return _Particle(
          x: x,
          y: y,
          size: random.nextDouble() * 8 + 7,
          speedY: random.nextDouble() * 0.002 + 0.0012,
          speedX: (random.nextDouble() - 0.5) * 0.001 + 0.0005,
          rotation: random.nextDouble() * math.pi * 2,
          rotationSpeed: (random.nextDouble() - 0.5) * 0.04,
          opacity: random.nextDouble() * 0.5 + 0.35,
          color: autumnTones[random.nextInt(autumnTones.length)],
          swayOffset: random.nextDouble() * math.pi * 2,
        );

      case SeasonalEffect.summerSparkle:
        final goldCyanTones = [
          const Color(0xFFFBBF24),
          const Color(0xFFF59E0B),
          const Color(0xFF38BDF8),
          const Color(0xFF67E8F9),
        ];
        return _Particle(
          x: x,
          y: y,
          size: random.nextDouble() * 6 + 3,
          speedY: -(random.nextDouble() * 0.0015 + 0.0008), // float upwards
          speedX: (random.nextDouble() - 0.5) * 0.0008,
          rotation: random.nextDouble() * math.pi * 2,
          rotationSpeed: (random.nextDouble() - 0.5) * 0.02,
          opacity: random.nextDouble() * 0.4 + 0.3,
          color: goldCyanTones[random.nextInt(goldCyanTones.length)],
          swayOffset: random.nextDouble() * math.pi * 2,
        );

      case SeasonalEffect.cozyRain:
        return _Particle(
          x: x,
          y: y,
          size: random.nextDouble() * 12 + 10,
          speedY: random.nextDouble() * 0.012 + 0.008,
          speedX: -0.0015, // slight angle
          rotation: 0.12,
          rotationSpeed: 0,
          opacity: random.nextDouble() * 0.25 + 0.15,
          color: const Color(0xFF38BDF8),
          swayOffset: 0,
        );

      case SeasonalEffect.stars:
        final starTones = [
          Colors.white,
          const Color(0xFFE9D5FF),
          const Color(0xFFFDE68A),
          const Color(0xFFBAE6FD),
        ];
        return _Particle(
          x: x,
          y: y,
          size: random.nextDouble() * 5 + 3,
          speedY: (random.nextDouble() - 0.5) * 0.0003,
          speedX: (random.nextDouble() - 0.5) * 0.0003,
          rotation: random.nextDouble() * math.pi * 2,
          rotationSpeed: 0.01,
          opacity: random.nextDouble() * 0.6 + 0.2,
          color: starTones[random.nextInt(starTones.length)],
          swayOffset: random.nextDouble() * math.pi * 2,
        );

      case SeasonalEffect.none:
        return _Particle(
          x: 0, y: 0, size: 0, speedY: 0, speedX: 0, rotation: 0,
          rotationSpeed: 0, opacity: 0, color: Colors.transparent, swayOffset: 0,
        );
    }
  }
}

class _SeasonalParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final SeasonalEffect effect;
  final math.Random random;

  _SeasonalParticlePainter({
    required this.particles,
    required this.effect,
    required this.random,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // Update position
      p.y += p.speedY;
      p.x += p.speedX + math.sin(p.swayOffset) * 0.0004;
      p.swayOffset += 0.02;
      p.rotation += p.rotationSpeed;

      // Wrap around bounds
      if (p.y > 1.05) {
        p.y = -0.05;
        p.x = random.nextDouble();
      } else if (p.y < -0.05) {
        p.y = 1.05;
        p.x = random.nextDouble();
      }
      if (p.x > 1.05) p.x = -0.05;
      if (p.x < -0.05) p.x = 1.05;

      final posX = p.x * size.width;
      final posY = p.y * size.height;

      final paint = Paint()
        ..color = p.color.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(posX, posY);
      canvas.rotate(p.rotation);

      switch (effect) {
        case SeasonalEffect.sakura:
          // Draw delicate sakura petal
          final path = Path();
          path.moveTo(0, -p.size);
          path.quadraticBezierTo(p.size * 0.6, -p.size * 0.3, 0, p.size);
          path.quadraticBezierTo(-p.size * 0.6, -p.size * 0.3, 0, -p.size);
          canvas.drawPath(path, paint);
          break;

        case SeasonalEffect.snow:
          // Draw soft glowing snowflake circle
          canvas.drawCircle(Offset.zero, p.size, paint);
          break;

        case SeasonalEffect.autumnLeaves:
          // Draw maple / autumn leaf diamond
          final path = Path();
          path.moveTo(0, -p.size);
          path.lineTo(p.size * 0.7, -p.size * 0.2);
          path.lineTo(p.size * 0.3, p.size * 0.8);
          path.lineTo(0, p.size);
          path.lineTo(-p.size * 0.3, p.size * 0.8);
          path.lineTo(-p.size * 0.7, -p.size * 0.2);
          path.close();
          canvas.drawPath(path, paint);
          break;

        case SeasonalEffect.summerSparkle:
          // Draw glowing sunburst sparkle
          final path = Path();
          path.moveTo(0, -p.size);
          path.quadraticBezierTo(0, 0, p.size, 0);
          path.quadraticBezierTo(0, 0, 0, p.size);
          path.quadraticBezierTo(0, 0, -p.size, 0);
          path.quadraticBezierTo(0, 0, 0, -p.size);
          canvas.drawPath(path, paint);
          break;

        case SeasonalEffect.cozyRain:
          // Draw raindrop streak
          paint.strokeWidth = 1.5;
          paint.style = PaintingStyle.stroke;
          canvas.drawLine(Offset.zero, Offset(p.speedX * 500, p.size), paint);
          break;

        case SeasonalEffect.stars:
          // Draw 4-pointed star
          final path = Path();
          path.moveTo(0, -p.size);
          path.lineTo(p.size * 0.25, -p.size * 0.25);
          path.lineTo(p.size, 0);
          path.lineTo(p.size * 0.25, p.size * 0.25);
          path.lineTo(0, p.size);
          path.lineTo(-p.size * 0.25, p.size * 0.25);
          path.lineTo(-p.size, 0);
          path.lineTo(-p.size * 0.25, -p.size * 0.25);
          path.close();
          canvas.drawPath(path, paint);
          break;

        case SeasonalEffect.none:
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SeasonalParticlePainter oldDelegate) => true;
}

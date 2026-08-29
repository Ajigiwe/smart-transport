import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';


/// Custom animated loader with Ghana flag colors
/// Pulsing bus icon with orbiting colored dots
class AnimatedLoader extends StatefulWidget {
  final double size;
  final String? message;

  const AnimatedLoader({
    Key? key,
    this.size = 80,
    this.message,
  }) : super(key: key);

  @override
  State<AnimatedLoader> createState() => _AnimatedLoaderState();
}

class _AnimatedLoaderState extends State<AnimatedLoader>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _orbitController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _orbitController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size * 1.8,
          height: widget.size * 1.8,
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulseController, _orbitController, _fadeController]),
            builder: (context, child) {
              return CustomPaint(
                painter: _LoaderPainter(
                  pulseValue: _pulseController.value,
                  orbitValue: _orbitController.value,
                  fadeValue: _fadeController.value,
                ),
                child: Center(
                  child: Transform.scale(
                    scale: 0.85 + 0.15 * _pulseController.value,
                    child: Container(
                      width: widget.size * 0.7,
                      height: widget.size * 0.7,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ghanaRed.withOpacity(
                              0.3 * _pulseController.value,
                            ),
                            blurRadius: 20 * _pulseController.value,
                            spreadRadius: 5 * _pulseController.value,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.directions_bus_rounded,
                        color: Colors.white,
                        size: widget.size * 0.35,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 24),
          FadeTransition(
            opacity: _fadeController,
            child: Text(
              widget.message!,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Painter for orbiting dots and glow effect
class _LoaderPainter extends CustomPainter {
  final double pulseValue;
  final double orbitValue;
  final double fadeValue;

  _LoaderPainter({
    required this.pulseValue,
    required this.orbitValue,
    required this.fadeValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw glow ring
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = AppColors.ghanaGold.withOpacity(0.2 + 0.1 * pulseValue);
    canvas.drawCircle(center, radius * 0.75, glowPaint);

    // Draw orbiting dots (Red, Gold, Green)
    final colors = [
      AppColors.ghanaRed,
      AppColors.ghanaGold,
      AppColors.ghanaGreen,
    ];

    for (int i = 0; i < 3; i++) {
      final angle = (orbitValue * 2 * math.pi) + (i * 2 * math.pi / 3);
      final dotRadius = radius * 0.75;
      final dotX = center.dx + math.cos(angle) * dotRadius;
      final dotY = center.dy + math.sin(angle) * dotRadius;

      final dotPaint = Paint()
        ..color = colors[i].withOpacity(0.6 + 0.4 * fadeValue)
        ..style = PaintingStyle.fill;

      // Outer glow
      final glowDotPaint = Paint()
        ..color = colors[i].withOpacity(0.2 * fadeValue)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(dotX, dotY),
        6 + 2 * pulseValue,
        glowDotPaint,
      );
      canvas.drawCircle(
        Offset(dotX, dotY),
        4,
        dotPaint,
      );
    }

    // Draw trailing arc
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final arcStart = orbitValue * 2 * math.pi;
    final arcSweep = math.pi * 0.6;

    final gradient = SweepGradient(
      startAngle: arcStart,
      endAngle: arcStart + arcSweep,
      colors: const [
        Colors.transparent,
        AppColors.ghanaRed,
        AppColors.ghanaGold,
        AppColors.ghanaGreen,
      ],
    );

    arcPaint.shader = gradient.createShader(
      Rect.fromCircle(center: center, radius: radius * 0.75),
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.75),
      arcStart,
      arcSweep,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LoaderPainter oldDelegate) =>
      oldDelegate.pulseValue != pulseValue ||
      oldDelegate.orbitValue != orbitValue ||
      oldDelegate.fadeValue != fadeValue;
}

/// Animated Moving Vehicle Loader Widget
class VehicleDriveLoader extends StatefulWidget {
  final double width;
  final double height;
  final String? message;
  final Color primaryColor;

  const VehicleDriveLoader({
    Key? key,
    this.width = 200,
    this.height = 110,
    this.message,
    this.primaryColor = AppColors.ghanaGreen,
  }) : super(key: key);

  @override
  State<VehicleDriveLoader> createState() => _VehicleDriveLoaderState();
}

class _VehicleDriveLoaderState extends State<VehicleDriveLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.width,
          height: widget.height,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _VehicleDrivePainter(
                  progress: _controller.value,
                  vehicleColor: widget.primaryColor,
                ),
              );
            },
          ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ],
    );
  }
}

/// Custom painter for moving vehicle, scrolling road, spinning wheels, headlight & exhaust particles
class _VehicleDrivePainter extends CustomPainter {
  final double progress;
  final Color vehicleColor;

  _VehicleDrivePainter({
    required this.progress,
    required this.vehicleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final roadY = size.height - 18.0;
    
    // 1. Draw Road Asphalt Baseline
    final roadPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, roadY), Offset(size.width, roadY), roadPaint);

    // 2. Draw Moving Road Dashed Markings
    final dashWidth = 14.0;
    final dashGap = 10.0;
    final totalDashUnit = dashWidth + dashGap;
    final dashOffset = (progress * totalDashUnit);

    final dashPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (double x = -totalDashUnit + dashOffset; x < size.width + totalDashUnit; x += totalDashUnit) {
      canvas.drawLine(Offset(x, roadY + 5), Offset(x + dashWidth, roadY + 5), dashPaint);
    }

    // 3. Suspension Bounce Physics (y offset)
    final bounceY = math.sin(progress * 2 * math.pi) * 1.8;
    final vehicleY = size.height - 52.0 + bounceY;
    final vehicleX = size.width * 0.28;
    final vehicleW = 85.0;
    final vehicleH = 34.0;

    // 4. Headlight Beam Projection
    final lightFrontX = vehicleX + vehicleW;
    final lightY = vehicleY + 18.0;
    final lightPath = Path()
      ..moveTo(lightFrontX, lightY - 4)
      ..lineTo(size.width * 0.95, lightY - 14)
      ..lineTo(size.width * 0.98, lightY + 12)
      ..lineTo(lightFrontX, lightY + 6)
      ..close();

    final lightGradient = RadialGradient(
      center: Alignment.centerLeft,
      radius: 1.2,
      colors: [
        AppColors.ghanaGold.withOpacity(0.45),
        AppColors.ghanaGold.withOpacity(0.0),
      ],
    );

    final lightPaint = Paint()
      ..shader = lightGradient.createShader(lightPath.getBounds());
    canvas.drawPath(lightPath, lightPaint);

    // 5. Vehicle Body RRect
    final bodyRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(vehicleX, vehicleY, vehicleW, vehicleH),
      topLeft: const Radius.circular(8),
      topRight: const Radius.circular(14),
      bottomLeft: const Radius.circular(4),
      bottomRight: const Radius.circular(6),
    );

    final bodyPaint = Paint()
      ..color = vehicleColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(bodyRect, bodyPaint);

    // Body Outline Accent
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(bodyRect, borderPaint);

    // 6. Tinted Windows
    final windowPaint = Paint()
      ..color = const Color(0xFF0F172A).withOpacity(0.85)
      ..style = PaintingStyle.fill;

    // Front Windshield
    final windshield = Path()
      ..moveTo(vehicleX + 54, vehicleY + 4)
      ..lineTo(vehicleX + 78, vehicleY + 4)
      ..lineTo(vehicleX + 82, vehicleY + 16)
      ..lineTo(vehicleX + 54, vehicleY + 16)
      ..close();
    canvas.drawPath(windshield, windowPaint);

    // Passenger Side Windows
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(vehicleX + 6, vehicleY + 4, 20, 12), const Radius.circular(2)),
      windowPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(vehicleX + 30, vehicleY + 4, 20, 12), const Radius.circular(2)),
      windowPaint,
    );

    // 7. Headlight & Taillight Bulbs
    final headlightPaint = Paint()..color = AppColors.ghanaGold;
    canvas.drawCircle(Offset(vehicleX + vehicleW - 2, vehicleY + 22), 3, headlightPaint);

    final taillightPaint = Paint()..color = AppColors.ghanaRed;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(vehicleX, vehicleY + 14, 3, 8), const Radius.circular(1)),
      taillightPaint,
    );

    // 8. Spinning Alloy Wheels
    final wheelY = vehicleY + vehicleH - 2;
    final rearWheelX = vehicleX + 18.0;
    final frontWheelX = vehicleX + 64.0;
    final wheelRadius = 8.5;

    _drawWheel(canvas, Offset(rearWheelX, wheelY), wheelRadius, progress);
    _drawWheel(canvas, Offset(frontWheelX, wheelY), wheelRadius, progress);

    // 9. Animated Exhaust / Speed Particles
    for (int i = 0; i < 4; i++) {
      final particleProgress = (progress + i * 0.25) % 1.0;
      final px = vehicleX - 6 - (particleProgress * 36);
      final py = vehicleY + vehicleH - 6 - (math.sin(particleProgress * math.pi) * 6);
      final pRadius = (1.0 - particleProgress) * 3.5;
      final pOpacity = (1.0 - particleProgress) * 0.5;

      final particlePaint = Paint()
        ..color = const Color(0xFF94A3B8).withOpacity(pOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), math.max(0.5, pRadius), particlePaint);
    }
  }

  void _drawWheel(Canvas canvas, Offset center, double radius, double progress) {
    // Tire Rubber
    final tirePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, tirePaint);

    // Rim Alloy
    final rimPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.55, rimPaint);

    // Rotating Spokes
    final spokeAngle = -progress * 2 * math.pi * 2;
    final spokePaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 4; i++) {
      final angle = spokeAngle + (i * math.pi / 2);
      final dx = math.cos(angle) * (radius * 0.5);
      final dy = math.sin(angle) * (radius * 0.5);
      canvas.drawLine(center, center + Offset(dx, dy), spokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VehicleDrivePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.vehicleColor != vehicleColor;
}

/// Full-screen loading overlay
class FullScreenLoader extends StatelessWidget {
  final String? message;

  const FullScreenLoader({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: VehicleDriveLoader(
          width: 220,
          height: 120,
          message: message ?? 'Tracking transport routes...',
        ),
      ),
    );
  }
}

/// Inline loader for buttons and lists
class InlineLoader extends StatelessWidget {
  final double size;
  final Color? color;

  const InlineLoader({
    Key? key,
    this.size = 24,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.ghanaGold,
        ),
      ),
    );
  }
}


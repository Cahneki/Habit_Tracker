import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class TexturedAppShell extends StatelessWidget {
  const TexturedAppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;

    final topLight = dark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.white.withValues(alpha: 0.3);
    final bottomShade = dark
        ? Colors.black.withValues(alpha: 0.24)
        : Colors.black.withValues(alpha: 0.1);
    final lightGrain = dark
        ? Colors.white.withValues(alpha: 0.03)
        : Colors.white.withValues(alpha: 0.08);
    final darkGrain = dark
        ? Colors.black.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: 0.06);

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.surface,
                scheme.surfaceContainerHigh.withValues(
                  alpha: dark ? 0.55 : 0.45,
                ),
                scheme.surface,
              ],
            ),
          ),
        ),
        child,
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [topLight, Colors.transparent, bottomShade],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: CustomPaint(
            painter: _PaperGrainPainter(
              lightColor: lightGrain,
              darkColor: darkGrain,
              step: 3,
              lightThreshold: 0.82,
              darkThreshold: 0.12,
            ),
          ),
        ),
        IgnorePointer(
          child: CustomPaint(
            painter: _PaperGrainPainter(
              lightColor: lightGrain.withValues(alpha: lightGrain.a * 0.7),
              darkColor: darkGrain.withValues(alpha: darkGrain.a * 0.7),
              step: 6,
              lightThreshold: 0.9,
              darkThreshold: 0.09,
            ),
          ),
        ),
      ],
    );
  }
}

class _PaperGrainPainter extends CustomPainter {
  const _PaperGrainPainter({
    required this.lightColor,
    required this.darkColor,
    required this.step,
    required this.lightThreshold,
    required this.darkThreshold,
  });

  final Color lightColor;
  final Color darkColor;
  final double step;
  final double lightThreshold;
  final double darkThreshold;

  @override
  void paint(Canvas canvas, Size size) {
    final lightPoints = <Offset>[];
    final darkPoints = <Offset>[];

    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        final n = _noise(x, y);
        if (n > lightThreshold) {
          lightPoints.add(Offset(x, y));
        } else if (n < darkThreshold) {
          darkPoints.add(Offset(x, y));
        }
      }
    }

    final lightPaint = Paint()
      ..color = lightColor
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final darkPaint = Paint()
      ..color = darkColor
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    if (lightPoints.isNotEmpty) {
      canvas.drawPoints(ui.PointMode.points, lightPoints, lightPaint);
    }
    if (darkPoints.isNotEmpty) {
      canvas.drawPoints(ui.PointMode.points, darkPoints, darkPaint);
    }
  }

  double _noise(double x, double y) {
    final value = math.sin((x * 12.9898) + (y * 78.233)) * 43758.5453;
    return value - value.floorToDouble();
  }

  @override
  bool shouldRepaint(covariant _PaperGrainPainter oldDelegate) {
    return oldDelegate.lightColor != lightColor ||
        oldDelegate.darkColor != darkColor ||
        oldDelegate.step != step ||
        oldDelegate.lightThreshold != lightThreshold ||
        oldDelegate.darkThreshold != darkThreshold;
  }
}

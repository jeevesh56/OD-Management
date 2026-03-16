import 'dart:math' as math;
import 'package:flutter/material.dart';

class WaveLayer extends StatefulWidget {
  final Color color;

  const WaveLayer({super.key, required this.color});

  @override
  State<WaveLayer> createState() => _WaveLayerState();
}

class _WaveLayerState extends State<WaveLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _WavePainter(
                progress: _controller.value,
                color: widget.color,
              ),
              size: Size(constraints.maxWidth, constraints.maxHeight),
            );
          },
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final Color color;

  _WavePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    const waveCount = 3;
    for (var i = 0; i < waveCount; i++) {
      final path = Path();
      final phase = (progress * 2 * math.pi) + (i * 2 * math.pi / waveCount);
      final amplitude = 40.0 + (i * 15);
      final frequency = 0.008;

      path.moveTo(0, size.height);

      for (var x = 0.0; x <= size.width + 10; x += 5) {
        final y = size.height * 0.6 +
            math.sin(x * frequency + phase) * amplitude +
            math.sin(x * 0.003 + phase * 1.5) * 20;

        path.lineTo(x, y);
      }

      path.lineTo(size.width + 10, size.height);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

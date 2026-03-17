import 'dart:ui';

import 'package:flutter/material.dart';

class WavyCursorBackground extends StatefulWidget {
  const WavyCursorBackground({super.key});

  @override
  State<WavyCursorBackground> createState() => _WavyCursorBackgroundState();
}

class _WavyCursorBackgroundState extends State<WavyCursorBackground> {
  Offset mouse = const Offset(0.5, 0.5);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        final size = MediaQuery.of(context).size;
        setState(() {
          mouse = Offset(
            event.position.dx / size.width,
            event.position.dy / size.height,
          );
        });
      },
      child: Stack(
        children: [
          // WHITE BASE
          Container(color: Colors.white),

          // WAVY COLOR LAYER
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(
                    mouse.dx * 2 - 1,
                    -1,
                  ),
                  end: Alignment(
                    1 - mouse.dx * 2,
                    1,
                  ),
                  colors: [
                    Colors.purpleAccent.withOpacity(0.25),
                    Colors.blueAccent.withOpacity(0.20),
                    Colors.pinkAccent.withOpacity(0.18),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // SMOOTH LIQUID BLUR
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 100,
                  sigmaY: 100,
                ),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

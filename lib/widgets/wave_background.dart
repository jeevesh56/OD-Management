import 'package:flutter/material.dart';

class WaveBackground extends StatefulWidget {
  const WaveBackground({super.key});

  @override
  State<WaveBackground> createState() => _WaveBackgroundState();
}

class _WaveBackgroundState extends State<WaveBackground> {
  Offset mousePos = const Offset(0.5, 0.5);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        final size = MediaQuery.of(context).size;
        setState(() {
          mousePos = Offset(
            event.position.dx / size.width,
            event.position.dy / size.height,
          );
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(
              mousePos.dx * 2 - 1,
              mousePos.dy * 2 - 1,
            ),
            radius: 1.2,
            colors: const [
              Colors.purpleAccent,
              Colors.blueAccent,
              Colors.cyanAccent,
              Colors.transparent,
            ],
            stops: const [0.1, 0.3, 0.6, 1.0],
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.6),
        ),
      ),
    );
  }
}

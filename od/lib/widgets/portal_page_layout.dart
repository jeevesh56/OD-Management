import 'package:flutter/material.dart';

/// Sky gradient + soft circles (student portal design system).
class PortalDecoratedBackground extends StatelessWidget {
  const PortalDecoratedBackground({super.key, this.bottomCircleOffset = 80});

  /// Push bottom circle up on pages with bottom nav.
  final double bottomCircleOffset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xffe9f2ff), Color(0xffffffff)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          right: -80,
          top: -60,
          child: Container(
            height: 280,
            width: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withValues(alpha: 0.08),
            ),
          ),
        ),
        Positioned(
          left: -100,
          bottom: bottomCircleOffset,
          child: Container(
            height: 320,
            width: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withValues(alpha: 0.06),
            ),
          ),
        ),
      ],
    );
  }
}

BoxDecoration portalWhiteCardDecoration({double radius = 20}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: const [
      BoxShadow(blurRadius: 14, color: Colors.black12),
    ],
  );
}

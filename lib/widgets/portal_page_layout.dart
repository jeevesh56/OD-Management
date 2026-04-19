import 'package:flutter/material.dart';

/// Sky gradient + soft circles (student portal design system).
class PortalDecoratedBackground extends StatelessWidget {
  const PortalDecoratedBackground({super.key, this.bottomCircleOffset = 80});

  /// Push bottom circle up on pages with bottom nav.
  final double bottomCircleOffset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.surfaceContainerLowest,
                scheme.surfaceContainerHigh,
              ],
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
              color: scheme.primary.withValues(alpha: 0.10),
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
              color: scheme.primary.withValues(alpha: 0.06),
            ),
          ),
        ),
      ],
    );
  }
}

BoxDecoration portalCardDecoration(BuildContext context, {double radius = 20}) {
  final scheme = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: scheme.surface,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: const [
      BoxShadow(blurRadius: 14, color: Color(0x1F000000)),
    ],
    border: Border.all(color: scheme.outlineVariant),
  );
}

BoxDecoration portalWhiteCardDecoration({double radius = 20}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: const [
      BoxShadow(blurRadius: 14, color: Color(0x1F000000)),
    ],
    border: Border.all(color: const Color(0xFFE7EDF5)),
  );
}

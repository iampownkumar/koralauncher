import 'dart:ui';
import 'package:flutter/material.dart';

class FrostedGlassWidget extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final double overlayOpacity;
  final EdgeInsetsGeometry padding;

  const FrostedGlassWidget({
    super.key,
    required this.child,
    this.blurSigma = 20.0,
    this.overlayOpacity = 0.55,
    this.padding = const EdgeInsets.all(20.0),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: overlayOpacity),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

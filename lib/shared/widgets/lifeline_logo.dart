import 'package:flutter/material.dart';

/// Samay Sarathi logo — rendered from the app_logo.png asset.
class LifelineLogo extends StatelessWidget {
  final double size;

  const LifelineLogo({
    super.key,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/app_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

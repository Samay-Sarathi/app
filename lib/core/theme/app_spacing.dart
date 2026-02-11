import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  // Spacing
  static const double space2xs = 4;
  static const double spaceXs = 8;
  static const double spaceSm = 12;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
  static const double space2xl = 48;

  // Border Radius
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusCard = 20;
  static const double radiusFull = 9999;

  static BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);
  static BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);
  static BorderRadius borderRadiusXl = BorderRadius.circular(radiusXl);
  static BorderRadius borderRadiusCard = BorderRadius.circular(radiusCard);
  static BorderRadius borderRadiusFull = BorderRadius.circular(radiusFull);

  // Shadows (diffuse, modern floating look)
  static const List<BoxShadow> shadowSm = [
    BoxShadow(color: Color(0x08000000), offset: Offset(0, 1), blurRadius: 3),
  ];
  static const List<BoxShadow> shadowMd = [
    BoxShadow(color: Color(0x0A000000), offset: Offset(0, 2), blurRadius: 8),
  ];
  static const List<BoxShadow> shadowLg = [
    BoxShadow(color: Color(0x0F000000), offset: Offset(0, 4), blurRadius: 16),
  ];
  static const List<BoxShadow> shadowXl = [
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 8), blurRadius: 25),
  ];

  // Dark-mode shadows
  static const List<BoxShadow> shadowSmDark = [
    BoxShadow(color: Color(0x20000000), offset: Offset(0, 1), blurRadius: 3),
  ];
  static const List<BoxShadow> shadowMdDark = [
    BoxShadow(color: Color(0x30000000), offset: Offset(0, 2), blurRadius: 8),
  ];
}

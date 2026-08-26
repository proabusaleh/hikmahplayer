import 'package:flutter/material.dart';

abstract final class AppDimensions {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const EdgeInsets screenH = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets cardPadding = EdgeInsets.all(12);

  static const double listItemHeight = 56;
  static const double listItemTallHeight = 72;
  static const double bottomNavHeight = 80;
  static const double appBarHeight = 56;
  static const double fabSize = 56;

  static const double radiusCard = 12;
  static const double radiusButton = 8;
  static const double radiusChip = 24;

  static const double thumbnailVideoAspect = 16 / 9;
  static const double thumbnailMusicAspect = 1.0;
}

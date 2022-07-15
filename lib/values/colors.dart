import 'package:flutter/material.dart';

class CustomColors {
  static const Color colorTheme = Color(0xFF000000);
  static Color tint = Color(0xFFffd1dc).withOpacity(0.25);
  static Color coverTint({Color color, double opacity}) {
    color ??= Color(0xFFff7300);
    opacity ??= 0.1;
    return color.withOpacity(opacity);
  }
  //static const Color tint = Color(0xFFc3e2f6);

  static const Color colorPrimary = Colors.white;
  static const Color colorPrimaryDark = Colors.black;
  static const Color colorGreyedOut = Colors.grey;

  static const Color createGrey = Color(0xFFdbdbdb);
  static const Color chipGrey = Color(0xFFededed);
  static const Color chipText = Color(0xFF3d3d3d);

  static const Color messageSent = Color(0xFFcfffcc);
  static const Color messageReceived = Colors.white;
  static const Color messageSpecial = Colors.cyanAccent;

  static ColorFilter coverFilter = ColorFilter.mode(CustomColors.coverTint(), BlendMode.color);
  static const ColorFilter grayscaleFilter = ColorFilter.mode(Colors.black, BlendMode.color);

  static Color translucent(double opacity) => Colors.white.withOpacity(opacity);
}
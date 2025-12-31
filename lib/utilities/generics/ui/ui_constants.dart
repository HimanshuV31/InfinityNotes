import 'package:flutter/material.dart';

class UIConstants {
  // Icon Shadow for better visibility
  static const List<Shadow> iconShadow = [
    Shadow(
      color: Colors.black54,
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  // Text Shadow for better contrast
  static const List<Shadow> textShadow = [
    Shadow(
      color: Colors.black54,
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
  ];

  // Container Box Shadow for depth
  static const List<BoxShadow> containerShadow = [
    BoxShadow(
      color: Colors.black26,
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 1,
    ),
  ];

  // Strong Shadow for important elements
  static const List<BoxShadow> strongShadow = [
    BoxShadow(
      color: Colors.black38,
      offset: Offset(0, 3),
      blurRadius: 6,
      spreadRadius: 1,
    ),
  ];
}

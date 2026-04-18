import 'package:flutter/material.dart';

class SizeConfig {
  static late double screenWidth;
  static late double screenHeight;
  static late Orientation orientation;

  static late double blockWidth;
  static late double blockHeight;

  static void init(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    orientation = MediaQuery.of(context).orientation;

    // Divide screen into 100 blocks for easy scaling
    blockWidth = screenWidth / 100;
    blockHeight = screenHeight / 100;
  }

  // Helper methods
  static double widthPercent(double percent) => blockWidth * percent;
  static double heightPercent(double percent) => blockHeight * percent;
}

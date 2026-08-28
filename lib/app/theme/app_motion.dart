import 'package:flutter/widgets.dart';

abstract final class AppMotion {
  static const instant = Duration(milliseconds: 120);
  static const interaction = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 220);
  static const structural = Duration(milliseconds: 300);

  static const instantCurve = Curves.easeOut;
  static const interactionCurve = Curves.easeOutCubic;
  static const standardCurve = Cubic(0.20, 0, 0, 1);
  static const structuralCurve = Cubic(0.22, 1, 0.36, 1);

  static Duration responsive(BuildContext context, Duration duration) {
    return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
  }
}

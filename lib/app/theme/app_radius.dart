import 'package:flutter/widgets.dart';

abstract final class AppRadius {
  static const control = BorderRadius.all(Radius.circular(6));
  static const surface = BorderRadius.all(Radius.circular(8));
  static const organicSmall = BorderRadius.only(
    topLeft: Radius.circular(14),
    topRight: Radius.circular(6),
    bottomRight: Radius.circular(14),
    bottomLeft: Radius.circular(6),
  );
  static const organicLarge = BorderRadius.only(
    topLeft: Radius.circular(24),
    topRight: Radius.circular(10),
    bottomRight: Radius.circular(24),
    bottomLeft: Radius.circular(10),
  );
}

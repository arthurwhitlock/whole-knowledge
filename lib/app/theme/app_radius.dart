import 'package:flutter/widgets.dart';

abstract final class AppRadius {
  static const control = BorderRadius.all(Radius.circular(7));
  static const surface = BorderRadius.all(Radius.circular(12));
  static const organicA = BorderRadius.only(
    topLeft: Radius.circular(24),
    topRight: Radius.circular(14),
    bottomRight: Radius.circular(24),
    bottomLeft: Radius.circular(14),
  );
  static const organicB = BorderRadius.only(
    topLeft: Radius.circular(14),
    topRight: Radius.circular(24),
    bottomRight: Radius.circular(14),
    bottomLeft: Radius.circular(24),
  );
}

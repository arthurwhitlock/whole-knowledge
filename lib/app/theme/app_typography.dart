import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

abstract final class AppTypography {
  static const family = 'packages/shadcn_ui/Geist';
  static const labelKey = 'label';
  static const metaKey = 'meta';

  static TextStyle _style({
    required double size,
    required double lineHeight,
    required FontWeight weight,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
    );
  }

  static final theme = ShadTextTheme(
    family: 'Geist',
    package: 'shadcn_ui',
    h1Large: _style(
      size: 34,
      lineHeight: 40,
      weight: FontWeight.w600,
      letterSpacing: -0.6,
    ),
    h1: _style(
      size: 34,
      lineHeight: 40,
      weight: FontWeight.w600,
      letterSpacing: -0.6,
    ),
    h2: _style(
      size: 28,
      lineHeight: 34,
      weight: FontWeight.w600,
      letterSpacing: -0.45,
    ),
    h3: _style(
      size: 21,
      lineHeight: 28,
      weight: FontWeight.w600,
      letterSpacing: -0.25,
    ),
    h4: _style(size: 17, lineHeight: 24, weight: FontWeight.w600),
    p: _style(size: 16, lineHeight: 25, weight: FontWeight.w400),
    lead: _style(size: 18, lineHeight: 27, weight: FontWeight.w400),
    large: _style(size: 17, lineHeight: 24, weight: FontWeight.w600),
    small: _style(
      size: 13,
      lineHeight: 18,
      weight: FontWeight.w600,
      letterSpacing: 0.25,
    ),
    muted: _style(
      size: 13,
      lineHeight: 19,
      weight: FontWeight.w400,
      letterSpacing: 0.1,
    ),
    custom: {
      labelKey: _style(
        size: 13,
        lineHeight: 18,
        weight: FontWeight.w600,
        letterSpacing: 0.25,
      ),
      metaKey: _style(
        size: 13,
        lineHeight: 19,
        weight: FontWeight.w400,
        letterSpacing: 0.1,
      ),
    },
  );
}

extension WholeKnowledgeTypography on ShadTextTheme {
  TextStyle get label => custom[AppTypography.labelKey]!;
  TextStyle get meta => custom[AppTypography.metaKey]!;
}

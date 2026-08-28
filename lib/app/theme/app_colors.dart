import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

abstract final class AppColors {
  static const brandAccentKey = 'brandAccent';
  static const surfaceElevatedKey = 'surfaceElevated';
  static const accentSubtleKey = 'accentSubtle';

  // The accent remains a single replaceable semantic token.
  static const brandAccentLight = Color(0xff76613b);
  static const brandAccentDark = Color(0xffb7a16f);

  static const lightScheme = ShadNeutralColorScheme.light(
    background: Color(0xfff7f3ec),
    foreground: Color(0xff201c17),
    card: Color(0xfffcfaf6),
    cardForeground: Color(0xff201c17),
    popover: Color(0xfffcfaf6),
    popoverForeground: Color(0xff201c17),
    primary: brandAccentLight,
    primaryForeground: Color(0xfffff9f0),
    secondary: Color(0xffeee7dc),
    secondaryForeground: Color(0xff201c17),
    muted: Color(0xffeee7dc),
    mutedForeground: Color(0xff6c655b),
    accent: Color(0xffe8dfd0),
    accentForeground: Color(0xff201c17),
    destructive: Color(0xff9b3d36),
    destructiveForeground: Color(0xfffff9f0),
    border: Color(0xffd8d0c4),
    input: Color(0xffcfc5b6),
    ring: brandAccentLight,
    selection: Color(0xffd9cbaf),
    custom: {
      brandAccentKey: brandAccentLight,
      surfaceElevatedKey: Color(0xffeee7dc),
      accentSubtleKey: Color(0xffe8dfd0),
    },
  );

  static const darkScheme = ShadNeutralColorScheme.dark(
    background: Color(0xff0a0908),
    foreground: Color(0xfff2eee6),
    card: Color(0xff12100e),
    cardForeground: Color(0xfff2eee6),
    popover: Color(0xff191612),
    popoverForeground: Color(0xfff2eee6),
    primary: brandAccentDark,
    primaryForeground: Color(0xff17130d),
    secondary: Color(0xff191612),
    secondaryForeground: Color(0xfff2eee6),
    muted: Color(0xff191612),
    mutedForeground: Color(0xffaaa298),
    accent: Color(0xff292318),
    accentForeground: Color(0xfff2eee6),
    destructive: Color(0xffc97870),
    destructiveForeground: Color(0xff17130d),
    border: Color(0xff302b24),
    input: Color(0xff383129),
    ring: brandAccentDark,
    selection: Color(0xff574a31),
    custom: {
      brandAccentKey: brandAccentDark,
      surfaceElevatedKey: Color(0xff191612),
      accentSubtleKey: Color(0xff292318),
    },
  );
}

extension WholeKnowledgeColors on ShadColorScheme {
  Color get brandAccent => custom[AppColors.brandAccentKey]!;
  Color get surfaceElevated => custom[AppColors.surfaceElevatedKey]!;
  Color get accentSubtle => custom[AppColors.accentSubtleKey]!;
}

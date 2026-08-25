import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

abstract final class AppColors {
  static const brandAccentKey = 'brandAccent';

  // This cool neutral is a replaceable placeholder, not the final brand color.
  static const provisionalBrandAccentLight = Color(0xff475569);
  static const provisionalBrandAccentDark = Color(0xff94a3b8);

  static const lightScheme = ShadNeutralColorScheme.light(
    custom: {brandAccentKey: provisionalBrandAccentLight},
  );

  static const darkScheme = ShadNeutralColorScheme.dark(
    custom: {brandAccentKey: provisionalBrandAccentDark},
  );
}

extension WholeKnowledgeColors on ShadColorScheme {
  Color get brandAccent => custom[AppColors.brandAccentKey]!;
}

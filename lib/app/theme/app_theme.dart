import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:whole_knowledge/app/theme/app_colors.dart';
import 'package:whole_knowledge/app/theme/app_radius.dart';

abstract final class AppTheme {
  static final light = ShadThemeData(
    brightness: Brightness.light,
    colorScheme: AppColors.lightScheme,
    radius: AppRadius.control,
  );

  static final dark = ShadThemeData(
    brightness: Brightness.dark,
    colorScheme: AppColors.darkScheme,
    radius: AppRadius.control,
  );
}

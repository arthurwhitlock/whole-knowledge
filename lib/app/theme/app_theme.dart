import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:whole_knowledge/app/theme/app_colors.dart';
import 'package:whole_knowledge/app/theme/app_radius.dart';
import 'package:whole_knowledge/app/theme/app_typography.dart';

abstract final class AppTheme {
  static final light = ShadThemeData(
    brightness: Brightness.light,
    colorScheme: AppColors.lightScheme,
    radius: AppRadius.control,
    textTheme: AppTypography.theme,
    disabledOpacity: 0.52,
  );

  static final dark = ShadThemeData(
    brightness: Brightness.dark,
    colorScheme: AppColors.darkScheme,
    radius: AppRadius.control,
    textTheme: AppTypography.theme,
    disabledOpacity: 0.52,
  );

  static ThemeData materialTheme(BuildContext context, ThemeData base) {
    final shadTheme = ShadTheme.of(context);
    final colors = shadTheme.colorScheme;
    final labelStyle = shadTheme.textTheme.small;

    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: AppTypography.family),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: colors.background,
        indicatorColor: colors.accent,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.control,
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return labelStyle.copyWith(
            color: selected ? colors.brandAccent : colors.mutedForeground,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 20,
            color: selected ? colors.brandAccent : colors.mutedForeground,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.background,
        indicatorColor: colors.accent,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.control,
        ),
        selectedIconTheme: IconThemeData(size: 20, color: colors.brandAccent),
        unselectedIconTheme: IconThemeData(
          size: 20,
          color: colors.mutedForeground,
        ),
        selectedLabelTextStyle: labelStyle.copyWith(color: colors.brandAccent),
        unselectedLabelTextStyle: labelStyle.copyWith(
          color: colors.mutedForeground,
        ),
      ),
    );
  }
}

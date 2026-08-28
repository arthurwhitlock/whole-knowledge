import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whole_knowledge/app/theme/app_colors.dart';
import 'package:whole_knowledge/app/theme/app_motion.dart';
import 'package:whole_knowledge/app/theme/app_radius.dart';
import 'package:whole_knowledge/app/theme/app_typography.dart';

void main() {
  test('quiet-luxury palettes keep one semantic brand accent', () {
    expect(AppColors.darkScheme.background, const Color(0xff0a0908));
    expect(AppColors.darkScheme.card, const Color(0xff12100e));
    expect(AppColors.darkScheme.foreground, const Color(0xfff2eee6));
    expect(AppColors.darkScheme.brandAccent, const Color(0xffb7a16f));
    expect(AppColors.darkScheme.primary, AppColors.darkScheme.brandAccent);

    expect(AppColors.lightScheme.background, const Color(0xfff7f3ec));
    expect(AppColors.lightScheme.card, const Color(0xfffcfaf6));
    expect(AppColors.lightScheme.foreground, const Color(0xff201c17));
    expect(AppColors.lightScheme.brandAccent, const Color(0xff76613b));
    expect(AppColors.lightScheme.primary, AppColors.lightScheme.brandAccent);
  });

  test('typography and radii preserve the editorial hierarchy', () {
    expect(AppTypography.theme.h1.fontSize, 34);
    expect(AppTypography.theme.h1.fontWeight, FontWeight.w600);
    expect(AppTypography.theme.p.fontSize, 16);
    expect(AppTypography.theme.p.height, closeTo(25 / 16, 0.001));
    expect(AppTypography.theme.label.fontSize, 13);

    expect(AppRadius.control.topLeft.x, 7);
    expect(AppRadius.surface.topLeft.x, 12);
    expect(AppRadius.organicA.topLeft.x, 24);
    expect(AppRadius.organicA.topRight.x, 14);
    expect(AppRadius.organicB.topLeft.x, 14);
    expect(AppRadius.organicB.topRight.x, 24);
  });

  testWidgets('reduced motion removes nonessential transition time', (
    tester,
  ) async {
    late Duration effectiveDuration;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            effectiveDuration = AppMotion.responsive(
              context,
              AppMotion.structural,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(effectiveDuration, Duration.zero);
  });
}

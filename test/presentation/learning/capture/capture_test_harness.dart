import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:whole_knowledge/app/theme/app_theme.dart';
import 'package:whole_knowledge/application/capture/capture_draft.dart';
import 'package:whole_knowledge/application/capture/capture_session_controller.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';
import 'package:whole_knowledge/presentation/learning/capture_screen.dart';

import '../../../support/fakes.dart';

final class CaptureTestHarness {
  CaptureTestHarness({
    required this.controller,
    required this.drafts,
    required this.items,
    required this.lexical,
  });

  final CaptureSessionController controller;
  final FakeCaptureDraftRepository drafts;
  final FakeLearningItemRepository items;
  final FakeLexicalProvider lexical;

  static Future<CaptureTestHarness> create({
    CaptureDraft? draft,
    List<LearningItem> initialItems = const [],
  }) async {
    final drafts = FakeCaptureDraftRepository()..saved = draft;
    final items = FakeLearningItemRepository(initialItems: initialItems);
    final lexical = FakeLexicalProvider();
    final controller = CaptureSessionController(
      drafts,
      lexical,
      items,
      Duration.zero,
    );
    await controller.restore();
    return CaptureTestHarness(
      controller: controller,
      drafts: drafts,
      items: items,
      lexical: lexical,
    );
  }
}

Future<void> pumpCapture(
  WidgetTester tester,
  CaptureSessionController controller, {
  Size size = const Size(720, 900),
  double textScale = 1,
  DateTime Function()? clock,
  bool Function(LearningItem)? onTestItem,
  bool reviewPaused = false,
  VoidCallback? onResumeReview,
  VoidCallback? onCaptured,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    ShadApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      materialThemeBuilder: AppTheme.materialTheme,
      home: Scaffold(
        body: _CaptureOwner(
          controller: controller,
          child: CaptureScreen(
            controller: controller,
            onCaptured: onCaptured ?? () {},
            onTestItem: onTestItem,
            reviewPaused: reviewPaused,
            onResumeReview: onResumeReview,
            clock: clock,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

class _CaptureOwner extends StatefulWidget {
  const _CaptureOwner({required this.controller, required this.child});

  final CaptureSessionController controller;
  final Widget child;

  @override
  State<_CaptureOwner> createState() => _CaptureOwnerState();
}

class _CaptureOwnerState extends State<_CaptureOwner> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

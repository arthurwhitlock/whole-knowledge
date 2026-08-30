import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:whole_knowledge/app/theme/app_motion.dart';
import 'package:whole_knowledge/app/theme/app_spacing.dart';
import 'package:whole_knowledge/application/capture/capture_session_controller.dart';
import 'package:whole_knowledge/application/capture/capture_session_state.dart';
import 'package:whole_knowledge/presentation/components/compact_editing_context_menu.dart';
import 'package:whole_knowledge/presentation/learning/capture/capture_chrome.dart';
import 'package:whole_knowledge/presentation/learning/capture/encounter_details.dart';

class CaptureExpressionMeaningView extends StatefulWidget {
  const CaptureExpressionMeaningView({
    required this.controller,
    required this.state,
    super.key,
  });

  final CaptureSessionController controller;
  final CaptureExpressionMeaning state;

  @override
  State<CaptureExpressionMeaningView> createState() =>
      _CaptureExpressionMeaningViewState();
}

class _CaptureExpressionMeaningViewState
    extends State<CaptureExpressionMeaningView> {
  final _meaning = TextEditingController();
  final _meaningFocus = FocusNode();
  final _meaningKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _sync();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _meaningFocus.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant CaptureExpressionMeaningView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _meaning.dispose();
    _meaningFocus.dispose();
    super.dispose();
  }

  void _sync() {
    final value = widget.controller.draft.meaning;
    if (_meaning.text == value) return;
    _meaning.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _continue() {
    if (widget.controller.continueToProduction()) return;
    _meaningFocus.requestFocus();
    final target = _meaningKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        alignment: 0.18,
        duration: AppMotion.responsive(context, AppMotion.standard),
        curve: AppMotion.standardCurve,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final theme = ShadTheme.of(context);
    return CapturePageLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CaptureOrientation(
            onBack: controller.back,
            restored: controller.restored,
          ),
          const SizedBox(height: AppSpacing.page),
          CaptureSubject(
            content: controller.draft.content,
            kind: controller.draft.kind,
            kindWasOverridden: controller.kindWasOverridden,
            onChangeKind: controller.updateKind,
          ),
          const SizedBox(height: AppSpacing.page),
          const CaptureTaskHeading(
            title: 'What does it mean here?',
            prompt: 'Explain this expression in the way you encountered it.',
          ),
          const SizedBox(height: AppSpacing.pageCompact),
          CaptureLibraryStatus(
            outcome: widget.state.library,
            onRetry: controller.retryLibrary,
          ),
          const SizedBox(height: AppSpacing.regular),
          CaptureFieldLabel('Meaning', required: true, key: _meaningKey),
          const SizedBox(height: AppSpacing.compact),
          ShadTextarea(
            key: const ValueKey('capture-meaning'),
            controller: _meaning,
            focusNode: _meaningFocus,
            contextMenuBuilder: compactEditingContextMenu,
            placeholder: const Text('Explain the meaning you encountered'),
            minHeight: 112,
            maxHeight: 240,
            onChanged: controller.updateMeaning,
          ),
          CaptureInlineError(controller.saveError),
          if (controller.draft.meaning.trim().isNotEmpty) ...[
            if (!controller.draft.isMeaningConfirmed) ...[
              const SizedBox(height: AppSpacing.regular),
              Semantics(
                liveRegion: true,
                child: Text(
                  'Review this meaning for Expression',
                  style: theme.textTheme.small,
                ),
              ),
              const SizedBox(height: AppSpacing.compact),
              ShadButton.outline(
                key: const ValueKey('confirm-current-meaning'),
                onPressed: controller.confirmMeaning,
                child: const Text('Use this meaning'),
              ),
            ],
            const SizedBox(height: AppSpacing.pageCompact),
            CaptureEncounterDetails(controller: controller),
            const SizedBox(height: AppSpacing.pageCompact),
            CaptureAdaptiveActions(
              primary: ShadButton(
                key: const ValueKey('continue-to-production'),
                onPressed: _continue,
                child: const Text('Continue to production'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

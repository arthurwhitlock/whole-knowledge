import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:whole_knowledge/app/theme/app_motion.dart';
import 'package:whole_knowledge/app/theme/app_spacing.dart';
import 'package:whole_knowledge/app/theme/app_typography.dart';
import 'package:whole_knowledge/application/capture/capture_session_controller.dart';
import 'package:whole_knowledge/application/capture/capture_session_state.dart';
import 'package:whole_knowledge/presentation/components/compact_editing_context_menu.dart';
import 'package:whole_knowledge/presentation/learning/capture/capture_chrome.dart';

class CaptureProductionView extends StatefulWidget {
  const CaptureProductionView({required this.controller, super.key});

  final CaptureSessionController controller;

  @override
  State<CaptureProductionView> createState() => _CaptureProductionViewState();
}

class _CaptureProductionViewState extends State<CaptureProductionView> {
  final _production = TextEditingController();
  final _productionFocus = FocusNode();
  final _productionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _sync();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _productionFocus.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant CaptureProductionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _production.dispose();
    _productionFocus.dispose();
    super.dispose();
  }

  void _sync() {
    final value = widget.controller.draft.production;
    if (_production.text == value) return;
    _production.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> _complete({required bool defer}) async {
    await widget.controller.completeDiscovery(deferProduction: defer);
    if (!mounted || widget.controller.state is! CaptureProduction) return;
    if (defer && widget.controller.saveError == null) return;
    _productionFocus.requestFocus();
    final target = _productionKey.currentContext;
    final duration = AppMotion.responsive(context, AppMotion.standard);
    if (target != null && target.mounted) {
      await Scrollable.ensureVisible(
        target,
        alignment: 0.15,
        duration: duration,
        curve: AppMotion.standardCurve,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final draft = controller.draft;
    final theme = ShadTheme.of(context);
    final libraryReady = controller.libraryOutcome is LibraryNoMatch;
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
            content: draft.content,
            kind: draft.kind,
            kindWasOverridden: controller.kindWasOverridden,
            onChangeKind: controller.updateKind,
          ),
          const SizedBox(height: AppSpacing.regular),
          if (draft.partOfSpeech != null)
            Text(draft.partOfSpeech!, style: theme.textTheme.label),
          const SizedBox(height: AppSpacing.compact),
          Text(draft.meaning, style: theme.textTheme.p),
          if (!draft.isMeaningConfirmed) ...[
            const SizedBox(height: AppSpacing.regular),
            Semantics(
              liveRegion: true,
              child: Text(
                'Review this meaning for ${draft.kind.name == 'vocabulary' ? 'Vocabulary' : 'Expression'}',
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
          const SizedBox(height: AppSpacing.page),
          CaptureTaskHeading(
            title: draft.kind.name == 'vocabulary'
                ? 'Use it in your own sentence'
                : 'Use the expression in your own sentence',
            prompt:
                'Write what you would naturally say. It is not graded here.',
          ),
          const SizedBox(height: AppSpacing.pageCompact),
          CaptureFieldLabel(
            'First production',
            required: true,
            key: _productionKey,
          ),
          const SizedBox(height: AppSpacing.compact),
          ShadTextarea(
            key: const ValueKey('first-production'),
            controller: _production,
            focusNode: _productionFocus,
            contextMenuBuilder: compactEditingContextMenu,
            placeholder: Text(
              draft.kind.name == 'vocabulary'
                  ? 'Use “${draft.content.trim()}” in a sentence'
                  : 'Use this expression in a sentence',
            ),
            minHeight: 128,
            maxHeight: 300,
            onChanged: controller.updateProduction,
          ),
          if (draft.production.trim().isNotEmpty &&
              !draft.isProductionConfirmed) ...[
            const SizedBox(height: AppSpacing.regular),
            Semantics(
              liveRegion: true,
              child: Text(
                'Review whether this sentence still fits the current meaning.',
                style: theme.textTheme.small,
              ),
            ),
            const SizedBox(height: AppSpacing.compact),
            ShadButton.outline(
              key: const ValueKey('confirm-current-production'),
              onPressed: controller.confirmProduction,
              child: const Text('This sentence still fits'),
            ),
          ],
          CaptureInlineError(controller.saveError),
          const SizedBox(height: AppSpacing.regular),
          CaptureLibraryStatus(
            outcome: controller.libraryOutcome,
            onRetry: controller.retryLibrary,
          ),
          const SizedBox(height: AppSpacing.pageCompact),
          CaptureAdaptiveActions(
            primary: ShadButton(
              key: const ValueKey('complete-discovery'),
              enabled: libraryReady,
              onPressed: () => _complete(defer: false),
              child: const Text('Complete discovery'),
            ),
            secondary: ShadButton.outline(
              key: const ValueKey('defer-production'),
              enabled: libraryReady,
              onPressed: () => _complete(defer: true),
              child: const Text('Save and finish later'),
            ),
          ),
        ],
      ),
    );
  }
}

class CaptureSubmissionView extends StatelessWidget {
  const CaptureSubmissionView({
    required this.controller,
    required this.state,
    super.key,
  });

  final CaptureSessionController controller;
  final CaptureSessionState state;

  @override
  Widget build(BuildContext context) {
    final reconciling = state is CaptureReconciling;
    return CapturePageLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CaptureOrientation(),
          const SizedBox(height: AppSpacing.page),
          CaptureSubject(
            content: controller.draft.content,
            kind: controller.draft.kind,
            kindWasOverridden: controller.kindWasOverridden,
          ),
          const SizedBox(height: AppSpacing.page),
          CaptureTaskHeading(
            title: reconciling ? 'Confirming discovery' : 'Saving discovery',
            prompt: reconciling
                ? 'The same secured submission will be checked again.'
                : 'Your authored details are secured locally before completion.',
          ),
          const SizedBox(height: AppSpacing.regular),
          if (controller.draft.partOfSpeech != null)
            Text(
              controller.draft.partOfSpeech!,
              style: ShadTheme.of(context).textTheme.label,
            ),
          const SizedBox(height: AppSpacing.compact),
          Text(
            controller.draft.meaning,
            style: ShadTheme.of(context).textTheme.p,
          ),
          if (controller.draft.context.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.regular),
            Text(
              controller.draft.context,
              style: ShadTheme.of(context).textTheme.p,
            ),
          ],
          if (controller.draft.source.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.compact),
            Text(
              controller.draft.source,
              style: ShadTheme.of(context).textTheme.muted,
            ),
          ],
          if (controller.draft.production.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.regular),
            Text(
              '“${controller.draft.production}”',
              style: ShadTheme.of(context).textTheme.lead,
            ),
          ],
          const SizedBox(height: AppSpacing.regular),
          CaptureServiceStatus(
            label: reconciling ? 'Outcome needs confirmation' : 'Saving',
            progress: !reconciling,
            error: reconciling ? controller.saveError : null,
          ),
          if (reconciling) ...[
            const SizedBox(height: AppSpacing.pageCompact),
            ShadButton(
              key: const ValueKey('retry-discovery-submission'),
              onPressed: controller.retrySubmission,
              child: const Text('Retry confirmation'),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:whole_knowledge/app/theme/app_motion.dart';
import 'package:whole_knowledge/app/theme/app_spacing.dart';
import 'package:whole_knowledge/app/theme/app_typography.dart';
import 'package:whole_knowledge/application/capture/capture_session_controller.dart';
import 'package:whole_knowledge/application/capture/capture_session_state.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';
import 'package:whole_knowledge/presentation/components/compact_editing_context_menu.dart';
import 'package:whole_knowledge/presentation/learning/capture/capture_chrome.dart';

class CaptureEntryCheckingView extends StatefulWidget {
  const CaptureEntryCheckingView({
    required this.controller,
    required this.state,
    super.key,
  });

  final CaptureSessionController controller;
  final CaptureSessionState state;

  @override
  State<CaptureEntryCheckingView> createState() =>
      _CaptureEntryCheckingViewState();
}

class _CaptureEntryCheckingViewState extends State<CaptureEntryCheckingView> {
  final _content = TextEditingController();
  final _contentFocus = FocusNode();
  final _contentKey = GlobalKey();

  bool get _checking => widget.state is CaptureChecking;

  @override
  void initState() {
    super.initState();
    _sync();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusEntry());
  }

  @override
  void didUpdateWidget(covariant CaptureEntryCheckingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
    if (oldWidget.state is CaptureChecking && widget.state is CaptureEntry) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusEntry());
    }
  }

  @override
  void dispose() {
    _content.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  void _sync() {
    final value = widget.controller.draft.content;
    if (_content.text == value) return;
    _content.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _focusEntry() {
    if (mounted && !_checking) _contentFocus.requestFocus();
  }

  Future<void> _discover() async {
    await widget.controller.discover();
    if (!mounted || widget.controller.contentError == null) return;
    _focusInvalidContent();
  }

  Future<void> _discoverManually() async {
    await widget.controller.discoverManually();
    if (!mounted || widget.controller.contentError == null) return;
    _focusInvalidContent();
  }

  void _focusInvalidContent() {
    _contentFocus.requestFocus();
    final target = _contentKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      alignment: 0.16,
      duration: AppMotion.responsive(context, AppMotion.standard),
      curve: AppMotion.standardCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final controller = widget.controller;
    final currentKind = controller.draft.kind;
    final label = currentKind == LearningItemKind.vocabulary
        ? 'Vocabulary'
        : 'Expression';
    final alternate = currentKind == LearningItemKind.vocabulary
        ? LearningItemKind.expression
        : LearningItemKind.vocabulary;
    final alternateLabel = alternate == LearningItemKind.vocabulary
        ? 'Vocabulary discovery'
        : 'Expression';
    final enlarged = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return CapturePageLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CaptureOrientation(
            restored: switch (widget.state) {
              CaptureEntry(:final restored) => restored,
              _ => false,
            },
          ),
          const SizedBox(height: AppSpacing.section),
          if (_checking) ...[
            CaptureSubject(
              content: controller.draft.content,
              kind: currentKind,
              kindWasOverridden: controller.kindWasOverridden,
              onChangeKind: controller.updateKind,
            ),
            const SizedBox(height: AppSpacing.page),
            const CaptureTaskHeading(
              title: 'Checking this encounter',
              prompt:
                  'Your Library and English meanings are checked separately.',
            ),
            const SizedBox(height: AppSpacing.regular),
            _CheckingStatuses(
              controller: controller,
              state: widget.state as CaptureChecking,
            ),
          ] else ...[
            const CaptureTaskHeading(
              title: 'What did you encounter?',
              liveRegion: false,
            ),
            const SizedBox(height: AppSpacing.pageCompact),
            CaptureFieldLabel('Language', required: true, key: _contentKey),
            const SizedBox(height: AppSpacing.compact),
            Semantics(
              textField: true,
              label: 'Language, required',
              child: ShadInput(
                key: const ValueKey('capture-content'),
                controller: _content,
                focusNode: _contentFocus,
                contextMenuBuilder: compactEditingContextMenu,
                placeholder: const Text('A word or expression'),
                textInputAction: TextInputAction.done,
                onChanged: controller.updateContent,
                onSubmitted: (_) => _discover(),
              ),
            ),
            CaptureInlineError(controller.contentError),
            const SizedBox(height: AppSpacing.compact),
            Wrap(
              spacing: AppSpacing.regular,
              runSpacing: AppSpacing.compact,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Semantics(
                  label: controller.kindWasOverridden
                      ? 'Current type: $label'
                      : 'Suggested type: $label',
                  child: Text(
                    controller.kindWasOverridden ? label : '$label suggested',
                    style: theme.textTheme.label,
                  ),
                ),
                ShadButton.link(
                  key: const ValueKey('change-discovery-type'),
                  height: enlarged ? 0 : 48,
                  onPressed: () => controller.updateKind(alternate),
                  child: CaptureButtonLabel('Use $alternateLabel'),
                ),
              ],
            ),
            if ((widget.state as CaptureEntry).failure != null) ...[
              const SizedBox(height: AppSpacing.regular),
              const CaptureInlineError('Could not restore this draft.'),
            ],
            const SizedBox(height: AppSpacing.pageCompact),
            CaptureAdaptiveActions(
              primary: ShadButton(
                key: const ValueKey('discover-language'),
                height: enlarged ? 0 : 48,
                onPressed: _discover,
                trailing: const Icon(Icons.arrow_forward, size: 18),
                child: const CaptureButtonLabel('Discover'),
              ),
              secondary: ShadButton.ghost(
                key: const ValueKey('enter-meaning-manually'),
                height: enlarged ? 0 : 48,
                onPressed: _discoverManually,
                child: const CaptureButtonLabel('Enter meaning manually'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CheckingStatuses extends StatelessWidget {
  const _CheckingStatuses({required this.controller, required this.state});

  final CaptureSessionController controller;
  final CaptureChecking state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        switch (state.library) {
          LibraryPending() => const CaptureServiceStatus(
            key: ValueKey('library-pending'),
            label: 'Checking your Library',
            progress: true,
          ),
          LibraryNoMatch() => const CaptureServiceStatus(
            key: ValueKey('library-clear'),
            label: 'No exact Library match',
          ),
          LibraryFailed() => CaptureServiceStatus(
            key: const ValueKey('library-failed'),
            label: 'Library check unavailable',
            error: 'Could not check your Library.',
            onRetry: controller.retryLibrary,
          ),
          LibraryMatches() => const CaptureServiceStatus(
            label: 'Already in your Library',
          ),
        },
        if (controller.draft.kind == LearningItemKind.vocabulary)
          switch (state.lexical) {
            LexicalPending() => const CaptureServiceStatus(
              key: ValueKey('lexical-pending'),
              label: 'Finding English meanings',
              progress: true,
            ),
            LexicalFound() => const CaptureServiceStatus(
              label: 'English meanings ready',
            ),
            LexicalFailed() => CaptureServiceStatus(
              key: const ValueKey('lexical-failed'),
              label: 'English meanings unavailable',
              error:
                  controller.lookupError ?? 'Could not find English meanings.',
              onRetry: controller.retryLexical,
            ),
            LexicalSkipped() => const SizedBox.shrink(),
          },
      ],
    );
  }
}

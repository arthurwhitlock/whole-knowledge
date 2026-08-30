import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:whole_knowledge/app/theme/app_colors.dart';
import 'package:whole_knowledge/app/theme/app_spacing.dart';
import 'package:whole_knowledge/app/theme/app_typography.dart';
import 'package:whole_knowledge/application/capture/capture_session_controller.dart';
import 'package:whole_knowledge/application/capture/capture_session_state.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';
import 'package:whole_knowledge/presentation/learning/capture/capture_chrome.dart';
import 'package:whole_knowledge/presentation/learning/capture/relative_calendar_time.dart';

class CaptureReEncounterView extends StatefulWidget {
  const CaptureReEncounterView({
    required this.controller,
    required this.state,
    required this.now,
    this.onTestItem,
    this.reviewPaused = false,
    this.onResumeReview,
    super.key,
  });

  final CaptureSessionController controller;
  final CaptureReEncounter state;
  final DateTime now;
  final bool Function(LearningItem)? onTestItem;
  final bool reviewPaused;
  final VoidCallback? onResumeReview;

  @override
  State<CaptureReEncounterView> createState() => _CaptureReEncounterViewState();
}

class _CaptureReEncounterViewState extends State<CaptureReEncounterView> {
  final _headingFocus = FocusNode();
  final _meaningFocus = FocusNode();
  final _revealControlFocus = FocusNode();
  String? _reviewMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _headingFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _headingFocus.dispose();
    _meaningFocus.dispose();
    _revealControlFocus.dispose();
    super.dispose();
  }

  void _showMeaning() {
    widget.controller.showMeaning();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _meaningFocus.requestFocus();
    });
  }

  void _hideMeaning() {
    widget.controller.hideMeaning();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _revealControlFocus.requestFocus();
    });
  }

  void _testMyself() {
    final item = widget.state.choice.item;
    if (item == null || widget.onTestItem == null) return;
    if (widget.onTestItem!(item)) {
      setState(() => _reviewMessage = null);
      return;
    }
    setState(() {
      _reviewMessage = 'A paused Review is already waiting. Resume it before starting another.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final selected = widget.state.choice.item;
    final revealed = widget.state.choice.kind == ReEncounterChoiceKind.revealed;
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
          CaptureTaskHeading(
            title: 'Already in your knowledge',
            prompt: widget.state.items.length == 1
                ? 'Choose what you want to do with this learned sense.'
                : 'Select a learned sense, or add another one.',
            focusNode: _headingFocus,
          ),
          const SizedBox(height: AppSpacing.pageCompact),
          for (final item in widget.state.items)
            _LearnedSenseRow(
              item: item,
              selected: selected?.id == item.id,
              now: widget.now,
              onSelected: () {
                widget.controller.selectReEncounterItem(item);
                setState(() => _reviewMessage = null);
              },
            ),
          const SizedBox(height: AppSpacing.pageCompact),
          if (selected == null)
            ShadButton.ghost(
              key: const ValueKey('learn-another-sense'),
              onPressed: controller.learnAnotherSense,
              child: const Text('Learn another sense'),
            )
          else
            CaptureAdaptiveActions(
              primary: ShadButton(
                key: const ValueKey('test-myself'),
                enabled: widget.onTestItem != null,
                onPressed: _testMyself,
                child: const Text('Test myself'),
              ),
              secondary: Focus(
                focusNode: _revealControlFocus,
                child: ShadButton.outline(
                  key: const ValueKey('toggle-reencounter-meaning'),
                  onPressed: revealed ? _hideMeaning : _showMeaning,
                  child: Text(revealed ? 'Hide meaning' : 'Show meaning'),
                ),
              ),
              tertiary: ShadButton.ghost(
                key: const ValueKey('learn-another-sense'),
                onPressed: controller.learnAnotherSense,
                child: const Text('Learn another sense'),
              ),
            ),
          if (_reviewMessage != null || widget.reviewPaused) ...[
            const SizedBox(height: AppSpacing.regular),
            CaptureInlineError(
              _reviewMessage ??
                  'Your Review is paused with its response intact.',
            ),
            if (widget.reviewPaused && widget.onResumeReview != null) ...[
              const SizedBox(height: AppSpacing.compact),
              ShadButton.outline(
                key: const ValueKey('resume-targeted-review'),
                onPressed: widget.onResumeReview,
                child: const Text('Resume review'),
              ),
            ],
          ],
          if (revealed && selected != null) ...[
            const SizedBox(height: AppSpacing.pageCompact),
            _RevealedMeaning(item: selected, focusNode: _meaningFocus),
          ],
        ],
      ),
    );
  }
}

class _LearnedSenseRow extends StatelessWidget {
  const _LearnedSenseRow({
    required this.item,
    required this.selected,
    required this.now,
    required this.onSelected,
  });

  final LearningItem item;
  final bool selected;
  final DateTime now;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final captured = localizations.formatShortDate(item.createdAt.toLocal());
    final reviewed = item.lastReviewedAt == null
        ? null
        : RelativeCalendarTime.format(item.lastReviewedAt!, now, localizations);
    final contextCue = item.source?.trim().isNotEmpty == true
        ? 'Captured from ${item.source!.trim()}'
        : item.context?.trim().isNotEmpty == true
        ? item.context!.trim()
        : 'Captured $captured';
    return Semantics(
      button: true,
      selected: selected,
      label: [
        if (item.partOfSpeech != null) item.partOfSpeech!,
        contextCue,
        if (reviewed != null) 'Last reviewed ${reviewed.semantic}',
      ].join('. '),
      child: InkWell(
        onTap: onSelected,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.regular,
            vertical: AppSpacing.regular,
          ),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.accentSubtle : null,
            border: Border(
              left: BorderSide(
                color: selected
                    ? theme.colorScheme.brandAccent
                    : Colors.transparent,
                width: 2,
              ),
              bottom: BorderSide(color: theme.colorScheme.border),
            ),
          ),
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.partOfSpeech != null)
                  Text(
                    item.partOfSpeech!.toUpperCase(),
                    style: theme.textTheme.label,
                  ),
                if (item.partOfSpeech != null)
                  const SizedBox(height: AppSpacing.compact),
                Text(contextCue, style: theme.textTheme.p),
                if (reviewed != null) ...[
                  const SizedBox(height: AppSpacing.tight),
                  Text(
                    'Last reviewed ${reviewed.visual}',
                    style: theme.textTheme.muted,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RevealedMeaning extends StatelessWidget {
  const _RevealedMeaning({required this.item, required this.focusNode});

  final LearningItem item;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Focus(
      focusNode: focusNode,
      child: Semantics(
        child: Column(
          key: const ValueKey('revealed-learned-meaning'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Meaning', style: theme.textTheme.h3),
            const SizedBox(height: AppSpacing.compact),
            Text(
              item.meaning ?? 'No meaning was captured.',
              style: theme.textTheme.p,
            ),
            if (item.context?.trim().isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.regular),
              Text('Encounter context', style: theme.textTheme.label),
              const SizedBox(height: AppSpacing.compact),
              Text(item.context!, style: theme.textTheme.p),
            ],
            if (item.source?.trim().isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.regular),
              Text('Source', style: theme.textTheme.label),
              const SizedBox(height: AppSpacing.compact),
              Text(item.source!, style: theme.textTheme.p),
            ],
            if (item.firstProduction?.trim().isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.regular),
              Text('First production', style: theme.textTheme.label),
              const SizedBox(height: AppSpacing.compact),
              Text('“${item.firstProduction!}”', style: theme.textTheme.p),
            ],
          ],
        ),
      ),
    );
  }
}

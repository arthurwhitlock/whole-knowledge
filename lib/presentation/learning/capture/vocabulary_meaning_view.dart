import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:whole_knowledge/app/theme/app_colors.dart';
import 'package:whole_knowledge/app/theme/app_motion.dart';
import 'package:whole_knowledge/app/theme/app_spacing.dart';
import 'package:whole_knowledge/app/theme/app_typography.dart';
import 'package:whole_knowledge/application/capture/capture_session_controller.dart';
import 'package:whole_knowledge/application/capture/capture_session_state.dart';
import 'package:whole_knowledge/application/capture/lexical_provider.dart';
import 'package:whole_knowledge/presentation/components/compact_editing_context_menu.dart';
import 'package:whole_knowledge/presentation/learning/capture/capture_chrome.dart';
import 'package:whole_knowledge/presentation/learning/capture/encounter_details.dart';

class CaptureVocabularyMeaningView extends StatefulWidget {
  const CaptureVocabularyMeaningView({
    required this.controller,
    required this.state,
    super.key,
  });

  final CaptureSessionController controller;
  final CaptureVocabularySenses state;

  @override
  State<CaptureVocabularyMeaningView> createState() =>
      _CaptureVocabularyMeaningViewState();
}

class _CaptureVocabularyMeaningViewState
    extends State<CaptureVocabularyMeaningView> {
  final _expandedGroups = <int>{};
  final _meaning = TextEditingController();
  final _partOfSpeech = TextEditingController();
  final _meaningFocus = FocusNode();
  final _headingFocus = FocusNode();
  final _meaningKey = GlobalKey();
  bool _editingMeaning = false;

  @override
  void initState() {
    super.initState();
    _editingMeaning = _manualEditorRequired(widget.state);
    _sync();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusInitial());
  }

  @override
  void didUpdateWidget(covariant CaptureVocabularyMeaningView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
    if (_manualEditorRequired(widget.state)) _editingMeaning = true;
  }

  @override
  void dispose() {
    _meaning.dispose();
    _partOfSpeech.dispose();
    _meaningFocus.dispose();
    _headingFocus.dispose();
    super.dispose();
  }

  static bool _manualEditorRequired(CaptureVocabularySenses state) =>
      state.meaningChoice.kind == MeaningChoiceKind.manual ||
      state.lexical is LexicalFailed ||
      state.lexical is LexicalSkipped;

  void _sync() {
    _replace(_meaning, widget.controller.draft.meaning);
    _replace(_partOfSpeech, widget.controller.draft.partOfSpeech ?? '');
  }

  static void _replace(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _focusInitial() {
    if (!mounted) return;
    if (_editingMeaning) {
      _meaningFocus.requestFocus();
    } else {
      _headingFocus.requestFocus();
    }
  }

  void _openManual() {
    widget.controller.chooseManualMeaning();
    setState(() => _editingMeaning = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _meaningFocus.requestFocus();
    });
  }

  void _editSelected() {
    setState(() => _editingMeaning = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _meaningFocus.requestFocus();
    });
  }

  void _finishEditing() {
    widget.controller.confirmMeaning();
    if (widget.state.meaningChoice.kind == MeaningChoiceKind.provider) {
      setState(() => _editingMeaning = false);
    }
  }

  void _continue() {
    if (widget.controller.continueToProduction()) return;
    _meaningFocus.requestFocus();
    final target = _meaningKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        alignment: 0.2,
        duration: AppMotion.responsive(context, AppMotion.standard),
        curve: AppMotion.standardCurve,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final theme = ShadTheme.of(context);
    final lookup = controller.lookup;
    final choice = widget.state.meaningChoice;
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
            title: 'Choose the meaning you encountered',
            prompt: 'English dictionary order is preserved.',
            focusNode: _headingFocus,
          ),
          const SizedBox(height: AppSpacing.regular),
          CaptureLibraryStatus(
            outcome: widget.state.library,
            onRetry: controller.retryLibrary,
          ),
          if (widget.state.lexical is LexicalPending)
            const CaptureServiceStatus(
              key: ValueKey('lexical-pending'),
              label: 'Finding English meanings',
              progress: true,
            ),
          if (widget.state.lexical is LexicalFailed)
            CaptureServiceStatus(
              key: const ValueKey('lexical-failed'),
              label: 'English meanings unavailable',
              error:
                  controller.lookupError ?? 'No English entry was available.',
              onRetry: controller.retryLexical,
            ),
          if (lookup != null) ...[
            const SizedBox(height: AppSpacing.regular),
            for (var index = 0; index < lookup.groups.length; index++) ...[
              _SenseGroup(
                groupIndex: index,
                group: lookup.groups[index],
                expanded: _expandedGroups.contains(index),
                selected: choice.sense,
                onToggle: () {
                  setState(() {
                    if (!_expandedGroups.add(index)) {
                      _expandedGroups.remove(index);
                    }
                  });
                },
                onSelected: controller.selectSense,
              ),
              if (index < lookup.groups.length - 1)
                const SizedBox(height: AppSpacing.pageCompact),
            ],
            const SizedBox(height: AppSpacing.compact),
            Text(controller.lookupAttribution, style: theme.textTheme.meta),
          ],
          const SizedBox(height: AppSpacing.regular),
          ShadButton.ghost(
            key: const ValueKey('manual-meaning'),
            onPressed: _openManual,
            child: const Text('Enter meaning manually'),
          ),
          if (choice.kind == MeaningChoiceKind.replacementPending) ...[
            const SizedBox(height: AppSpacing.regular),
            Semantics(
              liveRegion: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Replace your edited meaning with this sense?',
                    style: theme.textTheme.small,
                  ),
                  const SizedBox(height: AppSpacing.compact),
                  Wrap(
                    spacing: AppSpacing.compact,
                    children: [
                      ShadButton.outline(
                        key: const ValueKey('keep-edited-meaning'),
                        onPressed: () {
                          controller.keepEditingMeaning();
                          _editSelected();
                        },
                        child: const Text('Keep editing'),
                      ),
                      ShadButton(
                        key: const ValueKey('replace-edited-meaning'),
                        onPressed: () {
                          controller.replaceMeaning();
                          setState(() => _editingMeaning = false);
                        },
                        child: const Text('Replace'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (choice.kind == MeaningChoiceKind.provider &&
              !_editingMeaning) ...[
            const SizedBox(height: AppSpacing.pageCompact),
            _SelectedMeaningSummary(
              partOfSpeech: controller.draft.partOfSpeech,
              meaning: controller.draft.meaning,
              onEdit: _editSelected,
            ),
          ],
          if (_editingMeaning) ...[
            const SizedBox(height: AppSpacing.pageCompact),
            KeyedSubtree(
              key: _meaningKey,
              child: _MeaningEditor(
                meaning: _meaning,
                partOfSpeech: _partOfSpeech,
                meaningFocus: _meaningFocus,
                onMeaningChanged: controller.updateMeaning,
                onPartOfSpeechChanged: (value) => controller.update(
                  controller.draft.copyWith(
                    partOfSpeech: value,
                    clearPartOfSpeech: value.trim().isEmpty,
                  ),
                ),
                onUse: _finishEditing,
              ),
            ),
          ],
          CaptureInlineError(controller.saveError),
          if (controller.draft.meaning.trim().isNotEmpty) ...[
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

class _SenseGroup extends StatelessWidget {
  const _SenseGroup({
    required this.groupIndex,
    required this.group,
    required this.expanded,
    required this.selected,
    required this.onToggle,
    required this.onSelected,
  });

  final int groupIndex;
  final LexicalPartOfSpeechGroup group;
  final bool expanded;
  final LexicalSense? selected;
  final VoidCallback onToggle;
  final ValueChanged<LexicalSense> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final visible = expanded ? group.senses : group.senses.take(2);
    final hidden = group.senses.length - 2;
    return Column(
      key: ValueKey('sense-group-$groupIndex'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(group.name.toUpperCase(), style: theme.textTheme.label),
        const SizedBox(height: AppSpacing.compact),
        for (final sense in visible)
          _SenseRow(
            sense: sense,
            selected: identical(selected, sense),
            onSelected: () => onSelected(sense),
          ),
        if (hidden > 0)
          Semantics(
            expanded: expanded,
            child: ShadButton.ghost(
              key: ValueKey('expand-senses-$groupIndex'),
              onPressed: onToggle,
              child: Text(expanded ? 'Show fewer' : 'Show $hidden more'),
            ),
          ),
      ],
    );
  }
}

class _SenseRow extends StatelessWidget {
  const _SenseRow({
    required this.sense,
    required this.selected,
    required this.onSelected,
  });

  final LexicalSense sense;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${sense.definition}${sense.example == null ? '' : '. Example: ${sense.example}'}',
      child: InkWell(
        onTap: onSelected,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.regular,
            vertical: AppSpacing.compact,
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
                Text(sense.definition, style: theme.textTheme.p),
                if (sense.example != null) ...[
                  const SizedBox(height: AppSpacing.tight),
                  Text(sense.example!, style: theme.textTheme.muted),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedMeaningSummary extends StatelessWidget {
  const _SelectedMeaningSummary({
    required this.partOfSpeech,
    required this.meaning,
    required this.onEdit,
  });

  final String? partOfSpeech;
  final String meaning;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      key: const ValueKey('selected-meaning-summary'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Selected meaning', style: theme.textTheme.h4),
        if (partOfSpeech != null) ...[
          const SizedBox(height: AppSpacing.compact),
          Text(partOfSpeech!, style: theme.textTheme.label),
        ],
        const SizedBox(height: AppSpacing.compact),
        Text(meaning, style: theme.textTheme.p),
        const SizedBox(height: AppSpacing.compact),
        ShadButton.ghost(
          key: const ValueKey('edit-selected-meaning'),
          onPressed: onEdit,
          child: const Text('Edit meaning'),
        ),
      ],
    );
  }
}

class _MeaningEditor extends StatelessWidget {
  const _MeaningEditor({
    required this.meaning,
    required this.partOfSpeech,
    required this.meaningFocus,
    required this.onMeaningChanged,
    required this.onPartOfSpeechChanged,
    required this.onUse,
  });

  final TextEditingController meaning;
  final TextEditingController partOfSpeech;
  final FocusNode meaningFocus;
  final ValueChanged<String> onMeaningChanged;
  final ValueChanged<String> onPartOfSpeechChanged;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your meaning', style: theme.textTheme.h4),
        const SizedBox(height: AppSpacing.regular),
        const CaptureFieldLabel('Meaning', required: true),
        const SizedBox(height: AppSpacing.compact),
        ShadTextarea(
          key: const ValueKey('capture-meaning'),
          controller: meaning,
          focusNode: meaningFocus,
          contextMenuBuilder: compactEditingContextMenu,
          placeholder: const Text('Explain the meaning you encountered'),
          minHeight: 96,
          maxHeight: 220,
          onChanged: onMeaningChanged,
        ),
        const SizedBox(height: AppSpacing.regular),
        const CaptureFieldLabel('Part of speech'),
        const SizedBox(height: AppSpacing.compact),
        ShadInput(
          key: const ValueKey('capture-part-of-speech'),
          controller: partOfSpeech,
          contextMenuBuilder: compactEditingContextMenu,
          placeholder: const Text('Optional, e.g. noun or adjective'),
          onChanged: onPartOfSpeechChanged,
        ),
        const SizedBox(height: AppSpacing.regular),
        ShadButton.outline(
          key: const ValueKey('use-edited-meaning'),
          onPressed: onUse,
          child: const Text('Use this meaning'),
        ),
      ],
    );
  }
}

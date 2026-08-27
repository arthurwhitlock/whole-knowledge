import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:whole_knowledge/app/theme/app_spacing.dart';
import 'package:whole_knowledge/application/capture/capture_session_controller.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';
import 'package:whole_knowledge/presentation/components/compact_editing_context_menu.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({
    required this.controller,
    required this.onCaptured,
    super.key,
  });

  final CaptureSessionController controller;
  final VoidCallback onCaptured;

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _content = TextEditingController();
  final _partOfSpeech = TextEditingController();
  final _meaning = TextEditingController();
  final _context = TextEditingController();
  final _source = TextEditingController();
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_controllerChanged);
    _syncFromController();
  }

  @override
  void didUpdateWidget(covariant CaptureScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_controllerChanged);
      widget.controller.addListener(_controllerChanged);
      _syncFromController();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_controllerChanged);
    _content.dispose();
    _partOfSpeech.dispose();
    _meaning.dispose();
    _context.dispose();
    _source.dispose();
    super.dispose();
  }

  void _controllerChanged() {
    if (!mounted) return;
    _syncFromController();
    setState(() {});
  }

  void _syncFromController() {
    _syncing = true;
    final draft = widget.controller.draft;
    _replaceText(_content, draft.content);
    _replaceText(_partOfSpeech, draft.partOfSpeech ?? '');
    _replaceText(_meaning, draft.meaning);
    _replaceText(_context, draft.context);
    _replaceText(_source, draft.source);
    _syncing = false;
  }

  static void _replaceText(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _edit({
    String? content,
    String? partOfSpeech,
    String? meaning,
    String? context,
    String? source,
    LearningItemKind? kind,
  }) {
    if (_syncing) return;
    widget.controller.update(
      widget.controller.draft.copyWith(
        kind: kind,
        content: content,
        partOfSpeech: partOfSpeech,
        clearPartOfSpeech: partOfSpeech?.trim().isEmpty ?? false,
        meaning: meaning,
        context: context,
        source: source,
      ),
    );
  }

  Future<void> _save() async {
    final saved = await widget.controller.save();
    if (saved != null) widget.onCaptured();
  }

  Future<void> _discard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard this draft?'),
        content: const Text('The locally saved capture draft will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep draft'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.controller.discard();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final controller = widget.controller;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < AppSpacing.compactLayoutBreakpoint;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.regular : AppSpacing.pageCompact,
            vertical: compact ? AppSpacing.pageCompact : AppSpacing.page,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: FocusTraversalGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Capture', style: theme.textTheme.h1),
                    const SizedBox(height: AppSpacing.compact),
                    Text(
                      'Save language as you encounter it. It will be ready to review immediately.',
                      style: theme.textTheme.muted,
                    ),
                    if (controller.restored) ...[
                      const SizedBox(height: AppSpacing.regular),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          'Draft restored',
                          style: theme.textTheme.small,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.page),
                    Text('Type', style: theme.textTheme.small),
                    const SizedBox(height: AppSpacing.compact),
                    Wrap(
                      spacing: AppSpacing.compact,
                      runSpacing: AppSpacing.compact,
                      children: LearningItemKind.values
                          .map((kind) {
                            final selected = controller.draft.kind == kind;
                            final label = kind == LearningItemKind.expression
                                ? 'Expression'
                                : 'Vocabulary';
                            return Semantics(
                              selected: selected,
                              child: selected
                                  ? ShadButton(
                                      enabled: !controller.isSaving,
                                      onPressed: () => _edit(kind: kind),
                                      child: Text(label),
                                    )
                                  : ShadButton.outline(
                                      enabled: !controller.isSaving,
                                      onPressed: () => _edit(kind: kind),
                                      child: Text(label),
                                    ),
                            );
                          })
                          .toList(growable: false),
                    ),
                    const SizedBox(height: AppSpacing.regular),
                    const _FieldLabel(label: 'Language', required: true),
                    const SizedBox(height: AppSpacing.compact),
                    Semantics(
                      label: 'Language, required',
                      child: ShadTextarea(
                        key: const ValueKey('capture-content'),
                        controller: _content,
                        enabled: !controller.isSaving,
                        contextMenuBuilder: compactEditingContextMenu,
                        placeholder: const Text('What did you encounter?'),
                        minHeight: 96,
                        maxHeight: 180,
                        resizable: true,
                        onChanged: (value) => _edit(content: value),
                      ),
                    ),
                    if (controller.contentError != null)
                      _ErrorText(controller.contentError!),
                    const SizedBox(height: AppSpacing.regular),
                    Row(
                      children: [
                        const Expanded(child: _FieldLabel(label: 'Meaning')),
                        ShadButton.ghost(
                          key: const ValueKey('lookup-meaning'),
                          enabled:
                              !controller.isLookingUp &&
                              !controller.isSaving &&
                              _content.text.trim().isNotEmpty,
                          onPressed: controller.lookupMeaning,
                          leading: controller.isLookingUp
                              ? const SizedBox.square(
                                  dimension: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.menu_book_outlined, size: 16),
                          child: Text(
                            controller.isLookingUp
                                ? 'Looking up'
                                : 'Look up English',
                          ),
                        ),
                      ],
                    ),
                    if (controller.lookup != null ||
                        controller.lookupError != null)
                      _LookupResults(controller: controller),
                    const SizedBox(height: AppSpacing.compact),
                    Semantics(
                      label: 'Meaning, optional',
                      child: ShadTextarea(
                        key: const ValueKey('capture-meaning'),
                        controller: _meaning,
                        enabled: !controller.isSaving,
                        contextMenuBuilder: compactEditingContextMenu,
                        placeholder: const Text(
                          'Optional explanation or translation',
                        ),
                        minHeight: 72,
                        maxHeight: 180,
                        onChanged: (value) => _edit(meaning: value),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.regular),
                    const _FieldLabel(label: 'Part of speech'),
                    const SizedBox(height: AppSpacing.compact),
                    ShadInput(
                      key: const ValueKey('capture-part-of-speech'),
                      controller: _partOfSpeech,
                      enabled: !controller.isSaving,
                      contextMenuBuilder: compactEditingContextMenu,
                      placeholder: const Text('Optional, e.g. noun or verb'),
                      onChanged: (value) => _edit(partOfSpeech: value),
                    ),
                    const SizedBox(height: AppSpacing.regular),
                    const _FieldLabel(label: 'Context'),
                    const SizedBox(height: AppSpacing.compact),
                    ShadTextarea(
                      key: const ValueKey('capture-context'),
                      controller: _context,
                      enabled: !controller.isSaving,
                      contextMenuBuilder: compactEditingContextMenu,
                      placeholder: const Text('Optional sentence or situation'),
                      minHeight: 80,
                      maxHeight: 160,
                      onChanged: (value) => _edit(context: value),
                    ),
                    const SizedBox(height: AppSpacing.regular),
                    const _FieldLabel(label: 'Source'),
                    const SizedBox(height: AppSpacing.compact),
                    ShadInput(
                      key: const ValueKey('capture-source'),
                      controller: _source,
                      enabled: !controller.isSaving,
                      contextMenuBuilder: compactEditingContextMenu,
                      placeholder: const Text(
                        'Optional book, conversation, or link',
                      ),
                      onChanged: (value) => _edit(source: value),
                    ),
                    if (controller.saveError != null)
                      _ErrorText(controller.saveError!),
                    const SizedBox(height: AppSpacing.pageCompact),
                    Wrap(
                      spacing: AppSpacing.compact,
                      runSpacing: AppSpacing.compact,
                      children: [
                        ShadButton(
                          key: const ValueKey('save-capture'),
                          enabled: !controller.isSaving,
                          onPressed: _save,
                          leading: controller.isSaving
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : null,
                          child: Text(
                            controller.isSaving ? 'Saving' : 'Save for review',
                          ),
                        ),
                        if (controller.draft.isMeaningful)
                          ShadButton.ghost(
                            key: const ValueKey('discard-capture'),
                            enabled: !controller.isSaving,
                            onPressed: _discard,
                            child: const Text('Discard draft'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LookupResults extends StatelessWidget {
  const _LookupResults({required this.controller});

  final CaptureSessionController controller;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final lookup = controller.lookup;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.compact),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.lookupError != null)
            Text(controller.lookupError!, style: theme.textTheme.small),
          if (lookup != null) ...[
            Text('Choose a sense', style: theme.textTheme.small),
            const SizedBox(height: AppSpacing.compact),
            ...lookup.senses
                .take(12)
                .map(
                  (sense) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.compact),
                    child: Semantics(
                      button: true,
                      child: InkWell(
                        onTap: () => controller.selectSense(sense),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.regular,
                            vertical: AppSpacing.compact,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.border),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${sense.partOfSpeech} · ${sense.definition}',
                            style: theme.textTheme.p,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          ],
          Text(controller.lookupAttribution, style: theme.textTheme.muted),
        ],
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.compact),
      child: Semantics(
        liveRegion: true,
        child: Text(
          message,
          style: theme.textTheme.small.copyWith(
            color: theme.colorScheme.destructive,
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Text(required ? '$label *' : label, style: theme.textTheme.small);
  }
}

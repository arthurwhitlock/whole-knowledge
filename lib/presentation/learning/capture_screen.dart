import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:whole_knowledge/app/theme/app_spacing.dart';
import 'package:whole_knowledge/application/learning/capture_learning_item.dart';
import 'package:whole_knowledge/application/learning/learning_item_repository.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({
    required this.learningItems,
    required this.onCaptured,
    super.key,
  });

  final LearningItemRepository learningItems;
  final VoidCallback onCaptured;

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _content = TextEditingController();
  final _meaning = TextEditingController();
  final _context = TextEditingController();
  final _source = TextEditingController();
  LearningItemKind _kind = LearningItemKind.expression;
  String? _contentError;
  String? _saveError;
  bool _isSaving = false;

  @override
  void dispose() {
    _content.dispose();
    _meaning.dispose();
    _context.dispose();
    _source.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final contentError = CaptureLearningItemValidator.validateContent(
      _content.text,
    );
    final optionalFieldError =
        CaptureLearningItemValidator.validateMeaning(_meaning.text) ??
        CaptureLearningItemValidator.validateContext(_context.text) ??
        CaptureLearningItemValidator.validateSource(_source.text);
    setState(() {
      _contentError = contentError;
      _saveError = optionalFieldError;
    });
    if (contentError != null || optionalFieldError != null) return;

    setState(() => _isSaving = true);
    try {
      await widget.learningItems.create(
        CaptureLearningItem(
          kind: _kind,
          content: _content.text,
          meaning: _meaning.text,
          context: _context.text,
          source: _source.text,
        ),
      );
      if (!mounted) return;
      _content.clear();
      _meaning.clear();
      _context.clear();
      _source.clear();
      setState(() {
        _isSaving = false;
        _contentError = null;
      });
      widget.onCaptured();
    } on Object {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = 'Could not save this item. Your input is still here.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return _PageFrame(
      child: FocusTraversalGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Capture', style: theme.textTheme.h1),
            const SizedBox(height: AppSpacing.compact),
            Text(
              'Save language as you encounter it. It will be ready to review '
              'immediately.',
              style: theme.textTheme.muted,
            ),
            const SizedBox(height: AppSpacing.section),
            Text('Type', style: theme.textTheme.small),
            const SizedBox(height: AppSpacing.compact),
            Wrap(
              spacing: AppSpacing.compact,
              runSpacing: AppSpacing.compact,
              children: [
                _KindButton(
                  label: 'Expression',
                  selected: _kind == LearningItemKind.expression,
                  enabled: !_isSaving,
                  onPressed: () {
                    setState(() => _kind = LearningItemKind.expression);
                  },
                ),
                _KindButton(
                  label: 'Vocabulary',
                  selected: _kind == LearningItemKind.vocabulary,
                  enabled: !_isSaving,
                  onPressed: () {
                    setState(() => _kind = LearningItemKind.vocabulary);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.regular),
            const _FieldLabel(label: 'Language', required: true),
            const SizedBox(height: AppSpacing.compact),
            Semantics(
              label: 'Language, required',
              child: ShadTextarea(
                key: const ValueKey('capture-content'),
                controller: _content,
                enabled: !_isSaving,
                placeholder: const Text('What did you encounter?'),
                minHeight: 96,
                maxHeight: 180,
                resizable: true,
                onChanged: (_) {
                  if (_contentError != null) {
                    setState(() => _contentError = null);
                  }
                },
              ),
            ),
            if (_contentError != null) ...[
              const SizedBox(height: AppSpacing.compact),
              Semantics(
                liveRegion: true,
                child: Text(
                  _contentError!,
                  style: theme.textTheme.small.copyWith(
                    color: theme.colorScheme.destructive,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.regular),
            const _FieldLabel(label: 'Meaning'),
            const SizedBox(height: AppSpacing.compact),
            Semantics(
              label: 'Meaning, optional',
              child: ShadInput(
                key: const ValueKey('capture-meaning'),
                controller: _meaning,
                enabled: !_isSaving,
                placeholder: const Text('Optional explanation or translation'),
              ),
            ),
            const SizedBox(height: AppSpacing.regular),
            const _FieldLabel(label: 'Context'),
            const SizedBox(height: AppSpacing.compact),
            Semantics(
              label: 'Context, optional',
              child: ShadTextarea(
                key: const ValueKey('capture-context'),
                controller: _context,
                enabled: !_isSaving,
                placeholder: const Text('Optional sentence or situation'),
                minHeight: 80,
                maxHeight: 160,
              ),
            ),
            const SizedBox(height: AppSpacing.regular),
            const _FieldLabel(label: 'Source'),
            const SizedBox(height: AppSpacing.compact),
            Semantics(
              label: 'Source, optional',
              child: ShadInput(
                key: const ValueKey('capture-source'),
                controller: _source,
                enabled: !_isSaving,
                placeholder: const Text('Optional book, conversation, or link'),
              ),
            ),
            if (_saveError != null) ...[
              const SizedBox(height: AppSpacing.regular),
              Semantics(
                liveRegion: true,
                child: Text(
                  _saveError!,
                  style: theme.textTheme.small.copyWith(
                    color: theme.colorScheme.destructive,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.pageCompact),
            ShadButton(
              key: const ValueKey('save-capture'),
              enabled: !_isSaving,
              onPressed: _save,
              leading: _isSaving
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              child: Text(_isSaving ? 'Saving' : 'Save for review'),
            ),
          ],
        ),
      ),
    );
  }
}

class _KindButton extends StatelessWidget {
  const _KindButton({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: selected
          ? ShadButton(
              enabled: enabled,
              onPressed: onPressed,
              child: Text(label),
            )
          : ShadButton.outline(
              enabled: enabled,
              onPressed: onPressed,
              child: Text(label),
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

class _PageFrame extends StatelessWidget {
  const _PageFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageCompact,
        vertical: AppSpacing.page,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.contentMaxWidth,
          ),
          child: child,
        ),
      ),
    );
  }
}

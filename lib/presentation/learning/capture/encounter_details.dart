import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:whole_knowledge/app/theme/app_motion.dart';
import 'package:whole_knowledge/app/theme/app_spacing.dart';
import 'package:whole_knowledge/application/capture/capture_session_controller.dart';
import 'package:whole_knowledge/presentation/components/compact_editing_context_menu.dart';
import 'package:whole_knowledge/presentation/learning/capture/capture_chrome.dart';

class CaptureEncounterDetails extends StatefulWidget {
  const CaptureEncounterDetails({required this.controller, super.key});

  final CaptureSessionController controller;

  @override
  State<CaptureEncounterDetails> createState() =>
      _CaptureEncounterDetailsState();
}

class _CaptureEncounterDetailsState extends State<CaptureEncounterDetails> {
  final _context = TextEditingController();
  final _source = TextEditingController();
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _sync(openAuthored: true);
  }

  @override
  void didUpdateWidget(covariant CaptureEncounterDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync(openAuthored: true);
  }

  @override
  void dispose() {
    _context.dispose();
    _source.dispose();
    super.dispose();
  }

  void _sync({required bool openAuthored}) {
    final draft = widget.controller.draft;
    _replace(_context, draft.context);
    _replace(_source, draft.source);
    if (openAuthored &&
        (draft.context.trim().isNotEmpty || draft.source.trim().isNotEmpty)) {
      _expanded = true;
    }
  }

  static void _replace(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          expanded: _expanded,
          child: ShadButton.ghost(
            key: const ValueKey('encounter-details-toggle'),
            onPressed: () => setState(() => _expanded = !_expanded),
            trailing: Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              size: 18,
            ),
            child: Text(
              _expanded ? 'Hide encounter details' : 'Add encounter details',
            ),
          ),
        ),
        AnimatedSize(
          duration: AppMotion.responsive(context, AppMotion.structural),
          curve: AppMotion.structuralCurve,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Padding(
                  key: const ValueKey('encounter-details-fields'),
                  padding: const EdgeInsets.only(top: AppSpacing.regular),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CaptureFieldLabel('Encounter context'),
                      const SizedBox(height: AppSpacing.compact),
                      ShadTextarea(
                        key: const ValueKey('capture-context'),
                        controller: _context,
                        contextMenuBuilder: compactEditingContextMenu,
                        placeholder: const Text('Sentence or situation'),
                        minHeight: 80,
                        maxHeight: 180,
                        onChanged: (value) =>
                            widget.controller.updateEncounterDetails(
                              context: value,
                              source: _source.text,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.regular),
                      const CaptureFieldLabel('Source'),
                      const SizedBox(height: AppSpacing.compact),
                      ShadInput(
                        key: const ValueKey('capture-source'),
                        controller: _source,
                        contextMenuBuilder: compactEditingContextMenu,
                        placeholder: const Text(
                          'Book, conversation, article, or link',
                        ),
                        onChanged: (value) =>
                            widget.controller.updateEncounterDetails(
                              context: _context.text,
                              source: value,
                            ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(
                  key: ValueKey('encounter-details-hidden'),
                ),
        ),
      ],
    );
  }
}

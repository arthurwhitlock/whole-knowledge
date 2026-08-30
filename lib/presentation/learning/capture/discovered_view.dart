import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:whole_knowledge/app/theme/app_spacing.dart';
import 'package:whole_knowledge/app/theme/app_typography.dart';
import 'package:whole_knowledge/application/capture/capture_session_controller.dart';
import 'package:whole_knowledge/application/capture/capture_session_state.dart';
import 'package:whole_knowledge/presentation/learning/capture/capture_chrome.dart';
import 'package:whole_knowledge/presentation/learning/capture/relative_calendar_time.dart';

class CaptureDiscoveredView extends StatefulWidget {
  const CaptureDiscoveredView({
    required this.controller,
    required this.state,
    required this.now,
    required this.onDone,
    super.key,
  });

  final CaptureSessionController controller;
  final CaptureDiscovered state;
  final DateTime now;
  final VoidCallback onDone;

  @override
  State<CaptureDiscoveredView> createState() => _CaptureDiscoveredViewState();
}

class _CaptureDiscoveredViewState extends State<CaptureDiscoveredView> {
  final _headingFocus = FocusNode();

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
    super.dispose();
  }

  void _done() {
    widget.controller.done();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final item = widget.state.item;
    final production = item.firstProduction?.trim();
    final deferred = production == null || production.isEmpty;
    final timing = RelativeCalendarTime.format(
      item.nextReviewAt,
      widget.now,
      MaterialLocalizations.of(context),
    );
    return CapturePageLayout(
      child: Semantics(
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Focus(
              focusNode: _headingFocus,
              child: Semantics(
                header: true,
                child: Text('Discovered', style: theme.textTheme.h1),
              ),
            ),
            const SizedBox(height: AppSpacing.page),
            Text(item.content, style: theme.textTheme.h2),
            if (item.partOfSpeech != null) ...[
              const SizedBox(height: AppSpacing.compact),
              Text(item.partOfSpeech!, style: theme.textTheme.label),
            ],
            if (item.meaning != null) ...[
              const SizedBox(height: AppSpacing.regular),
              Text(item.meaning!, style: theme.textTheme.p),
            ],
            if (!deferred) ...[
              const SizedBox(height: AppSpacing.pageCompact),
              Text('“$production”', style: theme.textTheme.lead),
            ],
            const SizedBox(height: AppSpacing.pageCompact),
            if (deferred)
              Text(
                'Ready to practice now',
                key: const ValueKey('discovery-due-now'),
                style: theme.textTheme.h4,
              )
            else
              Semantics(
                label: 'First review ${timing.semantic}',
                child: ExcludeSemantics(
                  child: Text(
                    'First review ${timing.visual}',
                    key: const ValueKey('discovery-review-timing'),
                    style: theme.textTheme.h4,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.page),
            CaptureAdaptiveActions(
              primary: ShadButton(
                key: const ValueKey('discovery-done'),
                onPressed: _done,
                child: const Text('Done'),
              ),
              secondary: ShadButton.outline(
                key: const ValueKey('capture-another'),
                onPressed: widget.controller.captureAnother,
                child: const Text('Capture another'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CaptureRestoringView extends StatelessWidget {
  const CaptureRestoringView({super.key});

  @override
  Widget build(BuildContext context) {
    return CapturePageLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CaptureOrientation(),
          const SizedBox(height: AppSpacing.section),
          Semantics(
            liveRegion: true,
            label: 'Restoring capture draft',
            child: const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator.adaptive(strokeWidth: 2),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:whole_knowledge/app/theme/app_motion.dart';
import 'package:whole_knowledge/app/theme/app_spacing.dart';
import 'package:whole_knowledge/app/theme/app_typography.dart';
import 'package:whole_knowledge/application/capture/capture_session_state.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';

class CapturePageLayout extends StatelessWidget {
  const CapturePageLayout({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < AppSpacing.compactLayoutBreakpoint;
        return SingleChildScrollView(
          key: const ValueKey('capture-document-scroll'),
          padding: EdgeInsets.only(
            left: compact ? AppSpacing.regular : AppSpacing.pageCompact,
            right: compact ? AppSpacing.regular : AppSpacing.pageCompact,
            top: compact ? AppSpacing.pageCompact : AppSpacing.page,
            bottom:
                MediaQuery.viewInsetsOf(context).bottom + AppSpacing.regular,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.formMaxWidth,
              ),
              child: FocusTraversalGroup(child: child),
            ),
          ),
        );
      },
    );
  }
}

class CaptureOrientation extends StatelessWidget {
  const CaptureOrientation({this.onBack, this.restored = false, super.key});

  final VoidCallback? onBack;
  final bool restored;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onBack != null) ...[
          ShadButton.ghost(
            key: const ValueKey('capture-back'),
            onPressed: onBack,
            leading: const Icon(Icons.arrow_back, size: 18),
            child: const Text('Back'),
          ),
          const SizedBox(height: AppSpacing.regular),
        ],
        Text('Capture', style: theme.textTheme.h1),
        if (restored) ...[
          const SizedBox(height: AppSpacing.compact),
          Semantics(
            liveRegion: true,
            child: Text(
              'Draft restored',
              key: const ValueKey('draft-restored'),
              style: theme.textTheme.label.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class CaptureSubject extends StatelessWidget {
  const CaptureSubject({
    required this.content,
    required this.kind,
    required this.kindWasOverridden,
    this.onChangeKind,
    super.key,
  });

  final String content;
  final LearningItemKind kind;
  final bool kindWasOverridden;
  final ValueChanged<LearningItemKind>? onChangeKind;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final enlarged = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final label = kind == LearningItemKind.vocabulary
        ? 'Vocabulary'
        : 'Expression';
    final alternate = kind == LearningItemKind.vocabulary
        ? LearningItemKind.expression
        : LearningItemKind.vocabulary;
    final alternateLabel = alternate == LearningItemKind.vocabulary
        ? 'Vocabulary discovery'
        : 'Expression';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(content.trim(), style: theme.textTheme.h2),
        const SizedBox(height: AppSpacing.compact),
        Wrap(
          spacing: AppSpacing.regular,
          runSpacing: AppSpacing.compact,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Semantics(
              label: kindWasOverridden
                  ? 'Current type: $label'
                  : 'Suggested type: $label',
              child: Text(
                kindWasOverridden ? label : '$label suggested',
                style: theme.textTheme.label,
              ),
            ),
            if (onChangeKind != null)
              ShadButton.link(
                key: const ValueKey('change-discovery-type'),
                height: enlarged ? 0 : 48,
                onPressed: () => onChangeKind!(alternate),
                child: CaptureButtonLabel('Use $alternateLabel'),
              ),
          ],
        ),
      ],
    );
  }
}

class CaptureButtonLabel extends StatelessWidget {
  const CaptureButtonLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Text(label, textAlign: TextAlign.center, softWrap: true),
    );
  }
}

class CaptureTaskHeading extends StatelessWidget {
  const CaptureTaskHeading({
    required this.title,
    this.prompt,
    this.focusNode,
    this.liveRegion = true,
    super.key,
  });

  final String title;
  final String? prompt;
  final FocusNode? focusNode;
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Focus(
      focusNode: focusNode,
      child: Semantics(
        header: true,
        liveRegion: liveRegion,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.h3),
            if (prompt != null) ...[
              const SizedBox(height: AppSpacing.compact),
              Text(prompt!, style: theme.textTheme.p),
            ],
          ],
        ),
      ),
    );
  }
}

class CaptureFieldLabel extends StatelessWidget {
  const CaptureFieldLabel(this.label, {this.required = false, super.key});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Text(
      required ? '$label · required' : label,
      style: theme.textTheme.label,
    );
  }
}

class CaptureInlineError extends StatelessWidget {
  const CaptureInlineError(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final content = message == null
        ? const SizedBox.shrink(key: ValueKey('no-capture-error'))
        : Padding(
            key: ValueKey(message),
            padding: const EdgeInsets.only(top: AppSpacing.compact),
            child: Semantics(
              liveRegion: true,
              child: Text(
                message!,
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.destructive,
                ),
              ),
            ),
          );
    final duration = AppMotion.responsive(context, AppMotion.standard);
    if (duration == Duration.zero) return content;
    return AnimatedSize(
      duration: duration,
      curve: AppMotion.standardCurve,
      alignment: Alignment.topCenter,
      child: content,
    );
  }
}

class CaptureServiceStatus extends StatelessWidget {
  const CaptureServiceStatus({
    required this.label,
    this.progress = false,
    this.error,
    this.onRetry,
    super.key,
  });

  final String label;
  final bool progress;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Semantics(
      liveRegion: true,
      label: error ?? label,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.compact),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (progress) ...[
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                const SizedBox(width: AppSpacing.compact),
              ],
              Expanded(
                child: Text(
                  error ?? label,
                  style: error == null
                      ? theme.textTheme.muted
                      : theme.textTheme.small.copyWith(
                          color: theme.colorScheme.destructive,
                        ),
                ),
              ),
              if (onRetry != null)
                ShadButton.ghost(
                  size: ShadButtonSize.sm,
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CaptureLibraryStatus extends StatelessWidget {
  const CaptureLibraryStatus({
    required this.outcome,
    required this.onRetry,
    super.key,
  });

  final LibraryOutcome outcome;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (outcome) {
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
        error: 'Could not check your Library. Saving waits for this check.',
        onRetry: onRetry,
      ),
      LibraryMatches() => const CaptureServiceStatus(
        label: 'Already in your Library',
      ),
    };
  }
}

class CaptureStaleProductionNotice extends StatelessWidget {
  const CaptureStaleProductionNotice({
    required this.production,
    required this.confirmed,
    required this.canConfirm,
    required this.onConfirm,
    super.key,
  });

  final String production;
  final bool confirmed;
  final bool canConfirm;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    if (production.trim().isEmpty) return const SizedBox.shrink();
    final theme = ShadTheme.of(context);
    return Column(
      key: const ValueKey('preserved-production'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Existing production', style: theme.textTheme.label),
        const SizedBox(height: AppSpacing.compact),
        Text('“$production”', style: theme.textTheme.p),
        if (!confirmed) ...[
          const SizedBox(height: AppSpacing.compact),
          Text(
            'Review whether this sentence still fits the current meaning.',
            style: theme.textTheme.small,
          ),
          const SizedBox(height: AppSpacing.compact),
          ShadButton.outline(
            key: const ValueKey('confirm-preserved-production'),
            height: 0,
            enabled: canConfirm,
            onPressed: onConfirm,
            child: const CaptureButtonLabel('This sentence still fits'),
          ),
        ],
      ],
    );
  }
}

class CaptureAdaptiveActions extends StatelessWidget {
  const CaptureAdaptiveActions({
    required this.primary,
    this.secondary,
    this.tertiary,
    super.key,
  });

  final Widget primary;
  final Widget? secondary;
  final Widget? tertiary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final stacked =
            constraints.maxWidth < AppSpacing.compactLayoutBreakpoint ||
            textScale > 1.3;
        final children = [primary, ?secondary, ?tertiary];
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                if (index > 0) const SizedBox(height: AppSpacing.compact),
                children[index],
              ],
            ],
          );
        }
        return Wrap(
          spacing: AppSpacing.compact,
          runSpacing: AppSpacing.compact,
          children: children,
        );
      },
    );
  }
}

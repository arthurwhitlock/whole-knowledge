import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:whole_knowledge/app/theme/app_colors.dart';
import 'package:whole_knowledge/app/theme/app_motion.dart';
import 'package:whole_knowledge/app/theme/app_radius.dart';
import 'package:whole_knowledge/app/theme/app_spacing.dart';
import 'package:whole_knowledge/app/theme/app_typography.dart';
import 'package:whole_knowledge/application/learning/today_overview.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({
    required this.overview,
    required this.isInitialLoading,
    required this.isRefreshing,
    required this.loadError,
    required this.reviewPaused,
    required this.reviewCompleted,
    required this.onStartReview,
    required this.onResumeReview,
    required this.onReload,
    required this.onQuickCapture,
    super.key,
  });

  final TodayOverview? overview;
  final bool isInitialLoading;
  final bool isRefreshing;
  final String? loadError;
  final bool reviewPaused;
  final bool reviewCompleted;
  final VoidCallback onStartReview;
  final VoidCallback onResumeReview;
  final VoidCallback onReload;
  final VoidCallback onQuickCapture;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: AppMotion.responsive(context, AppMotion.standard),
    switchInCurve: AppMotion.standardCurve,
    switchOutCurve: AppMotion.instantCurve,
    child: _buildContent(context),
  );

  Widget _buildContent(BuildContext context) {
    final theme = ShadTheme.of(context);
    if (isInitialLoading) {
      return const Center(
        key: ValueKey('today-loading'),
        child: CircularProgressIndicator.adaptive(),
      );
    }
    if (overview == null) {
      return KeyedSubtree(
        key: const ValueKey('today-failure'),
        child: _CenteredFailure(
          message: loadError ?? 'Could not load Today.',
          onRetry: onReload,
        ),
      );
    }
    final current = overview!;
    return LayoutBuilder(
      key: const ValueKey('today-overview'),
      builder: (context, constraints) {
        final desktop =
            constraints.maxWidth >= AppSpacing.contentLayoutBreakpoint;
        final body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Today', style: theme.textTheme.h1)),
                if (isRefreshing)
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.compact),
            Text(_todaySummary(current), style: theme.textTheme.muted),
            if (loadError != null) ...[
              const SizedBox(height: AppSpacing.regular),
              _InlineFailure(message: loadError!, onRetry: onReload),
            ],
            const SizedBox(height: AppSpacing.page),
            if (desktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _primaryColumn(context, current)),
                  const SizedBox(width: AppSpacing.pageCompact),
                  Expanded(flex: 2, child: _contextColumn(context, current)),
                ],
              )
            else ...[
              _primaryColumn(context, current),
              const SizedBox(height: AppSpacing.pageCompact),
              _contextColumn(context, current),
            ],
          ],
        );
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal:
                constraints.maxWidth < AppSpacing.compactLayoutBreakpoint
                ? AppSpacing.regular
                : AppSpacing.pageCompact,
            vertical: AppSpacing.page,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.workspaceMaxWidth,
              ),
              child: body,
            ),
          ),
        );
      },
    );
  }

  Widget _primaryColumn(BuildContext context, TodayOverview current) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Surface(
          key: const ValueKey('today-review-surface'),
          accent: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 296),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review queue',
                  style: theme.textTheme.label.copyWith(
                    color: theme.colorScheme.brandAccent,
                  ),
                ),
                const SizedBox(height: AppSpacing.largeSection),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedSwitcher(
                    duration: AppMotion.responsive(context, AppMotion.standard),
                    child: _reviewQueueContent(context, current),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.regular),
        ShadButton.ghost(
          onPressed: onQuickCapture,
          leading: const Icon(Icons.add, size: 18),
          child: const Text('Quick capture'),
        ),
      ],
    );
  }

  Widget _reviewQueueContent(BuildContext context, TodayOverview current) {
    final theme = ShadTheme.of(context);
    if (reviewPaused) {
      return Column(
        key: const ValueKey('queue-paused'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your review is paused', style: theme.textTheme.h2),
          const SizedBox(height: AppSpacing.compact),
          Text(
            'Your current response is kept in this session.',
            style: theme.textTheme.p,
          ),
          const SizedBox(height: AppSpacing.pageCompact),
          ShadButton.outline(
            key: const ValueKey('resume-review'),
            onPressed: onResumeReview,
            child: const Text('Resume review'),
          ),
        ],
      );
    }
    if (isRefreshing) {
      return Text(
        'Refreshing review queue.',
        key: const ValueKey('queue-refreshing'),
        style: theme.textTheme.lead,
      );
    }
    if (current.dueItems.isNotEmpty) {
      return Column(
        key: const ValueKey('queue-ready'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${current.dueItems.length} ${current.dueItems.length == 1 ? 'item' : 'items'} ready for review.',
            style: theme.textTheme.h2,
          ),
          const SizedBox(height: AppSpacing.compact),
          Text('Retrieve, check, produce, and rate.', style: theme.textTheme.p),
          const SizedBox(height: AppSpacing.pageCompact),
          ShadButton(
            key: const ValueKey('start-review'),
            enabled: !isRefreshing,
            onPressed: onStartReview,
            child: const Text('Start review'),
          ),
        ],
      );
    }
    return Column(
      key: ValueKey(reviewCompleted ? 'queue-complete' : 'queue-clear'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          reviewCompleted ? 'Review complete.' : _zeroDueHeading(current),
          style: theme.textTheme.h2,
        ),
        const SizedBox(height: AppSpacing.compact),
        Text('Nothing is due right now.', style: theme.textTheme.p),
      ],
    );
  }

  Widget _contextColumn(BuildContext context, TodayOverview current) {
    return Column(
      key: const ValueKey('today-context-rail'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ContextSection(
          title: 'Recently captured',
          items: current.recentlyCaptured,
        ),
        const SizedBox(height: AppSpacing.page),
        _ContextSection(
          title: 'Completed today',
          items: current.completedToday,
        ),
        const SizedBox(height: AppSpacing.page),
        _NextReviewSection(nextReviewAt: current.nextReviewAt),
      ],
    );
  }

  static String _todaySummary(TodayOverview current) => current.dueItems.isEmpty
      ? 'A quiet view of what matters next.'
      : '${current.dueItems.length} ready now.';

  static String _zeroDueHeading(TodayOverview current) {
    if (current.completedToday.isNotEmpty) return 'All caught up';
    if (current.recentlyCaptured.isEmpty) return 'Start your learning loop';
    return 'Nothing due yet';
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child, this.accent = false, super.key});

  final Widget child;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.pageCompact),
      decoration: BoxDecoration(
        color: accent ? theme.colorScheme.accentSubtle : theme.colorScheme.card,
        border: accent ? null : Border.all(color: theme.colorScheme.border),
        borderRadius: AppRadius.organicA,
      ),
      child: child,
    );
  }
}

class _ContextSection extends StatelessWidget {
  const _ContextSection({required this.title, required this.items});

  final String title;
  final List<LearningItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.h4),
        const SizedBox(height: AppSpacing.regular),
        Divider(height: 1, color: theme.colorScheme.border),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.regular),
            child: Text('No entries yet.', style: theme.textTheme.muted),
          )
        else
          ...items.map(
            (item) => Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.regular),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: theme.colorScheme.border),
                ),
              ),
              child: Text(
                item.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.p,
              ),
            ),
          ),
      ],
    );
  }
}

class _NextReviewSection extends StatelessWidget {
  const _NextReviewSection({required this.nextReviewAt});

  final DateTime? nextReviewAt;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Next review', style: theme.textTheme.h4),
        const SizedBox(height: AppSpacing.regular),
        Divider(height: 1, color: theme.colorScheme.border),
        const SizedBox(height: AppSpacing.regular),
        Text(
          nextReviewAt == null
              ? 'No scheduled review.'
              : _formatDate(nextReviewAt!.toLocal()),
          style: theme.textTheme.muted,
        ),
      ],
    );
  }

  static String _formatDate(DateTime value) {
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.day}/${value.month}/${value.year} · ${value.hour}:$minute';
  }
}

class _InlineFailure extends StatelessWidget {
  const _InlineFailure({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(message)),
      ShadButton.ghost(onPressed: onRetry, child: const Text('Retry')),
    ],
  );
}

class _CenteredFailure extends StatelessWidget {
  const _CenteredFailure({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        const SizedBox(height: AppSpacing.regular),
        ShadButton.outline(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:whole_knowledge/app/theme/app_colors.dart';
import 'package:whole_knowledge/app/theme/app_motion.dart';
import 'package:whole_knowledge/app/theme/app_radius.dart';
import 'package:whole_knowledge/app/theme/app_spacing.dart';
import 'package:whole_knowledge/app/theme/app_typography.dart';
import 'package:whole_knowledge/application/learning/review_repository.dart';
import 'package:whole_knowledge/application/learning/review_session_controller.dart';
import 'package:whole_knowledge/application/learning/today_overview.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';
import 'package:whole_knowledge/domain/learning/review_attempt.dart';
import 'package:whole_knowledge/presentation/components/compact_editing_context_menu.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({
    required this.overview,
    required this.isInitialLoading,
    required this.isRefreshing,
    required this.loadError,
    required this.reviews,
    required this.onCompleted,
    required this.onReload,
    required this.onQuickCapture,
    required this.onReviewModeChanged,
    super.key,
  });

  final TodayOverview? overview;
  final bool isInitialLoading;
  final bool isRefreshing;
  final String? loadError;
  final ReviewRepository reviews;
  final ValueChanged<LearningItem> onCompleted;
  final VoidCallback onReload;
  final VoidCallback onQuickCapture;
  final ValueChanged<bool> onReviewModeChanged;

  @override
  State<TodayScreen> createState() => TodayScreenState();
}

class TodayScreenState extends State<TodayScreen> {
  final _production = TextEditingController();
  final _productionFocus = FocusNode();
  late final ReviewSessionController _review;

  @override
  void initState() {
    super.initState();
    _review = ReviewSessionController(widget.reviews);
    _review.updateDueItems(widget.overview?.dueItems ?? const []);
    _review.addListener(_reviewChanged);
  }

  @override
  void didUpdateWidget(covariant TodayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.overview != null) {
      _review.updateDueItems(widget.overview!.dueItems);
    }
  }

  @override
  void dispose() {
    _review.removeListener(_reviewChanged);
    _review.dispose();
    _production.dispose();
    _productionFocus.dispose();
    super.dispose();
  }

  void _reviewChanged() {
    if (!mounted) return;
    if (_production.text != _review.responseText) {
      _production.value = TextEditingValue(
        text: _review.responseText,
        selection: TextSelection.collapsed(offset: _review.responseText.length),
      );
    }
    setState(() {});
  }

  void _startReview() {
    final due = widget.overview?.dueItems ?? const <LearningItem>[];
    if (_review.start(due)) widget.onReviewModeChanged(true);
  }

  void _resumeReview() {
    _review.resume();
    widget.onReviewModeChanged(true);
    if (_review.stage == ReviewStage.production) _focusProduction();
  }

  Future<void> _pauseReview() async {
    if (_review.isSaving) return;
    var confirmed = true;
    if (_production.text.trim().isNotEmpty) {
      confirmed =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Pause review?'),
              content: const Text(
                'Your response stays in this session until the app closes.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Keep reviewing'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Pause'),
                ),
              ],
            ),
          ) ??
          false;
    }
    if (!mounted || !confirmed) return;
    _review.pause();
    widget.onReviewModeChanged(false);
  }

  Future<void> pauseReviewFromSystem() => _pauseReview();

  void _continueToRating() {
    _review.updateResponse(_production.text);
    _review.continueToRating();
  }

  Future<void> _rate(ReviewRating rating) async {
    final updatedItem = await _review.rate(rating);
    if (!mounted || updatedItem == null) return;
    if (_review.queue.isEmpty) widget.onReviewModeChanged(false);
    widget.onCompleted(updatedItem);
  }

  void _enterProduction() {
    _review.enterProduction();
    _focusProduction();
  }

  void _focusProduction() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _productionFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.responsive(context, AppMotion.standard),
      switchInCurve: AppMotion.standardCurve,
      switchOutCurve: AppMotion.instantCurve,
      child: _review.isReviewing
          ? KeyedSubtree(
              key: const ValueKey('review-focus'),
              child: _buildReview(context),
            )
          : KeyedSubtree(
              key: const ValueKey('today-overview'),
              child: _buildToday(context),
            ),
    );
  }

  Widget _buildToday(BuildContext context) {
    final theme = ShadTheme.of(context);
    if (widget.isInitialLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (widget.overview == null) {
      return _CenteredFailure(
        message: widget.loadError ?? 'Could not load Today.',
        onRetry: widget.onReload,
      );
    }
    final overview = widget.overview!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop =
            constraints.maxWidth >= AppSpacing.contentLayoutBreakpoint;
        final body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Today', style: theme.textTheme.h1)),
                if (widget.isRefreshing)
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.compact),
            Text(_todaySummary(overview), style: theme.textTheme.muted),
            if (widget.loadError != null) ...[
              const SizedBox(height: AppSpacing.regular),
              _InlineFailure(
                message: widget.loadError!,
                onRetry: widget.onReload,
              ),
            ],
            const SizedBox(height: AppSpacing.page),
            if (desktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _primaryColumn(context, overview)),
                  const SizedBox(width: AppSpacing.pageCompact),
                  Expanded(flex: 2, child: _contextColumn(context, overview)),
                ],
              )
            else ...[
              _primaryColumn(context, overview),
              const SizedBox(height: AppSpacing.pageCompact),
              _contextColumn(context, overview),
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
              // The wider editorial canvas keeps the primary action dominant
              // without turning the context rail into a stack of dashboards.
              child: body,
            ),
          ),
        );
      },
    );
  }

  Widget _primaryColumn(BuildContext context, TodayOverview overview) {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review queue',
                  style: theme.textTheme.label.copyWith(
                    color: theme.colorScheme.brandAccent,
                  ),
                ),
                const SizedBox(height: AppSpacing.pageCompact),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedSwitcher(
                    duration: AppMotion.responsive(context, AppMotion.standard),
                    child: _reviewQueueContent(context, overview),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.regular),
        ShadButton.ghost(
          onPressed: widget.onQuickCapture,
          leading: const Icon(Icons.add, size: 18),
          child: const Text('Quick capture'),
        ),
      ],
    );
  }

  Widget _reviewQueueContent(BuildContext context, TodayOverview overview) {
    final theme = ShadTheme.of(context);
    if (_review.isPaused) {
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
            onPressed: _resumeReview,
            child: const Text('Resume review'),
          ),
        ],
      );
    }
    if (widget.isRefreshing) {
      return Text(
        'Refreshing review queue.',
        key: const ValueKey('queue-refreshing'),
        style: theme.textTheme.lead,
      );
    }
    if (overview.dueItems.isNotEmpty) {
      return Column(
        key: const ValueKey('queue-ready'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${overview.dueItems.length} ${overview.dueItems.length == 1 ? 'item' : 'items'} ready for review.',
            style: theme.textTheme.h2,
          ),
          const SizedBox(height: AppSpacing.compact),
          Text('Retrieve, check, produce, and rate.', style: theme.textTheme.p),
          const SizedBox(height: AppSpacing.pageCompact),
          ShadButton(
            key: const ValueKey('start-review'),
            enabled: !widget.isRefreshing,
            onPressed: _startReview,
            child: const Text('Start review'),
          ),
        ],
      );
    }
    return Column(
      key: ValueKey(_review.completed ? 'queue-complete' : 'queue-clear'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _review.completed ? 'Review complete.' : _zeroDueHeading(overview),
          style: theme.textTheme.h2,
        ),
        const SizedBox(height: AppSpacing.compact),
        Text('Nothing is due right now.', style: theme.textTheme.p),
      ],
    );
  }

  Widget _contextColumn(BuildContext context, TodayOverview overview) {
    return Column(
      key: const ValueKey('today-context-rail'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ContextSection(
          title: 'Recently captured',
          items: overview.recentlyCaptured,
        ),
        const SizedBox(height: AppSpacing.page),
        _ContextSection(
          title: 'Completed today',
          items: overview.completedToday,
        ),
        const SizedBox(height: AppSpacing.page),
        _NextReviewSection(nextReviewAt: overview.nextReviewAt),
      ],
    );
  }

  Widget _buildReview(BuildContext context) {
    final theme = ShadTheme.of(context);
    final item = _review.queue.first;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: constraints.maxWidth < AppSpacing.compactLayoutBreakpoint
              ? AppSpacing.regular
              : AppSpacing.pageCompact,
          vertical: AppSpacing.pageCompact,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: FocusTraversalGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ShadButton.ghost(
                        key: const ValueKey('pause-review'),
                        enabled: !_review.isSaving,
                        onPressed: _pauseReview,
                        leading: const Icon(Icons.close, size: 18),
                        child: const Text('Pause'),
                      ),
                      const Spacer(),
                      Text(
                        '${_review.reviewedInSession + 1} of ${_review.reviewTotal}',
                        style: theme.textTheme.muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.pageCompact),
                  _ReviewProgress(stage: _review.stage),
                  const SizedBox(height: AppSpacing.regular),
                  _Surface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _stageLabel,
                            style: theme.textTheme.small,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.regular),
                        Text(item.content, style: theme.textTheme.h2),
                        if (item.partOfSpeech != null) ...[
                          const SizedBox(height: AppSpacing.compact),
                          Text(
                            item.partOfSpeech!,
                            style: theme.textTheme.muted,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.pageCompact),
                        AnimatedSwitcher(
                          duration: AppMotion.responsive(
                            context,
                            AppMotion.standard,
                          ),
                          switchInCurve: AppMotion.standardCurve,
                          switchOutCurve: AppMotion.instantCurve,
                          transitionBuilder: _stageTransition,
                          child: KeyedSubtree(
                            key: ValueKey(_review.stage),
                            child: _reviewStageBody(context, item),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_review.error != null) ...[
                    const SizedBox(height: AppSpacing.regular),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _review.error!,
                        style: theme.textTheme.small.copyWith(
                          color: theme.colorScheme.destructive,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.pageCompact),
                  AnimatedSwitcher(
                    duration: AppMotion.responsive(
                      context,
                      AppMotion.interaction,
                    ),
                    child: KeyedSubtree(
                      key: ValueKey('actions-${_review.stage}'),
                      child: _reviewActions(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stageTransition(Widget child, Animation<double> animation) {
    final offset =
        Tween<Offset>(begin: const Offset(0, 0.025), end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: AppMotion.standardCurve),
        );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: offset, child: child),
    );
  }

  Widget _reviewStageBody(BuildContext context, LearningItem item) {
    final theme = ShadTheme.of(context);
    return switch (_review.stage) {
      ReviewStage.recall => Text(
        'Recall the meaning before revealing your notes.',
        style: theme.textTheme.lead,
      ),
      ReviewStage.revealed => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Meaning', style: theme.textTheme.label),
          const SizedBox(height: AppSpacing.compact),
          Text(
            item.meaning ?? 'No meaning was captured.',
            style: theme.textTheme.p,
          ),
          if (item.context != null) ...[
            const SizedBox(height: AppSpacing.regular),
            Text('Context', style: theme.textTheme.label),
            const SizedBox(height: AppSpacing.compact),
            Text(item.context!, style: theme.textTheme.p),
          ],
        ],
      ),
      ReviewStage.production || ReviewStage.rating => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Use it in a sentence or write what you would say.',
            style: theme.textTheme.p,
          ),
          const SizedBox(height: AppSpacing.regular),
          ShadTextarea(
            key: const ValueKey('production-response'),
            controller: _production,
            focusNode: _productionFocus,
            readOnly: _review.stage == ReviewStage.rating,
            enabled: !_review.isSaving,
            contextMenuBuilder: compactEditingContextMenu,
            placeholder: const Text('Write your response'),
            minHeight: 128,
            maxHeight: 260,
            onChanged: _review.updateResponse,
          ),
        ],
      ),
    };
  }

  Widget _reviewActions(BuildContext context) {
    final theme = ShadTheme.of(context);
    return switch (_review.stage) {
      ReviewStage.recall => ShadButton(
        key: const ValueKey('reveal-answer'),
        onPressed: _review.reveal,
        child: const Text('Reveal notes'),
      ),
      ReviewStage.revealed => ShadButton(
        onPressed: _enterProduction,
        child: const Text('Continue to production'),
      ),
      ReviewStage.production => ShadButton(
        key: const ValueKey('continue-to-rating'),
        onPressed: _continueToRating,
        child: const Text('Continue to self-rating'),
      ),
      ReviewStage.rating => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How did that feel?', style: theme.textTheme.h4),
          const SizedBox(height: AppSpacing.regular),
          Wrap(
            spacing: AppSpacing.compact,
            runSpacing: AppSpacing.compact,
            children: _review.failedRating == null
                ? ReviewRating.values
                      .map(
                        (rating) => ShadButton.outline(
                          key: ValueKey('rating-${rating.name}'),
                          enabled: !_review.isSaving,
                          onPressed: () => _rate(rating),
                          child: Text(_ratingLabel(rating)),
                        ),
                      )
                      .toList(growable: false)
                : [
                    ShadButton.outline(
                      key: const ValueKey('retry-review'),
                      enabled: !_review.isSaving,
                      onPressed: () => _rate(_review.failedRating!),
                      child: Text(
                        'Retry ${_ratingLabel(_review.failedRating!)}',
                      ),
                    ),
                    ShadButton.outline(
                      key: const ValueKey('reload-review-queue'),
                      enabled: !_review.isSaving,
                      onPressed: _reloadQueue,
                      child: const Text('Discard response and reload'),
                    ),
                  ],
          ),
        ],
      ),
    };
  }

  void _reloadQueue() {
    _review.discard();
    widget.onReviewModeChanged(false);
    widget.onReload();
  }

  String get _stageLabel => switch (_review.stage) {
    ReviewStage.recall => 'Retrieve',
    ReviewStage.revealed => 'Check',
    ReviewStage.production => 'Produce',
    ReviewStage.rating => 'Self-rate',
  };

  static String _todaySummary(TodayOverview overview) =>
      overview.dueItems.isEmpty
      ? 'A quiet view of what matters next.'
      : '${overview.dueItems.length} ready now.';

  static String _zeroDueHeading(TodayOverview overview) {
    if (overview.completedToday.isNotEmpty) return 'All caught up';
    if (overview.recentlyCaptured.isEmpty) return 'Start your learning loop';
    return 'Nothing due yet';
  }

  static String _ratingLabel(ReviewRating rating) => switch (rating) {
    ReviewRating.again => 'Again · 10m',
    ReviewRating.hard => 'Hard · 1d',
    ReviewRating.good => 'Good · 3d',
    ReviewRating.easy => 'Easy · 7d',
  };
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

class _ReviewProgress extends StatelessWidget {
  const _ReviewProgress({required this.stage});

  final ReviewStage stage;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    const stages = ['Retrieve', 'Check', 'Produce', 'Self-rate'];
    final activeIndex = ReviewStage.values.indexOf(stage);
    return Semantics(
      key: const ValueKey('review-stage-progress'),
      label: 'Review progress: ${activeIndex + 1} of 4, ${stages[activeIndex]}',
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var index = 0; index < stages.length; index++) ...[
              if (index > 0) const SizedBox(width: AppSpacing.compact),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: AppMotion.responsive(
                        context,
                        AppMotion.interaction,
                      ),
                      height: 2,
                      color: index <= activeIndex
                          ? theme.colorScheme.brandAccent
                          : theme.colorScheme.border,
                    ),
                    const SizedBox(height: AppSpacing.compact),
                    Text(
                      stages[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.meta.copyWith(
                        color: index == activeIndex
                            ? theme.colorScheme.foreground
                            : theme.colorScheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
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

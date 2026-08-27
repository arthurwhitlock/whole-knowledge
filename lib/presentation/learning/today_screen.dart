import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:whole_knowledge/app/theme/app_radius.dart';
import 'package:whole_knowledge/app/theme/app_spacing.dart';
import 'package:whole_knowledge/application/learning/review_repository.dart';
import 'package:whole_knowledge/application/learning/review_submission_id.dart';
import 'package:whole_knowledge/application/learning/today_overview.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';
import 'package:whole_knowledge/domain/learning/review_attempt.dart';
import 'package:whole_knowledge/presentation/components/compact_editing_context_menu.dart';

enum _ReviewStage { recall, revealed, production, rating }

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
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final _production = TextEditingController();
  final _productionFocus = FocusNode();
  List<LearningItem> _queue = [];
  _ReviewStage _stage = _ReviewStage.recall;
  bool _reviewing = false;
  bool _paused = false;
  bool _completed = false;
  bool _isSaving = false;
  String? _error;
  ReviewRating? _failedRating;
  String _submissionId = ReviewSubmissionId.generate();
  int _reviewedInSession = 0;
  int _reviewTotal = 0;

  @override
  void didUpdateWidget(covariant TodayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_reviewing && !_paused && widget.overview != null) {
      _queue = List.of(widget.overview!.dueItems);
      if (_queue.isNotEmpty) _completed = false;
    }
  }

  @override
  void dispose() {
    _production.dispose();
    _productionFocus.dispose();
    super.dispose();
  }

  void _startReview() {
    final due = widget.overview?.dueItems ?? const <LearningItem>[];
    setState(() {
      _queue = List.of(due);
      _reviewing = _queue.isNotEmpty;
      _paused = false;
      _completed = false;
      _stage = _ReviewStage.recall;
      _error = null;
      _failedRating = null;
      _production.clear();
      _reviewedInSession = 0;
      _reviewTotal = _queue.length;
      _submissionId = ReviewSubmissionId.generate();
    });
    if (_reviewing) widget.onReviewModeChanged(true);
  }

  void _resumeReview() {
    setState(() {
      _reviewing = true;
      _paused = false;
    });
    widget.onReviewModeChanged(true);
    if (_stage == _ReviewStage.production) _focusProduction();
  }

  Future<void> _pauseReview() async {
    if (_isSaving) return;
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
    setState(() {
      _reviewing = false;
      _paused = true;
    });
    widget.onReviewModeChanged(false);
  }

  void _continueToRating() {
    final response = _production.text.trim();
    if (response.isEmpty) {
      setState(() => _error = 'Write a response before self-rating.');
      return;
    }
    if (response.length > 10000) {
      setState(
        () => _error = 'Keep the production response under 10,000 characters.',
      );
      return;
    }
    setState(() {
      _stage = _ReviewStage.rating;
      _error = null;
    });
  }

  Future<void> _rate(ReviewRating rating) async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final updatedItem = await widget.reviews.completeReview(
        item: _queue.first,
        submissionId: _submissionId,
        responseText: _production.text.trim(),
        rating: rating,
      );
      if (!mounted) return;
      _queue.removeAt(0);
      _reviewedInSession += 1;
      _production.clear();
      _submissionId = ReviewSubmissionId.generate();
      setState(() {
        _isSaving = false;
        _failedRating = null;
        _stage = _ReviewStage.recall;
        if (_queue.isEmpty) {
          _reviewing = false;
          _completed = true;
        }
      });
      if (_queue.isEmpty) widget.onReviewModeChanged(false);
      widget.onCompleted(updatedItem);
    } on Object {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _stage = _ReviewStage.rating;
        _failedRating = rating;
        _error = 'Could not confirm this review. Retry safely with the same response, or discard it and reload the queue.';
      });
    }
  }

  void _enterProduction() {
    setState(() {
      _stage = _ReviewStage.production;
      _error = null;
      _failedRating = null;
    });
    _focusProduction();
  }

  void _focusProduction() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _productionFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_reviewing) return _buildReview(context);
    return _buildToday(context);
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
              constraints: const BoxConstraints(maxWidth: 1040),
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
          prominent: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Review queue', style: theme.textTheme.h3),
              const SizedBox(height: AppSpacing.compact),
              if (widget.isRefreshing)
                Text('Refreshing review queue.', style: theme.textTheme.p)
              else if (overview.dueItems.isNotEmpty) ...[
                Text(
                  '${overview.dueItems.length} ${overview.dueItems.length == 1 ? 'item' : 'items'} ready for review.',
                  style: theme.textTheme.p,
                ),
                const SizedBox(height: AppSpacing.regular),
                ShadButton(
                  key: const ValueKey('start-review'),
                  enabled: !widget.isRefreshing,
                  onPressed: _startReview,
                  child: const Text('Start review'),
                ),
              ] else ...[
                Text(_zeroDueHeading(overview), style: theme.textTheme.h4),
                const SizedBox(height: AppSpacing.compact),
                Text('Nothing is due right now.', style: theme.textTheme.p),
              ],
              if (_paused) ...[
                const SizedBox(height: AppSpacing.regular),
                ShadButton.outline(
                  key: const ValueKey('resume-review'),
                  onPressed: _resumeReview,
                  child: const Text('Resume paused review'),
                ),
              ],
              if (_completed) ...[
                const SizedBox(height: AppSpacing.regular),
                Text('Review complete.', style: theme.textTheme.p),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.regular),
        ShadButton.outline(
          onPressed: widget.onQuickCapture,
          child: const Text('Quick capture'),
        ),
      ],
    );
  }

  Widget _contextColumn(BuildContext context, TodayOverview overview) {
    return Column(
      children: [
        _ItemListSurface(
          title: 'Recently captured',
          items: overview.recentlyCaptured,
        ),
        const SizedBox(height: AppSpacing.regular),
        _ItemListSurface(
          title: 'Completed today',
          items: overview.completedToday,
        ),
        const SizedBox(height: AppSpacing.regular),
        _NextReviewSurface(nextReviewAt: overview.nextReviewAt),
      ],
    );
  }

  Widget _buildReview(BuildContext context) {
    final theme = ShadTheme.of(context);
    final item = _queue.first;
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
                        enabled: !_isSaving,
                        onPressed: _pauseReview,
                        leading: const Icon(Icons.close, size: 18),
                        child: const Text('Pause'),
                      ),
                      const Spacer(),
                      Text(
                        '${_reviewedInSession + 1} of $_reviewTotal',
                        style: theme.textTheme.muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.pageCompact),
                  _Surface(
                    prominent: true,
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
                        if (_stage == _ReviewStage.recall) ...[
                          const SizedBox(height: AppSpacing.regular),
                          Text(
                            'Recall the meaning before revealing your notes.',
                            style: theme.textTheme.p,
                          ),
                        ],
                        if (_stage == _ReviewStage.revealed) ...[
                          const SizedBox(height: AppSpacing.pageCompact),
                          Text('Meaning', style: theme.textTheme.small),
                          const SizedBox(height: AppSpacing.compact),
                          Text(
                            item.meaning ?? 'No meaning was captured.',
                            style: theme.textTheme.p,
                          ),
                          if (item.context != null) ...[
                            const SizedBox(height: AppSpacing.regular),
                            Text('Context', style: theme.textTheme.small),
                            const SizedBox(height: AppSpacing.compact),
                            Text(item.context!, style: theme.textTheme.p),
                          ],
                        ],
                        if (_stage == _ReviewStage.production ||
                            _stage == _ReviewStage.rating) ...[
                          const SizedBox(height: AppSpacing.pageCompact),
                          Text(
                            'Use it in a sentence or write what you would say.',
                            style: theme.textTheme.p,
                          ),
                          const SizedBox(height: AppSpacing.regular),
                          ShadTextarea(
                            key: const ValueKey('production-response'),
                            controller: _production,
                            focusNode: _productionFocus,
                            readOnly: _stage == _ReviewStage.rating,
                            enabled: !_isSaving,
                            contextMenuBuilder: compactEditingContextMenu,
                            placeholder: const Text('Write your response'),
                            minHeight: 128,
                            maxHeight: 260,
                            onChanged: (_) {
                              if (_error != null) setState(() => _error = null);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.regular),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: theme.textTheme.small.copyWith(
                          color: theme.colorScheme.destructive,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.pageCompact),
                  _reviewActions(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _reviewActions(BuildContext context) {
    final theme = ShadTheme.of(context);
    return switch (_stage) {
      _ReviewStage.recall => ShadButton(
        key: const ValueKey('reveal-answer'),
        onPressed: () => setState(() => _stage = _ReviewStage.revealed),
        child: const Text('Reveal notes'),
      ),
      _ReviewStage.revealed => ShadButton(
        onPressed: _enterProduction,
        child: const Text('Continue to production'),
      ),
      _ReviewStage.production => ShadButton(
        key: const ValueKey('continue-to-rating'),
        onPressed: _continueToRating,
        child: const Text('Continue to self-rating'),
      ),
      _ReviewStage.rating => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How did that feel?', style: theme.textTheme.h4),
          const SizedBox(height: AppSpacing.regular),
          Wrap(
            spacing: AppSpacing.compact,
            runSpacing: AppSpacing.compact,
            children: _failedRating == null
                ? ReviewRating.values
                      .map(
                        (rating) => ShadButton.outline(
                          key: ValueKey('rating-${rating.name}'),
                          enabled: !_isSaving,
                          onPressed: () => _rate(rating),
                          child: Text(_ratingLabel(rating)),
                        ),
                      )
                      .toList(growable: false)
                : [
                    ShadButton.outline(
                      key: const ValueKey('retry-review'),
                      enabled: !_isSaving,
                      onPressed: () => _rate(_failedRating!),
                      child: Text('Retry ${_ratingLabel(_failedRating!)}'),
                    ),
                    ShadButton.outline(
                      key: const ValueKey('reload-review-queue'),
                      enabled: !_isSaving,
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
    setState(() {
      _reviewing = false;
      _paused = false;
      _completed = false;
      _stage = _ReviewStage.recall;
      _error = null;
      _failedRating = null;
      _production.clear();
    });
    widget.onReviewModeChanged(false);
    widget.onReload();
  }

  String get _stageLabel => switch (_stage) {
    _ReviewStage.recall => 'Retrieve',
    _ReviewStage.revealed => 'Check',
    _ReviewStage.production => 'Produce',
    _ReviewStage.rating => 'Self-rate',
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
  const _Surface({required this.child, this.prominent = false});

  final Widget child;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        prominent ? AppSpacing.pageCompact : AppSpacing.regular,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: prominent
            ? AppRadius.organicLarge
            : AppRadius.organicSmall,
      ),
      child: child,
    );
  }
}

class _ItemListSurface extends StatelessWidget {
  const _ItemListSurface({required this.title, required this.items});

  final String title;
  final List<LearningItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.h4),
          const SizedBox(height: AppSpacing.regular),
          if (items.isEmpty)
            Text('None yet.', style: theme.textTheme.muted)
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.compact),
                child: Text(
                  item.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NextReviewSurface extends StatelessWidget {
  const _NextReviewSurface({required this.nextReviewAt});

  final DateTime? nextReviewAt;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Next review', style: theme.textTheme.h4),
          const SizedBox(height: AppSpacing.compact),
          Text(
            nextReviewAt == null
                ? 'No scheduled review.'
                : _formatDate(nextReviewAt!.toLocal()),
            style: theme.textTheme.muted,
          ),
        ],
      ),
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

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:whole_knowledge/app/theme/app_radius.dart';
import 'package:whole_knowledge/app/theme/app_spacing.dart';
import 'package:whole_knowledge/application/learning/review_repository.dart';
import 'package:whole_knowledge/application/learning/review_submission_id.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';
import 'package:whole_knowledge/domain/learning/review_attempt.dart';

enum _ReviewStage { recall, revealed, production, rating }

class TodayScreen extends StatefulWidget {
  const TodayScreen({
    required this.dueItems,
    required this.reviews,
    required this.queueStatusMessage,
    required this.onCompleted,
    required this.onReload,
    required this.onQuickCapture,
    super.key,
  });

  final List<LearningItem> dueItems;
  final ReviewRepository reviews;
  final String? queueStatusMessage;
  final ValueChanged<LearningItem> onCompleted;
  final VoidCallback onReload;
  final VoidCallback onQuickCapture;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final _production = TextEditingController();
  final _productionFocus = FocusNode();
  late List<LearningItem> _queue;
  _ReviewStage _stage = _ReviewStage.recall;
  bool _reviewing = false;
  bool _completed = false;
  bool _isSaving = false;
  String? _error;
  ReviewRating? _failedRating;
  late String _submissionId;
  int _reviewedInSession = 0;
  int _reviewTotal = 0;

  @override
  void initState() {
    super.initState();
    _queue = List.of(widget.dueItems);
    _submissionId = ReviewSubmissionId.generate();
  }

  @override
  void didUpdateWidget(covariant TodayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_reviewing) {
      _queue = List.of(widget.dueItems);
      if (widget.dueItems.isNotEmpty) {
        _completed = false;
      }
    }
  }

  @override
  void dispose() {
    _production.dispose();
    _productionFocus.dispose();
    super.dispose();
  }

  void _startReview() {
    setState(() {
      _queue = List.of(widget.dueItems);
      _reviewing = _queue.isNotEmpty;
      _completed = false;
      _stage = _ReviewStage.recall;
      _error = null;
      _failedRating = null;
      _production.clear();
      _reviewedInSession = 0;
      _reviewTotal = _queue.length;
      _submissionId = ReviewSubmissionId.generate();
    });
  }

  void _continueToRating() {
    final response = _production.text.trim();
    if (response.isEmpty) {
      setState(() => _error = 'Write a response before self-rating.');
      return;
    }
    if (response.length > 10000) {
      setState(() {
        _error = 'Keep the production response under 10,000 characters.';
      });
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
      widget.onCompleted(updatedItem);
    } on Object {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _stage = _ReviewStage.rating;
        _failedRating = rating;
        _error =
            'Could not confirm this review. Retry safely with the same '
            'response, or discard it and reload the queue.';
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
          child: _reviewing ? _buildReview(context) : _buildToday(context),
        ),
      ),
    );
  }

  Widget _buildToday(BuildContext context) {
    final theme = ShadTheme.of(context);
    final dueCount = widget.dueItems.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Today', style: theme.textTheme.h1),
        const SizedBox(height: AppSpacing.compact),
        Text(
          dueCount == 0
              ? 'Nothing is due right now.'
              : '$dueCount ${dueCount == 1 ? 'item' : 'items'} ready for review.',
          style: theme.textTheme.muted,
        ),
        const SizedBox(height: AppSpacing.section),
        if (_completed) ...[
          _StatusSurface(
            child: Text('Review complete.', style: theme.textTheme.p),
          ),
          const SizedBox(height: AppSpacing.regular),
        ],
        if (widget.queueStatusMessage != null)
          Text(widget.queueStatusMessage!, style: theme.textTheme.p)
        else if (dueCount > 0)
          ShadButton(
            key: const ValueKey('start-review'),
            onPressed: _startReview,
            child: const Text('Start review'),
          )
        else
          Text(
            'Capture something useful when you next meet it in the wild.',
            style: theme.textTheme.p,
          ),
        const SizedBox(height: AppSpacing.regular),
        ShadButton.outline(
          onPressed: widget.onQuickCapture,
          child: const Text('Quick capture'),
        ),
      ],
    );
  }

  Widget _buildReview(BuildContext context) {
    final theme = ShadTheme.of(context);
    final item = _queue.first;
    return FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review', style: theme.textTheme.h1),
          const SizedBox(height: AppSpacing.compact),
          Text(
            '${_reviewedInSession + 1} of $_reviewTotal',
            style: theme.textTheme.muted,
          ),
          const SizedBox(height: AppSpacing.section),
          _StatusSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _stage == _ReviewStage.recall
                        ? 'Retrieve'
                        : _stage == _ReviewStage.production
                        ? 'Produce'
                        : _stage == _ReviewStage.rating
                        ? 'Self-rate'
                        : 'Check',
                    style: theme.textTheme.small.copyWith(
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.regular),
                Text(item.content, style: theme.textTheme.h2),
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
                    placeholder: const Text('Write your response'),
                    minHeight: 112,
                    maxHeight: 220,
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
          if (_stage == _ReviewStage.recall)
            ShadButton(
              key: const ValueKey('reveal-answer'),
              onPressed: () {
                setState(() => _stage = _ReviewStage.revealed);
              },
              child: const Text('Reveal notes'),
            ),
          if (_stage == _ReviewStage.revealed)
            ShadButton(
              onPressed: _enterProduction,
              child: const Text('Continue to production'),
            ),
          if (_stage == _ReviewStage.production)
            ShadButton(
              key: const ValueKey('continue-to-rating'),
              onPressed: _continueToRating,
              child: const Text('Continue to self-rating'),
            ),
          if (_stage == _ReviewStage.rating) ...[
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
        ],
      ),
    );
  }

  void _reloadQueue() {
    setState(() {
      _reviewing = false;
      _completed = false;
      _stage = _ReviewStage.recall;
      _error = null;
      _failedRating = null;
      _production.clear();
    });
    widget.onReload();
  }

  static String _ratingLabel(ReviewRating rating) {
    return switch (rating) {
      ReviewRating.again => 'Again · 10m',
      ReviewRating.hard => 'Hard · 1d',
      ReviewRating.good => 'Good · 3d',
      ReviewRating.easy => 'Easy · 7d',
    };
  }
}

class _StatusSurface extends StatelessWidget {
  const _StatusSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.pageCompact),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: AppRadius.surface,
      ),
      child: child,
    );
  }
}

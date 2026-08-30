import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:whole_knowledge/app/theme/app_colors.dart';
import 'package:whole_knowledge/app/theme/app_motion.dart';
import 'package:whole_knowledge/app/theme/app_radius.dart';
import 'package:whole_knowledge/app/theme/app_spacing.dart';
import 'package:whole_knowledge/app/theme/app_typography.dart';
import 'package:whole_knowledge/application/learning/review_session_controller.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';
import 'package:whole_knowledge/domain/learning/review_attempt.dart';
import 'package:whole_knowledge/presentation/components/compact_editing_context_menu.dart';

class ReviewFocusView extends StatefulWidget {
  const ReviewFocusView({
    required this.controller,
    required this.onPaused,
    required this.onCompleted,
    required this.onReload,
    super.key,
  });

  final ReviewSessionController controller;
  final VoidCallback onPaused;
  final ValueChanged<LearningItem> onCompleted;
  final VoidCallback onReload;

  @override
  State<ReviewFocusView> createState() => _ReviewFocusViewState();
}

class _ReviewFocusViewState extends State<ReviewFocusView> {
  final _production = TextEditingController();
  final _productionFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_controllerChanged);
    _syncResponse();
  }

  @override
  void didUpdateWidget(covariant ReviewFocusView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_controllerChanged);
      widget.controller.addListener(_controllerChanged);
      _syncResponse();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_controllerChanged);
    _production.dispose();
    _productionFocus.dispose();
    super.dispose();
  }

  void _controllerChanged() {
    if (!mounted) return;
    _syncResponse();
    setState(() {});
  }

  void _syncResponse() {
    final response = widget.controller.responseText;
    if (_production.text == response) return;
    _production.value = TextEditingValue(
      text: response,
      selection: TextSelection.collapsed(offset: response.length),
    );
  }

  Future<void> _pause() async {
    final review = widget.controller;
    if (review.isSaving) return;
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
    widget.onPaused();
  }

  void _enterProduction() {
    widget.controller.enterProduction();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _productionFocus.requestFocus();
    });
  }

  void _continueToRating() {
    widget.controller.updateResponse(_production.text);
    widget.controller.continueToRating();
  }

  Future<void> _rate(ReviewRating rating) async {
    final updated = await widget.controller.rate(rating);
    if (!mounted || updated == null) return;
    widget.onCompleted(updated);
  }

  void _reloadQueue() {
    widget.controller.discard();
    widget.onReload();
  }

  @override
  Widget build(BuildContext context) {
    final review = widget.controller;
    if (!review.isReviewing || review.queue.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = ShadTheme.of(context);
    final item = review.queue.first;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        key: const ValueKey('review-focus'),
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
                        enabled: !review.isSaving,
                        onPressed: _pause,
                        leading: const Icon(Icons.close, size: 18),
                        child: const Text('Pause'),
                      ),
                      const Spacer(),
                      Text(
                        '${review.reviewedInSession + 1} of ${review.reviewTotal}',
                        style: theme.textTheme.muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.pageCompact),
                  _ReviewProgress(stage: review.stage),
                  const SizedBox(height: AppSpacing.regular),
                  _ReviewSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _stageLabel(review.stage),
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
                            key: ValueKey(review.stage),
                            child: _stageNarrative(context, item, review.stage),
                          ),
                        ),
                        if (review.stage == ReviewStage.production ||
                            review.stage == ReviewStage.rating) ...[
                          const SizedBox(height: AppSpacing.regular),
                          ShadTextarea(
                            key: const ValueKey('production-response'),
                            controller: _production,
                            focusNode: _productionFocus,
                            readOnly: review.stage == ReviewStage.rating,
                            enabled: !review.isSaving,
                            contextMenuBuilder: compactEditingContextMenu,
                            placeholder: const Text('Write your response'),
                            minHeight: 128,
                            maxHeight: 260,
                            onChanged: review.updateResponse,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (review.error != null) ...[
                    const SizedBox(height: AppSpacing.regular),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        review.error!,
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
                      key: ValueKey('actions-${review.stage}'),
                      child: _actions(context, review),
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

  Widget _stageNarrative(
    BuildContext context,
    LearningItem item,
    ReviewStage stage,
  ) {
    final theme = ShadTheme.of(context);
    return switch (stage) {
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
      ReviewStage.production || ReviewStage.rating => Text(
        'Use it in a sentence or write what you would say.',
        style: theme.textTheme.p,
      ),
    };
  }

  Widget _actions(BuildContext context, ReviewSessionController review) {
    final theme = ShadTheme.of(context);
    return switch (review.stage) {
      ReviewStage.recall => ShadButton(
        key: const ValueKey('reveal-answer'),
        onPressed: review.reveal,
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
            children: review.failedRating == null
                ? ReviewRating.values
                      .map(
                        (rating) => ShadButton.outline(
                          key: ValueKey('rating-${rating.name}'),
                          enabled: !review.isSaving,
                          onPressed: () => _rate(rating),
                          child: Text(_ratingLabel(rating)),
                        ),
                      )
                      .toList(growable: false)
                : [
                    ShadButton.outline(
                      key: const ValueKey('retry-review'),
                      enabled: !review.isSaving,
                      onPressed: () => _rate(review.failedRating!),
                      child: Text(_ratingLabel(review.failedRating!)),
                    ),
                    ShadButton.outline(
                      key: const ValueKey('reload-review-queue'),
                      enabled: !review.isSaving,
                      onPressed: _reloadQueue,
                      child: const Text('Discard response and reload'),
                    ),
                  ],
          ),
        ],
      ),
    };
  }

  static String _stageLabel(ReviewStage stage) => switch (stage) {
    ReviewStage.recall => 'Retrieve',
    ReviewStage.revealed => 'Check',
    ReviewStage.production => 'Produce',
    ReviewStage.rating => 'Self-rate',
  };

  static String _ratingLabel(ReviewRating rating) => switch (rating) {
    ReviewRating.again => 'Again · 10m',
    ReviewRating.hard => 'Hard · 1d',
    ReviewRating.good => 'Good · 3d',
    ReviewRating.easy => 'Easy · 7d',
  };
}

class _ReviewSurface extends StatelessWidget {
  const _ReviewSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.pageCompact),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: AppRadius.organicA,
      ),
      child: child,
    );
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

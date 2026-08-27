import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:whole_knowledge/app/theme/app_radius.dart';
import 'package:whole_knowledge/app/theme/app_spacing.dart';
import 'package:whole_knowledge/application/learning/learning_item_repository.dart';
import 'package:whole_knowledge/application/learning/review_repository.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';
import 'package:whole_knowledge/domain/learning/review_attempt.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    required this.learningItems,
    required this.reviews,
    super.key,
  });

  final LearningItemRepository learningItems;
  final ReviewRepository reviews;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  static const _pageSize = 50;
  final List<LearningItem> _items = [];
  bool _loading = false;
  bool _hasMore = true;
  String? _error;
  LearningItem? _selected;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.learningItems.listPage(
        offset: _items.length,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page);
        _hasMore = page.length == _pageSize;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load the library.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= AppSpacing.contentLayoutBreakpoint;
        if (!wide && _selected != null) {
          return _LibraryDetail(
            item: _selected!,
            reviews: widget.reviews,
            onBack: () => setState(() => _selected = null),
          );
        }
        final list = _LibraryList(
          items: _items,
          loading: _loading,
          hasMore: _hasMore,
          error: _error,
          selected: _selected,
          onSelect: (item) => setState(() => _selected = item),
          onLoadMore: _loadMore,
        );
        if (!wide) return list;
        return Row(
          children: [
            SizedBox(width: 420, child: list),
            VerticalDivider(
              width: 1,
              color: ShadTheme.of(context).colorScheme.border,
            ),
            Expanded(
              child: _selected == null
                  ? const Center(
                      child: Text(
                        'Select an item to inspect its learning history.',
                      ),
                    )
                  : _LibraryDetail(item: _selected!, reviews: widget.reviews),
            ),
          ],
        );
      },
    );
  }
}

class _LibraryList extends StatelessWidget {
  const _LibraryList({
    required this.items,
    required this.loading,
    required this.hasMore,
    required this.error,
    required this.selected,
    required this.onSelect,
    required this.onLoadMore,
  });

  final List<LearningItem> items;
  final bool loading;
  final bool hasMore;
  final String? error;
  final LearningItem? selected;
  final ValueChanged<LearningItem> onSelect;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageCompact),
      children: [
        Text('Library', style: theme.textTheme.h1),
        const SizedBox(height: AppSpacing.compact),
        Text(
          '${items.length}${hasMore ? '+' : ''} ${items.length == 1 ? 'item' : 'items'}',
          style: theme.textTheme.muted,
        ),
        const SizedBox(height: AppSpacing.page),
        if (items.isEmpty && loading)
          const Center(child: CircularProgressIndicator.adaptive())
        else if (items.isEmpty && error != null)
          _LoadAction(message: error!, onPressed: onLoadMore)
        else if (items.isEmpty)
          Text('Captured language will appear here.', style: theme.textTheme.p)
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.compact),
              child: Semantics(
                button: true,
                selected: selected?.id == item.id,
                child: InkWell(
                  key: ValueKey('library-item-${item.id}'),
                  borderRadius: AppRadius.organicSmall,
                  onTap: () => onSelect(item),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.regular),
                    decoration: BoxDecoration(
                      color: selected?.id == item.id
                          ? theme.colorScheme.muted
                          : null,
                      border: Border.all(color: theme.colorScheme.border),
                      borderRadius: AppRadius.organicSmall,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.content, style: theme.textTheme.h4),
                        if (item.meaning != null) ...[
                          const SizedBox(height: AppSpacing.compact),
                          Text(
                            item.meaning!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.muted,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.compact),
                        Text(
                          [
                            item.kind == LearningItemKind.expression
                                ? 'Expression'
                                : 'Vocabulary',
                            if (item.partOfSpeech != null) item.partOfSpeech!,
                          ].join(' · '),
                          style: theme.textTheme.small,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (error != null && items.isNotEmpty)
          _LoadAction(message: error!, onPressed: onLoadMore),
        if (hasMore && error == null) ...[
          const SizedBox(height: AppSpacing.regular),
          ShadButton.outline(
            enabled: !loading,
            onPressed: onLoadMore,
            child: Text(loading ? 'Loading' : 'Load more'),
          ),
        ],
      ],
    );
  }
}

class _LibraryDetail extends StatefulWidget {
  const _LibraryDetail({
    required this.item,
    required this.reviews,
    this.onBack,
  });

  final LearningItem item;
  final ReviewRepository reviews;
  final VoidCallback? onBack;

  @override
  State<_LibraryDetail> createState() => _LibraryDetailState();
}

class _LibraryDetailState extends State<_LibraryDetail> {
  static const _pageSize = 50;
  final List<ReviewAttempt> _attempts = [];
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  @override
  void didUpdateWidget(covariant _LibraryDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _attempts.clear();
      _hasMore = true;
      _error = null;
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final page = await widget.reviews.listAttempts(
        learningItemId: widget.item.id,
        offset: _attempts.length,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _attempts.addAll(page);
        _hasMore = page.length == _pageSize;
        _loading = false;
        _error = null;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load review history.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final item = widget.item;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageCompact),
      children: [
        if (widget.onBack != null)
          Align(
            alignment: Alignment.centerLeft,
            child: ShadButton.ghost(
              onPressed: widget.onBack,
              leading: const Icon(Icons.arrow_back, size: 18),
              child: const Text('Library'),
            ),
          ),
        Text(item.content, style: theme.textTheme.h1),
        if (item.partOfSpeech != null) ...[
          const SizedBox(height: AppSpacing.compact),
          Text(item.partOfSpeech!, style: theme.textTheme.muted),
        ],
        const SizedBox(height: AppSpacing.page),
        _DetailField(label: 'Meaning', value: item.meaning),
        _DetailField(label: 'Context', value: item.context),
        _DetailField(label: 'Source', value: item.source),
        _DetailField(label: 'Review count', value: '${item.reviewCount}'),
        _DetailField(
          label: 'Production count',
          value: '${item.productionCount}',
        ),
        _DetailField(
          label: 'Next review',
          value: _formatDate(item.nextReviewAt.toLocal()),
        ),
        const SizedBox(height: AppSpacing.page),
        Text('Review history', style: theme.textTheme.h3),
        const SizedBox(height: AppSpacing.regular),
        if (_attempts.isEmpty && _loading)
          const Center(child: CircularProgressIndicator.adaptive())
        else if (_attempts.isEmpty && _error == null)
          Text('No review attempts yet.', style: theme.textTheme.muted)
        else
          ..._attempts.map(
            (attempt) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.compact),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.regular),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.border),
                  borderRadius: AppRadius.organicSmall,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attempt.attemptType == ReviewAttemptType.production
                          ? 'Production'
                          : 'Retrieval',
                      style: theme.textTheme.small,
                    ),
                    if (attempt.rating != null)
                      Text(attempt.rating!.name, style: theme.textTheme.p),
                    if (attempt.responseText != null) ...[
                      const SizedBox(height: AppSpacing.compact),
                      Text(attempt.responseText!),
                    ],
                    const SizedBox(height: AppSpacing.compact),
                    Text(
                      _formatDate(attempt.createdAt.toLocal()),
                      style: theme.textTheme.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (_error != null) _LoadAction(message: _error!, onPressed: _loadMore),
        if (_hasMore && _error == null && _attempts.isNotEmpty)
          ShadButton.outline(
            enabled: !_loading,
            onPressed: _loadMore,
            child: Text(_loading ? 'Loading' : 'Load more history'),
          ),
      ],
    );
  }

  static String _formatDate(DateTime value) {
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.day}/${value.month}/${value.year} · ${value.hour}:$minute';
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.regular),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.small),
          const SizedBox(height: AppSpacing.compact),
          SelectableText(value!, style: theme.textTheme.p),
        ],
      ),
    );
  }
}

class _LoadAction extends StatelessWidget {
  const _LoadAction({required this.message, required this.onPressed});

  final String message;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(message),
      const SizedBox(height: AppSpacing.compact),
      ShadButton.outline(onPressed: onPressed, child: const Text('Retry')),
    ],
  );
}

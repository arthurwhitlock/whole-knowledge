import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:whole_knowledge/app/app_dependencies.dart';
import 'package:whole_knowledge/app/theme/app_spacing.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';
import 'package:whole_knowledge/presentation/learning/capture_screen.dart';
import 'package:whole_knowledge/presentation/learning/library_screen.dart';
import 'package:whole_knowledge/presentation/learning/today_screen.dart';

enum WorkspaceDestination { today, capture, library }

class LearningWorkspace extends StatefulWidget {
  const LearningWorkspace({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  State<LearningWorkspace> createState() => _LearningWorkspaceState();
}

class _LearningWorkspaceState extends State<LearningWorkspace>
    with WidgetsBindingObserver {
  final _contentKey = GlobalKey();
  WorkspaceDestination _destination = WorkspaceDestination.today;
  List<LearningItem> _dueItems = const [];
  List<LearningItem> _libraryItems = const [];
  bool _isLoading = true;
  bool _hasLoadedData = false;
  String? _loadError;
  Timer? _dueRefreshTimer;
  int _reloadGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dueRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reload();
    }
  }

  Future<void> _reload() async {
    final generation = ++_reloadGeneration;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        widget.dependencies.learningItems.listDue(at: DateTime.now().toUtc()),
        widget.dependencies.learningItems.listAll(),
      ]);
      if (!mounted || generation != _reloadGeneration) return;
      setState(() {
        _dueItems = results[0];
        _libraryItems = results[1];
        _isLoading = false;
        _hasLoadedData = true;
      });
      _scheduleDueRefresh();
    } on Object {
      if (!mounted || generation != _reloadGeneration) return;
      setState(() {
        _loadError = 'Could not load your learning items.';
        _isLoading = false;
      });
    }
  }

  void _select(WorkspaceDestination destination) {
    setState(() => _destination = destination);
    if (destination == WorkspaceDestination.today) {
      _reload();
    }
  }

  void _captured() {
    _select(WorkspaceDestination.today);
  }

  void _reviewCompleted(LearningItem updatedItem) {
    setState(() {
      _dueItems = _dueItems
          .where((item) => item.id != updatedItem.id)
          .toList(growable: false);
      _libraryItems = _libraryItems
          .map((item) => item.id == updatedItem.id ? updatedItem : item)
          .toList(growable: false);
    });
    _scheduleDueRefresh();
    _reload();
  }

  void _scheduleDueRefresh() {
    _dueRefreshTimer?.cancel();
    final now = DateTime.now().toUtc();
    DateTime? nextDueAt;
    for (final item in _libraryItems) {
      if (item.status != LearningItemStatus.active || item.reviewCount == 0) {
        continue;
      }
      if (item.nextReviewAt.isAfter(now) &&
          (nextDueAt == null || item.nextReviewAt.isBefore(nextDueAt))) {
        nextDueAt = item.nextReviewAt;
      }
    }
    if (nextDueAt != null) {
      _dueRefreshTimer = Timer(nextDueAt.difference(now), _reload);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                constraints.maxWidth >= AppSpacing.navigationBreakpoint;
            final content = _WorkspaceContent(
              key: _contentKey,
              destination: _destination,
              isInitialLoading: _isLoading && !_hasLoadedData,
              isRefreshing: _isLoading,
              hasLoadedData: _hasLoadedData,
              loadError: _loadError,
              dueItems: _dueItems,
              libraryItems: _libraryItems,
              dependencies: widget.dependencies,
              onRetry: _reload,
              onCaptured: _captured,
              onReviewCompleted: _reviewCompleted,
              onQuickCapture: () => _select(WorkspaceDestination.capture),
            );

            if (!wide) {
              return Column(
                children: [
                  Expanded(child: content),
                  NavigationBar(
                    selectedIndex: _destination.index,
                    backgroundColor: theme.colorScheme.background,
                    indicatorColor: theme.colorScheme.muted,
                    onDestinationSelected: (index) {
                      _select(WorkspaceDestination.values[index]);
                    },
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.today_outlined),
                        selectedIcon: Icon(Icons.today),
                        label: 'Today',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.add_box_outlined),
                        selectedIcon: Icon(Icons.add_box),
                        label: 'Capture',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.library_books_outlined),
                        selectedIcon: Icon(Icons.library_books),
                        label: 'Library',
                      ),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                NavigationRail(
                  selectedIndex: _destination.index,
                  backgroundColor: theme.colorScheme.background,
                  indicatorColor: theme.colorScheme.muted,
                  labelType: NavigationRailLabelType.all,
                  minWidth: 88,
                  onDestinationSelected: (index) {
                    _select(WorkspaceDestination.values[index]);
                  },
                  leading: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.regular),
                    child: Text('WK', style: theme.textTheme.h4),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.today_outlined),
                      selectedIcon: Icon(Icons.today),
                      label: Text('Today'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.add_box_outlined),
                      selectedIcon: Icon(Icons.add_box),
                      label: Text('Capture'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.library_books_outlined),
                      selectedIcon: Icon(Icons.library_books),
                      label: Text('Library'),
                    ),
                  ],
                ),
                VerticalDivider(width: 1, color: theme.colorScheme.border),
                Expanded(child: content),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WorkspaceContent extends StatelessWidget {
  const _WorkspaceContent({
    super.key,
    required this.destination,
    required this.isInitialLoading,
    required this.isRefreshing,
    required this.hasLoadedData,
    required this.loadError,
    required this.dueItems,
    required this.libraryItems,
    required this.dependencies,
    required this.onRetry,
    required this.onCaptured,
    required this.onReviewCompleted,
    required this.onQuickCapture,
  });

  final WorkspaceDestination destination;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool hasLoadedData;
  final String? loadError;
  final List<LearningItem> dueItems;
  final List<LearningItem> libraryItems;
  final AppDependencies dependencies;
  final VoidCallback onRetry;
  final VoidCallback onCaptured;
  final ValueChanged<LearningItem> onReviewCompleted;
  final VoidCallback onQuickCapture;

  @override
  Widget build(BuildContext context) {
    if (isInitialLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (loadError != null && !hasLoadedData) {
      return _LoadFailure(message: loadError!, onRetry: onRetry);
    }

    final content = IndexedStack(
      index: destination.index,
      children: [
        TodayScreen(
          dueItems: dueItems,
          reviews: dependencies.reviews,
          queueStatusMessage: isRefreshing
              ? 'Refreshing review queue.'
              : loadError != null
              ? 'Review queue unavailable. Retry loading above.'
              : null,
          onCompleted: onReviewCompleted,
          onReload: onRetry,
          onQuickCapture: onQuickCapture,
        ),
        CaptureScreen(
          learningItems: dependencies.learningItems,
          onCaptured: onCaptured,
        ),
        LibraryScreen(items: libraryItems),
      ],
    );

    if (loadError == null) return content;

    return Column(
      children: [
        _LoadFailure(message: loadError!, onRetry: onRetry, compact: true),
        Expanded(child: content),
      ],
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({
    required this.message,
    required this.onRetry,
    this.compact = false,
  });

  final String message;
  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final failure = Semantics(
      liveRegion: true,
      child: Padding(
        padding: EdgeInsets.all(
          compact ? AppSpacing.regular : AppSpacing.pageCompact,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: theme.textTheme.p),
            const SizedBox(height: AppSpacing.regular),
            ShadButton.outline(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
    return compact ? failure : Center(child: failure);
  }
}

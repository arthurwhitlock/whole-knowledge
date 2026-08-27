import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:whole_knowledge/app/app_dependencies.dart';
import 'package:whole_knowledge/app/theme/app_spacing.dart';
import 'package:whole_knowledge/application/capture/capture_session_controller.dart';
import 'package:whole_knowledge/application/learning/today_load_controller.dart';
import 'package:whole_knowledge/application/learning/today_overview.dart';
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
  final _todayKey = GlobalKey<TodayScreenState>();
  late final CaptureSessionController _capture;
  late final TodayLoadController _today;
  WorkspaceDestination _destination = WorkspaceDestination.today;
  bool _startupReady = false;
  bool _reviewFocusMode = false;
  Timer? _dueRefreshTimer;
  int _libraryGeneration = 0;
  bool _libraryVisited = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _capture = CaptureSessionController(
      widget.dependencies.captureDrafts,
      widget.dependencies.lexicalProvider,
      widget.dependencies.learningItems,
    );
    _today = TodayLoadController(
      LoadTodayOverview(widget.dependencies.learningItems),
    )..addListener(_todayChanged);
    _initialize();
  }

  Future<void> _initialize() async {
    final restoreFuture = _capture.restore();
    _today.refresh();
    final restored = await restoreFuture;
    if (!mounted) return;
    setState(() {
      if (restored) _destination = WorkspaceDestination.capture;
      _startupReady = true;
    });
    _scheduleDueRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dueRefreshTimer?.cancel();
    _capture.flush();
    _capture.dispose();
    _today.removeListener(_todayChanged);
    _today.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _today.refresh();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _capture.flush();
    }
  }

  void _todayChanged() {
    if (!mounted) return;
    setState(() {});
    if (!_today.isLoading) _scheduleDueRefresh();
  }

  void _select(WorkspaceDestination destination) {
    setState(() {
      _destination = destination;
      if (destination == WorkspaceDestination.library) {
        _libraryVisited = true;
      }
    });
    if (destination == WorkspaceDestination.today) _today.refresh();
  }

  void _captured() {
    setState(() {
      _destination = WorkspaceDestination.today;
      _libraryGeneration += 1;
      _libraryVisited = false;
    });
    _today.refresh();
  }

  void _reviewCompleted(LearningItem updatedItem) {
    setState(() {
      _libraryGeneration += 1;
      _libraryVisited = false;
    });
    _today.reconcileCompleted(updatedItem);
    _today.refresh();
  }

  void _scheduleDueRefresh() {
    _dueRefreshTimer?.cancel();
    final next = _today.overview?.nextReviewAt;
    if (next == null) return;
    final delay = next.difference(DateTime.now().toUtc());
    if (delay.isNegative) return;
    _dueRefreshTimer = Timer(delay, _today.refresh);
  }

  @override
  Widget build(BuildContext context) {
    if (!_startupReady) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
      );
    }
    final theme = ShadTheme.of(context);
    return PopScope(
      canPop: !_reviewFocusMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _reviewFocusMode) {
          _todayKey.currentState?.pauseReviewFromSystem();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide =
                  constraints.maxWidth >= AppSpacing.navigationBreakpoint;
              final content = _WorkspaceContent(
                key: _contentKey,
                destination: _destination,
                dependencies: widget.dependencies,
                capture: _capture,
                today: _today,
                todayKey: _todayKey,
                libraryVisited: _libraryVisited,
                libraryGeneration: _libraryGeneration,
                onRetry: _today.refresh,
                onCaptured: _captured,
                onReviewCompleted: _reviewCompleted,
                onQuickCapture: () => _select(WorkspaceDestination.capture),
                onReviewModeChanged: (active) {
                  setState(() => _reviewFocusMode = active);
                },
              );

              if (_reviewFocusMode) return content;
              if (!wide) {
                return Column(
                  children: [
                    Expanded(child: content),
                    NavigationBar(
                      selectedIndex: _destination.index,
                      backgroundColor: theme.colorScheme.background,
                      indicatorColor: theme.colorScheme.muted,
                      onDestinationSelected: (index) =>
                          _select(WorkspaceDestination.values[index]),
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
                    onDestinationSelected: (index) =>
                        _select(WorkspaceDestination.values[index]),
                    leading: Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppSpacing.regular,
                      ),
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
      ),
    );
  }
}

class _WorkspaceContent extends StatelessWidget {
  const _WorkspaceContent({
    super.key,
    required this.destination,
    required this.dependencies,
    required this.capture,
    required this.today,
    required this.todayKey,
    required this.libraryVisited,
    required this.libraryGeneration,
    required this.onRetry,
    required this.onCaptured,
    required this.onReviewCompleted,
    required this.onQuickCapture,
    required this.onReviewModeChanged,
  });

  final WorkspaceDestination destination;
  final AppDependencies dependencies;
  final CaptureSessionController capture;
  final TodayLoadController today;
  final GlobalKey<TodayScreenState> todayKey;
  final bool libraryVisited;
  final int libraryGeneration;
  final VoidCallback onRetry;
  final VoidCallback onCaptured;
  final ValueChanged<LearningItem> onReviewCompleted;
  final VoidCallback onQuickCapture;
  final ValueChanged<bool> onReviewModeChanged;

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: destination.index,
      children: [
        TodayScreen(
          key: todayKey,
          overview: today.overview,
          isInitialLoading: today.isInitialLoading,
          isRefreshing: today.isRefreshing,
          loadError: today.error,
          reviews: dependencies.reviews,
          onCompleted: onReviewCompleted,
          onReload: onRetry,
          onQuickCapture: onQuickCapture,
          onReviewModeChanged: onReviewModeChanged,
        ),
        CaptureScreen(controller: capture, onCaptured: onCaptured),
        if (libraryVisited)
          LibraryScreen(
            key: ValueKey('library-$libraryGeneration'),
            learningItems: dependencies.learningItems,
            reviews: dependencies.reviews,
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }
}

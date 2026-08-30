import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:whole_knowledge/app/app_dependencies.dart';
import 'package:whole_knowledge/app/theme/app_spacing.dart';
import 'package:whole_knowledge/application/capture/capture_session_controller.dart';
import 'package:whole_knowledge/application/learning/review_session_controller.dart';
import 'package:whole_knowledge/application/learning/today_load_controller.dart';
import 'package:whole_knowledge/application/learning/today_overview.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';
import 'package:whole_knowledge/presentation/learning/capture_screen.dart';
import 'package:whole_knowledge/presentation/learning/library_screen.dart';
import 'package:whole_knowledge/presentation/learning/review_focus_view.dart';
import 'package:whole_knowledge/presentation/learning/today_screen.dart';

enum WorkspaceDestination { today, capture, library }

enum ReviewLaunchOrigin { today, capture }

class LearningWorkspace extends StatefulWidget {
  const LearningWorkspace({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  State<LearningWorkspace> createState() => _LearningWorkspaceState();
}

class _LearningWorkspaceState extends State<LearningWorkspace>
    with WidgetsBindingObserver {
  final _contentKey = GlobalKey();
  late final CaptureSessionController _capture;
  late final TodayLoadController _today;
  late final ReviewSessionController _review;
  WorkspaceDestination _destination = WorkspaceDestination.today;
  ReviewLaunchOrigin? _reviewOrigin;
  bool _startupReady = false;
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
    _review = ReviewSessionController(widget.dependencies.reviews)
      ..addListener(_reviewChanged);
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
    _review.removeListener(_reviewChanged);
    _review.dispose();
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
    final overview = _today.overview;
    if (overview != null) _review.updateDueItems(overview.dueItems);
    setState(() {});
    if (!_today.isLoading) _scheduleDueRefresh();
  }

  void _reviewChanged() {
    if (mounted) setState(() {});
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
    if (_review.queue.isEmpty) {
      final origin = _reviewOrigin;
      _reviewOrigin = null;
      if (origin == ReviewLaunchOrigin.capture) {
        _destination = WorkspaceDestination.capture;
        unawaited(_capture.discover());
      } else {
        _destination = WorkspaceDestination.today;
      }
    }
  }

  void _startDueReview() {
    final due = _today.overview?.dueItems ?? const <LearningItem>[];
    if (_review.start(due)) {
      _reviewOrigin = ReviewLaunchOrigin.today;
      setState(() => _destination = WorkspaceDestination.today);
    }
  }

  bool _startTargetedReview(LearningItem item) {
    if (!_review.start([item])) return false;
    _reviewOrigin = ReviewLaunchOrigin.capture;
    setState(() => _destination = WorkspaceDestination.capture);
    return true;
  }

  void _resumeReview() {
    _review.resume();
  }

  void _pauseReview() {
    if (_review.isSaving || !_review.isReviewing) return;
    _review.pause();
    setState(() {
      _destination = _reviewOrigin == ReviewLaunchOrigin.capture
          ? WorkspaceDestination.capture
          : WorkspaceDestination.today;
    });
  }

  void _reloadReviewOrigin() {
    final origin = _reviewOrigin;
    _reviewOrigin = null;
    setState(() {
      _destination = origin == ReviewLaunchOrigin.capture
          ? WorkspaceDestination.capture
          : WorkspaceDestination.today;
    });
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
      canPop: !_review.isReviewing,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _review.isReviewing) _pauseReview();
      },
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide =
                  constraints.maxWidth >= AppSpacing.navigationBreakpoint;
              if (_review.isReviewing) {
                return ReviewFocusView(
                  controller: _review,
                  onPaused: _pauseReview,
                  onCompleted: _reviewCompleted,
                  onReload: _reloadReviewOrigin,
                );
              }
              final content = _WorkspaceContent(
                key: _contentKey,
                destination: _destination,
                dependencies: widget.dependencies,
                capture: _capture,
                today: _today,
                libraryVisited: _libraryVisited,
                libraryGeneration: _libraryGeneration,
                onRetry: _today.refresh,
                onCaptured: _captured,
                onQuickCapture: () => _select(WorkspaceDestination.capture),
                reviewPaused:
                    _review.isPaused &&
                    _reviewOrigin == ReviewLaunchOrigin.today,
                captureReviewPaused:
                    _review.isPaused &&
                    _reviewOrigin == ReviewLaunchOrigin.capture,
                reviewCompleted: _review.completed,
                onStartReview: _startDueReview,
                onResumeReview: _resumeReview,
                onStartTargetedReview: _startTargetedReview,
              );

              if (!wide) {
                return Column(
                  children: [
                    Expanded(child: content),
                    NavigationBar(
                      selectedIndex: _destination.index,
                      backgroundColor: theme.colorScheme.background,
                      indicatorColor: theme.colorScheme.accent,
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
                    indicatorColor: theme.colorScheme.accent,
                    labelType: NavigationRailLabelType.all,
                    minWidth: 96,
                    onDestinationSelected: (index) =>
                        _select(WorkspaceDestination.values[index]),
                    leading: Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppSpacing.regular,
                      ),
                      child: Semantics(
                        header: true,
                        label: 'Whole Knowledge',
                        child: ExcludeSemantics(
                          child: Text(
                            'WHOLE\nKNOWLEDGE',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.muted.copyWith(
                              letterSpacing: 0.8,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ),
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
    required this.libraryVisited,
    required this.libraryGeneration,
    required this.onRetry,
    required this.onCaptured,
    required this.onQuickCapture,
    required this.reviewPaused,
    required this.captureReviewPaused,
    required this.reviewCompleted,
    required this.onStartReview,
    required this.onResumeReview,
    required this.onStartTargetedReview,
  });

  final WorkspaceDestination destination;
  final AppDependencies dependencies;
  final CaptureSessionController capture;
  final TodayLoadController today;
  final bool libraryVisited;
  final int libraryGeneration;
  final VoidCallback onRetry;
  final VoidCallback onCaptured;
  final VoidCallback onQuickCapture;
  final bool reviewPaused;
  final bool captureReviewPaused;
  final bool reviewCompleted;
  final VoidCallback onStartReview;
  final VoidCallback onResumeReview;
  final bool Function(LearningItem) onStartTargetedReview;

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: destination.index,
      children: [
        TodayScreen(
          overview: today.overview,
          isInitialLoading: today.isInitialLoading,
          isRefreshing: today.isRefreshing,
          loadError: today.error,
          reviewPaused: reviewPaused,
          reviewCompleted: reviewCompleted,
          onStartReview: onStartReview,
          onResumeReview: onResumeReview,
          onReload: onRetry,
          onQuickCapture: onQuickCapture,
        ),
        CaptureScreen(
          controller: capture,
          onCaptured: onCaptured,
          onTestItem: onStartTargetedReview,
          reviewPaused: captureReviewPaused,
          onResumeReview: onResumeReview,
        ),
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

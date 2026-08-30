import 'dart:async';

import 'package:flutter/material.dart';
import 'package:whole_knowledge/app/theme/app_motion.dart';
import 'package:whole_knowledge/application/capture/capture_session_controller.dart';
import 'package:whole_knowledge/application/capture/capture_session_state.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';
import 'package:whole_knowledge/presentation/learning/capture/discovered_view.dart';
import 'package:whole_knowledge/presentation/learning/capture/entry_checking_view.dart';
import 'package:whole_knowledge/presentation/learning/capture/expression_meaning_view.dart';
import 'package:whole_knowledge/presentation/learning/capture/production_view.dart';
import 'package:whole_knowledge/presentation/learning/capture/reencounter_view.dart';
import 'package:whole_knowledge/presentation/learning/capture/vocabulary_meaning_view.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({
    required this.controller,
    required this.onCaptured,
    this.onTestItem,
    this.reviewPaused = false,
    this.onResumeReview,
    this.clock,
    super.key,
  });

  final CaptureSessionController controller;
  final VoidCallback onCaptured;
  final bool Function(LearningItem)? onTestItem;
  final bool reviewPaused;
  final VoidCallback? onResumeReview;
  final DateTime Function()? clock;

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with WidgetsBindingObserver {
  Timer? _calendarTimer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _now = _readNow();
    widget.controller.addListener(_controllerChanged);
    _syncCalendarTimer();
  }

  @override
  void didUpdateWidget(covariant CaptureScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_controllerChanged);
      widget.controller.addListener(_controllerChanged);
    }
    if (oldWidget.clock != widget.clock) {
      _now = _readNow();
      _syncCalendarTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    setState(() => _now = _readNow());
    _syncCalendarTimer();
  }

  @override
  void dispose() {
    _calendarTimer?.cancel();
    widget.controller.removeListener(_controllerChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  DateTime _readNow() => widget.clock?.call() ?? DateTime.now();

  void _controllerChanged() {
    if (!mounted) return;
    setState(() {});
    _syncCalendarTimer();
  }

  bool get _usesRelativeCalendar =>
      widget.controller.state is CaptureReEncounter ||
      widget.controller.state is CaptureDiscovered;

  void _syncCalendarTimer() {
    _calendarTimer?.cancel();
    _calendarTimer = null;
    if (!_usesRelativeCalendar) return;
    final now = _readNow();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final delay = nextMidnight.difference(now);
    _calendarTimer = Timer(
      delay > Duration.zero ? delay : const Duration(seconds: 1),
      () {
        if (!mounted) return;
        setState(() => _now = _readNow());
        _syncCalendarTimer();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state;
    final canHandleBack = switch (state) {
      CaptureChecking() ||
      CaptureVocabularySenses() ||
      CaptureExpressionMeaning() ||
      CaptureReEncounter() ||
      CaptureProduction() => true,
      _ => false,
    };
    return PopScope(
      canPop: !canHandleBack,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && canHandleBack) widget.controller.back();
      },
      child: AnimatedSwitcher(
        duration: state is CaptureSaving || state is CaptureReconciling
            ? Duration.zero
            : AppMotion.responsive(context, AppMotion.standard),
        switchInCurve: AppMotion.standardCurve,
        switchOutCurve: AppMotion.instantCurve,
        transitionBuilder: (child, animation) {
          final offset = Tween<Offset>(
            begin: const Offset(0, 0.012),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offset, child: child),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_phaseKey(state)),
          child: switch (state) {
            CaptureRestoring() => const CaptureRestoringView(),
            CaptureEntry() || CaptureChecking() => CaptureEntryCheckingView(
              controller: widget.controller,
              state: state,
            ),
            CaptureVocabularySenses() => CaptureVocabularyMeaningView(
              controller: widget.controller,
              state: state,
            ),
            CaptureExpressionMeaning() => CaptureExpressionMeaningView(
              controller: widget.controller,
              state: state,
            ),
            CaptureReEncounter() => CaptureReEncounterView(
              controller: widget.controller,
              state: state,
              now: _now,
              onTestItem: widget.onTestItem,
              reviewPaused: widget.reviewPaused,
              onResumeReview: widget.onResumeReview,
            ),
            CaptureProduction() => CaptureProductionView(
              controller: widget.controller,
            ),
            CaptureSaving() || CaptureReconciling() => CaptureSubmissionView(
              controller: widget.controller,
              state: state,
            ),
            CaptureDiscovered() => CaptureDiscoveredView(
              controller: widget.controller,
              state: state,
              now: _now,
              onDone: widget.onCaptured,
            ),
          },
        ),
      ),
    );
  }

  static String _phaseKey(CaptureSessionState state) => switch (state) {
    CaptureRestoring() => 'restoring',
    CaptureEntry() => 'entry',
    CaptureChecking() => 'checking',
    CaptureVocabularySenses() => 'vocabulary',
    CaptureExpressionMeaning() => 'expression',
    CaptureReEncounter() => 'reencounter',
    CaptureProduction() => 'production',
    CaptureSaving() => 'saving',
    CaptureReconciling() => 'reconciling',
    CaptureDiscovered() => 'discovered',
  };
}

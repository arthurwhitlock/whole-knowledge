import 'package:whole_knowledge/application/learning/today_overview.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';

typedef TodayLoadListener = void Function();

final class TodayLoadController {
  TodayLoadController(this._load);

  final LoadTodayOverview _load;
  final Set<TodayLoadListener> _listeners = {};
  TodayOverview? overview;
  bool isLoading = false;
  String? error;
  int _generation = 0;

  bool get isInitialLoading => isLoading && overview == null;
  bool get isRefreshing => isLoading && overview != null;

  void addListener(TodayLoadListener listener) => _listeners.add(listener);
  void removeListener(TodayLoadListener listener) =>
      _listeners.remove(listener);

  Future<void> refresh() async {
    final generation = ++_generation;
    isLoading = true;
    error = null;
    _notify();
    try {
      final loaded = await _load(now: DateTime.now());
      if (generation != _generation) return;
      overview = loaded;
      isLoading = false;
      _notify();
    } on Object {
      if (generation != _generation) return;
      error = 'Could not load your learning items.';
      isLoading = false;
      _notify();
    }
  }

  void reconcileCompleted(LearningItem updatedItem) {
    final current = overview;
    if (current == null) return;
    overview = TodayOverview(
      dueItems: current.dueItems
          .where((item) => item.id != updatedItem.id)
          .toList(growable: false),
      recentlyCaptured: current.recentlyCaptured
          .map((item) => item.id == updatedItem.id ? updatedItem : item)
          .toList(growable: false),
      completedToday: [
        updatedItem,
        ...current.completedToday.where((item) => item.id != updatedItem.id),
      ].take(5).toList(growable: false),
      nextReviewAt: current.nextReviewAt,
    );
    _notify();
  }

  void dispose() => _listeners.clear();

  void _notify() {
    for (final listener in _listeners.toList(growable: false)) {
      listener();
    }
  }
}

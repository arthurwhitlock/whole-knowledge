import 'package:flutter_test/flutter_test.dart';
import 'package:whole_knowledge/application/learning/today_load_controller.dart';
import 'package:whole_knowledge/application/learning/today_overview.dart';

import '../../support/fakes.dart';

void main() {
  test(
    'loads a bounded overview and preserves it when refresh fails',
    () async {
      final repository = FakeLearningItemRepository(
        initialItems: [learningItem()],
      );
      final controller = TodayLoadController(LoadTodayOverview(repository));

      final firstRefresh = controller.refresh();
      expect(controller.isInitialLoading, isTrue);
      await firstRefresh;
      expect(controller.overview?.dueItems, hasLength(1));
      expect(controller.error, isNull);

      repository.shouldFailLoads = true;
      await controller.refresh();

      expect(controller.overview?.dueItems, hasLength(1));
      expect(controller.isRefreshing, isFalse);
      expect(controller.error, 'Could not load your learning items.');
    },
  );
}

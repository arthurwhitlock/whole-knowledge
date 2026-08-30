import 'package:whole_knowledge/application/learning/capture_learning_item.dart';
import 'package:whole_knowledge/application/capture/discovery_submission.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';

abstract interface class LearningItemRepository {
  Future<LearningItem> create(CaptureLearningItem capture);

  Future<List<LearningItem>> findActiveBySurfaceForm(String content);

  Future<DiscoveryCompletion> completeDiscovery(DiscoverySubmission submission);

  Future<List<LearningItem>> listAll();

  Future<List<LearningItem>> listDue({required DateTime at, int limit = 100});

  Future<List<LearningItem>> listRecent({required int limit});

  Future<List<LearningItem>> listCompletedBetween({
    required DateTime from,
    required DateTime to,
    required int limit,
  });

  Future<DateTime?> findNextScheduled({required DateTime after});

  Future<List<LearningItem>> listPage({
    required int offset,
    required int limit,
  });
}

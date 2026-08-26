import 'package:whole_knowledge/application/learning/capture_learning_item.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';

abstract interface class LearningItemRepository {
  Future<LearningItem> create(CaptureLearningItem capture);

  Future<List<LearningItem>> listAll();

  Future<List<LearningItem>> listDue({required DateTime at});
}

import 'package:whole_knowledge/application/auth/auth_session_repository.dart';
import 'package:whole_knowledge/application/learning/learning_item_repository.dart';
import 'package:whole_knowledge/application/learning/review_repository.dart';

final class AppDependencies {
  const AppDependencies({
    required this.authSessions,
    required this.learningItems,
    required this.reviews,
  });

  final AuthSessionRepository authSessions;
  final LearningItemRepository learningItems;
  final ReviewRepository reviews;
}

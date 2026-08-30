import 'package:whole_knowledge/application/capture/capture_draft.dart';
import 'package:whole_knowledge/application/capture/discovery_failure.dart';
import 'package:whole_knowledge/application/capture/discovery_submission.dart';
import 'package:whole_knowledge/application/capture/lexical_provider.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';

sealed class CaptureSessionState {
  const CaptureSessionState(this.draft);

  final CaptureDraft draft;
}

final class CaptureRestoring extends CaptureSessionState {
  const CaptureRestoring(super.draft);
}

final class CaptureEntry extends CaptureSessionState {
  const CaptureEntry(super.draft, {this.failure, this.restored = false});

  final DiscoveryFailure? failure;
  final bool restored;
}

sealed class LibraryOutcome {
  const LibraryOutcome();
}

final class LibraryPending extends LibraryOutcome {
  const LibraryPending();
}

final class LibraryMatches extends LibraryOutcome {
  const LibraryMatches(this.items);

  final List<LearningItem> items;
}

final class LibraryNoMatch extends LibraryOutcome {
  const LibraryNoMatch();
}

final class LibraryFailed extends LibraryOutcome {
  const LibraryFailed(this.failure);

  final DiscoveryFailure failure;
}

sealed class LexicalOutcome {
  const LexicalOutcome();
}

final class LexicalPending extends LexicalOutcome {
  const LexicalPending();
}

final class LexicalFound extends LexicalOutcome {
  const LexicalFound(this.lookup);

  final LexicalLookup lookup;
}

final class LexicalSkipped extends LexicalOutcome {
  const LexicalSkipped();
}

final class LexicalFailed extends LexicalOutcome {
  const LexicalFailed(this.failure);

  final DiscoveryFailure failure;
}

final class CaptureChecking extends CaptureSessionState {
  const CaptureChecking(
    super.draft, {
    required this.generation,
    required this.library,
    required this.lexical,
  });

  final int generation;
  final LibraryOutcome library;
  final LexicalOutcome lexical;
}

enum MeaningChoiceKind { none, manual, provider, replacementPending }

final class MeaningChoice {
  const MeaningChoice({required this.kind, this.sense, this.proposedSense});

  final MeaningChoiceKind kind;
  final LexicalSense? sense;
  final LexicalSense? proposedSense;
}

final class CaptureVocabularySenses extends CaptureSessionState {
  const CaptureVocabularySenses(
    super.draft, {
    required this.lookup,
    required this.library,
    this.meaningChoice = const MeaningChoice(kind: MeaningChoiceKind.none),
  });

  final LexicalLookup lookup;
  final LibraryOutcome library;
  final MeaningChoice meaningChoice;
}

final class CaptureExpressionMeaning extends CaptureSessionState {
  const CaptureExpressionMeaning(super.draft, {required this.library});

  final LibraryOutcome library;
}

enum ReEncounterChoiceKind { unselected, selected, revealed }

final class ReEncounterChoice {
  const ReEncounterChoice({required this.kind, this.item});

  final ReEncounterChoiceKind kind;
  final LearningItem? item;
}

final class CaptureReEncounter extends CaptureSessionState {
  const CaptureReEncounter(
    super.draft, {
    required this.items,
    required this.choice,
  });

  final List<LearningItem> items;
  final ReEncounterChoice choice;
}

final class CaptureProduction extends CaptureSessionState {
  const CaptureProduction(super.draft);
}

final class CaptureSaving extends CaptureSessionState {
  const CaptureSaving(super.draft, {required this.submission});

  final DiscoverySubmission submission;
}

final class CaptureReconciling extends CaptureSessionState {
  const CaptureReconciling(
    super.draft, {
    required this.submission,
    required this.failure,
  });

  final DiscoverySubmission submission;
  final DiscoveryFailure failure;
}

final class CaptureDiscovered extends CaptureSessionState {
  const CaptureDiscovered(super.draft, {required this.item});

  final LearningItem item;
}

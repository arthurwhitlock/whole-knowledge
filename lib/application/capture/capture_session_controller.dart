import 'dart:async';

import 'package:whole_knowledge/application/capture/capture_draft.dart';
import 'package:whole_knowledge/application/capture/capture_session_state.dart';
import 'package:whole_knowledge/application/capture/discovery_failure.dart';
import 'package:whole_knowledge/application/capture/discovery_submission.dart';
import 'package:whole_knowledge/application/capture/discovery_submission_id.dart';
import 'package:whole_knowledge/application/capture/discovery_validation.dart';
import 'package:whole_knowledge/application/capture/lexical_provider.dart';
import 'package:whole_knowledge/application/learning/capture_learning_item.dart';
import 'package:whole_knowledge/application/learning/learning_item_repository.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';

typedef CaptureSessionListener = void Function();

final class CaptureSessionController {
  CaptureSessionController(
    this._drafts,
    this._lexicalProvider,
    this._learningItems, [
    this._saveDebounce = const Duration(milliseconds: 400),
  ]);

  final CaptureDraftRepository _drafts;
  final LexicalProvider _lexicalProvider;
  final LearningItemRepository _learningItems;
  final Duration _saveDebounce;
  final Set<CaptureSessionListener> _listeners = {};
  Timer? _debounce;
  CaptureSessionState _state = const CaptureRestoring(CaptureDraft());
  LexicalLookup? _activeLookup;
  LibraryOutcome _libraryOutcome = const LibraryPending();
  int _generation = 0;
  bool _kindOverridden = false;
  bool _allowExistingSurface = false;
  bool _legacySaving = false;
  bool _legacyLookingUp = false;

  CaptureSessionState get state => _state;
  CaptureDraft get draft => _state.draft;
  LexicalLookup? get lookup => _activeLookup;
  String get lookupAttribution => _lexicalProvider.attribution;
  bool get isRestoring => _state is CaptureRestoring;
  bool get isSaving =>
      _legacySaving || _state is CaptureSaving || _state is CaptureReconciling;
  bool get isLookingUp =>
      _legacyLookingUp ||
      switch (_state) {
        CaptureChecking(:final lexical) => lexical is LexicalPending,
        CaptureVocabularySenses(:final lexical) => lexical is LexicalPending,
        _ => false,
      };
  bool restored = false;
  String? contentError;
  String? saveError;
  String? lookupError;

  void addListener(CaptureSessionListener listener) => _listeners.add(listener);

  void removeListener(CaptureSessionListener listener) =>
      _listeners.remove(listener);

  Future<bool> restore() async {
    _setState(const CaptureRestoring(CaptureDraft()));
    try {
      final saved = await _drafts.read();
      if (saved == null) {
        restored = false;
        _setState(const CaptureEntry(CaptureDraft()));
        return false;
      }
      restored = saved.isMeaningful;
      final checkpoint = saved.submissionCheckpoint;
      if (checkpoint != null) {
        if (checkpoint.status ==
            DiscoverySubmissionCheckpointStatus.attempted) {
          _setState(
            CaptureReconciling(
              saved,
              submission: checkpoint.submission,
              failure: const DiscoveryFailure(
                DiscoveryFailureCode.discoveryOutcomeUnknown,
              ),
            ),
          );
        } else {
          _setState(CaptureSaving(saved, submission: checkpoint.submission));
        }
        return true;
      }
      if (saved.meaning.trim().isNotEmpty) {
        _setState(CaptureProduction(saved));
      } else {
        _setState(CaptureEntry(saved, restored: restored));
      }
      return restored;
    } on DiscoveryFailure catch (failure) {
      restored = false;
      _setState(CaptureEntry(const CaptureDraft(), failure: failure));
      return false;
    } on Object {
      restored = false;
      _setState(
        const CaptureEntry(
          CaptureDraft(),
          failure: DiscoveryFailure(DiscoveryFailureCode.draftReadFailure),
        ),
      );
      return false;
    }
  }

  void update(CaptureDraft value) {
    final current = draft;
    var next = value;
    var meaningChanged =
        current.meaning != value.meaning ||
        current.partOfSpeech != value.partOfSpeech ||
        current.kind != value.kind;
    final contentChanged = current.content != value.content;
    final invalidatesMeaningConfirmation =
        contentChanged || current.kind != value.kind;
    if (contentChanged) meaningChanged = true;
    if (meaningChanged) {
      final revision = current.meaningRevision + 1;
      next = next.copyWith(
        meaningRevision: revision,
        meaningConfirmedRevision:
            invalidatesMeaningConfirmation || next.meaning.trim().isEmpty
            ? null
            : revision,
        clearMeaningConfirmedRevision:
            invalidatesMeaningConfirmation || next.meaning.trim().isEmpty,
        clearProductionConfirmedMeaningRevision: true,
        manualMeaningBuffer: current.meaning != value.meaning
            ? value.meaning
            : value.manualMeaningBuffer,
      );
    }
    if (current.production != value.production) {
      next = next.copyWith(
        productionConfirmedMeaningRevision: value.production.trim().isEmpty
            ? null
            : next.meaningRevision,
        clearProductionConfirmedMeaningRevision: value.production
            .trim()
            .isEmpty,
      );
    }
    next = next.copyWith(draftRevision: current.draftRevision + 1);
    restored = false;
    contentError = null;
    saveError = null;
    if (contentChanged || current.kind != next.kind) {
      _generation += 1;
      _activeLookup = null;
      lookupError = null;
      _allowExistingSurface = false;
      _setState(CaptureEntry(next));
    } else {
      _replaceDraft(next);
    }
    _schedulePersist();
  }

  void updateContent(String value) {
    final kind = _kindOverridden
        ? draft.kind
        : DiscoveryValidation.suggestKind(value);
    update(draft.copyWith(content: value, kind: kind));
  }

  void updateKind(LearningItemKind kind) {
    _kindOverridden = true;
    update(draft.copyWith(kind: kind));
  }

  void updateEncounterDetails({String? context, String? source}) {
    update(draft.copyWith(context: context, source: source));
  }

  Future<void> discover() async {
    final error = DiscoveryValidation.validateContent(draft.content);
    if (error != null) {
      contentError = error;
      _notify();
      return;
    }
    contentError = null;
    saveError = null;
    lookupError = null;
    final generation = ++_generation;
    _libraryOutcome = const LibraryPending();
    final lexical = draft.kind == LearningItemKind.vocabulary
        ? const LexicalPending()
        : const LexicalSkipped();
    _setState(
      CaptureChecking(
        draft,
        generation: generation,
        library: _libraryOutcome,
        lexical: lexical,
      ),
    );

    final futures = <Future<void>>[_loadLibrary(generation)];
    if (draft.kind == LearningItemKind.vocabulary) {
      futures.add(_loadLexical(generation));
    }
    await Future.wait(futures);
  }

  Future<void> retryLibrary() async {
    final generation = _generation;
    _applyLibraryOutcome(const LibraryPending(), generation);
    await _loadLibrary(generation);
  }

  Future<void> retryLexical() async {
    final generation = _generation;
    _applyLexicalOutcome(const LexicalPending(), generation);
    await _loadLexical(generation);
  }

  Future<void> _loadLibrary(int generation) async {
    try {
      final items = await _learningItems.findActiveBySurfaceForm(draft.content);
      if (generation != _generation) return;
      _applyLibraryOutcome(
        items.isEmpty ? const LibraryNoMatch() : LibraryMatches(items),
        generation,
      );
    } on DiscoveryFailure catch (failure) {
      if (generation != _generation) return;
      _applyLibraryOutcome(LibraryFailed(failure), generation);
    } on Object {
      if (generation != _generation) return;
      _applyLibraryOutcome(
        const LibraryFailed(
          DiscoveryFailure(DiscoveryFailureCode.libraryCheckUnavailable),
        ),
        generation,
      );
    }
  }

  Future<void> _loadLexical(int generation) async {
    try {
      final found = await _lexicalProvider.lookup(draft.content);
      if (generation != _generation) return;
      _activeLookup = found;
      _applyLexicalOutcome(LexicalFound(found), generation);
    } on DiscoveryFailure catch (failure) {
      if (generation != _generation) return;
      lookupError = _lookupFailureCopy(failure.code);
      _applyLexicalOutcome(LexicalFailed(failure), generation);
    } on Object {
      if (generation != _generation) return;
      const failure = DiscoveryFailure(
        DiscoveryFailureCode.lexicalServiceUnavailable,
      );
      lookupError = _lookupFailureCopy(failure.code);
      _applyLexicalOutcome(const LexicalFailed(failure), generation);
    }
  }

  void _applyLibraryOutcome(LibraryOutcome outcome, int generation) {
    if (generation != _generation) return;
    _libraryOutcome = outcome;
    if (outcome case LibraryMatches(:final items)) {
      _setState(
        CaptureReEncounter(
          draft,
          items: items,
          choice: ReEncounterChoice(
            kind: items.length == 1
                ? ReEncounterChoiceKind.selected
                : ReEncounterChoiceKind.unselected,
            item: items.length == 1 ? items.first : null,
          ),
        ),
      );
      return;
    }
    switch (_state) {
      case CaptureChecking(:final lexical):
        _advanceFromReads(generation, outcome, lexical);
      case CaptureVocabularySenses(:final lexical, :final meaningChoice):
        _setState(
          CaptureVocabularySenses(
            draft,
            lexical: lexical,
            library: outcome,
            meaningChoice: meaningChoice,
          ),
        );
      case CaptureExpressionMeaning():
        _setState(CaptureExpressionMeaning(draft, library: outcome));
      default:
        _notify();
    }
  }

  void _applyLexicalOutcome(LexicalOutcome outcome, int generation) {
    if (generation != _generation) return;
    switch (_state) {
      case CaptureChecking(:final library):
        _advanceFromReads(generation, library, outcome);
      case CaptureVocabularySenses(:final library, :final meaningChoice):
        _setState(
          CaptureVocabularySenses(
            draft,
            lexical: outcome,
            library: library,
            meaningChoice: meaningChoice,
          ),
        );
      default:
        _notify();
    }
  }

  void _advanceFromReads(
    int generation,
    LibraryOutcome library,
    LexicalOutcome lexical,
  ) {
    if (generation != _generation) return;
    if (library case LibraryMatches(:final items)) {
      _applyLibraryOutcome(LibraryMatches(items), generation);
      return;
    }
    if (draft.kind == LearningItemKind.expression) {
      if (library is! LibraryPending) {
        _setState(CaptureExpressionMeaning(draft, library: library));
      } else {
        _setState(
          CaptureChecking(
            draft,
            generation: generation,
            library: library,
            lexical: lexical,
          ),
        );
      }
      return;
    }
    if (lexical is! LexicalPending) {
      _setState(
        CaptureVocabularySenses(
          draft,
          lexical: lexical,
          library: library,
          meaningChoice: MeaningChoice(
            kind: draft.meaning.trim().isEmpty
                ? MeaningChoiceKind.none
                : MeaningChoiceKind.manual,
          ),
        ),
      );
    } else {
      _setState(
        CaptureChecking(
          draft,
          generation: generation,
          library: library,
          lexical: lexical,
        ),
      );
    }
  }

  void selectSense(LexicalSense sense) {
    final current = _state;
    if (current is! CaptureVocabularySenses) {
      update(
        draft.copyWith(
          partOfSpeech: sense.partOfSpeech,
          meaning: sense.definition,
        ),
      );
      return;
    }
    final priorSense = current.meaningChoice.sense;
    final editedProviderCopy =
        priorSense != null &&
        draft.meaning.trim() != priorSense.definition.trim();
    if (editedProviderCopy) {
      _setState(
        CaptureVocabularySenses(
          draft,
          lexical: current.lexical,
          library: current.library,
          meaningChoice: MeaningChoice(
            kind: MeaningChoiceKind.replacementPending,
            sense: priorSense,
            proposedSense: sense,
          ),
        ),
      );
      return;
    }
    _applyProviderSense(current, sense);
  }

  void keepEditingMeaning() {
    final current = _state;
    if (current is! CaptureVocabularySenses ||
        current.meaningChoice.kind != MeaningChoiceKind.replacementPending) {
      return;
    }
    _setState(
      CaptureVocabularySenses(
        draft,
        lexical: current.lexical,
        library: current.library,
        meaningChoice: MeaningChoice(
          kind: MeaningChoiceKind.provider,
          sense: current.meaningChoice.sense,
        ),
      ),
    );
  }

  void replaceMeaning() {
    final current = _state;
    if (current is! CaptureVocabularySenses) return;
    final proposed = current.meaningChoice.proposedSense;
    if (proposed == null) return;
    _applyProviderSense(current, proposed);
  }

  void _applyProviderSense(
    CaptureVocabularySenses current,
    LexicalSense sense,
  ) {
    final revision = draft.meaningRevision + 1;
    final next = draft.copyWith(
      draftRevision: draft.draftRevision + 1,
      partOfSpeech: sense.partOfSpeech,
      meaning: sense.definition,
      meaningRevision: revision,
      meaningConfirmedRevision: revision,
      clearProductionConfirmedMeaningRevision: true,
    );
    _setState(
      CaptureVocabularySenses(
        next,
        lexical: current.lexical,
        library: current.library,
        meaningChoice: MeaningChoice(
          kind: MeaningChoiceKind.provider,
          sense: sense,
        ),
      ),
    );
    _schedulePersist();
  }

  void chooseManualMeaning() {
    final current = _state;
    if (current is! CaptureVocabularySenses) return;
    final revision = draft.meaningRevision + 1;
    final manual = draft.manualMeaningBuffer;
    final next = draft.copyWith(
      draftRevision: draft.draftRevision + 1,
      meaning: manual,
      meaningRevision: revision,
      meaningConfirmedRevision: manual.trim().isEmpty ? null : revision,
      clearMeaningConfirmedRevision: manual.trim().isEmpty,
      clearProductionConfirmedMeaningRevision: true,
    );
    _setState(
      CaptureVocabularySenses(
        next,
        lexical: current.lexical,
        library: current.library,
        meaningChoice: const MeaningChoice(kind: MeaningChoiceKind.manual),
      ),
    );
    _schedulePersist();
  }

  void updateMeaning(String value) {
    final revision = draft.meaningRevision + 1;
    final next = draft.copyWith(
      draftRevision: draft.draftRevision + 1,
      meaning: value,
      manualMeaningBuffer: switch (_state) {
        CaptureVocabularySenses(:final meaningChoice)
            when meaningChoice.kind == MeaningChoiceKind.provider ||
                meaningChoice.kind == MeaningChoiceKind.replacementPending =>
          draft.manualMeaningBuffer,
        _ => value,
      },
      meaningRevision: revision,
      meaningConfirmedRevision: value.trim().isEmpty ? null : revision,
      clearMeaningConfirmedRevision: value.trim().isEmpty,
      clearProductionConfirmedMeaningRevision: true,
    );
    _replaceDraft(next);
    saveError = null;
    _schedulePersist();
  }

  bool continueToProduction() {
    final error = DiscoveryValidation.validateMeaning(draft.meaning);
    if (error != null) {
      saveError = error;
      _notify();
      return false;
    }
    final next = draft.copyWith(
      draftRevision: draft.draftRevision + 1,
      meaningConfirmedRevision: draft.meaningRevision,
    );
    saveError = null;
    _setState(CaptureProduction(next));
    _schedulePersist();
    return true;
  }

  void updateProduction(String value) {
    final next = draft.copyWith(
      draftRevision: draft.draftRevision + 1,
      production: value,
      productionConfirmedMeaningRevision: value.trim().isEmpty
          ? null
          : draft.meaningRevision,
      clearProductionConfirmedMeaningRevision: value.trim().isEmpty,
    );
    _replaceDraft(next);
    saveError = null;
    _schedulePersist();
  }

  void confirmMeaning() {
    if (draft.meaning.trim().isEmpty) return;
    final next = draft.copyWith(
      draftRevision: draft.draftRevision + 1,
      meaningConfirmedRevision: draft.meaningRevision,
    );
    _replaceDraft(next);
    _schedulePersist();
  }

  void confirmProduction() {
    if (draft.production.trim().isEmpty || !draft.isMeaningConfirmed) return;
    final next = draft.copyWith(
      draftRevision: draft.draftRevision + 1,
      productionConfirmedMeaningRevision: draft.meaningRevision,
    );
    _replaceDraft(next);
    _schedulePersist();
  }

  void selectReEncounterItem(LearningItem item) {
    final current = _state;
    if (current is! CaptureReEncounter ||
        !current.items.any((candidate) => candidate.id == item.id)) {
      return;
    }
    _setState(
      CaptureReEncounter(
        draft,
        items: current.items,
        choice: ReEncounterChoice(
          kind: ReEncounterChoiceKind.selected,
          item: item,
        ),
      ),
    );
  }

  void showMeaning() {
    final current = _state;
    if (current is! CaptureReEncounter || current.choice.item == null) return;
    _setState(
      CaptureReEncounter(
        draft,
        items: current.items,
        choice: ReEncounterChoice(
          kind: ReEncounterChoiceKind.revealed,
          item: current.choice.item,
        ),
      ),
    );
  }

  void hideMeaning() {
    final current = _state;
    if (current is! CaptureReEncounter || current.choice.item == null) return;
    _setState(
      CaptureReEncounter(
        draft,
        items: current.items,
        choice: ReEncounterChoice(
          kind: ReEncounterChoiceKind.selected,
          item: current.choice.item,
        ),
      ),
    );
  }

  LearningItem? get selectedReEncounterItem => switch (_state) {
    CaptureReEncounter(:final choice) => choice.item,
    _ => null,
  };

  void learnAnotherSense() {
    if (_state is! CaptureReEncounter) return;
    _allowExistingSurface = true;
    _setState(CaptureEntry(draft));
  }

  Future<LearningItem?> completeDiscovery({
    bool deferProduction = false,
  }) async {
    if (isSaving) return null;
    final contentFailure = DiscoveryValidation.validateContent(draft.content);
    final meaningFailure = DiscoveryValidation.validateMeaning(draft.meaning);
    final productionFailure = DiscoveryValidation.validateProduction(
      draft.production,
      required: !deferProduction,
    );
    contentError = contentFailure;
    saveError = meaningFailure ?? productionFailure;
    if (contentFailure != null || meaningFailure != null) {
      _notify();
      return null;
    }
    if (!draft.isMeaningConfirmed) {
      saveError = 'Confirm the current meaning before completing Discovery.';
      _notify();
      return null;
    }
    final production = deferProduction ? null : draft.production.trim();
    if (!deferProduction &&
        (productionFailure != null || !draft.isProductionConfirmed)) {
      saveError =
          productionFailure ??
          'Confirm that this sentence still fits the current meaning.';
      _notify();
      return null;
    }
    if (_libraryOutcome is LibraryPending) {
      saveError = 'Check your Library before saving.';
      _notify();
      return null;
    }
    if (_libraryOutcome is LibraryFailed) {
      saveError = 'Retry the Library check before saving.';
      _notify();
      return null;
    }

    final submission = DiscoverySubmission(
      submissionId: DiscoverySubmissionId.generate(),
      kind: draft.kind,
      content: draft.content,
      partOfSpeech: draft.partOfSpeech,
      meaning: draft.meaning,
      context: draft.context,
      source: draft.source,
      firstProduction: production?.isEmpty ?? true ? null : production,
      allowExistingSurface: _allowExistingSurface,
    ).normalized();
    return _prepareAndSubmit(submission);
  }

  Future<LearningItem?> retrySubmission() async {
    final checkpoint = draft.submissionCheckpoint;
    if (checkpoint == null) return null;
    return _submitCheckpoint(checkpoint);
  }

  Future<LearningItem?> _prepareAndSubmit(
    DiscoverySubmission submission,
  ) async {
    final prepared = draft.copyWith(
      draftRevision: draft.draftRevision + 1,
      submissionCheckpoint: DiscoverySubmissionCheckpoint(
        status: DiscoverySubmissionCheckpointStatus.prepared,
        submission: submission,
      ),
    );
    _setState(CaptureSaving(prepared, submission: submission));
    try {
      await _drafts.write(prepared);
    } on Object {
      saveError =
          'Could not secure this draft locally. Your input is still here.';
      _setState(
        CaptureProduction(prepared.copyWith(clearSubmissionCheckpoint: true)),
      );
      return null;
    }
    return _submitCheckpoint(prepared.submissionCheckpoint!);
  }

  Future<LearningItem?> _submitCheckpoint(
    DiscoverySubmissionCheckpoint checkpoint,
  ) async {
    var attemptedDraft = draft;
    if (checkpoint.status == DiscoverySubmissionCheckpointStatus.prepared) {
      attemptedDraft = draft.copyWith(
        draftRevision: draft.draftRevision + 1,
        submissionCheckpoint: checkpoint.copyWith(
          status: DiscoverySubmissionCheckpointStatus.attempted,
        ),
      );
      _setState(
        CaptureSaving(attemptedDraft, submission: checkpoint.submission),
      );
      try {
        await _drafts.write(attemptedDraft);
      } on Object {
        saveError =
            'Could not secure this draft locally. Your input is still here.';
        _setState(CaptureProduction(attemptedDraft));
        return null;
      }
    } else {
      _setState(
        CaptureSaving(attemptedDraft, submission: checkpoint.submission),
      );
    }

    try {
      final completion = await _learningItems.completeDiscovery(
        checkpoint.submission,
      );
      switch (completion) {
        case DiscoveryExistingSurface(:final item):
          final matches = await _learningItems.findActiveBySurfaceForm(
            checkpoint.submission.content,
          );
          final nextDraft = attemptedDraft.copyWith(
            draftRevision: attemptedDraft.draftRevision + 1,
            clearSubmissionCheckpoint: true,
          );
          await _drafts.write(nextDraft);
          _setState(
            CaptureReEncounter(
              nextDraft,
              items: matches.isEmpty ? [item] : matches,
              choice: ReEncounterChoice(
                kind: matches.length == 1
                    ? ReEncounterChoiceKind.selected
                    : ReEncounterChoiceKind.unselected,
                item: matches.length == 1 ? matches.first : null,
              ),
            ),
          );
          return null;
        case DiscoveryCreated(:final item) || DiscoveryReplayed(:final item):
          await _clearAfterSuccessfulCreate();
          _allowExistingSurface = false;
          final empty = CaptureDraft(kind: draft.kind);
          _setState(CaptureDiscovered(empty, item: item));
          return item;
      }
    } on DiscoveryFailure catch (failure) {
      saveError = _submissionFailureCopy(failure.code);
      if (failure.code == DiscoveryFailureCode.discoveryValidationRejected) {
        final next = attemptedDraft.copyWith(
          draftRevision: attemptedDraft.draftRevision + 1,
          clearSubmissionCheckpoint: true,
        );
        _setState(CaptureProduction(next));
      } else {
        _setState(
          CaptureReconciling(
            attemptedDraft,
            submission: checkpoint.submission,
            failure: failure,
          ),
        );
      }
      return null;
    } on Object {
      const failure = DiscoveryFailure(
        DiscoveryFailureCode.discoveryOutcomeUnknown,
      );
      saveError = _submissionFailureCopy(failure.code);
      _setState(
        CaptureReconciling(
          attemptedDraft,
          submission: checkpoint.submission,
          failure: failure,
        ),
      );
      return null;
    }
  }

  void done() {
    if (_state is CaptureDiscovered) {
      _setState(const CaptureEntry(CaptureDraft()));
    }
  }

  void captureAnother() {
    if (_state is CaptureDiscovered) {
      _kindOverridden = false;
      _setState(const CaptureEntry(CaptureDraft()));
    }
  }

  Future<void> lookupMeaning() async {
    if (_legacyLookingUp) return;
    _legacyLookingUp = true;
    lookupError = null;
    _activeLookup = null;
    _notify();
    try {
      _activeLookup = await _lexicalProvider.lookup(draft.content);
    } on DiscoveryFailure catch (failure) {
      lookupError = _lookupFailureCopy(failure.code);
    } on Object {
      lookupError = 'English lookup is unavailable. Add a meaning manually.';
    } finally {
      _legacyLookingUp = false;
      _notify();
    }
  }

  Future<LearningItem?> save() async {
    if (_legacySaving) return null;
    final optionalError =
        CaptureLearningItemValidator.validatePartOfSpeech(draft.partOfSpeech) ??
        CaptureLearningItemValidator.validateMeaning(draft.meaning) ??
        CaptureLearningItemValidator.validateContext(draft.context) ??
        CaptureLearningItemValidator.validateSource(draft.source);
    contentError = CaptureLearningItemValidator.validateContent(draft.content);
    saveError = optionalError;
    if (contentError != null || optionalError != null) {
      _notify();
      return null;
    }

    _legacySaving = true;
    _debounce?.cancel();
    try {
      await _drafts.write(draft);
    } on Object {
      _legacySaving = false;
      saveError =
          'Could not secure this draft locally. Your input is still here.';
      _notify();
      return null;
    }
    _notify();
    try {
      final item = await _learningItems.create(
        CaptureLearningItem(
          kind: draft.kind,
          content: draft.content,
          partOfSpeech: draft.partOfSpeech,
          meaning: draft.meaning,
          context: draft.context,
          source: draft.source,
        ),
      );
      await _clearAfterSuccessfulCreate();
      _activeLookup = null;
      lookupError = null;
      contentError = null;
      saveError = null;
      _setState(const CaptureEntry(CaptureDraft()));
      return item;
    } on Object {
      saveError = 'Could not save this item. Your input is still here.';
      return null;
    } finally {
      _legacySaving = false;
      _notify();
    }
  }

  Future<void> _clearAfterSuccessfulCreate() async {
    try {
      await _drafts.clear();
    } on Object {
      try {
        await _drafts.write(const CaptureDraft());
      } on Object {
        // The committed server item is authoritative. No duplicate action is
        // exposed when local cleanup is unavailable.
      }
    }
  }

  Future<void> discard() async {
    _debounce?.cancel();
    try {
      await _drafts.clear();
    } on Object {
      saveError =
          'Could not discard the local draft. Your input is still here.';
      _notify();
      return;
    }
    _generation += 1;
    _activeLookup = null;
    lookupError = null;
    contentError = null;
    saveError = null;
    restored = false;
    _allowExistingSurface = false;
    _setState(const CaptureEntry(CaptureDraft()));
  }

  Future<void> flush() async {
    _debounce?.cancel();
    try {
      if (draft.isMeaningful) {
        await _drafts.write(draft);
      } else {
        await _drafts.clear();
      }
    } on Object {
      saveError =
          'Could not save this draft locally. Your input is still here.';
      _notify();
    }
  }

  void dispose() {
    _debounce?.cancel();
    _listeners.clear();
  }

  void _schedulePersist() {
    _debounce?.cancel();
    _debounce = Timer(_saveDebounce, flush);
  }

  void _replaceDraft(CaptureDraft next) {
    _state = switch (_state) {
      CaptureRestoring() => CaptureRestoring(next),
      CaptureEntry(:final failure, :final restored) => CaptureEntry(
        next,
        failure: failure,
        restored: restored,
      ),
      CaptureChecking(:final generation, :final library, :final lexical) =>
        CaptureChecking(
          next,
          generation: generation,
          library: library,
          lexical: lexical,
        ),
      CaptureVocabularySenses(
        :final lexical,
        :final library,
        :final meaningChoice,
      ) =>
        CaptureVocabularySenses(
          next,
          lexical: lexical,
          library: library,
          meaningChoice: meaningChoice,
        ),
      CaptureExpressionMeaning(:final library) => CaptureExpressionMeaning(
        next,
        library: library,
      ),
      CaptureReEncounter(:final items, :final choice) => CaptureReEncounter(
        next,
        items: items,
        choice: choice,
      ),
      CaptureProduction() => CaptureProduction(next),
      CaptureSaving(:final submission) => CaptureSaving(
        next,
        submission: submission,
      ),
      CaptureReconciling(:final submission, :final failure) =>
        CaptureReconciling(next, submission: submission, failure: failure),
      CaptureDiscovered(:final item) => CaptureDiscovered(next, item: item),
    };
    _notify();
  }

  void _setState(CaptureSessionState next) {
    _state = next;
    _notify();
  }

  void _notify() {
    for (final listener in _listeners.toList(growable: false)) {
      listener();
    }
  }

  static String _lookupFailureCopy(DiscoveryFailureCode code) {
    return switch (code) {
      DiscoveryFailureCode.lexicalEntryNotFound =>
        'No English entry found. Add a meaning manually.',
      DiscoveryFailureCode.lexicalRateLimited =>
        'English lookup is busy. Retry later or add a meaning manually.',
      DiscoveryFailureCode.lexicalTimedOut =>
        'English lookup timed out. Retry or add a meaning manually.',
      DiscoveryFailureCode.lexicalPayloadInvalid =>
        'The English lookup returned an unreadable entry. Add it manually.',
      DiscoveryFailureCode.lexicalResponseTooLarge =>
        'The lookup response was too large. Add a meaning manually.',
      _ => 'English lookup is unavailable. Add a meaning manually.',
    };
  }

  static String _submissionFailureCopy(DiscoveryFailureCode code) {
    return switch (code) {
      DiscoveryFailureCode.discoverySubmissionConflict => 'This saved attempt conflicts with different data. Reconcile it before retrying.',
      DiscoveryFailureCode.discoveryValidationRejected =>
        'Some Discovery details need correction.',
      DiscoveryFailureCode.sessionUnavailable =>
        'Your session is unavailable. Your draft is still here.',
      _ =>
        'Could not confirm this discovery. Retry safely with the same draft.',
    };
  }
}

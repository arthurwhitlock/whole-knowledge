import 'dart:async';

import 'package:whole_knowledge/application/capture/capture_draft.dart';
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
  CaptureDraft draft = const CaptureDraft();
  LexicalLookup? lookup;
  bool restored = false;
  bool isRestoring = true;
  bool isSaving = false;
  bool isLookingUp = false;
  String? contentError;
  String? saveError;
  String? lookupError;

  String get lookupAttribution => _lexicalProvider.attribution;

  void addListener(CaptureSessionListener listener) => _listeners.add(listener);

  void removeListener(CaptureSessionListener listener) =>
      _listeners.remove(listener);

  Future<bool> restore() async {
    final saved = await _drafts.read();
    draft = saved ?? const CaptureDraft();
    restored = saved?.isMeaningful ?? false;
    isRestoring = false;
    _notify();
    return restored;
  }

  void update(CaptureDraft value) {
    draft = value;
    restored = false;
    contentError = null;
    saveError = null;
    _schedulePersist();
    _notify();
  }

  void selectSense(LexicalSense sense) {
    update(
      draft.copyWith(
        partOfSpeech: sense.partOfSpeech,
        meaning: sense.definition,
      ),
    );
  }

  Future<void> lookupMeaning() async {
    if (isLookingUp) return;
    isLookingUp = true;
    lookupError = null;
    lookup = null;
    _notify();
    try {
      lookup = await _lexicalProvider.lookup(draft.content);
    } on LexicalLookupException catch (error) {
      lookupError = error.message;
    } on Object {
      lookupError = 'English lookup is unavailable. Add a meaning manually.';
    } finally {
      isLookingUp = false;
      _notify();
    }
  }

  Future<LearningItem?> save() async {
    if (isSaving) return null;
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

    isSaving = true;
    _debounce?.cancel();
    await _drafts.write(draft);
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
      await _drafts.clear();
      draft = const CaptureDraft();
      lookup = null;
      lookupError = null;
      contentError = null;
      saveError = null;
      return item;
    } on Object {
      saveError = 'Could not save this item. Your input is still here.';
      return null;
    } finally {
      isSaving = false;
      _notify();
    }
  }

  Future<void> discard() async {
    _debounce?.cancel();
    await _drafts.clear();
    draft = const CaptureDraft();
    lookup = null;
    lookupError = null;
    contentError = null;
    saveError = null;
    restored = false;
    _notify();
  }

  Future<void> flush() async {
    _debounce?.cancel();
    if (draft.isMeaningful) {
      await _drafts.write(draft);
    } else {
      await _drafts.clear();
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

  void _notify() {
    for (final listener in _listeners.toList(growable: false)) {
      listener();
    }
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:whole_knowledge/application/capture/capture_draft.dart';
import 'package:whole_knowledge/application/capture/capture_session_controller.dart';

import '../../support/fakes.dart';

void main() {
  test(
    'restores a meaningful draft and persists edits after the debounce',
    () async {
      final drafts = FakeCaptureDraftRepository()
        ..saved = const CaptureDraft(content: 'restored language');
      final learningItems = FakeLearningItemRepository();
      final controller = CaptureSessionController(
        drafts,
        FakeLexicalProvider(),
        learningItems,
        Duration.zero,
      );

      expect(await controller.restore(), isTrue);
      expect(controller.restored, isTrue);

      controller.update(controller.draft.copyWith(context: 'new context'));
      await Future<void>.delayed(Duration.zero);

      expect(controller.restored, isFalse);
      expect(drafts.saved?.context, 'new context');
    },
  );

  test(
    'clears the local draft only after a successful remote create',
    () async {
      final drafts = FakeCaptureDraftRepository();
      final learningItems = FakeLearningItemRepository()
        ..shouldFailCreate = true;
      final controller = CaptureSessionController(
        drafts,
        FakeLexicalProvider(),
        learningItems,
      );
      await controller.restore();
      controller.update(const CaptureDraft(content: 'keep me'));

      expect(await controller.save(), isNull);
      expect(drafts.saved?.content, 'keep me');
      expect(controller.draft.content, 'keep me');

      learningItems.shouldFailCreate = false;
      expect(await controller.save(), isNotNull);
      expect(drafts.saved, isNull);
      expect(controller.draft.isMeaningful, isFalse);
    },
  );

  test('a selected dictionary sense remains editable capture data', () async {
    final controller = CaptureSessionController(
      FakeCaptureDraftRepository(),
      FakeLexicalProvider(),
      FakeLearningItemRepository(),
    );
    await controller.restore();
    controller.update(const CaptureDraft(content: 'record'));
    await controller.lookupMeaning();
    controller.selectSense(controller.lookup!.senses.last);

    expect(controller.draft.partOfSpeech, 'verb');
    expect(controller.draft.meaning, 'To preserve information.');
  });
}

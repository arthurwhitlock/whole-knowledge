import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:whole_knowledge/application/capture/capture_draft.dart';
import 'package:whole_knowledge/application/capture/discovery_failure.dart';
import 'package:whole_knowledge/infrastructure/local/file_capture_draft_repository.dart';

void main() {
  test('round trips versioned draft JSON and clears it explicitly', () async {
    final directory = await Directory.systemTemp.createTemp('wk-draft-test-');
    addTearDown(() => directory.delete(recursive: true));
    final repository = FileCaptureDraftRepository(
      directoryProvider: () async => directory,
    );
    const draft = CaptureDraft(
      content: 'record',
      partOfSpeech: 'noun',
      meaning: 'a stored account',
    );

    await repository.write(draft);
    final restored = await repository.read();

    expect(restored?.content, 'record');
    expect(restored?.partOfSpeech, 'noun');
    expect(restored?.meaning, 'a stored account');

    await repository.clear();
    expect(await repository.read(), isNull);
  });

  test('maps a corrupt draft to a typed format failure', () async {
    final directory = await Directory.systemTemp.createTemp('wk-draft-test-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/capture-draft-v1.json');
    await file.writeAsString('{not-json');
    final repository = FileCaptureDraftRepository(
      directoryProvider: () async => directory,
    );

    await expectLater(
      repository.read(),
      throwsA(
        isA<DiscoveryFailure>().having(
          (failure) => failure.code,
          'code',
          DiscoveryFailureCode.draftFormatInvalid,
        ),
      ),
    );
  });

  test('migrates a v1 file without losing authored fields', () async {
    final directory = await Directory.systemTemp.createTemp('wk-draft-test-');
    addTearDown(() => directory.delete(recursive: true));
    final legacy = File('${directory.path}/capture-draft-v1.json');
    await legacy.writeAsString(
      '{"version":1,"kind":"vocabulary","content":"record",'
      '"partOfSpeech":"noun","meaning":"stored account",'
      '"context":"meeting","source":"conversation"}',
    );
    final repository = FileCaptureDraftRepository(
      directoryProvider: () async => directory,
    );

    final restored = await repository.read();

    expect(restored?.meaning, 'stored account');
    expect(restored?.manualMeaningBuffer, 'stored account');
    expect(restored?.context, 'meeting');
    expect(
      File('${directory.path}/capture-draft-v2.json').existsSync(),
      isTrue,
    );
  });

  test(
    'rejects a stale revision that completes after newer authored work',
    () async {
      final directory = await Directory.systemTemp.createTemp('wk-draft-test-');
      addTearDown(() => directory.delete(recursive: true));
      final repository = FileCaptureDraftRepository(
        directoryProvider: () async => directory,
      );

      await repository.write(
        const CaptureDraft(draftRevision: 2, content: 'new'),
      );
      await repository.write(
        const CaptureDraft(draftRevision: 1, content: 'old'),
      );

      expect((await repository.read())?.content, 'new');
    },
  );
}

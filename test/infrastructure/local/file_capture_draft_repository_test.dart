import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:whole_knowledge/application/capture/capture_draft.dart';
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

  test('fails soft when the draft file is corrupt', () async {
    final directory = await Directory.systemTemp.createTemp('wk-draft-test-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/capture-draft-v1.json');
    await file.writeAsString('{not-json');
    final repository = FileCaptureDraftRepository(
      directoryProvider: () async => directory,
    );

    expect(await repository.read(), isNull);
  });
}

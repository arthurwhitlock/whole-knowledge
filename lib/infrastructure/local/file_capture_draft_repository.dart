import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:whole_knowledge/application/capture/capture_draft.dart';
import 'package:whole_knowledge/application/capture/discovery_failure.dart';

typedef ApplicationSupportDirectoryProvider = Future<Directory> Function();

final class FileCaptureDraftRepository implements CaptureDraftRepository {
  FileCaptureDraftRepository({
    ApplicationSupportDirectoryProvider? directoryProvider,
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  final ApplicationSupportDirectoryProvider _directoryProvider;
  Future<void> _pendingWrite = Future.value();
  int _highestRevision = 0;

  @override
  Future<CaptureDraft?> read() async {
    await _pendingWrite;
    try {
      final file = await _readableFile();
      if (file == null) return null;
      final value = jsonDecode(await file.readAsString());
      if (value is! Map<String, dynamic>) {
        throw const DiscoveryFailure(DiscoveryFailureCode.draftFormatInvalid);
      }
      if (value['version'] != 1 && value['version'] != 2) {
        throw const DiscoveryFailure(
          DiscoveryFailureCode.draftVersionUnsupported,
        );
      }
      final draft = CaptureDraft.fromJson(value);
      _highestRevision = draft.draftRevision;
      if (value['version'] == 1) await write(draft);
      return draft;
    } on DiscoveryFailure {
      rethrow;
    } on FormatException {
      throw const DiscoveryFailure(DiscoveryFailureCode.draftFormatInvalid);
    } on Object {
      throw const DiscoveryFailure(DiscoveryFailureCode.draftReadFailure);
    }
  }

  @override
  Future<void> write(CaptureDraft draft) {
    return _serialize(() async {
      if (draft.draftRevision < _highestRevision) return;
      try {
        final file = await _file();
        await file.parent.create(recursive: true);
        final temporary = File('${file.path}.tmp');
        await temporary.writeAsString(jsonEncode(draft.toJson()), flush: true);
        await temporary.rename(file.path);
        _highestRevision = draft.draftRevision;
      } on Object {
        throw const DiscoveryFailure(DiscoveryFailureCode.draftWriteFailure);
      }
    });
  }

  @override
  Future<void> clear() {
    return _serialize(() async {
      final file = await _file();
      if (await file.exists()) await file.delete();
      final temporary = File('${file.path}.tmp');
      if (await temporary.exists()) await temporary.delete();
      final legacy = await _legacyFile();
      if (await legacy.exists()) await legacy.delete();
      _highestRevision = 0;
    });
  }

  Future<File> _file() async {
    final directory = await _directoryProvider();
    return File('${directory.path}/capture-draft-v2.json');
  }

  Future<File> _legacyFile() async {
    final directory = await _directoryProvider();
    return File('${directory.path}/capture-draft-v1.json');
  }

  Future<File?> _readableFile() async {
    final current = await _file();
    if (await current.exists()) return current;
    final legacy = await _legacyFile();
    return await legacy.exists() ? legacy : null;
  }

  Future<void> _serialize(Future<void> Function() operation) {
    final result = _pendingWrite.then((_) => operation());
    _pendingWrite = result.catchError((Object _) {});
    return result;
  }
}

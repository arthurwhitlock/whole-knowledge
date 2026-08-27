import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:whole_knowledge/application/capture/capture_draft.dart';

typedef ApplicationSupportDirectoryProvider = Future<Directory> Function();

final class FileCaptureDraftRepository implements CaptureDraftRepository {
  FileCaptureDraftRepository({
    ApplicationSupportDirectoryProvider? directoryProvider,
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  final ApplicationSupportDirectoryProvider _directoryProvider;
  Future<void> _pendingWrite = Future.value();

  @override
  Future<CaptureDraft?> read() async {
    await _pendingWrite;
    final file = await _file();
    if (!await file.exists()) return null;
    try {
      final value = jsonDecode(await file.readAsString());
      if (value is! Map<String, dynamic> || value['version'] != 1) return null;
      return CaptureDraft.fromJson(value);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> write(CaptureDraft draft) {
    return _serialize(() async {
      final file = await _file();
      await file.parent.create(recursive: true);
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(jsonEncode(draft.toJson()), flush: true);
      await temporary.rename(file.path);
    });
  }

  @override
  Future<void> clear() {
    return _serialize(() async {
      final file = await _file();
      if (await file.exists()) await file.delete();
      final temporary = File('${file.path}.tmp');
      if (await temporary.exists()) await temporary.delete();
    });
  }

  Future<File> _file() async {
    final directory = await _directoryProvider();
    return File('${directory.path}/capture-draft-v1.json');
  }

  Future<void> _serialize(Future<void> Function() operation) {
    final result = _pendingWrite.then((_) => operation());
    _pendingWrite = result.catchError((Object _) {});
    return result;
  }
}

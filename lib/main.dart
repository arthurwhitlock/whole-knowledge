import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:whole_knowledge/app/app.dart';
import 'package:whole_knowledge/app/app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bootstrapStatus = await bootstrapApplication();
  final message = bootstrapStatus.message;
  if (kDebugMode && message != null) {
    debugPrint(message);
  }

  runApp(const WholeKnowledgeApp());
}

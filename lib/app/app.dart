import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:whole_knowledge/app/app_dependencies.dart';
import 'package:whole_knowledge/app/theme/app_spacing.dart';
import 'package:whole_knowledge/app/theme/app_theme.dart';
import 'package:whole_knowledge/presentation/learning/learning_workspace.dart';

class WholeKnowledgeApp extends StatelessWidget {
  const WholeKnowledgeApp({super.key, this.dependencies, this.backendMessage});

  final AppDependencies? dependencies;
  final String? backendMessage;

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      title: 'Whole Knowledge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: dependencies == null
          ? _BackendUnavailableScreen(message: backendMessage)
          : LearningWorkspace(dependencies: dependencies!),
    );
  }
}

class _BackendUnavailableScreen extends StatelessWidget {
  const _BackendUnavailableScreen({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.pageCompact),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.contentMaxWidth,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Whole Knowledge', style: theme.textTheme.h1),
                  const SizedBox(height: AppSpacing.regular),
                  Text(
                    'The learning workspace is unavailable.',
                    style: theme.textTheme.h3,
                  ),
                  const SizedBox(height: AppSpacing.compact),
                  Text(
                    message ??
                        'Add the Supabase development configuration and '
                            'restart the app.',
                    style: theme.textTheme.muted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

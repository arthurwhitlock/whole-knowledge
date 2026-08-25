import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:whole_knowledge/app/theme/app_spacing.dart';
import 'package:whole_knowledge/app/theme/app_theme.dart';

class WholeKnowledgeApp extends StatelessWidget {
  const WholeKnowledgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      title: 'Whole Knowledge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const _DesignFoundationScreen(),
    );
  }
}

class _DesignFoundationScreen extends StatelessWidget {
  const _DesignFoundationScreen();

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                constraints.maxWidth < AppSpacing.compactLayoutBreakpoint
                ? AppSpacing.pageCompact
                : AppSpacing.page;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: AppSpacing.section,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (AppSpacing.section * 2),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSpacing.contentMaxWidth,
                    ),
                    child: FocusTraversalGroup(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Language OS',
                            style: theme.textTheme.small.copyWith(
                              color: theme.colorScheme.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.compact),
                          Text('Whole Knowledge', style: theme.textTheme.h1),
                          const SizedBox(height: AppSpacing.regular),
                          Text(
                            'A personal system for learning languages with '
                            'clarity and continuity.',
                            style: theme.textTheme.muted,
                          ),
                          const SizedBox(height: AppSpacing.section),
                          ShadButton(
                            onPressed: () {},
                            child: const Text('Continue'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

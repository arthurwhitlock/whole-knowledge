import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:whole_knowledge/app/theme/app_radius.dart';
import 'package:whole_knowledge/app/theme/app_spacing.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({required this.items, super.key});

  final List<LearningItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageCompact,
        vertical: AppSpacing.page,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.contentMaxWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Library', style: theme.textTheme.h1),
              const SizedBox(height: AppSpacing.compact),
              Text(
                '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                style: theme.textTheme.muted,
              ),
              const SizedBox(height: AppSpacing.section),
              if (items.isEmpty)
                Text(
                  'Captured language will appear here.',
                  style: theme.textTheme.p,
                )
              else
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.compact),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.regular),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.border),
                        borderRadius: AppRadius.surface,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.content, style: theme.textTheme.h4),
                          if (item.meaning != null) ...[
                            const SizedBox(height: AppSpacing.compact),
                            Text(item.meaning!, style: theme.textTheme.muted),
                          ],
                          const SizedBox(height: AppSpacing.compact),
                          Text(
                            item.kind == LearningItemKind.expression
                                ? 'Expression'
                                : 'Vocabulary',
                            style: theme.textTheme.small.copyWith(
                              color: theme.colorScheme.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

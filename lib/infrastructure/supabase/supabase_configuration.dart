const supabaseUrlDefine = 'SUPABASE_URL';
const supabasePublishableKeyDefine = 'SUPABASE_PUBLISHABLE_KEY';

enum SupabaseConfigurationIssue {
  missingProjectUrl,
  missingPublishableKey,
  invalidProjectUrl,
}

final class SupabaseConfiguration {
  const SupabaseConfiguration({
    required this.projectUrl,
    required this.publishableKey,
  });

  final Uri projectUrl;
  final String publishableKey;

  static SupabaseConfigurationLoadResult load({
    String projectUrl = const String.fromEnvironment(supabaseUrlDefine),
    String publishableKey = const String.fromEnvironment(
      supabasePublishableKeyDefine,
    ),
  }) {
    final normalizedUrl = projectUrl.trim();
    final normalizedKey = publishableKey.trim();
    final issues = <SupabaseConfigurationIssue>[];

    if (normalizedUrl.isEmpty) {
      issues.add(SupabaseConfigurationIssue.missingProjectUrl);
    }
    if (normalizedKey.isEmpty) {
      issues.add(SupabaseConfigurationIssue.missingPublishableKey);
    }

    final parsedUrl = Uri.tryParse(normalizedUrl);
    if (normalizedUrl.isNotEmpty && !_isSupportedProjectUrl(parsedUrl)) {
      issues.add(SupabaseConfigurationIssue.invalidProjectUrl);
    }

    if (issues.isNotEmpty) {
      return SupabaseConfigurationLoadResult._(issues: issues);
    }

    return SupabaseConfigurationLoadResult._(
      configuration: SupabaseConfiguration(
        projectUrl: parsedUrl!,
        publishableKey: normalizedKey,
      ),
    );
  }

  static bool _isSupportedProjectUrl(Uri? url) {
    return url != null &&
        url.host.isNotEmpty &&
        (url.scheme == 'https' || url.scheme == 'http');
  }
}

final class SupabaseConfigurationLoadResult {
  SupabaseConfigurationLoadResult._({
    this.configuration,
    List<SupabaseConfigurationIssue> issues = const [],
  }) : issues = List.unmodifiable(issues);

  final SupabaseConfiguration? configuration;
  final List<SupabaseConfigurationIssue> issues;

  bool get isConfigured => configuration != null;

  bool get isAbsent {
    return issues.length == 2 &&
        issues.contains(SupabaseConfigurationIssue.missingProjectUrl) &&
        issues.contains(SupabaseConfigurationIssue.missingPublishableKey);
  }
}

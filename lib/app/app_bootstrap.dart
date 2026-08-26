import 'package:whole_knowledge/app/app_dependencies.dart';
import 'package:whole_knowledge/infrastructure/supabase/supabase_bootstrap.dart';
import 'package:whole_knowledge/infrastructure/supabase/supabase_configuration.dart';

final class AppBootstrapStatus {
  const AppBootstrapStatus({this.dependencies, this.message});

  final AppDependencies? dependencies;
  final String? message;
}

Future<AppBootstrapStatus> bootstrapApplication() async {
  final result = await SupabaseBootstrap().initialize(
    SupabaseConfiguration.load(),
  );

  return switch (result.status) {
    SupabaseBootstrapStatus.ready => AppBootstrapStatus(
      dependencies: result.dependencies,
    ),
    SupabaseBootstrapStatus.notConfigured => const AppBootstrapStatus(
      message:
          'Supabase is not configured; continuing without backend services.',
    ),
    SupabaseBootstrapStatus.invalidConfiguration => const AppBootstrapStatus(
      message:
          'Supabase configuration is invalid; continuing without backend '
          'services.',
    ),
    SupabaseBootstrapStatus.failed => const AppBootstrapStatus(
      message:
          'Supabase initialization failed; continuing without backend '
          'services.',
    ),
  };
}

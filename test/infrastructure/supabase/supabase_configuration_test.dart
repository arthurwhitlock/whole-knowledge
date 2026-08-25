import 'package:flutter_test/flutter_test.dart';
import 'package:whole_knowledge/infrastructure/supabase/supabase_configuration.dart';

void main() {
  group('SupabaseConfiguration', () {
    test('treats entirely missing build defines as absent', () {
      final result = SupabaseConfiguration.load(
        projectUrl: '',
        publishableKey: '',
      );

      expect(result.isAbsent, isTrue);
      expect(result.isConfigured, isFalse);
      expect(
        result.issues,
        containsAll(<SupabaseConfigurationIssue>[
          SupabaseConfigurationIssue.missingProjectUrl,
          SupabaseConfigurationIssue.missingPublishableKey,
        ]),
      );
    });

    test('loads and normalizes a complete configuration', () {
      final result = SupabaseConfiguration.load(
        projectUrl: ' https://project.supabase.co/ ',
        publishableKey: ' publishable-key ',
      );

      expect(result.isConfigured, isTrue);
      expect(
        result.configuration?.projectUrl,
        Uri.parse('https://project.supabase.co/'),
      );
      expect(result.configuration?.publishableKey, 'publishable-key');
      expect(result.issues, isEmpty);
    });

    test('reports partial configuration without constructing a client', () {
      final result = SupabaseConfiguration.load(
        projectUrl: 'https://project.supabase.co',
      );

      expect(result.isAbsent, isFalse);
      expect(result.isConfigured, isFalse);
      expect(result.issues, [SupabaseConfigurationIssue.missingPublishableKey]);
    });

    test('rejects non-HTTP project URLs', () {
      final result = SupabaseConfiguration.load(
        projectUrl: 'file:///tmp/supabase',
        publishableKey: 'publishable-key',
      );

      expect(result.isConfigured, isFalse);
      expect(result.issues, [SupabaseConfigurationIssue.invalidProjectUrl]);
    });

    test('allows HTTP for local Supabase development', () {
      final result = SupabaseConfiguration.load(
        projectUrl: 'http://127.0.0.1:54321',
        publishableKey: 'publishable-key',
      );

      expect(result.isConfigured, isTrue);
    });
  });
}

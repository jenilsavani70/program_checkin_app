import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:program_checkin_app/src/core/observability.dart';
import 'package:program_checkin_app/src/core/storage.dart';

import '../test_helpers.dart';

void main() {
  test('plain preferences reject sensitive storage keys', () async {
    final secureStore = InMemorySecureStore();
    final preferences = InMemoryPreferences();

    await secureStore.write('access_token', 'fake_access_token');
    await preferences.write('locale', 'de');

    await expectLater(
      preferences.write('email', 'maya@example.org'),
      throwsArgumentError,
    );
    expect(preferences.dumpForTests(), {'locale': 'de'});
    expect(secureStore.dumpForTests()['access_token'], 'fake_access_token');
  });

  test('allowlist redacts unsafe observability attributes', () {
    final safe = allowSafeAttributes({
      'route_name': 'check-in',
      'progress_value': 80.4,
      'note': 'private note',
      'email': 'maya@example.org',
      'authorization': 'Bearer fake_access_token',
      'safe_error_code': 'offline',
    });

    expect(safe, {'route_name': 'check-in', 'safe_error_code': 'offline'});
  });

  test(
    'serialized observability and storage records exclude fake sensitive fixture values',
    () async {
      final scope = testScope();
      await scope.sessionRepository.bootstrapFakeSession();
      scope.observability.recordEvent('checkin_failed', LogLevel.warning, {
        'route_name': 'check-in',
        'safe_error_code': 'offline',
        'note': 'private note',
        'progress_value': 80.4,
        'user_id': 'demo_user_123',
        'email': 'maya@example.org',
        'phone': '+10000000000',
        'authorization': 'Bearer fake_access_token',
        'file_path': '/Users/mac/private',
        'url_query': '?token=fake_access_token',
      });

      final serialized = jsonEncode({
        'logs': scope.observability.logs.map((log) => log.toJson()).toList(),
        'plain_preferences': scope.preferences.dumpForTests(),
      });

      for (final sensitive in [
        'private note',
        '80.4',
        'demo_user_123',
        'Maya',
        'maya@example.org',
        '+10000000000',
        'fake_access_token',
        'Authorization',
        'request body',
        'response body',
        '/Users/mac/private',
        '?token=',
      ]) {
        expect(serialized, isNot(contains(sensitive)));
      }
    },
  );
}

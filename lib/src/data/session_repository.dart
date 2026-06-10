import '../core/clock.dart';
import '../core/observability.dart';
import '../core/result.dart';
import '../core/storage.dart';
import '../domain/session.dart';
import 'fake_program_client.dart';

class SessionRepository {
  SessionRepository({
    required this.secureStore,
    required this.preferences,
    required this.client,
    required this.clock,
    required this.observability,
  });

  final SecureStore secureStore;
  final PlainPreferences preferences;
  final FakeProgramClient client;
  final Clock clock;
  final InMemoryObservability observability;

  static const accessTokenKey = 'access_token';
  static const refreshTokenKey = 'refresh_token';
  static const expiryKey = 'token_expiry';
  static const localeKey = 'locale';

  Future<void> bootstrapFakeSession() async {
    await _save(
      Session(
        accessToken: 'fake_access_token',
        refreshToken: 'fake_refresh_token',
        expiresAt: DateTime.utc(2026, 6, 2, 12, 30),
      ),
    );
  }

  Future<Result<Session>> refresh() async {
    final result = await client.refreshSession();
    return result.when(
      success: (session) async {
        await _save(session);
        return Success(session);
      },
      failure: (failure) async {
        if (failure.clearsSession) await clearSession();
        observability.recordEvent('session_refresh_failed', LogLevel.warning, {
          'safe_error_code': failure.safeCode,
          'status_class': failure.clearsSession ? '401' : 'failure',
          'retryable': failure.retryable,
        });
        return Failure(failure);
      },
    );
  }

  Future<void> clearSession() async {
    await secureStore.clear();
  }

  Future<void> saveLocale(String localeCode) =>
      preferences.write(localeKey, localeCode);

  Future<String?> loadLocale() => preferences.read(localeKey);

  Future<void> _save(Session session) async {
    await secureStore.write(accessTokenKey, session.accessToken);
    await secureStore.write(refreshTokenKey, session.refreshToken);
    await secureStore.write(expiryKey, session.expiresAt.toIso8601String());
  }
}

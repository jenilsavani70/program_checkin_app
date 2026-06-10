import '../core/clock.dart';
import '../core/observability.dart';
import '../core/storage.dart';
import '../data/fake_program_client.dart';
import '../data/program_repository.dart';
import '../data/session_repository.dart';

class AppScope {
  AppScope({
    required this.programRepository,
    required this.sessionRepository,
    required this.secureStore,
    required this.preferences,
    required this.clock,
    required this.observability,
  });

  factory AppScope.demo() {
    final clock = FixedClock(DateTime.utc(2026, 6, 8, 10));
    final secureStore = InMemorySecureStore();
    final preferences = InMemoryPreferences();
    final observability = InMemoryObservability(clock: clock);
    final client = FakeProgramClient(clock: clock);
    final sessionRepository = SessionRepository(
      secureStore: secureStore,
      preferences: preferences,
      client: client,
      clock: clock,
      observability: observability,
    );
    return AppScope(
      programRepository: ProgramRepository(client: client, clock: clock),
      sessionRepository: sessionRepository,
      secureStore: secureStore,
      preferences: preferences,
      clock: clock,
      observability: observability,
    );
  }

  final ProgramRepository programRepository;
  final SessionRepository sessionRepository;
  final SecureStore secureStore;
  final PlainPreferences preferences;
  final Clock clock;
  final InMemoryObservability observability;
}

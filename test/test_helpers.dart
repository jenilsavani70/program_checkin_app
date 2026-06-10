import 'package:program_checkin_app/src/core/clock.dart';
import 'package:program_checkin_app/src/core/observability.dart';
import 'package:program_checkin_app/src/core/storage.dart';
import 'package:program_checkin_app/src/data/fake_program_client.dart';
import 'package:program_checkin_app/src/data/program_repository.dart';
import 'package:program_checkin_app/src/data/session_repository.dart';
import 'package:program_checkin_app/src/di/app_scope.dart';

AppScope testScope() {
  final clock = FixedClock(DateTime.utc(2026, 6, 8, 12));
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

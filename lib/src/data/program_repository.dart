import '../core/clock.dart';
import '../core/result.dart';
import '../domain/checkin.dart';
import 'fake_program_client.dart';

class ProgramRepository {
  ProgramRepository({required this.client, required this.clock});

  final FakeProgramClient client;
  final Clock clock;
  ProgramSnapshot? _lastSnapshot;

  ProgramSnapshot? get cachedSnapshot => _lastSnapshot;

  Future<Result<ProgramSnapshot>> loadDashboardAndHistory() async {
    final result = await client.loadProgram();
    if (result case Success<ProgramSnapshot>(:final value)) {
      _lastSnapshot = value;
    }
    return result;
  }

  Future<Result<CheckInEntry>> submitCheckIn(
    CheckInSubmission submission,
  ) async {
    final result = await client.submitCheckIn(submission);
    if (result case Success<CheckInEntry>()) {
      await loadDashboardAndHistory();
    }
    return result;
  }
}

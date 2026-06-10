import '../core/clock.dart';
import '../core/formatting.dart';
import '../core/result.dart';
import '../domain/checkin.dart';
import '../domain/program.dart';
import '../domain/session.dart';

enum FakeScenario {
  success,
  timeout,
  offline,
  malformedJson,
  unauthorized,
  rateLimited,
}

class ProgramSnapshot {
  const ProgramSnapshot({required this.dashboard, required this.history});

  final ProgramDashboard dashboard;
  final List<CheckInEntry> history;
}

class FakeProgramClient {
  FakeProgramClient({required this.clock});

  final Clock clock;
  FakeScenario nextLoadScenario = FakeScenario.success;
  FakeScenario nextSubmitScenario = FakeScenario.success;
  FakeScenario nextRefreshScenario = FakeScenario.success;
  Duration nextLoadDelay = Duration.zero;
  final Set<String> _submittedKeys = {};
  bool sessionCleared = false;

  ProgramDashboard _dashboard = ProgramDashboard(
    firstName: 'Maya',
    region: 'Region A',
    programName: '12 Week Coaching Program',
    currentWeek: 8,
    nextCheckInDue: DateTime.utc(2026, 6, 8),
    hasPendingTask: true,
  );

  final List<Map<String, Object?>> _fixtureHistory = [
    {
      'id': 'c1',
      'date': '2026-05-04',
      'progressValue': 85,
      'adherence': 'completed',
      'wellbeing': 'good',
    },
    {
      'id': 'c2',
      'date': '2026-05-11',
      'progressValue': 84,
      'adherence': 'completed',
      'wellbeing': 'good',
    },
    {
      'id': 'c3',
      'date': '2026-05-18',
      'progressValue': 83.2,
      'adherence': 'partial',
      'wellbeing': 'okay',
    },
    {
      'id': 'c4',
      'date': '2026-05-25',
      'progressValue': '82,7',
      'adherence': 'completed',
      'wellbeing': 'good',
    },
    {
      'id': 'c5',
      'date': '2026-06-01',
      'progressValue': null,
      'adherence': 'missed',
      'wellbeing': 'needs_support',
    },
  ];

  Result<T>? _failureFor<T>(FakeScenario scenario) {
    return switch (scenario) {
      FakeScenario.success => null,
      FakeScenario.timeout => const Failure(
        AppFailure(
          kind: FailureKind.timeout,
          safeCode: 'timeout',
          retryable: true,
        ),
      ),
      FakeScenario.offline => const Failure(
        AppFailure(
          kind: FailureKind.offline,
          safeCode: 'offline',
          retryable: true,
        ),
      ),
      FakeScenario.malformedJson => const Failure(
        AppFailure(
          kind: FailureKind.malformedJson,
          safeCode: 'malformed_json',
          retryable: false,
        ),
      ),
      FakeScenario.unauthorized => const Failure(
        AppFailure(
          kind: FailureKind.unauthorized,
          safeCode: 'unauthorized',
          retryable: false,
        ),
      ),
      FakeScenario.rateLimited => const Failure(
        AppFailure(
          kind: FailureKind.rateLimited,
          safeCode: 'rate_limited',
          retryable: true,
        ),
      ),
    };
  }

  Future<Result<ProgramSnapshot>> loadProgram() async {
    final scenario = nextLoadScenario;
    nextLoadScenario = FakeScenario.success;
    if (nextLoadDelay != Duration.zero) {
      final delay = nextLoadDelay;
      nextLoadDelay = Duration.zero;
      await Future<void>.delayed(delay);
    }
    final failure = _failureFor<ProgramSnapshot>(scenario);
    if (failure != null) return failure;
    final history = _fixtureHistory.map(_entryFromJson).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return Success(ProgramSnapshot(dashboard: _dashboard, history: history));
  }

  Future<Result<CheckInEntry>> submitCheckIn(
    CheckInSubmission submission,
  ) async {
    final scenario = nextSubmitScenario;
    nextSubmitScenario = FakeScenario.success;
    final failure = _failureFor<CheckInEntry>(scenario);
    if (failure != null) return failure;
    if (_submittedKeys.contains(submission.idempotencyKey)) {
      final existing = _entryFromSubmission(submission);
      return Success(existing);
    }
    _submittedKeys.add(submission.idempotencyKey);
    final entry = _entryFromSubmission(submission);
    _fixtureHistory.add({
      'id': entry.id,
      'date': entry.date.toIso8601String().substring(0, 10),
      'progressValue': entry.progressValue,
      'adherence': entry.adherence.name,
      'wellbeing': entry.wellbeing.name,
    });
    _dashboard = _dashboard.copyWith(hasPendingTask: false);
    return Success(entry);
  }

  Future<Result<Session>> refreshSession() async {
    final scenario = nextRefreshScenario;
    nextRefreshScenario = FakeScenario.success;
    final failure = _failureFor<Session>(scenario);
    if (failure != null) return failure;
    return Success(
      Session(
        accessToken: 'fake_access_token_refreshed',
        refreshToken: 'fake_refresh_token_refreshed',
        expiresAt: clock.now().add(const Duration(hours: 1)),
      ),
    );
  }

  CheckInEntry _entryFromSubmission(CheckInSubmission submission) {
    return CheckInEntry(
      id: submission.idempotencyKey,
      date: DateTime.utc(
        submission.submittedAt.year,
        submission.submittedAt.month,
        submission.submittedAt.day,
      ),
      progressValue: submission.progressValue,
      adherence: submission.adherence,
      wellbeing: submission.wellbeing,
    );
  }

  CheckInEntry _entryFromJson(Map<String, Object?> json) {
    return CheckInEntry(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      progressValue: parseProgressValue(json['progressValue']),
      adherence: _adherenceFrom(json['adherence'] as String),
      wellbeing: _wellbeingFrom(json['wellbeing'] as String),
    );
  }

  Adherence _adherenceFrom(String value) => switch (value) {
    'completed' => Adherence.completed,
    'partial' => Adherence.partial,
    'missed' => Adherence.missed,
    _ => Adherence.partial,
  };

  Wellbeing _wellbeingFrom(String value) => switch (value) {
    'good' => Wellbeing.good,
    'okay' => Wellbeing.okay,
    'needs_support' || 'needsSupport' => Wellbeing.needsSupport,
    _ => Wellbeing.okay,
  };
}

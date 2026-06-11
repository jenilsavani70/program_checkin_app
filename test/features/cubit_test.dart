import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:program_checkin_app/src/core/observability.dart';
import 'package:program_checkin_app/src/data/fake_program_client.dart';
import 'package:program_checkin_app/src/domain/checkin.dart';
import 'package:program_checkin_app/src/features/checkin/presentation/bloc/checkin.dart';
import 'package:program_checkin_app/src/features/dashboard/presentation/bloc/dashboard.dart';
import 'package:program_checkin_app/src/features/settings/presentation/bloc/session_cubit.dart';

import '../test_helpers.dart';

void main() {
  blocTest<CheckInBloc, CheckInState>(
    'successful submission reaches submitted state',
    build: () {
      final scope = testScope();
      return CheckInBloc(
          programRepository: scope.programRepository,
          sessionRepository: scope.sessionRepository,
          clock: scope.clock,
          observability: scope.observability,
        )
        ..add(const CheckInFlowStarted('corr_test'))
        ..add(const CheckInProgressChanged(80))
        ..add(const CheckInAdherenceChanged(Adherence.completed))
        ..add(const CheckInWellbeingChanged(Wellbeing.good));
    },
    skip: 4,
    act: (bloc) => bloc.add(const CheckInSubmitPressed()),
    expect: () => [
      isA<CheckInState>().having(
        (state) => state.status,
        'status',
        CheckInStatus.validating,
      ),
      isA<CheckInState>().having(
        (state) => state.status,
        'status',
        CheckInStatus.submitting,
      ),
      isA<CheckInState>().having(
        (state) => state.status,
        'status',
        CheckInStatus.submitted,
      ),
    ],
  );

  blocTest<CheckInBloc, CheckInState>(
    'invalid input emits invalid state and validation metric',
    build: () {
      final scope = testScope();
      return CheckInBloc(
        programRepository: scope.programRepository,
        sessionRepository: scope.sessionRepository,
        clock: scope.clock,
        observability: scope.observability,
      );
    },
    act: (bloc) => bloc.add(const CheckInSubmitPressed()),
    verify: (bloc) {
      expect(bloc.state.status, CheckInStatus.invalid);
      expect(bloc.observability.metrics['checkin.validation_failures'], 1);
    },
  );

  test('starting flow clears old validation error but keeps draft', () async {
    final scope = testScope();
    final bloc = CheckInBloc(
      programRepository: scope.programRepository,
      sessionRepository: scope.sessionRepository,
      clock: scope.clock,
      observability: scope.observability,
    )..add(const CheckInAdherenceChanged(Adherence.completed));

    bloc.add(const CheckInSubmitPressed());
    await bloc.stream.firstWhere((state) => state.status == CheckInStatus.invalid);

    bloc.add(const CheckInFlowStarted('corr_restart'));
    await bloc.stream.firstWhere((state) => state.status == CheckInStatus.editing);

    expect(bloc.state.draft.adherence, Adherence.completed);
    expect(bloc.state.draft.progressValue, isNull);
    expect(bloc.state.status, CheckInStatus.editing);
  });

  test(
    'timeout/offline submit failure preserves draft and offers retryable state',
    () async {
      final scope = testScope();
      final client = scope.programRepository.client;
      client.nextSubmitScenario = FakeScenario.offline;
      final bloc =
          CheckInBloc(
              programRepository: scope.programRepository,
              sessionRepository: scope.sessionRepository,
              clock: scope.clock,
              observability: scope.observability,
            )
            ..add(const CheckInProgressChanged(80))
            ..add(const CheckInAdherenceChanged(Adherence.partial))
            ..add(const CheckInWellbeingChanged(Wellbeing.okay))
            ..add(const CheckInNoteChanged('private retry note'));

      bloc.add(const CheckInSubmitPressed());
      await bloc.stream.firstWhere(
        (state) => state.status == CheckInStatus.retryableFailure,
      );

      expect(bloc.state.status, CheckInStatus.retryableFailure);
      expect(bloc.state.draft.note, 'private retry note');
      expect(bloc.observability.crashCount, 0);
    },
  );

  test('401 unauthorized clears secure session state', () async {
    final scope = testScope();
    await scope.sessionRepository.bootstrapFakeSession();
    scope.programRepository.client.nextSubmitScenario =
        FakeScenario.unauthorized;
    final bloc =
        CheckInBloc(
            programRepository: scope.programRepository,
            sessionRepository: scope.sessionRepository,
            clock: scope.clock,
            observability: scope.observability,
          )
          ..add(const CheckInProgressChanged(80))
          ..add(const CheckInAdherenceChanged(Adherence.completed))
          ..add(const CheckInWellbeingChanged(Wellbeing.good));

    bloc.add(const CheckInSubmitPressed());
    await bloc.stream.firstWhere(
      (state) => state.status == CheckInStatus.unauthorized,
    );

    expect(bloc.state.status, CheckInStatus.unauthorized);
    expect(scope.secureStore.dumpForTests(), isEmpty);
  });

  test('double submit saves only once', () async {
    final scope = testScope();
    final bloc =
        CheckInBloc(
            programRepository: scope.programRepository,
            sessionRepository: scope.sessionRepository,
            clock: scope.clock,
            observability: scope.observability,
          )
          ..add(const CheckInProgressChanged(80))
          ..add(const CheckInAdherenceChanged(Adherence.completed))
          ..add(const CheckInWellbeingChanged(Wellbeing.good));

    bloc
      ..add(const CheckInSubmitPressed())
      ..add(const CheckInSubmitPressed());
    await bloc.stream.firstWhere(
      (state) => state.status == CheckInStatus.submitted,
    );

    final snapshot = scope.programRepository.cachedSnapshot;
    expect(
      snapshot!.history.where((entry) => entry.id == 'checkin-2026-06-08'),
      hasLength(1),
    );
  });

  test('stale delayed dashboard load cannot overwrite newer success', () async {
    final scope = testScope();
    final bloc = DashboardBloc(
      programRepository: scope.programRepository,
      sessionRepository: scope.sessionRepository,
      observability: scope.observability,
    );
    scope.programRepository.client.nextLoadDelay = const Duration(
      milliseconds: 30,
    );
    bloc.add(const DashboardLoadRequested());
    final first = Future<void>.delayed(const Duration(milliseconds: 35));
    await Future<void>.delayed(const Duration(milliseconds: 1));
    bloc.add(const DashboardLoadRequested());
    await first;

    expect(bloc.state.status, DashboardStatus.loaded);
    expect(bloc.state.dashboard?.firstName, 'Maya');
  });

  test(
    'observability records successful submit span lifecycle with safe attributes',
    () async {
      final scope = testScope();
      final bloc =
          CheckInBloc(
              programRepository: scope.programRepository,
              sessionRepository: scope.sessionRepository,
              clock: scope.clock,
              observability: scope.observability,
            )
            ..add(const CheckInProgressChanged(80))
            ..add(const CheckInAdherenceChanged(Adherence.completed))
            ..add(const CheckInWellbeingChanged(Wellbeing.good));

      bloc.add(const CheckInSubmitPressed());
      await bloc.stream.firstWhere(
        (state) => state.status == CheckInStatus.submitted,
      );

      final submit = scope.observability.spans.firstWhere(
        (span) => span.name == 'checkin.submit',
      );
      final repo = scope.observability.spans.firstWhere(
        (span) => span.name == 'repository.submit_checkin',
      );
      expect(repo.parentName, submit.name);
      expect(submit.status, SpanStatus.ok);
      expect(submit.durationMs, isNotNull);
      expect(
        submit.attributes.keys,
        everyElement(isIn(['route_name', 'adherence', 'wellbeing'])),
      );
    },
  );

  test(
    'failed submit shares correlation id across breadcrumb span log and error',
    () async {
      final scope = testScope();
      scope.programRepository.client.nextSubmitScenario = FakeScenario.timeout;
      final bloc =
          CheckInBloc(
              programRepository: scope.programRepository,
              sessionRepository: scope.sessionRepository,
              clock: scope.clock,
              observability: scope.observability,
            )
            ..add(const CheckInProgressChanged(80))
            ..add(const CheckInAdherenceChanged(Adherence.missed))
            ..add(const CheckInWellbeingChanged(Wellbeing.needsSupport));

      bloc.add(const CheckInSubmitPressed());
      await bloc.stream.firstWhere(
        (state) => state.status == CheckInStatus.retryableFailure,
      );

      final correlationId = bloc.state.correlationId;
      expect(
        scope.observability.breadcrumbs.any(
          (item) => item['correlation_id'] == correlationId,
        ),
        isTrue,
      );
      expect(
        scope.observability.spans.any(
          (span) =>
              span.correlationId == correlationId &&
              span.status == SpanStatus.error,
        ),
        isTrue,
      );
      expect(
        scope.observability.logs.any(
          (log) => log.attributes['correlation_id'] == correlationId,
        ),
        isTrue,
      );
      expect(
        scope.observability.errors.any(
          (error) => error.correlationId == correlationId,
        ),
        isTrue,
      );
      expect(scope.observability.metrics['checkin.submit_failures'], 1);
    },
  );

  test('retry submit increments retry_count metric', () async {
    final scope = testScope();
    scope.programRepository.client.nextSubmitScenario = FakeScenario.offline;
    final bloc =
        CheckInBloc(
            programRepository: scope.programRepository,
            sessionRepository: scope.sessionRepository,
            clock: scope.clock,
            observability: scope.observability,
          )
          ..add(const CheckInProgressChanged(80))
          ..add(const CheckInAdherenceChanged(Adherence.completed))
          ..add(const CheckInWellbeingChanged(Wellbeing.good));

    bloc.add(const CheckInSubmitPressed());
    await bloc.stream.firstWhere(
      (state) => state.status == CheckInStatus.retryableFailure,
    );
    bloc.add(const CheckInSubmitPressed());
    await bloc.stream.firstWhere(
      (state) => state.status == CheckInStatus.submitting,
    );

    expect(scope.observability.metrics['checkin.retry_count'], 1);
  });

  test('dashboard load 401 clears session and shows unauthorized', () async {
    final scope = testScope();
    await scope.sessionRepository.bootstrapFakeSession();
    scope.programRepository.client.nextLoadScenario = FakeScenario.unauthorized;
    final bloc = DashboardBloc(
      programRepository: scope.programRepository,
      sessionRepository: scope.sessionRepository,
      observability: scope.observability,
    );

    bloc.add(const DashboardLoadRequested());
    await bloc.stream.firstWhere(
      (state) => state.status == DashboardStatus.unauthorized,
    );

    expect(scope.secureStore.dumpForTests(), isEmpty);
  });

  test(
    'session refresh 401 clears secure store and unauthorized state',
    () async {
      final scope = testScope();
      await scope.sessionRepository.bootstrapFakeSession();
      scope.programRepository.client.nextRefreshScenario =
          FakeScenario.unauthorized;
      final sessionCubit = SessionCubit(
        sessionRepository: scope.sessionRepository,
      );
      final dashboardBloc = DashboardBloc(
        programRepository: scope.programRepository,
        sessionRepository: scope.sessionRepository,
        observability: scope.observability,
      );

      await sessionCubit.refresh();
      dashboardBloc.add(const DashboardSessionExpired());
      await dashboardBloc.stream.firstWhere(
        (state) => state.status == DashboardStatus.unauthorized,
      );

      expect(sessionCubit.state.status, SessionStatus.unauthorized);
      expect(scope.secureStore.dumpForTests(), isEmpty);
      expect(
        scope.observability.logs.any(
          (log) => log.eventName == 'session_refresh_failed',
        ),
        isTrue,
      );
      await sessionCubit.close();
      await dashboardBloc.close();
    },
  );

  test(
    'expected failure is not crash while unexpected exception is captured once',
    () async {
      final scope = testScope();
      scope.observability.expectedError('offline', 'corr_x', {
        'route_name': 'check-in',
      });
      scope.observability.unexpectedException(StateError('boom'), 'corr_x', {
        'route_name': 'check-in',
      });

      expect(
        scope.observability.errors.where((error) => error.crash),
        hasLength(1),
      );
      expect(scope.observability.crashCount, 1);
    },
  );
}

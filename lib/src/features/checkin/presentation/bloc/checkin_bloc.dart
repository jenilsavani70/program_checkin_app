import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/clock.dart';
import '../../../../core/observability.dart';
import '../../../../core/result.dart';
import '../../../../data/program_repository.dart';
import '../../../../data/session_repository.dart';
import '../../../../domain/checkin.dart';
import 'checkin_event.dart';
import 'checkin_state.dart';

class CheckInBloc extends Bloc<CheckInEvent, CheckInState> {
  CheckInBloc({
    required this.programRepository,
    required this.sessionRepository,
    required this.clock,
    required this.observability,
  }) : super(const CheckInState.initial()) {
    on<CheckInProgressChanged>(_onProgressChanged);
    on<CheckInAdherenceChanged>(_onAdherenceChanged);
    on<CheckInWellbeingChanged>(_onWellbeingChanged);
    on<CheckInNoteChanged>(_onNoteChanged);
    on<CheckInNextPressed>(_onNextPressed);
    on<CheckInBackPressed>(_onBackPressed);
    on<CheckInFlowStarted>(_onFlowStarted);
    on<CheckInSubmitPressed>(_onSubmitPressed);
  }

  final ProgramRepository programRepository;
  final SessionRepository sessionRepository;
  final Clock clock;
  final InMemoryObservability observability;
  bool _submitInFlight = false;

  void _onProgressChanged(
    CheckInProgressChanged event,
    Emitter<CheckInState> emit,
  ) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          progressValue: event.value,
          clearProgress: event.value == null,
        ),
      ),
    );
  }

  void _onAdherenceChanged(
    CheckInAdherenceChanged event,
    Emitter<CheckInState> emit,
  ) {
    emit(state.copyWith(draft: state.draft.copyWith(adherence: event.value)));
  }

  void _onWellbeingChanged(
    CheckInWellbeingChanged event,
    Emitter<CheckInState> emit,
  ) {
    emit(state.copyWith(draft: state.draft.copyWith(wellbeing: event.value)));
  }

  void _onNoteChanged(CheckInNoteChanged event, Emitter<CheckInState> emit) {
    emit(state.copyWith(draft: state.draft.copyWith(note: event.value)));
  }

  void _onNextPressed(CheckInNextPressed event, Emitter<CheckInState> emit) {
    final nextStep = state.step + 1;
    if (state.step == 2 && state.draft.wellbeing == Wellbeing.needsSupport) {
      emit(state.copyWith(status: CheckInStatus.supportNeeded, step: 3));
      return;
    }
    emit(
      state.copyWith(step: nextStep.clamp(0, 5), status: CheckInStatus.editing),
    );
  }

  void _onFlowStarted(CheckInFlowStarted event, Emitter<CheckInState> emit) {
    emit(state.copyWith(correlationId: event.correlationId));
  }

  void _onBackPressed(CheckInBackPressed event, Emitter<CheckInState> emit) {
    emit(
      state.copyWith(
        step: (state.step - 1).clamp(0, 5),
        status: CheckInStatus.editing,
      ),
    );
  }

  Future<void> _onSubmitPressed(
    CheckInSubmitPressed event,
    Emitter<CheckInState> emit,
  ) async {
    if (_submitInFlight || state.status == CheckInStatus.submitted) return;
    final correlationId =
        state.correlationId ?? observability.newCorrelationId();
    if (state.status == CheckInStatus.retryableFailure) {
      observability.metric('checkin.retry_count');
    }
    observability.breadcrumb('check-in', correlationId);
    emit(
      state.copyWith(
        status: CheckInStatus.validating,
        correlationId: correlationId,
      ),
    );
    final submissionResult = state.draft.toSubmission(submittedAt: clock.now());
    if (submissionResult case Failure<CheckInSubmission>(
      failure: final failure,
    )) {
      observability.metric('checkin.validation_failures');
      observability.recordEvent('checkin_validated', LogLevel.warning, {
        'route_name': 'check-in',
        'safe_error_code': failure.safeCode,
        'correlation_id': correlationId,
      });
      observability.endOpenSpan(
        'checkin.flow',
        correlationId,
        SpanStatus.error,
      );
      emit(
        state.copyWith(
          status: CheckInStatus.invalid,
          failure: failure,
          correlationId: correlationId,
        ),
      );
      return;
    }

    final submission = (submissionResult as Success<CheckInSubmission>).value;
    _submitInFlight = true;
    observability.metric('checkin.submit_attempts');
    observability.recordEvent('checkin_submit_attempted', LogLevel.info, {
      'route_name': 'check-in',
      'adherence': submission.adherence.name,
      'wellbeing': submission.wellbeing.name,
      'has_note': submission.note != null,
      'correlation_id': correlationId,
    });
    final submitSpan = observability.startSpan(
      'checkin.submit',
      correlationId,
      parentName: 'checkin.flow',
      attributes: {
        'route_name': 'check-in',
        'adherence': submission.adherence.name,
        'wellbeing': submission.wellbeing.name,
      },
    );
    final repoSpan = observability.startSpan(
      'repository.submit_checkin',
      correlationId,
      parentName: 'checkin.submit',
    );
    emit(
      state.copyWith(
        status: CheckInStatus.submitting,
        correlationId: correlationId,
      ),
    );

    try {
      final result = await programRepository.submitCheckIn(submission);
      switch (result) {
        case Success<CheckInEntry>(value: final entry):
          observability.endSpan(repoSpan, SpanStatus.ok);
          observability.endSpan(submitSpan, SpanStatus.ok);
          observability.endOpenSpan(
            'checkin.flow',
            correlationId,
            SpanStatus.ok,
          );
          observability.metric(
            'checkin.submit_duration_ms',
            by: submitSpan.durationMs ?? 0,
          );
          observability.recordEvent('checkin_submitted', LogLevel.info, {
            'route_name': 'check-in',
            'status_class': 'success',
            'adherence': submission.adherence.name,
            'wellbeing': submission.wellbeing.name,
            'has_note': submission.note != null,
            'correlation_id': correlationId,
          });
          emit(
            state.copyWith(
              status: CheckInStatus.submitted,
              submittedEntry: entry,
              correlationId: correlationId,
            ),
          );
        case Failure<CheckInEntry>(failure: final failure):
          if (failure.clearsSession) await sessionRepository.clearSession();
          observability.endSpan(repoSpan, SpanStatus.error);
          observability.endSpan(submitSpan, SpanStatus.error);
          observability.endOpenSpan(
            'checkin.flow',
            correlationId,
            SpanStatus.error,
          );
          observability.metric('checkin.submit_failures');
          observability.recordEvent('checkin_failed', LogLevel.warning, {
            'route_name': 'check-in',
            'safe_error_code': failure.safeCode,
            'retryable': failure.retryable,
            'correlation_id': correlationId,
          });
          observability.expectedError(failure.safeCode, correlationId, {
            'route_name': 'check-in',
            'safe_error_code': failure.safeCode,
            'retryable': failure.retryable,
          });
          emit(
            state.copyWith(
              status: failure.clearsSession
                  ? CheckInStatus.unauthorized
                  : CheckInStatus.retryableFailure,
              failure: failure,
              correlationId: correlationId,
            ),
          );
      }
    } catch (error) {
      observability.unexpectedException(error, correlationId, {
        'route_name': 'check-in',
      });
      emit(
        state.copyWith(
          status: CheckInStatus.retryableFailure,
          failure: const AppFailure(
            kind: FailureKind.unknown,
            safeCode: 'unexpected',
            retryable: true,
          ),
        ),
      );
    } finally {
      _submitInFlight = false;
    }
  }
}

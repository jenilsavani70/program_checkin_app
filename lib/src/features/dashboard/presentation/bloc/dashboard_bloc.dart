import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/observability.dart';
import '../../../../core/result.dart';
import '../../../../data/fake_program_client.dart';
import '../../../../data/program_repository.dart';
import '../../../../data/session_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    required this.programRepository,
    required this.sessionRepository,
    required this.observability,
  }) : super(const DashboardState.loading()) {
    on<DashboardLoadRequested>(_onLoadRequested);
    on<DashboardSessionExpired>(_onSessionExpired);
  }

  final ProgramRepository programRepository;
  final SessionRepository sessionRepository;
  final InMemoryObservability observability;
  int _loadGeneration = 0;

  void _onSessionExpired(
    DashboardSessionExpired event,
    Emitter<DashboardState> emit,
  ) {
    emit(
      DashboardState(
        status: DashboardStatus.unauthorized,
        dashboard: state.dashboard,
        history: state.history,
      ),
    );
  }

  Future<void> _onLoadRequested(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    final generation = ++_loadGeneration;
    final correlationId = observability.newCorrelationId();
    final span = observability.startSpan(
      'dashboard.load',
      correlationId,
      attributes: {'route_name': 'dashboard'},
    );
    final hasUsableState = state.dashboard != null;
    if (!event.refresh && !hasUsableState) emit(const DashboardState.loading());
    if (event.refresh && hasUsableState) {
      emit(state.copyWith(isRefreshing: true));
    }

    final result = await programRepository.loadDashboardAndHistory();
    if (generation != _loadGeneration) return;

    switch (result) {
      case Success<ProgramSnapshot>(value: final snapshot):
        final status = snapshot.history.isEmpty
            ? DashboardStatus.empty
            : DashboardStatus.loaded;
        emit(
          DashboardState(
            status: status,
            dashboard: snapshot.dashboard,
            history: snapshot.history,
          ),
        );
        observability.recordEvent('dashboard_loaded', LogLevel.info, {
          'route_name': 'dashboard',
          'status_class': 'success',
          'region': snapshot.dashboard.region,
          'correlation_id': correlationId,
        });
        observability.endSpan(span, SpanStatus.ok);
      case Failure<ProgramSnapshot>(failure: final failure):
        if (failure.clearsSession) await sessionRepository.clearSession();
        final cached = programRepository.cachedSnapshot;
        if (hasUsableState || cached != null) {
          emit(
            DashboardState(
              status: DashboardStatus.loaded,
              dashboard: state.dashboard ?? cached!.dashboard,
              history: state.history.isNotEmpty
                  ? state.history
                  : cached!.history,
              failure: failure,
            ),
          );
        } else {
          emit(
            DashboardState(
              status: failure.clearsSession
                  ? DashboardStatus.unauthorized
                  : DashboardStatus.error,
              failure: failure,
            ),
          );
        }
        observability.expectedError(failure.safeCode, correlationId, {
          'route_name': 'dashboard',
          'safe_error_code': failure.safeCode,
          'retryable': failure.retryable,
        });
        observability.endSpan(span, SpanStatus.error);
    }
  }
}

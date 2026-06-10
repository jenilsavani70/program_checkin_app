import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result.dart';
import '../../../../data/session_repository.dart';

enum SessionStatus { authenticated, refreshing, unauthorized }

class SessionState extends Equatable {
  const SessionState({this.status = SessionStatus.authenticated});

  final SessionStatus status;

  SessionState copyWith({SessionStatus? status}) {
    return SessionState(status: status ?? this.status);
  }

  @override
  List<Object?> get props => [status];
}

class SessionCubit extends Cubit<SessionState> {
  SessionCubit({required this.sessionRepository}) : super(const SessionState());

  final SessionRepository sessionRepository;

  Future<bool> refresh() async {
    emit(state.copyWith(status: SessionStatus.refreshing));
    final result = await sessionRepository.refresh();
    return switch (result) {
      Success() => () {
        emit(const SessionState(status: SessionStatus.authenticated));
        return true;
      }(),
      Failure(:final failure) => () {
        if (failure.clearsSession) {
          emit(const SessionState(status: SessionStatus.unauthorized));
        } else {
          emit(const SessionState(status: SessionStatus.authenticated));
        }
        return false;
      }(),
    };
  }
}

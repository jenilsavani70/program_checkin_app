import 'package:equatable/equatable.dart';

import '../../../../core/result.dart';
import '../../../../domain/checkin.dart';
import '../../../../domain/program.dart';

enum DashboardStatus { loading, loaded, empty, error, unauthorized }

class DashboardState extends Equatable {
  const DashboardState({
    required this.status,
    this.dashboard,
    this.history = const [],
    this.failure,
    this.isRefreshing = false,
  });

  const DashboardState.loading() : this(status: DashboardStatus.loading);

  final DashboardStatus status;
  final ProgramDashboard? dashboard;
  final List<CheckInEntry> history;
  final AppFailure? failure;
  final bool isRefreshing;

  DashboardState copyWith({
    DashboardStatus? status,
    ProgramDashboard? dashboard,
    List<CheckInEntry>? history,
    AppFailure? failure,
    bool? isRefreshing,
  }) {
    return DashboardState(
      status: status ?? this.status,
      dashboard: dashboard ?? this.dashboard,
      history: history ?? this.history,
      failure: failure,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
    status,
    dashboard,
    history,
    failure,
    isRefreshing,
  ];
}

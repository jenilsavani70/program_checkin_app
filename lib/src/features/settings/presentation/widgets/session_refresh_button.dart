import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization.dart';
import '../../../dashboard/presentation/bloc/dashboard.dart';
import '../bloc/session_cubit.dart';

class SessionRefreshButton extends StatelessWidget {
  const SessionRefreshButton({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return BlocListener<SessionCubit, SessionState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == SessionStatus.unauthorized) {
          context.read<DashboardBloc>().add(const DashboardSessionExpired());
        }
      },
      child: IconButton(
        tooltip: strings.refreshSession,
        icon: const Icon(Icons.lock_reset),
        onPressed: () => context.read<SessionCubit>().refresh(),
      ),
    );
  }
}

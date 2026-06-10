import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/widgets/app_panels.dart';
import '../../../../core/localization.dart';
import '../../../dashboard/presentation/bloc/dashboard.dart';
import '../../../settings/presentation/widgets/locale_menu.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appTitle),
        actions: const [LocaleMenu(), SizedBox(width: 8)],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          final dashboard = state.dashboard;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              HeroPanel(
                icon: Icons.auto_awesome,
                title: dashboard == null
                    ? strings.appTitle
                    : strings.greeting(dashboard.firstName),
                subtitle: dashboard == null
                    ? strings.pendingTask
                    : strings.programWeekSummary(
                        dashboard.programName,
                        dashboard.currentWeek,
                      ),
              ),
              const SizedBox(height: 16),
              ActionPanel(
                icon: Icons.dashboard_outlined,
                title: strings.dashboard,
                subtitle: dashboard == null
                    ? strings.activeProgram
                    : strings.programWeekSummary(
                        dashboard.programName,
                        dashboard.currentWeek,
                      ),
                accentColor: const Color(0xff176b5b),
                onTap: () => context.pushNamed('dashboard'),
              ),
              const SizedBox(height: 12),
              ActionPanel(
                icon: Icons.fact_check_outlined,
                title: strings.startCheckIn,
                subtitle: dashboard?.hasPendingTask == false
                    ? strings.noPendingTask
                    : strings.pendingTask,
                accentColor: const Color(0xffd86b45),
                onTap: dashboard?.hasPendingTask == false
                    ? null
                    : () => context.pushNamed('check-in'),
              ),
              const SizedBox(height: 12),
              ActionPanel(
                icon: Icons.timeline,
                title: strings.history,
                subtitle: strings.progress,
                accentColor: const Color(0xffb88a15),
                onTap: () => context.pushNamed('history'),
              ),
            ],
          );
        },
      ),
    );
  }
}

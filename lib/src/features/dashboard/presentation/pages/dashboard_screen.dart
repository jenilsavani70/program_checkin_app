import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/widgets/app_panels.dart';
import '../../../../common/widgets/base_screen.dart';
import '../../../../common/widgets/feedback_widgets.dart';
import '../../../../core/formatting.dart';
import '../../../../core/localization.dart';
import '../../../settings/presentation/widgets/locale_menu.dart';
import '../../../settings/presentation/widgets/session_refresh_button.dart';
import '../bloc/dashboard.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    return BaseScreen(
      title: strings.dashboard,
      actions: const [SessionRefreshButton(), LocaleMenu(), SizedBox(width: 8)],
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state.status == DashboardStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == DashboardStatus.unauthorized) {
            return SafeMessage(
              title: strings.signedOut,
              actionLabel: strings.retry,
              onPressed: () => context.read<DashboardBloc>().add(
                const DashboardLoadRequested(),
              ),
            );
          }
          if (state.status == DashboardStatus.error) {
            return SafeMessage(
              title: state.failure?.safeCode ?? strings.emptyDashboard,
              actionLabel: strings.retry,
              onPressed: () => context.read<DashboardBloc>().add(
                const DashboardLoadRequested(),
              ),
            );
          }
          if (state.status == DashboardStatus.empty) {
            return SafeMessage(
              title: strings.emptyDashboard,
              actionLabel: strings.retry,
              onPressed: () => context.read<DashboardBloc>().add(
                const DashboardLoadRequested(),
              ),
            );
          }
          final dashboard = state.dashboard;
          if (dashboard == null) {
            return SafeMessage(
              title: strings.emptyDashboard,
              actionLabel: strings.retry,
              onPressed: () => context.read<DashboardBloc>().add(
                const DashboardLoadRequested(),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => context.read<DashboardBloc>().add(
              const DashboardLoadRequested(refresh: true),
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                HeroPanel(
                  icon: Icons.local_florist_outlined,
                  title: strings.greeting(dashboard.firstName),
                  subtitle: strings.dueDate(
                    formatShortDate(dashboard.nextCheckInDue, locale),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    InfoTile(label: strings.region, value: dashboard.region),
                    InfoTile(
                      label: strings.activeProgram,
                      value: dashboard.programName,
                    ),
                    InfoTile(
                      label: strings.currentWeek,
                      value: strings.currentWeekValue(dashboard.currentWeek),
                    ),
                    InfoTile(
                      label: strings.due,
                      value: formatShortDate(dashboard.nextCheckInDue, locale),
                    ),
                  ],
                ),
                if (state.failure != null) ...[
                  const SizedBox(height: 12),
                  BannerMessage(
                    text: strings.errorWithCode(state.failure!.safeCode),
                  ),
                ],
                const SizedBox(height: 20),
                ActionPanel(
                  icon: Icons.fact_check_outlined,
                  title: dashboard.hasPendingTask
                      ? strings.pendingTask
                      : strings.noPendingTask,
                  subtitle: strings.dueDate(
                    formatShortDate(dashboard.nextCheckInDue, locale),
                  ),
                  accentColor: const Color(0xffd86b45),
                  onTap: dashboard.hasPendingTask
                      ? () => context.goNamed('check-in')
                      : null,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => context.goNamed('history'),
                  icon: const Icon(Icons.timeline),
                  label: Text(strings.history),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../common/widgets/app_panels.dart';
import '../../../../common/widgets/base_screen.dart';
import '../../../../core/formatting.dart';
import '../../../../core/observability.dart';
import '../../../../core/localization.dart';
import '../../../../domain/checkin.dart';
import '../../../dashboard/presentation/bloc/dashboard.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final dashboard = context.read<DashboardBloc>();
      final observability = dashboard.observability;
      final correlationId = observability.newCorrelationId();
      final span = observability.startSpan(
        'history.refresh',
        correlationId,
        attributes: {'route_name': 'history'},
      );
      observability.endSpan(span, SpanStatus.ok);
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    return BaseScreen(
      title: strings.history,
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          final entries = [...state.history]
            ..sort((a, b) => b.date.compareTo(a.date));
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              HeroPanel(
                icon: Icons.insights,
                title: strings.history,
                subtitle: strings.progress,
              ),
              const SizedBox(height: 16),
              SurfacePanel(child: TrendStrip(entries: entries)),
              const SizedBox(height: 16),
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ActionPanel(
                    icon: Icons.event_available_outlined,
                    title: formatShortDate(entry.date, locale),
                    subtitle: strings.historyAdherence(
                      strings.adherenceOption(entry.adherence),
                    ),
                    trailing: formatProgressValue(entry.progressValue, locale),
                    accentColor: const Color(0xff176b5b),
                    onTap: () {},
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class TrendStrip extends StatelessWidget {
  const TrendStrip({super.key, required this.entries});

  final List<CheckInEntry> entries;

  @override
  Widget build(BuildContext context) {
    final values = entries
        .where((entry) => entry.progressValue != null)
        .map((entry) => entry.progressValue!)
        .toList();
    final maxValue = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 96,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final entry in entries.reversed)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: FractionallySizedBox(
                  heightFactor: entry.progressValue == null
                      ? .08
                      : (entry.progressValue! / maxValue).clamp(.08, 1),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: entry.progressValue == null
                          ? Colors.grey.shade400
                          : Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

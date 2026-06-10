import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/route_args.dart';
import '../../../../common/widgets/app_panels.dart';
import '../../../../common/widgets/base_screen.dart';
import '../../../../common/widgets/feedback_widgets.dart';
import '../../../../core/localization.dart';
import '../../../../core/observability.dart';
import '../../../dashboard/presentation/bloc/dashboard.dart';
import '../bloc/checkin.dart';
import '../widgets/checkin_widgets.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key, this.returnTo = CheckInReturnTo.history});

  final CheckInReturnTo returnTo;

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<CheckInBloc>();
      final observability = bloc.observability;
      final correlationId =
          bloc.state.correlationId ?? observability.newCorrelationId();
      observability.breadcrumb('check-in', correlationId);
      observability.startSpan(
        'checkin.flow',
        correlationId,
        attributes: {'route_name': 'check-in'},
      );
      observability.recordEvent('checkin_started', LogLevel.info, {
        'route_name': 'check-in',
        'correlation_id': correlationId,
      });
      bloc.add(CheckInFlowStarted(correlationId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return BlocListener<CheckInBloc, CheckInState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == CheckInStatus.submitted) {
          context.read<DashboardBloc>().add(
            const DashboardLoadRequested(refresh: true),
          );
          final routeName = switch (widget.returnTo) {
            CheckInReturnTo.dashboard => 'dashboard',
            CheckInReturnTo.history => 'history',
          };
          context.goNamed(routeName);
        }
      },
      child: BaseScreen(
        title: strings.startCheckIn,
        body: BlocBuilder<CheckInBloc, CheckInState>(
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                StepProgressPanel(value: ((state.step + 1).clamp(1, 5)) / 5),
                const SizedBox(height: 16),
                SurfacePanel(child: CheckInStepBody(state: state)),
                if (state.failure != null) ...[
                  const SizedBox(height: 12),
                  BannerMessage(
                    text: strings.errorWithCode(state.failure!.safeCode),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (state.step > 0)
                      OutlinedButton.icon(
                        onPressed: state.status == CheckInStatus.submitting
                            ? null
                            : () => context.read<CheckInBloc>().add(
                                const CheckInBackPressed(),
                              ),
                        icon: const Icon(Icons.arrow_back),
                        label: Text(strings.back),
                      ),
                    const Spacer(),
                    if (state.step < 4)
                      FilledButton.icon(
                        onPressed: () => context.read<CheckInBloc>().add(
                          const CheckInNextPressed(),
                        ),
                        icon: const Icon(Icons.arrow_forward),
                        label: Text(strings.next),
                      )
                    else
                      FilledButton.icon(
                        onPressed: state.status == CheckInStatus.submitting
                            ? null
                            : () => context.read<CheckInBloc>().add(
                                const CheckInSubmitPressed(),
                              ),
                        icon: state.status == CheckInStatus.submitting
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(
                          state.status == CheckInStatus.retryableFailure
                              ? strings.tryAgain
                              : strings.submit,
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

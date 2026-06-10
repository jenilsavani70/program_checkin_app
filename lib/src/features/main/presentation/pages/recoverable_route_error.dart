import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/widgets/base_screen.dart';
import '../../../../common/widgets/feedback_widgets.dart';
import '../../../../core/localization.dart';

class RecoverableRouteError extends StatelessWidget {
  const RecoverableRouteError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: AppStrings.of(context).appTitle,
      body: SafeMessage(
        title: message,
        actionLabel: AppStrings.of(context).dashboard,
        onPressed: () => context.goNamed('dashboard'),
      ),
    );
  }
}

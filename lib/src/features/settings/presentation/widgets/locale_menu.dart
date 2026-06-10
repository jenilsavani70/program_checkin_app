import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization.dart';
import '../bloc/locale_cubit.dart';

class LocaleMenu extends StatelessWidget {
  const LocaleMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return PopupMenuButton<String>(
      tooltip: strings.locale,
      icon: const Icon(Icons.language),
      onSelected: (value) =>
          context.read<LocaleCubit>().setLocale(Locale(value)),
      itemBuilder: (context) => [
        PopupMenuItem(value: 'en', child: Text(strings.english)),
        PopupMenuItem(value: 'de', child: Text(strings.german)),
      ],
    );
  }
}

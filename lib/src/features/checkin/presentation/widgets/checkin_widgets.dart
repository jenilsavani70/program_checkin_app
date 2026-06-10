import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/formatting.dart';
import '../../../../core/localization.dart';
import '../../../../domain/checkin.dart';
import '../bloc/checkin.dart';

class StepProgressPanel extends StatelessWidget {
  const StepProgressPanel({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: value,
            backgroundColor: const Color(0xffe6eee9),
            color: const Color(0xffd86b45),
          ),
        ),
      ),
    );
  }
}

class CheckInStepBody extends StatelessWidget {
  const CheckInStepBody({super.key, required this.state});

  final CheckInState state;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return switch (state.step) {
      0 => TextFormField(
        key: ValueKey('progress_${state.draft.progressValue}'),
        initialValue: state.draft.progressValue?.toString() ?? '',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: strings.progress,
          errorText:
              state.status == CheckInStatus.invalid &&
                  state.draft.progressValue == null
              ? strings.requiredField
              : null,
        ),
        onChanged: (value) => context.read<CheckInBloc>().add(
          CheckInProgressChanged(double.tryParse(value.replaceAll(',', '.'))),
        ),
      ),
      1 => SelectionGroup<Adherence>(
        title: strings.adherence,
        value: state.draft.adherence,
        values: Adherence.values,
        labelFor: strings.adherenceOption,
        onChanged: (value) =>
            context.read<CheckInBloc>().add(CheckInAdherenceChanged(value)),
      ),
      2 => SelectionGroup<Wellbeing>(
        title: strings.wellbeing,
        value: state.draft.wellbeing,
        values: Wellbeing.values,
        labelFor: strings.wellbeingOption,
        onChanged: (value) =>
            context.read<CheckInBloc>().add(CheckInWellbeingChanged(value)),
      ),
      3 =>
        state.status == CheckInStatus.supportNeeded
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.supportTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(strings.supportCopy),
                ],
              )
            : TextFormField(
                key: ValueKey('note_${state.draft.note}'),
                initialValue: state.draft.note,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: strings.noteOptionalLabel(),
                ),
                onChanged: (value) =>
                    context.read<CheckInBloc>().add(CheckInNoteChanged(value)),
              ),
      _ => SummaryCard(state: state),
    };
  }
}

class SelectionGroup<T> extends StatelessWidget {
  const SelectionGroup({
    super.key,
    required this.title,
    required this.values,
    required this.value,
    required this.labelFor,
    required this.onChanged,
  });

  final String title;
  final List<T> values;
  final T? value;
  final String Function(T value) labelFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in values)
              Semantics(
                label: labelFor(item),
                selected: item == value,
                button: true,
                onTap: () => onChanged(item),
                child: ChoiceChip(
                  label: Text(labelFor(item)),
                  selected: item == value,
                  showCheckmark: false,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onSelected: (_) => onChanged(item),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.state});

  final CheckInState state;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.summary,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              strings.summaryProgress(
                formatProgressValue(state.draft.progressValue, locale),
              ),
            ),
            Text(
              strings.summaryAdherence(
                state.draft.adherence == null
                    ? strings.requiredField
                    : strings.adherenceOption(state.draft.adherence!),
              ),
            ),
            Text(
              strings.summaryWellbeing(
                state.draft.wellbeing == null
                    ? strings.requiredField
                    : strings.wellbeingOption(state.draft.wellbeing!),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

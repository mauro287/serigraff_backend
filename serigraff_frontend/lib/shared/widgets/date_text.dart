import 'package:flutter/material.dart';

class DateText extends StatelessWidget {
  const DateText(this.date, {super.key});

  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final value = date?.toLocal();
    final label = value == null
        ? 'Fecha no disponible'
        : '${value.day.toString().padLeft(2, '0')}/'
              '${value.month.toString().padLeft(2, '0')}/${value.year}';
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}

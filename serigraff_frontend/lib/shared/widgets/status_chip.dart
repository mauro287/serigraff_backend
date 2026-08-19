import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final (background, foreground) = switch (normalized) {
      'APROBADA' ||
      'COMPLETADO' => (const Color(0xFFDDF7E8), const Color(0xFF176B3A)),
      'RECHAZADA' ||
      'CANCELADO' => (const Color(0xFFFFE3E6), const Color(0xFFA92A3A)),
      'EN_PROCESO' => (const Color(0xFFE3EEFF), const Color(0xFF245CA8)),
      _ => (const Color(0xFFFFF1CC), const Color(0xFF805B00)),
    };

    return Chip(
      label: Text(normalized.replaceAll('_', ' ')),
      backgroundColor: background,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      labelStyle: TextStyle(
        color: foreground,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

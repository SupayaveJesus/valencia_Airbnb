import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Envuelve contenido con la superficie visual común de la app.
///
/// Así cualquier bloque informativo mantiene el mismo borde, radio y padding,
/// incluso cuando la información proviene de pantallas distintas o de respuestas
/// reales del backend.
class MinimalCard extends StatelessWidget {
  const MinimalCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.line),
      ),
      child: child,
    );
  }
}

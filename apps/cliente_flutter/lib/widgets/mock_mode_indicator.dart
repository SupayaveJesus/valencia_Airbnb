import 'package:flutter/material.dart';

import '../config/app_environment.dart';
import '../services/mock/mock_cliente_data.dart';

/// Indicador visible y pedagógico del modo contingencia.
///
/// La idea NO es meter lógica de negocio en la UI. Solo avisamos claramente qué
/// fuente de datos está activa para no confundir a quien evalúa la app.
class MockModeIndicator extends StatelessWidget {
  const MockModeIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppEnvironment.useMockServices || !AppEnvironment.showMockIndicator) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Material(
            elevation: 2,
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                MockClienteData.bannerMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

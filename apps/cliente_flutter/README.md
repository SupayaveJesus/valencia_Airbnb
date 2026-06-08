# Cliente Flutter

Aplicación cliente del práctico final.

## Flujo cubierto

- login cliente
- registro cliente
- búsqueda simple
- búsqueda avanzada
- resultados
- detalle del lugar
- confirmación de reserva
- reservas del cliente

## Decisiones técnicas

- `provider` maneja el estado observable de la UI
- `dio` resuelve HTTP real y fallback de endpoints
- `models` normalizan respuestas inconsistentes del backend
- se mantienen comentarios pedagógicos para defensa académica

## Comandos

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

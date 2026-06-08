# Proyecto final - arquitectura de dos apps

## Respuesta corta

Este repositorio ahora está separado en DOS aplicaciones:

- `apps/cliente_flutter/` → entrega real para mañana
- `apps/arrendatario_ionic/` → frontera separada para el futuro módulo arrendatario

`docs/` y `.atl/` se mantienen en la raíz como fuente compartida.

## Qué está implementado hoy

La app cliente en Flutter ya cubre el flujo principal del PDF con backend real:

1. login cliente
2. registro cliente
3. home con búsqueda simple
4. búsqueda avanzada como frontera funcional
5. lista de resultados
6. detalle del lugar en pantalla dedicada
7. confirmación de reserva
8. pantalla de reservas del cliente

## Fuentes de verdad

- PDF: `docs/requeriments/ProyectoFinalMobiles.pdf`
- API principal: `docs/api/bnbMovilesII.postman_collection.json`

## Estructura

```text
.
├── .atl/
├── docs/
└── apps/
    ├── cliente_flutter/
    └── arrendatario_ionic/
```

## Cómo ejecutar la app cliente

```bash
cd apps/cliente_flutter
flutter pub get
flutter run
```

## Nota importante

La app cliente usa HTTP real, sin mocks. Cuando el backend responde 404, 500 o errores de contrato, la UI los muestra explícitamente para que el comportamiento sea defendible en revisión académica.

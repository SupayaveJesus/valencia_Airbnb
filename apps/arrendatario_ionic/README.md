# Arrendatario Ionic

App móvil del arrendatario en Ionic + Angular. Hoy YA permite autenticarse, mantener sesión y administrar el flujo base de publicaciones desde una shell interna, pero todavía tiene huecos funcionales que se detallan más abajo.

## Ruta rápida

1. Instalar dependencias con `npm install`.
2. Levantar la app con `npm start` o generar build con `npm run build`.
3. Ejecutar pruebas con `npm test -- --watch=false --browsers=ChromeHeadless`.

## Arquitectura

La app está organizada para enseñar responsabilidades por capa, no solo para “hacer que funcione”. La idea es que cada carpeta responda una pregunta concreta.

| Carpeta | Para qué existe | Ejemplos |
|---|---|---|
| `src/app/core/auth` | Resuelve identidad, sesión y reglas de acceso. | `guards/auth.guard.ts`, `services/auth-session.service.ts` |
| `src/app/core/config` | Declara decisiones globales del entorno. | `app-environment.ts` |
| `src/app/core/http` | Centraliza llamadas HTTP, headers, token y clasificación de errores. | `api-client.service.ts` |
| `src/app/core/storage` | Encapsula persistencia local para no acoplar features a Capacitor. | `preferences-storage.service.ts` |
| `src/app/core/places` | Traduce contratos de API y modelos del dominio de lugares. | `models/`, `services/landlord-places-api.service.ts` |
| `src/app/features/auth` | Contiene pantallas públicas de login y registro. | `login.page.ts`, `register.page.ts` |
| `src/app/features/shell` | Da el marco visual autenticado: cabecera, navegación y outlet interno. | `internal-shell.page.ts` |
| `src/app/features/places` | Reúne las pantallas del caso de uso “mis lugares”. | listado, formulario, reservas |

## Flujo principal

1. `app.routes.ts` separa rutas públicas y rutas internas.
2. `auth.guard.ts` obliga a restaurar la sesión antes de decidir si se entra o no.
3. `internal-shell.page.ts` monta la estructura persistente de la app autenticada.
4. Las páginas de `features/places` piden datos a `LandlordPlacesApiService`.
5. `LandlordPlacesApiService` usa `ApiClientService` para hablar con la API sin duplicar manejo de errores.

## Decisiones pedagógicas actuales

- La sesión vive en `AuthSessionService` para que la UI lea estado reactivo y no storage crudo.
- `ApiClientService` absorbe detalles repetitivos de red para que cada feature piense en casos de uso, no en plumbing.
- La shell interna separa “marco de navegación” de “pantalla puntual”; eso simplifica crecer el módulo de lugares.
- El formulario de lugares sigue siendo **solo creación**. NO se simuló edición porque eso generaría una UX engañosa.
- Los archivos TypeScript clave están comentados con intención docente: propiedades, ramas importantes, mapeos de API y decisiones de navegación explican qué hacen y por qué existen.

## Cobertura de requerimientos

Estado honesto del alcance actual:

| Requerimiento | Estado | Nota |
|---|---|---|
| Login público | DONE | Con persistencia de sesión. |
| Registro público | DONE | Flujo base disponible. |
| Rutas protegidas | DONE | Resueltas con guards y restauración previa de sesión. |
| Shell interna autenticada | DONE | Cabecera, navegación y logout. |
| Listado de lugares del arrendatario | DONE | Ahora muestra miniatura con primera foto o placeholder sólido. |
| Acción de reservas desde el listado | DONE | CTA visible hacia el detalle de reservas. |
| Crear lugar | PARTIAL | Guarda datos y luego intenta subir fotos, pero todavía permite publicar sin fotos. |
| Vista de mapa en el formulario | PARTIAL | Solo abre un enlace externo; falta selector interactivo en mapa. |
| Editar lugar existente | MISSING | No hay flujo real de edición en esta app. |

## Qué mirar primero si vas a revisar

1. `src/app/features/places/landlord-places.page.*` para el cambio visual del listado.
2. `src/app/core/places/services/landlord-places-api.service.ts` para entender cómo la UI recibe datos normalizados.
3. `src/app/app.routes.ts` y `src/app/features/shell/internal-shell.page.ts` para la estructura de navegación.

## Cómo estudiar este código para defensa académica

1. Empezá por `src/app/app.routes.ts` para ver cómo se separa el flujo público del flujo autenticado.
2. Seguí con `src/app/core/auth` para entender quién decide acceso, quién restaura sesión y por qué esas responsabilidades no viven en las páginas.
3. Luego revisá `src/app/core/http` y `src/app/core/places` para ver la transformación **API cruda -> modelos estables de UI**.
4. Terminá en `src/app/features/...` para observar cómo cada página consume servicios ya preparados en vez de mezclar red, storage y navegación en el mismo lugar.

La intención de estos comentarios NO es llenar el código de texto, sino dejar visible el razonamiento arquitectónico para que otra persona pueda leer el archivo y defender su diseño sin depender de contexto oral.

## Comandos útiles

```powershell
npm install
npm run build
npm test -- --watch=false --browsers=ChromeHeadless
npm start
```

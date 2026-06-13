# Cliente Flutter de `valencia_airbnb`

Este README sirve para DEFENDER la app, entenderla de punta a punta y ubicar rápido dónde vive cada responsabilidad. Si tienes que explicar el cliente en una exposición oral, la idea es que puedas responder **qué hace**, **cómo fluye la información**, **por qué se diseñó así** y **qué dependencias reales tiene con el backend** sin reconstruir todo el proyecto desde cero.

## Resumen funcional rápido

La app permite este flujo completo:

1. iniciar sesión o registrarse como cliente,
2. buscar alojamientos por ciudad o filtros avanzados,
3. ver resultados en lista o mapa,
4. abrir el detalle de un lugar,
5. confirmar una reserva con cotización visible,
6. revisar el historial real de reservas del cliente.

## Tecnologías usadas en este lado del cliente

| Tecnología | Uso dentro del cliente Flutter |
|---|---|
| **Flutter** | Framework principal para construir la app móvil multiplataforma |
| **Dart** | Lenguaje de implementación de pantallas, providers, servicios, modelos y tests |
| **Material 3** | Base visual del sistema de diseño usado en la interfaz |
| **Provider** | Manejo de estado observable para auth, lugares y reservas |
| **Dio** | Cliente HTTP para consumir la API real y probar endpoints candidatos |
| **flutter_map** | Renderizado del mapa de resultados de alojamientos |
| **latlong2** | Manejo de coordenadas geográficas para marcadores y cámara del mapa |
| **flutter_test** | Pruebas de widgets, providers y contratos de servicios |
| **flutter_lints** | Reglas de análisis estático para mantener consistencia del código |

### Qué significa eso en una defensa

- **Flutter + Dart** construyen toda la UI y la lógica del cliente.
- **Provider** separa pantalla y estado observable.
- **Dio** resuelve la comunicación con la **API real**.
- **flutter_map + latlong2** cubren la vista geográfica de resultados.
- **flutter_test** protege el flujo crítico para no depender solo de prueba manual.

## Qué debes poder decir en 30 segundos

> El cliente Flutter está organizado en capas simples: **screens** muestran UI, **providers** administran estado observable, **services** hablan con la API real y **models** normalizan respuestas inconsistentes del backend. La sesión manda qué datos pueden verse. Desde login hasta reservas, todo el flujo depende del contrato real del servidor: identidad de cliente, endpoints candidatos, wrappers JSON variables, URLs de imágenes relativas y reservas creadas con `cliente_id`, fechas y precios desglosados.

---

## Mapa de arquitectura

## Capas y responsabilidades

| Capa | Qué contiene | Responsabilidad real | Ejemplos |
|---|---|---|---|
| `screens/` | Pantallas | Renderizar UI y disparar acciones | `login_screen.dart`, `home_screen.dart`, `reservations_screen.dart` |
| `providers/` | Estado observable | Exponer loading, errores, resultados y sesión a la UI | `AuthProvider`, `PlacesProvider`, `ReservationsProvider` |
| `services/` | HTTP + contrato backend | Construir payloads reales, probar endpoints candidatos y normalizar respuestas | `AuthService`, `PlacesService`, `ReservationsService`, `ApiClient` |
| `models/` | Modelos de dominio de UI | Traducir JSON variable a objetos consistentes para la app | `UserSession`, `PlaceModel`, `ReservationModel`, `SearchFilters` |
| `widgets/` | Componentes compartidos | Repetir patrones visuales sin duplicación | `PrimaryButton`, `AppTextField`, `MinimalCard`, `PlaceCard` |
| `config/` | Configuración común | Tema, hosts base y helpers de entorno | `app_theme.dart`, `app_environment.dart` |
| `test/` | Pruebas | Proteger contrato real, estado por sesión y UX crítica | `auth_real_contract_test.dart`, `session_scoped_state_test.dart` |

## Árbol compacto

```text
lib/
├── main.dart
├── config/
│   ├── app_environment.dart
│   └── app_theme.dart
├── models/
│   ├── user_session.dart
│   ├── search_filters.dart
│   ├── place_model.dart
│   ├── reservation_quote.dart
│   ├── reservation_model.dart
│   └── registration_result.dart
├── providers/
│   ├── auth_provider.dart
│   ├── places_provider.dart
│   └── reservations_provider.dart
├── services/
│   ├── api_client.dart
│   ├── auth_service.dart
│   ├── places_service.dart
│   └── reservations_service.dart
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   ├── advanced_search_screen.dart
│   ├── search_results_screen.dart
│   ├── map_results_screen.dart
│   ├── place_detail_screen.dart
│   ├── reservation_confirmation_screen.dart
│   └── reservations_screen.dart
└── widgets/
    ├── app_text_field.dart
    ├── primary_button.dart
    ├── minimal_card.dart
    └── place_card.dart
```

## Regla arquitectónica central

La UI **NO** habla directo con `Dio` ni interpreta JSON crudo.

El flujo correcto es:

```text
Widget/Screen -> Provider -> Service -> ApiClient -> Backend
Backend -> ApiClient -> Service -> Model normalizado -> Provider -> UI
```

Eso importa porque en defensa puedes justificar que la app separa:

- presentación,
- estado,
- transporte HTTP,
- contrato de datos.

---

## Flujo end-to-end: desde el arranque hasta el historial

## 1) Arranque

- `main.dart` ejecuta `runApp(const PracticoFinalApp())`.
- `PracticoFinalApp` crea un `MultiProvider` con tres fuentes globales de estado:
  - `AuthProvider`
  - `PlacesProvider`
  - `ReservationsProvider`
- `PlacesProvider` y `ReservationsProvider` se conectan a `AuthProvider` mediante `ChangeNotifierProxyProvider`.

### Qué significa eso

La sesión autenticada es la **fuente de verdad**. Cuando cambia el usuario, los bloques de lugares y reservas reciben esa identidad y deciden si mantienen o limpian su estado.

## 2) Decisión inicial de navegación

`MaterialApp.home` observa `AuthProvider`:

- si `isAuthenticated == true` → abre `HomeScreen`,
- si no → abre `LoginScreen`.

### Idea clave para defensa

La app no decide Home/Login por “si hay token”, sino por “si existe una sesión usable”. En este proyecto, **una identidad de cliente reconocible ya permite considerar la sesión válida**.

## 3) Login o registro

Desde `LoginScreen`:

- el formulario valida email y contraseña,
- llama a `AuthProvider.login(...)`,
- el provider delega a `AuthService.login(...)`,
- el service prueba rutas candidatas, normaliza respuesta y construye `UserSession`.

Si el login funciona, el `Consumer` del arranque reconstruye y la app entra a `HomeScreen`.

Si la persona abre `RegisterScreen`:

- la pantalla junta nombre, email, teléfono y password,
- `AuthProvider.register(...)` delega a `AuthService.register(...)`,
- el service envía el payload con nombres reales del backend,
- el resultado puede ser:
  - **éxito con sesión**,
  - **éxito sin sesión**,
  - **error real**.

## 4) Búsqueda de lugares

Desde `HomeScreen` la persona completa:

- ciudad,
- fecha de llegada,
- fecha de salida,
- huéspedes.

Con eso se construye un `SearchFilters`.

Hay dos caminos:

- **búsqueda simple** → `searchSimple(filters)`
- **búsqueda avanzada** → `AdvancedSearchScreen` + `searchAdvanced(filters)`

`PlacesProvider` guarda:

- resultados,
- loading,
- error,
- últimos filtros usados.

## 5) Resultados y mapa

`SearchResultsScreen` muestra exactamente lo que quedó en `PlacesProvider`.

- Si hay error, lo explica.
- Si no hay resultados, muestra estado vacío.
- Si hay resultados, permite:
  - ver lista,
  - abrir `MapResultsScreen`,
  - entrar al detalle de un lugar.

`MapResultsScreen` reutiliza el mismo conjunto de resultados y solo excluye los lugares sin coordenadas válidas. O sea: **mapa y lista salen de la misma búsqueda; no son dos consultas distintas**.

## 6) Detalle del lugar

`PlaceDetailScreen` recibe un `placePreview` desde resultados y luego pide el detalle real a `PlacesProvider.loadPlaceDetail(placeId)`.

Esto permite dos cosas:

- mostrar algo útil de inmediato,
- reemplazar luego con información más completa si la API responde bien.

Si el detalle falla pero había preview, la pantalla sigue mostrando ese preview. Es una decisión de resiliencia de UX.

## 7) Confirmación de reserva

Desde el detalle, si la pantalla fue abierta con filtros de búsqueda, aparece el CTA **Reservar este lugar**.

`ReservationConfirmationScreen`:

1. recibe `place + filters + user`,
2. calcula una `ReservationQuote`,
3. muestra el desglose económico,
4. llama a `ReservationsProvider.createReservation(...)`,
5. si la API responde bien, reemplaza la ruta por `ReservationsScreen`.

## 8) Historial de reservas

`ReservationsScreen` carga `GET /reservas/cliente/{id}` usando el cliente autenticado.

Maneja estos estados:

- sin sesión,
- sesión sin `id`,
- loading inicial,
- error sin datos previos,
- historial vacío,
- historial con reservas.

Cada tarjeta del historial también sirve como puerta al `PlaceDetailScreen`. En ese caso se arma un preview desde `rawData` de la reserva y se oculta el botón de reservar otra vez, porque la entrada ya no trae filtros reutilizables.

---

## Bloque 1: startup + auth

## Objetivo del bloque

Garantizar que la app siempre sepa si debe mostrar login o permitir acceso al resto del flujo.

## Piezas principales

| Pieza | Rol |
|---|---|
| `main.dart` | Compone providers globales y define la pantalla inicial |
| `AuthProvider` | Fuente de verdad de la sesión observable |
| `AuthService` | Traduce login/registro al contrato HTTP real |
| `UserSession` | Modelo de identidad útil para la app |
| `RegistrationResult` | Distingue registro con sesión vs sin sesión |
| `LoginScreen` | Captura credenciales y muestra errores |
| `RegisterScreen` | Captura alta de cliente y define el siguiente paso de UX |

## Cómo se conectan

```text
LoginScreen/RegisterScreen
  -> AuthProvider
    -> AuthService
      -> ApiClient
        -> backend
      -> UserSession / RegistrationResult
    -> notifyListeners()
  -> PracticoFinalApp decide Home o Login
```

## Decisiones clave

### 1. Sesión basada en identidad, no solo en token

`UserSession.isAuthenticatedSession` devuelve `true` cuando hay identidad usable (`id` o `email`).

**Por qué:** el backend real puede autenticar al cliente sin emitir Bearer token en todos los casos. Si la app exigiera token para entrar, rompería el flujo real.

### 2. Registro y login NO son lo mismo

`RegistrationResult` evita confundir:

- “cuenta creada”
- con “sesión abierta”.

**Por qué:** el backend puede registrar exitosamente pero pedir login manual después.

### 3. La UI no interpreta transporte HTTP

Los mensajes, errores y validación de sesión quedan en provider/service.

**Por qué:** así la pantalla solo reacciona a estado observable y no a JSON crudo.

## Qué podrías decir en defensa

> El bloque de auth está separado en pantalla, provider, servicio y modelo. La pantalla valida y muestra feedback, el provider publica estado, el service conoce el backend real y el modelo decide si la sesión es utilizable. Así evitamos mezclar UI con contrato HTTP.

---

## Bloque 2: search + places

## Objetivo del bloque

Buscar alojamientos, mostrar resultados consistentes y permitir saltar al detalle sin romper la navegación.

## Piezas principales

| Pieza | Rol |
|---|---|
| `HomeScreen` | Formulario base de búsqueda simple |
| `AdvancedSearchScreen` | Amplía filtros sin cambiar fechas ni concepto de búsqueda |
| `SearchResultsScreen` | Muestra resultados, errores o vacío |
| `MapResultsScreen` | Reutiliza resultados y pinta marcadores válidos |
| `PlaceDetailScreen` | Muestra preview inmediato + detalle real si llega |
| `PlacesProvider` | Dueño de resultados, filtros, loading y error |
| `PlacesService` | Traduce búsquedas y detalle a requests reales |
| `SearchFilters` | Modelo de filtros y payloads |
| `PlaceModel` | Normaliza el lugar para toda la UI |

## Flujo de datos del bloque

```text
HomeScreen / AdvancedSearchScreen
  -> SearchFilters
  -> PlacesProvider.searchSimple/searchAdvanced
  -> PlacesService
  -> ApiClient
  -> backend
  -> PlaceModel.fromJson(...)
  -> PlacesProvider.results
  -> SearchResultsScreen / MapResultsScreen / PlaceDetailScreen
```

## Qué hace cada parte

### `SearchFilters`

- calcula noches,
- formatea fechas API (`yyyy-mm-dd`),
- genera payload simple y avanzado,
- permite `copyWith(...)` para extender filtros sin perder contexto.

### `PlacesProvider`

- ejecuta búsqueda simple o avanzada,
- guarda `lastFilters`,
- limpia estado si cambia la sesión,
- evita notificaciones prematuras en la carga del detalle para no romper el lifecycle de Flutter.

### `PlacesService`

- prueba rutas candidatas para búsqueda y detalle,
- acepta respuestas como lista directa o envueltas en `data`, `lugares`, `results`, `items`,
- usa `preferredBaseUrl` para recomponer imágenes relativas con el mismo host que respondió.

### `PlaceModel`

- normaliza alias de campos del backend,
- recompone fotos absolutas,
- tolera relaciones anidadas como `arrendatario`,
- expone labels listos para UI (`priceLabel`, `capacityLabel`, `parkingLabel`).

## Decisiones UX del bloque

| Decisión | Por qué existe |
|---|---|
| Búsquedas rápidas por ciudad | Reducen fricción en demos o defensa |
| Mapa y lista comparten resultados | Evita inconsistencias entre vistas |
| Preview inmediato en detalle | La pantalla no queda vacía mientras llega el request completo |
| Fallbacks de imagen | Mejor explicar ausencia que dejar error silencioso |
| Estados vacíos y de error explícitos | Ayudan a defender qué pasó cuando el backend no devuelve datos útiles |

---

## Bloque 3: reservas

## Objetivo del bloque

Crear una reserva real y luego validar visualmente que quedó persistida en el historial del cliente.

## Piezas principales

| Pieza | Rol |
|---|---|
| `ReservationConfirmationScreen` | Resume importes y ejecuta la confirmación |
| `ReservationsScreen` | Muestra el historial real del cliente |
| `ReservationsProvider` | Maneja loading, errores, lista y última reserva creada |
| `ReservationsService` | Construye payload y normaliza respuestas del backend |
| `ReservationQuote` | Calcula cotización local antes de persistir |
| `ReservationModel` | Traduce la reserva a formato estable para la UI |

## Flujo de datos del bloque

```text
PlaceDetailScreen
  -> ReservationConfirmationScreen
    -> ReservationQuote
    -> ReservationsProvider.createReservation
      -> ReservationsService.createReservation
        -> ApiClient
          -> backend
        -> ReservationModel
      -> inserta la nueva reserva al inicio
    -> pushReplacement(ReservationsScreen)
      -> ReservationsProvider.loadClientReservations
        -> ReservationsService.getClientReservations
        -> ReservationModel[]
```

## Decisiones clave

### 1. Cotización local antes del POST

`ReservationQuote` calcula:

- noches,
- subtotal de noches,
- limpieza,
- servicio 10%,
- total.

**Por qué:** el mismo cálculo alimenta la UI y el payload enviado al backend. Así lo que ve la persona y lo que se persiste siguen la misma lógica.

### 2. La reserva se identifica por `cliente_id`

Aunque exista token, el flujo actual depende de la identidad del cliente activo.

**Por qué:** el contrato real hoy exige `cliente_id` como dato imprescindible del alta.

### 3. El historial se recarga por cliente, no globalmente

La pantalla siempre usa `/reservas/cliente/{id}`.

**Por qué:** el bloque representa “mis reservas”, no “todas las reservas”.

### 4. Estado dependiente de sesión

`ReservationsProvider.syncSession(...)` limpia reservas y feedback cuando cambia el usuario.

**Por qué:** evita mostrar reservas ajenas entre sesiones distintas.

## Estados que la pantalla de reservas sabe defender

- usuario ausente,
- usuario sin `id`,
- primera carga,
- error con reintento,
- historial vacío,
- historial con navegación al detalle.

---

## Bloque 4: widgets compartidos + tests

## Widgets compartidos

| Widget | Qué resuelve |
|---|---|
| `AppTextField` | Unifica configuración base de inputs |
| `PrimaryButton` | Centraliza CTA principal/secundario y loading |
| `MinimalCard` | Mantiene superficie visual consistente |
| `PlaceCard` | Resume un lugar con imagen, chips y precio |

### Idea defendible

Estos widgets no existen “solo para reutilizar”, sino para mantener **consistencia visual y semántica** entre formularios, resultados, errores y acciones principales.

## Qué prueban los tests

| Test | Qué protege |
|---|---|
| `test/widget_test.dart` | Arranque en login, payload simple y etiquetas monetarias |
| `test/services/auth_real_contract_test.dart` | Auth válida por identidad aunque no haya token |
| `test/services/real_api_services_test.dart` | Wrappers reales, payloads, noches derivadas y normalización de reservas/lugares |
| `test/providers/session_scoped_state_test.dart` | Limpieza de estado cuando cambia la sesión |
| `test/screens/map_results_screen_test.dart` | UX del mapa con y sin coordenadas válidas |
| `test/screens/reservations_screen_test.dart` | Historial, preview de imagen, noches y navegación al detalle sin CTA duplicado |

## Lectura correcta de la estrategia de testing

La suite se enfoca en lo que MÁS se puede romper por contrato real:

- cambios de shape JSON,
- sesión sin token,
- wrappers variables,
- navegación entre bloques,
- estado incorrectamente heredado entre usuarios.

Eso es mejor que tener muchas pruebas superficiales de widgets sin valor arquitectónico.

---

## Realidades del contrato backend que condicionan el diseño

Esta es una de las partes MÁS importantes para defender la app.

## 1. API real con múltiples hosts candidatos

`AppEnvironment.baseUrls` define prioridad de hosts:

1. `http://67.205.172.167`
2. `https://airbnbmob2.site`
3. `http://10.0.2.2:8000`
4. `http://127.0.0.1:8000`

`ApiClient` prueba combinaciones de `baseUrl + path` hasta obtener 2xx.

### Por qué importa

El cliente no está atado a un solo host duro. Eso reduce acoplamiento con despliegues docentes o entornos alternos.

## 2. Sesión basada en identidad de cliente

`UserSession` considera válida una sesión cuando hay identidad usable.

### Por qué importa

El contrato actual no siempre garantiza token, pero sí puede devolver cliente identificable. La app se adapta a ESA realidad, no a una suposición ideal.

## 3. Normalización de wrappers JSON

Services y models toleran respuestas como:

- lista directa,
- `data`,
- `lugares`,
- `results`,
- `items`,
- `value`,
- `reserva`,
- `lugar`.

### Por qué importa

La UI no queda acoplada a una única forma de serialización del backend.

## 4. URLs de imágenes relativas

El backend puede devolver rutas como `/storage/...` o `fotos/...`.

`AppEnvironment.resolveAssetUrl(...)` las convierte en URLs absolutas.

### Por qué importa

Sin eso, las tarjetas y detalles mostrarían imágenes rotas aunque el dato exista.

## 5. Payload real de reservas

La creación envía explícitamente:

- `lugar_id`
- `cliente_id`
- `fechaInicio`
- `fechaFin`
- `precioTotal`
- `precioLimpieza`
- `precioNoches`
- `precioServicio`

### Por qué importa

La reserva no envía solo “quiero reservar”. Envía una representación explícita del acuerdo económico y del cliente activo.

## 6. El historial depende de `id`

Si la sesión no trae `id`, `ReservationsScreen` explica que no puede consultar `/reservas/cliente/{id}`.

### Por qué importa

La app distingue un problema visual de un problema contractual. ESO en defensa vale mucho.

---

## Modelos, providers, services y screens: conexión práctica

## Modelos clave

| Modelo | Para qué existe |
|---|---|
| `UserSession` | Representar identidad mínima del cliente autenticado |
| `RegistrationResult` | Separar éxito con sesión de éxito sin sesión |
| `SearchFilters` | Transportar criterios de búsqueda y convertirlos a payloads |
| `PlaceModel` | Ofrecer un lugar estable a la UI pese a variaciones del backend |
| `ReservationQuote` | Mostrar y calcular el resumen económico previo al alta |
| `ReservationModel` | Mostrar reservas con un formato consistente |

## Providers clave

| Provider | Estado que administra |
|---|---|
| `AuthProvider` | usuario, loading, error, success |
| `PlacesProvider` | resultados, loading, error, últimos filtros |
| `ReservationsProvider` | historial, loading, error, última reserva creada |

## Services clave

| Service | Operaciones |
|---|---|
| `ApiClient` | requests GET/POST con fallback de hosts/rutas |
| `AuthService` | login y registro según contrato real |
| `PlacesService` | búsqueda simple, avanzada y detalle |
| `ReservationsService` | alta e historial de reservas |

## Screens clave

| Screen | Propósito |
|---|---|
| `LoginScreen` | entrada a la app |
| `RegisterScreen` | alta de cliente |
| `HomeScreen` | búsqueda inicial y acceso a reservas |
| `AdvancedSearchScreen` | filtros extendidos |
| `SearchResultsScreen` | resultados en lista |
| `MapResultsScreen` | resultados en mapa |
| `PlaceDetailScreen` | ficha ampliada del alojamiento |
| `ReservationConfirmationScreen` | validación final antes del POST |
| `ReservationsScreen` | historial real del cliente |

---

## Decisiones de UX y por qué existen

| Decisión UX | Justificación |
|---|---|
| Mostrar `Home` solo con sesión usable | Evita entrar al flujo principal sin identidad mínima |
| Devolver mensaje a login tras registro exitoso sin sesión | Lleva el feedback al lugar donde ocurre la siguiente acción real |
| Mantener preview mientras falla el detalle | Evita pantalla vacía si el request adicional falla |
| Ocultar CTA de reserva al entrar desde historial | Previene duplicar una reserva sin fechas/filtros confiables |
| `pushReplacement` tras confirmar reserva | Evita volver a una confirmación ya consumida |
| Cargar historial después del primer frame | Evita `notifyListeners()` durante build |
| Limpiar estado de lugares/reservas al cambiar sesión | Evita contaminación entre usuarios |

---

## Guía de defensa oral: preguntas probables y respuestas cortas

## 1. ¿Por qué usaron `provider`?

**Respuesta corta:** porque separa la UI del estado observable sin meter complejidad extra. Las pantallas solo observan loading, errores, resultados y sesión; la lógica de negocio queda fuera del widget tree.

## 2. ¿Por qué no llaman la API directo desde las pantallas?

**Respuesta corta:** porque una pantalla debe renderizar y reaccionar, no conocer rutas, payloads o wrappers JSON. Esa responsabilidad vive en services y models.

## 3. ¿Por qué la sesión puede ser válida sin token?

**Respuesta corta:** por el contrato real del backend. La app necesita una identidad de cliente usable para decidir navegación y reservas. El token queda disponible si existe, pero no es la única señal válida hoy.

## 4. ¿Qué hace `ChangeNotifierProxyProvider` en el arranque?

**Respuesta corta:** sincroniza lugares y reservas con la sesión actual. Si cambia el usuario, esos providers limpian estado dependiente de identidad.

## 5. ¿Cómo manejan respuestas inconsistentes del backend?

**Respuesta corta:** con normalización en services y models. Aceptamos wrappers distintos (`data`, `value`, `reserva`, etc.) y alias de campos para que la UI reciba siempre un contrato estable.

## 6. ¿Por qué calcular la cotización antes de reservar?

**Respuesta corta:** porque el mismo cálculo sirve para mostrar el resumen y para construir el payload económico que persiste la API. Así no hay desalineación entre UI y request.

## 7. ¿Por qué el historial necesita `cliente_id`?

**Respuesta corta:** porque el endpoint real está acotado por cliente: `/reservas/cliente/{id}`. Sin `id`, no es un problema visual: falta un dato contractual.

## 8. ¿Qué pasa si el backend devuelve fotos relativas?

**Respuesta corta:** se reconstruyen con `resolveAssetUrl(...)` usando el host que respondió, para mantener consistencia entre datos y assets.

## 9. ¿Cómo evitan mezclar datos entre usuarios?

**Respuesta corta:** con `syncSession(...)` en `PlacesProvider` y `ReservationsProvider`, usando una huella de sesión basada en identidad (`id + email`).

## 10. ¿Qué prueban realmente los tests?

**Respuesta corta:** prueban lo crítico del contrato real: auth por identidad, normalización de respuestas, estado por sesión y UX de mapa/reservas.

---

## Comandos útiles

Ejecutar desde `apps/cliente_flutter`.

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --debug
```

## Ruta feliz para demo rápida

1. abrir app,
2. iniciar sesión o registrar cliente,
3. buscar por ciudad,
4. abrir resultados,
5. entrar al detalle,
6. confirmar reserva,
7. validar en “Mis reservas”.

## Qué conviene revisar antes de defender

- que el backend elegido esté accesible,
- que login responda con identidad usable,
- que los lugares tengan imágenes o fallbacks visibles,
- que al menos un lugar tenga coordenadas válidas para el mapa,
- que la sesión incluya `id` para poder consultar historial.

---

## Resumen final para cerrar la explicación

Este cliente Flutter no está construido alrededor de pantallas aisladas, sino alrededor de un flujo real:

- **auth** define identidad,
- **búsqueda** produce lugares normalizados,
- **detalle** amplía información sin bloquear la UX,
- **reserva** traduce intención a payload real,
- **historial** valida que el alta quedó persistida.

Si en la defensa te preguntan por arquitectura, la respuesta fuerte es esta: **la app separa UI, estado, contrato HTTP y normalización de datos para sobrevivir al backend real sin ensuciar las pantallas con lógica de transporte**.

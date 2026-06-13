# `valencia_airbnb` - repositorio de entrega

Este repositorio está pensado para que **una sola clonación** baje todo lo relacionado al práctico. La idea es que cualquier compañero pueda hacer `git clone` una vez y encontrar la estructura completa del proyecto sin tener que cambiar de repositorio.

## Qué contiene este repo

```text
practico_final/
├── apps/
│   ├── cliente_flutter/
│   └── arrendatario_ionic/
└── docs/
```

## Estado actual de cada lado

| Carpeta | Tecnología | Estado actual | Qué contiene |
|---|---|---|---|
| `apps/cliente_flutter/` | Flutter + Dart | Implementado | Cliente completo: auth, búsqueda, detalle, reservas, historial, widgets y tests |
| `apps/arrendatario_ionic/` | Ionic | Reservado / placeholder | README explicando que este directorio queda preparado para la app del arrendatario |

## Importante

Hoy, cuando alguien clone este repo, **sí va a bajar ambos directorios**, pero eso NO significa que ambos estén igual de implementados.

- `cliente_flutter` ya tiene código real.
- `arrendatario_ionic` por ahora solo deja la frontera del segundo proyecto y su README explicativo.

Si el compañero necesita también una implementación real del arrendatario, ese código debe agregarse dentro de `apps/arrendatario_ionic/` antes de la entrega final.

---

## Cómo organizar las ramas para que el compañero clone todo junto

## Recomendación

Usar una rama **integradora** llamada `main`.

### ¿Por qué?

Porque la rama actual se llama `feat/cliente-flutter-entrega`, y ese nombre ya quedó demasiado específico. Si ahí terminas metiendo también el estado global del repo, el nombre empieza a mentir.

La forma más ordenada es:

1. terminar y commitear el trabajo actual,
2. crear `main` desde ese estado,
3. subir `main`,
4. compartir esa rama como base de clonación.

Así tu compañero hace una sola clonación y baja todo lo que esté integrado en el repo.

---

## Orden exacto de comandos recomendado

> Ejecuta esto desde la raíz del repo: `D:\movilII\valencia\practico_final`

### 1) Revisar el estado actual

```powershell
git status
```

### 2) Agregar todos los cambios que SÍ quieres entregar

```powershell
git add .
```

### 3) Crear el commit final de integración actual

```powershell
git commit -m "feat: integra entrega de cliente flutter y estructura general del repo"
```

### 4) Crear la rama `main` desde tu estado ya listo

```powershell
git switch -c main
```

### 5) Subir `main` al remoto

```powershell
git push -u origin main
```

### 6) Opcional pero MUY recomendado: dejar `main` como rama principal en GitHub

Eso se hace desde la interfaz web del repositorio:

- Settings
- Branches
- Default branch
- elegir `main`

### 7) Opcional: etiquetar la entrega

```powershell
git tag v1-entrega
git push origin v1-entrega
```

---

## Cómo lo clonaría tu compañero

## Opción simple

```powershell
git clone <URL_DEL_REPO>
cd practico_final
git switch main
```

## Opción directa a `main`

```powershell
git clone -b main <URL_DEL_REPO>
```

Con eso le quedará descargado el repo completo con:

- `apps/cliente_flutter/`
- `apps/arrendatario_ionic/`
- `docs/`

---

## Cómo seguir trabajando después sin desordenar la entrega

Una vez que exista `main`, lo sano es esto:

### Para nuevas mejoras

```powershell
git switch main
git pull
git switch -c feat/nombre-de-la-mejora
```

Trabajas en esa rama nueva y luego decides si volver a integrarla en `main`.

### Qué evitar

Evita usar una rama específica del cliente como rama final de TODO el repo si ahí también vivirán decisiones del arrendatario, docs y entrega general.

---

## Cómo ejecutar el lado cliente Flutter

```powershell
cd apps/cliente_flutter
flutter pub get
flutter analyze
flutter test
flutter run
```

## Qué incluye ese lado

- login cliente
- registro cliente
- búsqueda simple
- búsqueda avanzada
- resultados en lista
- resultados en mapa
- detalle de lugar
- confirmación de reserva
- historial real de reservas

Para una explicación completa del cliente, revisar:

- `apps/cliente_flutter/README.md`

---

## Cómo ejecutar el lado arrendatario

## Estado actual

Por ahora `apps/arrendatario_ionic/` **no tiene una app Ionic implementada**. Solo deja la estructura reservada y un README explicativo.

Por tanto, hoy NO hay comandos reales de ejecución para ese lado dentro de este repo.

Si luego se implementa la app Ionic, la idea correcta es que ese directorio contenga al menos:

- `package.json`
- `ionic.config.json`
- `src/`
- instrucciones propias en su `README.md`

---

## Qué deberías decirle al compañero al pasárselo

Puedes mandarle algo como esto:

> Clona la rama `main`, porque ahí dejé el estado integrado del repo. Dentro de `apps/` vas a encontrar el cliente Flutter ya implementado y el espacio reservado del arrendatario Ionic. Para correr el cliente entra a `apps/cliente_flutter`. El README raíz te explica la estructura general y el README del cliente explica arquitectura, flujo y defensa.

---

## Resumen corto

- Sí, conviene crear una rama **`main`**.
- Sí, tu compañero puede clonar una sola vez y bajar ambos lados del repo.
- No, hoy ambos lados NO están implementados al mismo nivel.
- `cliente_flutter` está listo.
- `arrendatario_ionic` todavía está reservado, no desarrollado.

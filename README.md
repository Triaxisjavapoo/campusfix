# CampusFix

Aplicación Flutter Web para la gestión de incidencias y solicitudes de servicio de la Universidad de Costa Rica, Sede del Sur. Forma parte del Proyecto Integrador 1 de IF0009, II Ciclo 2026.

[Abrir CampusFix](https://campusfix-ae32e.web.app/?v=2026.10.21.4)

## Funciones principales

- Registro e inicio de sesión por correo electrónico y contraseña.
- Reportes con descripción, ubicación, categoría y prioridad.
- Asignación de responsables y seguimiento del ciclo de atención.
- Fotografías privadas, comentarios, historial de cambios e indicadores del campus.
- Administración de categorías, usuarios y roles.
- Interfaz con identidad visual UCR y temas claro y oscuro.

Los roles disponibles son reportante, técnico y administrador. Cada cuenta accede a las operaciones y los reportes correspondientes a su rol.

## Servicios

| Servicio | Función |
| --- | --- |
| Authentication | Registro, acceso, cierre de sesión y recuperación de contraseña. |
| Cloud Firestore | Perfiles, incidencias, categorías, comentarios, historial y actualización en tiempo real. |
| Supabase Storage | Fotografías privadas en producción, con autorización mediante una Edge Function y las reglas de Firestore. |
| Cloud Storage | Fotografías en el entorno de emuladores de Firebase. |
| Hosting | Publicación de la aplicación web. |

El proyecto de producción es `campusfix-ae32e`, con Firestore `(default)` en `us-central1`. Authentication, Firestore y Hosting están activos en el plan Spark.

En producción las fotografías se almacenan en Supabase, con el plan gratuito y sin activar Blaze. Firebase conserva las cuentas, los reportes y la publicación web. El entorno local mantiene Cloud Storage mediante emuladores. Esta alternativa cambia el proveedor de fotografías en producción respecto al requisito de Cloud Storage del enunciado. Configuración y límites en [Fotografías con Supabase](docs/SUPABASE.md).

## Ejecutar localmente

Requisitos: Flutter estable con soporte web, Node.js **24.12 o superior** y Java/JDK **21 o superior**.

Desde la carpeta del proyecto:

```powershell
flutter pub get
npm ci
flutter build web --release --dart-define-from-file=firebase.emulators.json --output build/emulator-web
npm run demo
```

Abrir [CampusFix local](http://127.0.0.1:5000). El comando inicia los emuladores de Authentication, Firestore, Storage y Hosting, y carga las cuentas y los datos de demostración. `Ctrl+C` detiene el entorno.

Las cuentas locales, los puertos y el modo de desarrollo están en [Entorno local](docs/ENTORNO_LOCAL.md). Las carpetas `build/` y `node_modules/` se generan localmente y no forman parte del repositorio. Las versiones de dependencias se registran en `pubspec.lock` y `package-lock.json`.

## Compilar y publicar

`firebase.config.json` contiene las opciones públicas de la aplicación web de Firebase. Las credenciales administrativas se gestionan fuera del código.

```powershell
flutter build web --release --dart-define-from-file=firebase.config.json
npx firebase deploy --project campusfix-ae32e --only firestore:rules,firestore:indexes,hosting
```

`firebase.json` publica el contenido de `build/web`. Los cambios subidos a GitHub se publican en el sitio después de compilar y desplegar en Firebase.

## Documentación

| Documento | Contenido |
| --- | --- |
| [Inicio rápido](EMPEZAR_AQUI.md) | Acceso y ejecución local. |
| [Requisitos](docs/REQUISITOS.md) | Historias HU-01 a HU-20 y alcance funcional. |
| [Arquitectura](docs/ARQUITECTURA.md) | Capas, modelo de datos, estados y permisos. |
| [Manual de usuario](docs/MANUAL_USUARIO.md) | Operación del reportante, técnico y administrador. |
| [Fotografías con Supabase](docs/SUPABASE.md) | Almacenamiento privado, autorización, límites y despliegue. |
| [Firebase y publicación](docs/FIREBASE.md) | Configuración de servicios, reglas y despliegue. |
| [Entorno local](docs/ENTORNO_LOCAL.md) | Emuladores, cuentas de demostración y desarrollo. |
| [Paquetes](docs/PAQUETES.md) | Dependencias y su función en la aplicación. |
| [Identidad UCR](docs/IDENTIDAD_UCR.md) | Colores, recursos gráficos y fuentes institucionales. |

# Entorno local

CampusFix utiliza Firebase Emulator Suite para ejecutar Authentication, Firestore, Cloud Storage y Hosting en la computadora. El proyecto local es `demo-campusfix`, independiente del proyecto de producción `campusfix-ae32e`.

## Requisitos

- Flutter estable con soporte web.
- Node.js **24.12 o superior**.
- Java/JDK **21 o superior**.
- Conexión a Internet para descargar las dependencias y los emuladores la primera vez.

La configuración y los puertos se definen en `firebase.demo.json` y `firebase.emulators.json`. La referencia de Firebase está en [Emulator Suite](https://firebase.google.com/docs/emulator-suite/install_and_configure).

## Compilar e iniciar

Desde la raíz del proyecto:

```powershell
flutter pub get
npm ci
flutter build web --release --dart-define-from-file=firebase.emulators.json --output build/emulator-web
npm run demo
```

Abrir [CampusFix local](http://127.0.0.1:5000). El comando inicia los servicios locales y carga las cuentas, categorías e incidencias de demostración. `Ctrl+C` detiene el entorno.

La compilación se guarda en `build/emulator-web` y se genera de nuevo cuando cambia el código. Si esa carpeta ya está disponible, basta con instalar las dependencias de Node.js y ejecutar `npm run demo`. En Windows también se puede usar `iniciar-demo.cmd`.

El script `scripts/run-firebase-local.mjs` mantiene su caché de herramientas en `.firebase/local-tooling` y selecciona un JDK instalado en Windows. La variable `JAVA_HOME` permite indicar otra instalación de Java.

## Servicios y puertos

| Servicio | Dirección |
| --- | --- |
| Authentication | `127.0.0.1:9099` |
| Firestore | `127.0.0.1:8080` |
| Cloud Storage | `127.0.0.1:9199` |
| Hosting | `127.0.0.1:5000` |
| Consola de emuladores | [127.0.0.1:4000](http://127.0.0.1:4000) |

Los puertos deben estar disponibles antes de iniciar los servicios. La consola local permite consultar las cuentas, documentos y fotografías de la sesión.

## Cuentas de demostración

Todas las cuentas de la tabla utilizan la contraseña local **`CampusFix2026!`**.

| Rol | Correo local |
| --- | --- |
| Reportante | `reporter@campusfix.local` |
| Técnico | `tecnico@campusfix.local` |
| Administrador | `admin@campusfix.local` |

La semilla `scripts/seed-emulators.mjs` define las cuentas, cinco categorías y los casos de ejemplo. Los datos pertenecen a los emuladores y no se envían al sitio publicado. Se reinician en cada arranque, salvo que se configure exportación e importación.

Las fotografías admiten JPEG, PNG o WebP de hasta **5 MiB** por archivo. La carga se realiza desde **Fotografías y evidencias** en el detalle de una incidencia. El entorno local permite utilizar Cloud Storage sin vincular facturación.

## Desarrollo con recarga de Flutter

En una terminal:

```powershell
npm run emulators
```

Con los servicios iniciados, cargar los datos en otra terminal:

```powershell
npm run seed:emulators
```

Iniciar el cliente Flutter:

```powershell
flutter run -d chrome --web-port 7357 --dart-define-from-file=firebase.emulators.json
```

El modo local utiliza `USE_EMULATORS=true`. La configuración de producción mantiene esa opción en `false`.

## Operación por roles

El reportante registra una incidencia y consulta su seguimiento. El administrador clasifica el reporte y lo asigna a un técnico. El técnico inicia la atención, registra avances y describe la solución. El administrador realiza el cierre. Los cambios aparecen en las sesiones con acceso al caso y se conservan en su historial.

El procedimiento de cada rol está en [Manual de usuario](MANUAL_USUARIO.md). La configuración del sitio publicado y la habilitación de Storage se describen en [Firebase y publicación](FIREBASE.md).

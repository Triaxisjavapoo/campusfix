# CampusFix

Aplicación Flutter Web para reportar, asignar y atender incidencias del campus. Corresponde al Proyecto Integrador 1 de IF0009, Universidad de Costa Rica, Sede del Sur, II Ciclo 2026.

Utiliza Firebase Authentication para las cuentas, Cloud Firestore para los datos y el seguimiento en tiempo real, Cloud Storage para fotografías privadas y Firebase Hosting para publicar el cliente web. Incluye tres roles: reportante, técnico y administrador.

**Sitio publicado:** [Abrir CampusFix](https://campusfix-ae32e.web.app). Authentication por correo/contraseña está habilitado; el proyecto `campusfix-ae32e` tiene Firestore `(default)` en `us-central1`, cinco categorías y una cuenta administradora inicial. Su acceso se entrega en un archivo separado, fuera del código y del paquete compartible.

**Fotografías:** se conserva Cloud Storage y se demuestra gratuitamente con los emuladores reales de Firebase. Por decisión del usuario, las fotografías de producción quedan pendientes para evitar activar facturación. El sitio muestra esa limitación y no ofrece el botón de adjuntar en producción. No se reemplaza Storage con imágenes guardadas en Firestore.

## Empezar

Para usar el sitio publicado, abra el enlace anterior. Para ejecutar la demostración local con las tres cuentas y fotografías, necesita Node.js **24.12 o superior** y Java/JDK **21 o superior**. Desde esta carpeta:

```powershell
npm ci
npm run demo
```

Abra [CampusFix local](http://127.0.0.1:5000). El comando inicia Authentication, Firestore, Storage y Hosting locales, y carga las cuentas y datos de ejemplo automáticamente. La compilación de demostración está en `build/emulator-web`. Las cuentas de los tres roles están en [Pruebas](docs/PRUEBAS.md); `Ctrl+C` detiene los emuladores.

Para modificar el código o repetir las pruebas Flutter, instale además Flutter estable con soporte web. Las dependencias concretas quedan registradas en `pubspec.lock` y `package-lock.json`.

```powershell
flutter pub get
npm ci
dart analyze lib test
flutter test
```

Para probar Firebase localmente, siga [la guía de emuladores y pruebas](docs/PRUEBAS.md). Para conectar su proyecto y publicar, siga [la guía completa de Firebase](docs/FIREBASE.md). La publicación requiere la configuración real de una aplicación web del proyecto y acceso autorizado a sus servicios.

## Documentación

| Documento | Contenido |
| --- | --- |
| [Requisitos y trazabilidad](docs/REQUISITOS.md) | Historias HU-01 a HU-20, criterios y correspondencia con la implementación. |
| [Arquitectura](docs/ARQUITECTURA.md) | Capas, modelo Firestore, estados, autorización y evidencia privada. |
| [Manual de usuario](docs/MANUAL_USUARIO.md) | Operación del reportante, técnico y administrador. |
| [Firebase y publicación](docs/FIREBASE.md) | Authentication, Firestore, Storage, reglas, primer administrador y Hosting. |
| [Paquetes](docs/PAQUETES.md) | Qué paquete se usa, para qué sirve y cómo interviene en el sistema. |
| [Pruebas](docs/PRUEBAS.md) | Comandos reproducibles, cuentas locales y comprobaciones funcionales. |

## Compilar para producción

`firebase.config.json` contiene las opciones públicas de la aplicación Firebase de esta entrega; no contiene credenciales de administrador. Si cambia de proyecto, sustituya sus valores. Para volver a publicar:

```powershell
flutter build web --release --dart-define-from-file=firebase.config.json
npx firebase deploy --project campusfix-ae32e --only firestore:rules,firestore:indexes,hosting
```

`firebase.json` publica `build/web`. Las reglas e índices de Firestore deben desplegarse junto con el cliente. Las reglas de Storage quedan preparadas para desplegarlas cuando se habilite ese servicio; las fotos de producción permanecen pendientes. Consulte [Firebase](docs/FIREBASE.md) para el procedimiento completo.

## Estado de entrega

Verificado el 21 de octubre de 2026: análisis Dart sin problemas, **12/12** pruebas Flutter, **20/20** pruebas de reglas y **8/8** de integración Firebase; compilaciones de producción y emuladores terminadas correctamente. Hosting se desplegó y devolvió HTTP 200. El acceso administrativo, el panel y las cinco categorías se comprobaron en el navegador de producción. Los límites de esa evidencia y el procedimiento reproducible están en [Pruebas](docs/PRUEBAS.md). Las fotografías de producción permanecen pendientes.

# Paquetes utilizados y funcionamiento

Las dependencias directas se declaran en `pubspec.yaml` y `package.json`. Las versiones exactas que se resuelven para esta entrega aparecen en `pubspec.lock` y `package-lock.json`; use `flutter pub get` y `npm ci` para reproducirlas. Las dependencias transitivas las descargan los gestores a partir de esos archivos de bloqueo.

Se conserva `firebase_storage` como integración de fotografías. El usuario decidió demostrarla gratis en emuladores y dejar pendiente su habilitación en producción; no se añadió un almacenamiento alternativo de imágenes en Firestore.

## Versiones de la entrega

Valores comprobados en los archivos de bloqueo:

| Paquete | Versión |
| --- | --- |
| `firebase_core` | 4.15.0 |
| `firebase_auth` | 6.7.0 |
| `cloud_firestore` | 6.10.0 |
| `firebase_storage` | 13.6.0 |
| `provider` | 6.1.5+1 |
| `intl` | 0.20.3 |
| `file_picker` | 10.3.10 |
| `uuid` | 4.6.0 |
| `flutter_lints` | 6.0.0 |
| `firebase-admin` | 14.5.0 |
| `firebase-tools` | 15.34.1 |
| `@firebase/rules-unit-testing` | 6.0.0 |
| `firebase` (JavaScript para pruebas) | 13.1.0 |

`flutter`, `flutter_localizations` y `flutter_test` provienen del SDK de Flutter. Node.js debe ser 24.12 o superior para las herramientas fijadas en esta entrega.

## Aplicación Flutter Web

| Paquete | Función en CampusFix | Cómo funciona |
| --- | --- | --- |
| `flutter` | Interfaz web, navegación, formularios y diseño responsivo. | Los widgets construyen las pantallas y actualizan su presentación cuando cambia el estado. Material aporta los controles visuales. |
| `flutter_localizations` | Localización de controles de Flutter. | Proporciona textos y convenciones de interfaz en español para componentes compatibles. |
| `firebase_core` | Inicialización de Firebase. | Crea la instancia de Firebase con los identificadores recibidos durante la compilación; los otros plugins usan esa instancia. |
| `firebase_auth` | Registro, acceso y cierre de sesión. | Firebase Authentication valida el correo/contraseña y entrega la identidad autenticada. Los cambios de sesión permiten mostrar el panel correspondiente. |
| `cloud_firestore` | Persistencia y seguimiento en tiempo real. | Lee documentos, escucha `snapshots()` y ejecuta escrituras y transacciones. Las reglas del servidor autorizan cada operación. |
| `firebase_storage` | Subir y visualizar fotografías. | Envía los bytes al bucket y lee evidencia privada mediante el SDK autenticado; las reglas controlan el acceso al objeto. |
| `provider` | Distribuir estado y servicios a la interfaz. | Inyecta las dependencias y permite que los widgets observen los cambios publicados por los controladores de estado. |
| `intl` | Presentación de fechas y valores. | Formatea los datos para que sean legibles y coherentes con la interfaz en español. |
| `file_picker` | Seleccionar fotografías del equipo. | Abre el selector del navegador y entrega nombre y bytes; la aplicación comprueba tamaño/formato antes de subir. |
| `uuid` | Identificadores de eventos y archivos. | Genera IDs para asociar cambios atómicos y evitar que dos imágenes usen el mismo nombre de objeto. |

Los SDK de Firebase para Flutter se conectan con los servicios del proyecto configurado. La elección de Firestore proporciona persistencia documental y suscripciones en tiempo real, como describe la [referencia oficial](https://firebase.google.com/docs/flutter/setup#available-plugins).

## Desarrollo y pruebas Flutter

| Paquete | Función |
| --- | --- |
| `flutter_test` | Ejecutar pruebas de modelos, políticas, indicadores y widgets mediante `flutter test`. |
| `flutter_lints` | Detectar problemas de estilo y prácticas de Dart con `flutter analyze`. No sustituye las pruebas funcionales. |

## Herramientas Node.js

| Paquete | Uso en el proyecto | Cómo funciona |
| --- | --- | --- |
| `firebase-admin` | Semilla local y promoción del primer administrador. | Es un SDK privilegiado para scripts confiables. En producción usa ADC; nunca se ejecuta como parte del cliente web. |
| `firebase-tools` | Emuladores y despliegue. | Aporta la CLI `firebase`, lee `firebase.json` y publica reglas, índices y los archivos de Hosting. |
| `@firebase/rules-unit-testing` | Probar las reglas de seguridad. | Crea contextos autenticados con identidades de prueba y permite comprobar operaciones aceptadas o rechazadas en los emuladores. |
| `firebase` | Cliente JavaScript utilizado en pruebas. | Ejecuta lecturas, escrituras y subidas como un cliente sujeto a reglas, para comprobar permisos reales de cada rol. |

`node:test` es el ejecutor de pruebas integrado de Node.js; no es un paquete adicional instalado. Los paquetes Node se usan para desarrollo, pruebas y administración, y no se publican dentro del cliente Flutter compilado.

## Actualización en tiempo real

No se agregó `web_socket_channel`, Socket.IO ni un servidor WebSocket propio. El SDK de Firestore mantiene los listeners de `snapshots()` y entrega los cambios; el estado los distribuye a la interfaz con Provider. Esto cubre la sincronización multiusuario del proyecto sin introducir otro servidor, protocolo de autorización o canal de persistencia. [Funcionamiento oficial de los listeners](https://firebase.google.com/docs/firestore/query-data/listen).

No se usa Firebase Realtime Database: el servicio persistente escogido es **Cloud Firestore**, como solicita el enunciado. Authentication gestiona la identidad; las reglas de Firestore y Storage establecen qué puede hacer esa identidad.

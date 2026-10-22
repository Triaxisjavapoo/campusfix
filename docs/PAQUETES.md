# Paquetes utilizados y funcionamiento

Las dependencias directas se declaran en `pubspec.yaml` y `package.json`. Las versiones exactas aparecen en `pubspec.lock` y `package-lock.json`; `flutter pub get` y `npm ci` instalan las dependencias correspondientes. Los gestores resuelven las dependencias transitivas a partir de esos archivos de bloqueo.

`firebase_storage` conserva la integración con Cloud Storage en emuladores. En producción, `http` comunica Flutter con la Edge Function de Supabase; esa función utiliza `@supabase/supabase-js` para guardar y leer archivos privados, y `jose` para verificar las sesiones de Firebase. Firestore guarda referencias y metadatos, sin incluir los bytes de las imágenes.

## Versiones

Versiones registradas en los archivos de bloqueo:

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
| `http` | 1.6.0 |
| `@supabase/supabase-js` (Edge Function) | 2.118.0 |
| `jose` (Edge Function) | 6.1.3 |
| `flutter_lints` | 6.0.0 |
| `firebase-admin` | 14.5.0 |
| `firebase-tools` | 15.34.1 |
| `firebase` (SDK JavaScript) | 13.1.0 |

`flutter` y `flutter_localizations` provienen del SDK de Flutter. Las herramientas Node.js requieren la versión 24.12 o superior.

## Aplicación Flutter Web

| Paquete | Función en CampusFix | Cómo funciona |
| --- | --- | --- |
| `flutter` | Interfaz web, navegación, formularios y diseño responsivo. | Los widgets construyen las pantallas y actualizan su presentación cuando cambia el estado. Material aporta los controles visuales. |
| `flutter_localizations` | Localización de controles de Flutter. | Proporciona textos y convenciones de interfaz en español para componentes compatibles. |
| `firebase_core` | Inicialización de Firebase. | Crea la instancia de Firebase con los identificadores recibidos durante la compilación; los otros plugins usan esa instancia. |
| `firebase_auth` | Registro, acceso y cierre de sesión. | Firebase Authentication valida el correo/contraseña y entrega la identidad autenticada. Los cambios de sesión permiten mostrar el panel correspondiente. |
| `cloud_firestore` | Persistencia y seguimiento en tiempo real. | Lee documentos, escucha `snapshots()` y ejecuta escrituras y transacciones. Las reglas del servidor autorizan cada operación. |
| `firebase_storage` | Fotografías con Cloud Storage en el entorno local. | Envía y obtiene bytes autenticados del emulador; las reglas de Storage controlan el acceso. |
| `http` | Fotografías de producción. | Envía la imagen o solicita sus bytes a la Edge Function por HTTPS con el token Firebase de la sesión actual. |
| `provider` | Distribuir estado y servicios a la interfaz. | Inyecta las dependencias y permite que los widgets observen los cambios publicados por los controladores de estado. |
| `intl` | Presentación de fechas y valores. | Formatea los datos para que sean legibles y coherentes con la interfaz en español. |
| `file_picker` | Seleccionar fotografías del equipo. | Abre el selector del navegador y entrega nombre y bytes; la aplicación comprueba tamaño/formato antes de subir. |
| `uuid` | Identificadores de eventos y archivos. | Genera IDs para asociar cambios atómicos y evitar que dos imágenes usen el mismo nombre de objeto. |

Los SDK de Firebase para Flutter se conectan con los servicios del proyecto configurado. La elección de Firestore proporciona persistencia documental y suscripciones en tiempo real, como describe la [referencia oficial](https://firebase.google.com/docs/flutter/setup#available-plugins).

## Servicio de fotografías en Supabase

| Paquete | Función | Cómo funciona |
| --- | --- | --- |
| `@supabase/supabase-js` | Acceso al bucket privado desde el servidor. | La Edge Function usa la credencial administrativa de su entorno para guardar, leer y compensar cargas incompletas. Esa credencial no llega al navegador. |
| `jose` | Verificar la identidad de Firebase. | Comprueba firma RS256, emisor, destinatario, vencimiento e identidad del token mediante las claves públicas de Google. |

Las versiones se fijan en `supabase/functions/incident-evidence/deno.json` y su archivo `deno.lock`. No se necesita `supabase_flutter`: la aplicación utiliza el servicio HTTP protegido para mantener las decisiones de acceso junto a los datos de Firestore.

## Desarrollo Flutter

| Paquete | Función |
| --- | --- |
| `flutter_lints` | Detectar problemas de estilo y prácticas de Dart con `flutter analyze`. |

## Herramientas Node.js

| Paquete | Uso en el proyecto | Cómo funciona |
| --- | --- | --- |
| `firebase-admin` | Semilla local y promoción del primer administrador. | Es un SDK privilegiado para scripts confiables. En producción usa ADC; nunca se ejecuta como parte del cliente web. |
| `firebase-tools` | Emuladores y despliegue. | Aporta la CLI `firebase`, lee `firebase.json` y publica reglas, índices y los archivos de Hosting. |
| `firebase` | SDK cliente JavaScript para el entorno de emuladores. | Permite conectar clientes con Authentication, Firestore y Storage locales mediante sus respectivas interfaces. Las operaciones del cliente están sujetas a las reglas de seguridad. |

Los paquetes Node se utilizan en el entorno de desarrollo y administración; no se publican dentro del cliente Flutter compilado.

## Actualización en tiempo real

El SDK de Firestore mantiene los listeners de `snapshots()` y entrega los cambios; el estado los distribuye a la interfaz con Provider. Esta integración proporciona la sincronización multiusuario sin un servidor WebSocket adicional. [Funcionamiento oficial de los listeners](https://firebase.google.com/docs/firestore/query-data/listen).

No se usa Firebase Realtime Database: el servicio persistente escogido es **Cloud Firestore**, como solicita el enunciado. Authentication gestiona la identidad; las reglas de Firestore establecen el acceso a cada reporte. La Edge Function aplica ese acceso a Supabase Storage; los emuladores utilizan las reglas de Cloud Storage.

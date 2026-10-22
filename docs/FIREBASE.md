# Configuración de Firebase y publicación

Guía para esta implementación de CampusFix. Ejecute los comandos desde la raíz del proyecto. `SU_PROJECT_ID` representa el ID real del proyecto; no es el nombre visible ni el identificador de la aplicación web.

## Configuración de esta entrega

| Recurso | Estado confirmado durante la preparación |
| --- | --- |
| Proyecto de producción | `campusfix-ae32e`. |
| Aplicación web registrada | `1:550971519365:web:eec2c84880e516433454ec`. |
| Cloud Firestore | Base `(default)` creada en `us-central1`. |
| Índices Firestore | Seis índices comprobados en estado `READY` en producción. |
| Authentication | Correo electrónico/contraseña habilitado y comprobado mediante API e inicio de sesión. |
| Cuenta administradora y catálogo | Cuenta inicial creada, perfil con rol administrador y cinco categorías de producción. Credenciales entregadas por separado; no se incluyen en el repositorio ni en el ZIP. |
| Cloud Storage | Integración y fotografías verificadas gratis con los emuladores. Producción queda pendiente por decisión del usuario. |
| Hosting | [CampusFix actualizado](https://campusfix-ae32e.web.app/?v=2026.10.21.2), versión **2026.10.21.2**, despliegue correcto y entradas verificadas con HTTP 200 y `no-store`. |
| Pruebas | Resultados reales y límites de verificación en [Pruebas](PRUEBAS.md). |

No se activa Blaze para esta entrega ni se sustituye Storage por fotografías en Firestore. La guía distingue el despliegue actual de la habilitación futura de Storage.

## 1. Herramientas y proyecto

Instale Flutter estable con soporte web y Node.js 24.12 o superior, compatible con las versiones fijadas en `package-lock.json`. Ejecute:

```powershell
flutter doctor
flutter pub get
npm ci
npx firebase login
npx firebase projects:list
```

Compruebe que el proyecto seleccionado pertenece a la cuenta correcta. Use `--project SU_PROJECT_ID` en los comandos de despliegue para evitar depender del proyecto activo de otra carpeta.

## 2. Registrar la aplicación web

La aplicación web de `campusfix-ae32e` ya está registrada y su configuración pública se entrega en `firebase.config.json`; no necesita registrar otra para usar este proyecto. Si lo adapta a un proyecto diferente, en [Firebase Console](https://console.firebase.google.com/) entre a Configuración del proyecto, registre una aplicación web y copie `apiKey`, `appId`, `messagingSenderId`, `projectId`, `authDomain` y el bucket cuando esté habilitado.

Esta aplicación lee esas opciones mediante constantes de compilación. El ejemplo siguiente sirve para configurar otro proyecto; no sobrescriba la configuración ya entregada con estos valores de ejemplo:

```json
{
  "FIREBASE_API_KEY": "COPIAR_API_KEY_WEB",
  "FIREBASE_APP_ID": "COPIAR_APP_ID_WEB",
  "FIREBASE_MESSAGING_SENDER_ID": "COPIAR_MESSAGING_SENDER_ID",
  "FIREBASE_PROJECT_ID": "SU_PROJECT_ID",
  "FIREBASE_AUTH_DOMAIN": "COPIAR_AUTH_DOMAIN",
  "FIREBASE_STORAGE_BUCKET": "COPIAR_STORAGE_BUCKET",
  "USE_EMULATORS": false,
  "STORAGE_ENABLED": false
}
```

Conserve el nombre exacto del bucket; puede terminar en `.firebasestorage.app` o `.appspot.com`. No agregue `gs://` en `FIREBASE_STORAGE_BUCKET`. Estas opciones identifican una aplicación cliente; la protección de datos depende de Authentication y las reglas. Un JSON de cuenta de servicio, una clave privada o un token administrativo nunca debe incluirse en este archivo, en `web/` ni en `build/web`. Firebase explica la naturaleza de estas opciones en [configuración del proyecto](https://firebase.google.com/docs/projects/learn-more#config-files-objects).

La configuración estándar mediante FlutterFire CLI es otra forma válida de obtener opciones, pero este proyecto ya usa `--dart-define-from-file`; no es necesario sustituir su inicialización. [Referencia oficial de Flutter y Firebase](https://firebase.google.com/docs/flutter/setup).

## 3. Authentication

En Authentication, habilite el proveedor **Correo electrónico/contraseña** y guarde. La aplicación utiliza registro, inicio de sesión y cierre de sesión de Firebase Authentication. No necesita habilitar inicio de sesión mediante vínculo por correo. [Guía oficial de autenticación con contraseña](https://firebase.google.com/docs/auth/flutter/password-auth).

En el proyecto actual, el proveedor ya está habilitado y puede revisarse en [Authentication de campusfix-ae32e](https://console.firebase.google.com/project/campusfix-ae32e/authentication/providers). El inicio básico de Authentication desde Firebase Console no exige actualizar a Identity Platform ni activar Blaze; no use la inicialización de GCIP como sustituto de ese paso. [Configuración oficial desde la consola](https://firebase.google.com/codelabs/firebase-terraform#6).

Revise los dominios autorizados de Authentication. Incluya el dominio de Hosting utilizado y su dominio propio si lo configura. Para desarrollo local, compruebe `localhost` explícitamente.

Al registrarse, una persona obtiene únicamente un perfil `reporter`. El cliente no puede autorregistrarse como administrador o técnico. Las contraseñas se gestionan en Authentication; no se guardan en documentos Firestore.

## 4. Cloud Firestore

La base `(default)` del proyecto `campusfix-ae32e` ya está creada en `us-central1`; no necesita crear otra. Si adapta la entrega a otro proyecto, cree **Cloud Firestore Standard, modo nativo**, con ID `(default)`, seleccione la ubicación antes de crearla e inicie con acceso restringido. El código y las reglas usan esa base.

Los documentos se organizan así:

```text
users/{uid}
categories/{categoryId}
incidents/{incidentId}
  events/{eventId}
  comments/{commentId}
  evidence/{evidenceId}
```

`firestore.rules` controla lectura, creación, roles, transición de estados y auditoría. `firestore.indexes.json` declara los índices para los listados. Despliéguelos desde los archivos entregados:

```powershell
npx firebase deploy --project SU_PROJECT_ID --only firestore:rules,firestore:indexes
```

Espere a que los índices terminen de construirse en la consola antes de la comprobación operativa. Las consultas deben respetar las restricciones de acceso: las reglas no convierten una consulta amplia en un filtro de seguridad. [Referencia de condiciones y consultas seguras](https://firebase.google.com/docs/firestore/security/rules-conditions#rules_are_not_filters).

## 5. Cloud Storage: fotografías privadas

**Alcance acordado:** las fotografías se prueban y demuestran gratis en el emulador de Cloud Storage con `demo-campusfix`. La integración y sus reglas permanecen en el código. Storage de producción queda pendiente; no hay un reemplazo mediante Firestore.

Para habilitar fotografías en producción en una etapa posterior, active Storage y cree el bucket desde Firebase Console. A fecha de consulta, **21 de octubre de 2026**, Firebase exige el plan **Blaze** para utilizar Cloud Storage, incluidos buckets existentes. Puede haber cuotas sin costo, pero Blaze requiere una cuenta de facturación vinculada. [Requisito oficial de facturación de Storage](https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024).

Las evidencias se almacenan bajo `incidents/{incidentId}/{uid}/{uuid}`. Se admiten imágenes JPEG, PNG o WebP de hasta **5 MiB por archivo**. La ruta se asocia al incidente en Firestore; la visualización solicita bytes con el SDK autenticado. La implementación no publica enlaces permanentes de descarga.

Cuando habilite Storage de producción, complete `FIREBASE_STORAGE_BUCKET` con su nombre real y publique las reglas incluidas:

```powershell
npx firebase deploy --project SU_PROJECT_ID --only storage
```

Si la CLI solicita habilitar la integración de reglas de Storage con Firestore, complete ese paso para permitir que las reglas comprueben rol y acceso al incidente. No cambie las reglas a acceso público para solucionar un error. En un error `storage/unauthorized`, compruebe perfil activo, pertenencia al incidente, reglas desplegadas y bucket configurado. [Inicio oficial de Storage para Flutter](https://firebase.google.com/docs/storage/flutter/start).

## 6. Crear el primer administrador

El primer administrador se establece desde un entorno confiable mediante `scripts/bootstrap-admin.mjs`. Primero cree la cuenta de esa persona usando el registro normal de CampusFix; identifíquela por su correo exacto. El script no necesita recibir su contraseña.

La sesión de `firebase login` permite usar la CLI, pero no sustituye automáticamente las credenciales que necesita `firebase-admin`. El script utiliza **Application Default Credentials (ADC)** y requiere una identidad con permisos de lectura de Authentication y escritura en Firestore. Firebase documenta esta inicialización en [Admin SDK](https://firebase.google.com/docs/admin/setup).

Puede ejecutar el script en un entorno de Google con una cuenta de servicio apropiada. Para desarrollo local, una opción sin clave persistente es crear ADC mediante suplantación de una cuenta de servicio autorizada. Deben estar habilitada la API Service Account Credentials y concedido el permiso de suplantación correspondiente:

```powershell
gcloud auth application-default login --impersonate-service-account=CUENTA_SERVICIO@SU_PROJECT_ID.iam.gserviceaccount.com
npm run bootstrap:admin -- --project SU_PROJECT_ID --email CORREO_ADMINISTRADOR
```

Consulte [ADC mediante suplantación](https://docs.cloud.google.com/docs/authentication/use-service-account-impersonation#adc). Una alternativa es que ADC apunte mediante `GOOGLE_APPLICATION_CREDENTIALS` a una clave de cuenta de servicio almacenada fuera de la carpeta del proyecto y protegida por el operador. El inicio ADC de usuario con `gcloud auth application-default login` sin opciones tiene limitaciones específicas para Firebase Authentication; no se debe asumir que basta. [Limitación oficial](https://firebase.google.com/docs/admin/setup#test-with-gcloud-end-user-credentials).

Una vez promovida la cuenta, cierre e inicie su sesión de CampusFix y compruebe que aparecen **Categorías** y **Usuarios y roles** en Administración. En **Usuarios y roles** puede administrar las siguientes cuentas registradas. El rol de la aplicación no concede acceso IAM al proyecto de Google Cloud. La cuenta inicial de esta entrega ya fue creada; no necesita repetir el bootstrap para usarla.

## 7. Configurar categorías y personal

Ingrese como administrador, revise las cinco categorías iniciales de producción y ajuste el catálogo desde **Categorías**. Promueva las cuentas registradas del personal a técnico desde **Usuarios y roles**. La semilla de emuladores contiene datos de demostración y no se utiliza para poblar producción.

## 8. Compilar y publicar Hosting

Ejecute primero las verificaciones locales descritas en [Pruebas](PRUEBAS.md). Confirme que la configuración de producción tiene `USE_EMULATORS` en `false` y apunta al proyecto correcto.

```powershell
dart analyze lib test
flutter test
npm run test:cache
flutter build web --release --dart-define-from-file=firebase.config.json
npx firebase deploy --project campusfix-ae32e --only firestore:rules,firestore:indexes,hosting
```

`firebase.json` usa `build/web` como carpeta pública y envía las rutas de la aplicación a `index.html`. La CLI muestra la dirección de Hosting al terminar; registre esa dirección real como evidencia de HU-20. La consola permite consultar las versiones desplegadas. [Despliegue oficial de Hosting](https://firebase.google.com/docs/hosting/quickstart#deploy).

### Distribución de la versión y conservación de sesiones

La entrega actual es **2026.10.21.2**. Use [su enlace versionado](https://campusfix-ae32e.web.app/?v=2026.10.21.2); el documento muestra el sello **v2026.10.21.2** abajo a la derecha y la interfaz Flutter muestra **v1.0.2** en el pie. El bootstrap y `main.dart.js` se solicitan también con la versión correspondiente.

Para la siguiente publicación, incremente **la misma versión** en `web/index.html` (meta, sello visible y URL del script) y en `web/flutter_bootstrap.js` antes de compilar. Mantenga coherente la versión esperada por `tests/cache-update.test.mjs`, ejecute `npm run test:cache` y genere las dos compilaciones. Comparta entonces el enlace con el identificador nuevo: reutilizar una URL con la versión fija anterior dejaría un marcador de entrega desactualizado.

La configuración de Hosting envía `Cache-Control: no-cache, no-store, must-revalidate` para `/`, `/index.html`, los JavaScript y `/version.json`. La verificación actual de esas entradas devolvió HTTP 200 con los encabezados previstos. En el despliegue anterior, `/`, `flutter_bootstrap.js` y `main.dart.js` conservaban `max-age=3600`, y el documento que seguía abierto no contenía el marcador nuevo: ese cliente almacenado podía ocultar la corrección ya publicada.

`web/flutter_bootstrap.js` no registra otro service worker. Migra únicamente el worker Flutter cuyo alcance y ruta corresponden a CampusFix y las entradas de caché identificadas como recursos de esta aplicación. No borra Authentication, IndexedDB, localStorage ni los datos de otras aplicaciones. La comprobación de producción se hizo en la misma sesión de la cuenta de prueba `test4`: la nueva versión abrió sin el aviso anterior y mantuvo el acceso. Los permisos de Firestore y Storage no se debilitaron.

`npm run test:cache` ejecuta siete comprobaciones Node de esta estrategia; no requiere emuladores. En esta corrección pasaron **7/7**, además de **25/25** pruebas Flutter y el análisis sin problemas. Las pruebas de reglas **20/20** y de integración Firebase **8/8** corresponden a la entrega anterior; no se afirma una nueva ejecución para este cambio. El detalle está en [Pruebas](PRUEBAS.md).

Para recibir la actualización, abra el enlace versionado y compruebe los sellos. No necesita borrar datos del navegador ni cerrar la sesión. Si el arranque indica que un worker antiguo aún controla la pestaña, cierre esa pestaña y abra otra vez el enlace versionado.

El comando actual omite Storage porque el usuario dejó ese servicio pendiente en producción. Para habilitar fotografías posteriormente:

1. Vincule Blaze, habilite Storage y copie el nombre real del bucket en `FIREBASE_STORAGE_BUCKET`.
2. Cambie `STORAGE_ENABLED` a `true` en `firebase.config.json` y mantenga `USE_EMULATORS` en `false`.
3. Aplique `storage.cors.json` al bucket. El archivo autoriza la lectura desde los dos dominios de Hosting de CampusFix; agregue el dominio propio si usa uno.
4. Despliegue las reglas, vuelva a compilar y publique el cliente:

```powershell
gcloud storage buckets update gs://NOMBRE_REAL_DEL_BUCKET --cors-file=storage.cors.json
npx firebase deploy --project campusfix-ae32e --only storage
flutter build web --release --dart-define-from-file=firebase.config.json
npx firebase deploy --project campusfix-ae32e --only hosting
```

La configuración CORS permite al navegador leer los bytes desde el origen indicado; no elimina la autenticación ni las reglas. [Referencia oficial de configuración CORS](https://docs.cloud.google.com/storage/docs/using-cors). No marque las fotografías de producción como operativas antes de completar las comprobaciones de acceso.

## 9. Comprobación después de publicar

Abra [CampusFix actualizado](https://campusfix-ae32e.web.app/?v=2026.10.21.2) en dos sesiones de navegador distintas y confirme los sellos de versión. Registre un reportante y cree un incidente. Con el administrador, clasifíquelo y asígnelo a un técnico. Con ese técnico, inicie la atención, agregue un avance y resuelva con descripción. Finalmente cierre el caso como administrador. Compruebe que la primera sesión recibe los cambios, que el historial identifica autor y fecha y que una cuenta ajena no puede leer el incidente. Este recorrido es una instrucción de aceptación; sus pasos efectivamente ejecutados se distinguen en [Pruebas](PRUEBAS.md).

La carga y lectura privada de imágenes se verifican ahora en los emuladores, siguiendo [Pruebas](PRUEBAS.md). Repita esas comprobaciones en producción únicamente después de habilitar Storage, configurar su bucket y desplegar sus reglas.

La compilación, los emuladores y el despliegue son verificaciones diferentes. Mantenga en [Pruebas](PRUEBAS.md) los resultados efectivamente observados y la URL real; no marque como publicado un proyecto que todavía requiere habilitar servicios o permisos.

# Configuración de Firebase y publicación

CampusFix utiliza Firebase Authentication, Cloud Firestore y Firebase Hosting. Cloud Storage está disponible en el entorno local. Las fotografías de producción utilizan Supabase Storage privado, descrito en [Fotografías con Supabase](SUPABASE.md). Ejecute los comandos de esta guía desde la raíz del proyecto. `SU_PROJECT_ID` representa el ID del proyecto, distinto de su nombre visible y del identificador de la aplicación web.

## Configuración actual

| Recurso | Configuración |
| --- | --- |
| Proyecto de producción | `campusfix-ae32e`, en el plan Spark. |
| Aplicación web | `1:550971519365:web:eec2c84880e516433454ec`. |
| Cloud Firestore | Base `(default)` en `us-central1`, con seis índices definidos en `firestore.indexes.json`. |
| Authentication | Proveedor Correo electrónico/contraseña habilitado. |
| Administración | Cuenta inicial con rol administrador y catálogo de cinco categorías. Las credenciales se mantienen fuera del repositorio. |
| Fotografías | Supabase Storage en producción; Cloud Storage en emuladores. `STORAGE_ENABLED=true`, `EVIDENCE_PROVIDER=supabase`. |
| Firebase Hosting | [CampusFix 2026.10.21.4](https://campusfix-ae32e.web.app/?v=2026.10.21.4). |

El entorno de producción mantiene Authentication, Firestore y Hosting en Spark. Las imágenes se guardan en Supabase; Firestore conserva los metadatos. El entorno local conserva Cloud Storage. La [guía del entorno local](ENTORNO_LOCAL.md) describe el uso de fotografías sin activar Blaze.

## 1. Herramientas y proyecto

Instale Flutter estable con soporte web y Node.js 24.12 o superior, compatible con las versiones fijadas en `package-lock.json`.

```powershell
flutter doctor
flutter pub get
npm ci
npx firebase login
npx firebase projects:list
```

Compruebe que el proyecto pertenece a la cuenta correcta. Use `--project SU_PROJECT_ID` en los comandos de despliegue para seleccionar el destino explícitamente.

## 2. Aplicación web y configuración pública

La aplicación web de `campusfix-ae32e` está registrada y sus opciones públicas se encuentran en `firebase.config.json`. Para utilizar otro proyecto, registre una aplicación web en [Firebase Console](https://console.firebase.google.com/) y copie `apiKey`, `appId`, `messagingSenderId`, `projectId`, `authDomain` y el nombre del bucket cuando esté habilitado.

La aplicación lee esas opciones mediante constantes de compilación. El siguiente ejemplo corresponde a la configuración de otro proyecto:

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

Conserve el nombre exacto del bucket, que puede terminar en `.firebasestorage.app` o `.appspot.com`, sin el prefijo `gs://`. Estas opciones identifican una aplicación cliente; la protección de datos depende de Authentication y las reglas. Los JSON de cuentas de servicio, claves privadas y tokens administrativos deben permanecer fuera de estos archivos, de `web/` y de `build/web`. Consulte la [configuración de proyectos de Firebase](https://firebase.google.com/docs/projects/learn-more#config-files-objects).

FlutterFire CLI también permite obtener opciones de Firebase. CampusFix utiliza `--dart-define-from-file` para su inicialización. [Configuración oficial de Flutter y Firebase](https://firebase.google.com/docs/flutter/setup).

## 3. Authentication

El proveedor **Correo electrónico/contraseña** permite registrar cuentas, iniciar sesión, recuperar acceso y cerrar sesión. No requiere el inicio de sesión mediante vínculo por correo. [Autenticación con contraseña](https://firebase.google.com/docs/auth/flutter/password-auth).

El proveedor se administra desde [Authentication de campusfix-ae32e](https://console.firebase.google.com/project/campusfix-ae32e/authentication/providers). Su habilitación básica desde Firebase Console no requiere actualizar a Identity Platform ni activar Blaze. [Configuración desde la consola](https://firebase.google.com/codelabs/firebase-terraform#6).

Revise los dominios autorizados e incluya los dominios de Hosting utilizados, el dominio propio si corresponde y `localhost` para desarrollo local.

El registro crea únicamente un perfil `reporter`. El cliente no permite autorregistrarse como administrador o técnico. Authentication gestiona las contraseñas; Firestore no las almacena.

## 4. Cloud Firestore

La aplicación utiliza la base `(default)` de `campusfix-ae32e`, ubicada en `us-central1`. Para otro proyecto, cree **Cloud Firestore Standard, modo nativo**, con ID `(default)`, seleccione la ubicación antes de crearla y mantenga acceso restringido.

```text
users/{uid}
categories/{categoryId}
incidents/{incidentId}
  events/{eventId}
  comments/{commentId}
  evidence/{evidenceId}
```

`firestore.rules` controla lecturas, creación, roles, transiciones y auditoría. `firestore.indexes.json` declara los índices de los listados.

```powershell
npx firebase deploy --project SU_PROJECT_ID --only firestore:rules,firestore:indexes
```

Los índices deben finalizar su construcción antes de utilizar las consultas correspondientes. Las consultas deben respetar el alcance de acceso; las reglas no transforman una consulta amplia en un filtro de seguridad. [Condiciones y consultas seguras](https://firebase.google.com/docs/firestore/security/rules-conditions#rules_are_not_filters).

## 5. Proveedores de fotografías

La producción utiliza Supabase con la configuración de [Fotografías con Supabase](SUPABASE.md). La Edge Function debe estar publicada y las reglas de Firestore deben admitir el campo opcional `storageProvider`. No se requiere Firebase Cloud Functions ni Blaze para esta integración.

### Cloud Storage en emuladores y habilitación opcional

El emulador de Cloud Storage utiliza el proyecto local `demo-campusfix` y permite cargar y consultar fotografías sin facturación. El proveedor Cloud Storage permanece deshabilitado en producción; Supabase cubre esa función.

A fecha del **21 de octubre de 2026**, Firebase exige el plan **Blaze** para utilizar Cloud Storage, incluidos buckets existentes. Aunque existen cuotas sin costo, Blaze requiere una cuenta de facturación vinculada. [Requisito de facturación de Storage](https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024).

Las evidencias se almacenan bajo `incidents/{incidentId}/{uid}/{uuid}`. Se admiten imágenes JPEG, PNG o WebP de hasta **5 MiB por archivo**. Firestore conserva los metadatos y la ruta; la visualización solicita los bytes mediante el SDK autenticado. La aplicación no publica enlaces permanentes de descarga.

Para cambiar el proveedor de producción a Cloud Storage:

1. Vincule Blaze y cree el bucket desde Firebase Console.
2. Copie su nombre real en `FIREBASE_STORAGE_BUCKET`.
3. Establezca `STORAGE_ENABLED=true`, `EVIDENCE_PROVIDER=firebase` y `USE_EMULATORS=false`. Las evidencias ya guardadas en Supabase mantienen su proveedor y requieren conservar el servicio de lectura correspondiente.
4. Aplique `storage.cors.json` al bucket y publique las reglas.
5. Compile y publique el cliente actualizado.

```powershell
gcloud storage buckets update gs://NOMBRE_REAL_DEL_BUCKET --cors-file=storage.cors.json
npx firebase deploy --project campusfix-ae32e --only storage
flutter build web --release --dart-define-from-file=firebase.config.json
npx firebase deploy --project campusfix-ae32e --only hosting
```

`storage.cors.json` autoriza las lecturas desde los dos dominios de Hosting de CampusFix. Agregue el dominio propio si utiliza uno. CORS permite la lectura desde el origen indicado y conserva los requisitos de autenticación y reglas. [Configuración CORS](https://docs.cloud.google.com/storage/docs/using-cors).

Si la CLI solicita habilitar la integración de reglas de Storage con Firestore, complete ese paso para consultar el rol y el acceso al incidente. Ante un error `storage/unauthorized`, revise el perfil activo, el acceso al incidente, las reglas y el bucket configurado. Mantenga las fotografías privadas. [Storage para Flutter](https://firebase.google.com/docs/storage/flutter/start).

## 6. Administración inicial y roles

`scripts/bootstrap-admin.mjs` establece el primer administrador desde un entorno confiable. Para un proyecto nuevo, cree primero la cuenta mediante el registro normal de CampusFix y utilice su correo exacto en el script. El procedimiento no requiere la contraseña de esa persona. En `campusfix-ae32e` ya existe la cuenta administradora inicial.

La sesión de `firebase login` permite usar la CLI, mientras que `firebase-admin` requiere **Application Default Credentials (ADC)** con permisos para leer Authentication y escribir en Firestore. [Inicialización del Admin SDK](https://firebase.google.com/docs/admin/setup).

El script puede ejecutarse en un entorno de Google con una cuenta de servicio apropiada. Para desarrollo local, ADC admite la suplantación de una cuenta de servicio autorizada, con la API Service Account Credentials habilitada y el permiso correspondiente:

```powershell
gcloud auth application-default login --impersonate-service-account=CUENTA_SERVICIO@SU_PROJECT_ID.iam.gserviceaccount.com
npm run bootstrap:admin -- --project SU_PROJECT_ID --email CORREO_ADMINISTRADOR
```

Consulte [ADC mediante suplantación](https://docs.cloud.google.com/docs/authentication/use-service-account-impersonation#adc). También puede usar `GOOGLE_APPLICATION_CREDENTIALS` con una clave de cuenta de servicio protegida y almacenada fuera del proyecto. Las credenciales ADC de usuario sin suplantación tienen limitaciones específicas con Firebase Authentication; consulte el [Admin SDK](https://firebase.google.com/docs/admin/setup).

Después de promover una cuenta, cierre e inicie su sesión para acceder a **Categorías** y **Usuarios y roles**. Un administrador existente puede gestionar los roles de las demás cuentas registradas. El rol de CampusFix no concede permisos IAM en Google Cloud.

## 7. Categorías y personal

**Categorías** permite administrar el catálogo de producción. **Usuarios y roles** permite promover las cuentas registradas del personal a técnico. La semilla local contiene cuentas y datos de demostración; no se utiliza para poblar producción.

## 8. Compilación y publicación

Confirme que `firebase.config.json` apunta al proyecto de producción y que `USE_EMULATORS` está desactivado.

```powershell
flutter build web --release --dart-define-from-file=firebase.config.json
npx firebase deploy --project campusfix-ae32e --only firestore:rules,firestore:indexes,hosting
```

`firebase.json` publica `build/web` y redirige las rutas de la aplicación a `index.html`. El comando omite Cloud Storage porque las fotos de producción utilizan Supabase. La función de Supabase se publica por separado como indica su guía. La CLI muestra la dirección de Hosting y Firebase Console conserva las versiones desplegadas. [Publicación de Hosting](https://firebase.google.com/docs/hosting/quickstart#deploy).

### Versiones y conservación de sesiones

La versión **2026.10.21.4** se identifica mediante el sello **v2026.10.21.4** abajo a la derecha y el pie de la interfaz **v1.0.4**. El acceso es [CampusFix](https://campusfix-ae32e.web.app/?v=2026.10.21.4). Los recursos visuales se describen en [Identidad UCR](IDENTIDAD_UCR.md).

En cada publicación, actualice el mismo identificador en `web/index.html` —meta, sello visible y URL del script— y `web/flutter_bootstrap.js`, junto con la versión visible del pie de la interfaz. Compile los entornos de producción y local con sus respectivas configuraciones. El enlace de publicación debe usar el identificador correspondiente.

Hosting aplica `Cache-Control: no-cache, no-store, must-revalidate` a `/`, `/index.html`, los JavaScript y `/version.json`. El bootstrap añade la versión a la dirección del código principal para que el navegador cargue la publicación correspondiente.

`web/flutter_bootstrap.js` no registra un service worker nuevo. Retira únicamente el worker Flutter con alcance y ruta de CampusFix y las entradas de caché identificadas como recursos de esta aplicación. Conserva Authentication, IndexedDB, localStorage y los datos de otras aplicaciones.

Para recibir una publicación, abra el enlace versionado y revise sus sellos. La sesión puede permanecer abierta. Si el arranque informa que un worker antiguo controla la pestaña, cierre esa pestaña y vuelva a abrir el enlace.

## 9. Operación por roles

Un reportante registra una incidencia. El administrador la clasifica y asigna a un técnico; este inicia la atención, registra avances y documenta la solución. El administrador cierra el caso resuelto. El historial conserva autor y fecha, y los cambios se reflejan mediante las suscripciones de Firestore.

Cada rol conserva su alcance: el reportante accede a sus incidencias, el técnico a sus asignaciones y el administrador a la supervisión general. La carga y consulta de fotografías utilizan [Supabase en producción](SUPABASE.md) y Cloud Storage en el [entorno local](ENTORNO_LOCAL.md), con acceso restringido a los participantes del reporte.

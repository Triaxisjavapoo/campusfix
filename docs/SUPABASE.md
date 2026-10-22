# Fotografías privadas con Supabase

CampusFix conserva Firebase Authentication, Firestore y Hosting en el plan Spark. Supabase almacena las fotografías de producción y ejecuta el servicio que autoriza su carga y lectura. Las personas utilizan su misma cuenta de CampusFix; no se registran de nuevo en Supabase.

## Configuración actual

| Recurso | Valor |
| --- | --- |
| Proyecto | `CampusFix`, referencia `kpwpiqaxhcnkjtdgadue`. |
| Región | `us-east-1`. |
| Plan | Free. |
| API | `https://kpwpiqaxhcnkjtdgadue.supabase.co`. |
| Bucket | `campusfix-evidence`, privado. |
| Edge Function | `incident-evidence`. |
| Formatos y tamaño | JPEG, PNG y WebP; máximo 5 MiB por imagen. |

## Recorrido de una fotografía

1. La persona abre un reporte y pulsa **Fotografías y evidencias → Adjuntar**.
2. Flutter envía los bytes por HTTPS con el token Firebase de su sesión.
3. La función verifica la firma RS256, el proyecto emisor, el destinatario, el vencimiento y la identidad del token usando las claves públicas de Google.
4. La función consulta el perfil y el reporte en Firestore con el token de la persona. Las reglas vigentes verifican que la cuenta esté activa y sea reportante propietario, técnico asignado o administrador.
5. La función valida tamaño, MIME y firma de archivo. Guarda el objeto y escribe los metadatos en `incidents/{id}/evidence/{uuid}` con fecha del servidor y `storageProvider=supabase`.
6. Firestore notifica el cambio a los participantes. Al abrir una miniatura, la función vuelve a comprobar permisos y entrega los bytes con `Cache-Control: no-store, private`.

No se publican URLs permanentes de descarga. El bucket no concede acceso directo a clientes anónimos ni autenticados de Supabase. La política restrictiva `campusfix_evidence_server_only` conserva esa restricción aunque se agreguen políticas más amplias. Solo el servicio autorizado opera con la credencial administrativa de su entorno.

## Identidad y autorización

Esta implementación verifica los tokens Firebase dentro de la Edge Function; no utiliza el inicio de sesión de Supabase ni necesita agregar la claim `role=authenticated` a las cuentas Firebase. `verify_jwt=false` desactiva únicamente la comprobación del gateway basada en sesiones Supabase: la comprobación criptográfica de Firebase permanece obligatoria en el código. No debe sustituirse por una simple decodificación del token.

Las reglas de Firestore son la fuente de autorización. Cambiar un técnico o desactivar un perfil impide nuevas solicitudes de imágenes con los permisos anteriores. Una imagen ya descargada puede seguir visible en la memoria de la sesión que la abrió.

La función no necesita claves privadas de Firebase. `SUPABASE_URL` y `SUPABASE_SERVICE_ROLE_KEY` son variables del entorno de ejecución de Supabase. La segunda no debe copiarse al cliente, a Git, a `firebase.config.json` ni a archivos publicados.

## Eliminación de reportes

La misma función acepta `DELETE` con `incidentId` y `version`. Exige un perfil Firebase activo con rol `admin`. Una versión desactualizada devuelve conflicto antes de borrar. La operación marca el reporte para eliminación, bloquea nuevas escrituras, elimina sus objetos privados y subcolecciones y retira el padre al final. El navegador muestra confirmación irreversible y permite reintentar si hubo una interrupción. Las credenciales administrativas de Supabase permanecen en el servidor.

## Configuración del cliente

`firebase.config.json` incluye las opciones públicas:

```json
{
  "STORAGE_ENABLED": true,
  "EVIDENCE_PROVIDER": "supabase",
  "SUPABASE_URL": "https://kpwpiqaxhcnkjtdgadue.supabase.co"
}
```

El cliente utiliza `http`; no necesita una clave administrativa ni una sesión Supabase. En compilaciones con `USE_EMULATORS=true`, `EvidenceConfig` selecciona Firebase Storage independientemente de la opción de producción.

## Publicar el servicio

Los archivos de la función están en `supabase/functions/incident-evidence/`; la migración del bucket y la política está en `supabase/migrations/`. Con Supabase CLI y una sesión autorizada:

```powershell
supabase login
supabase link --project-ref kpwpiqaxhcnkjtdgadue
supabase db push
supabase functions deploy incident-evidence --no-verify-jwt
flutter build web --release --dart-define-from-file=firebase.config.json
npx firebase deploy --project campusfix-ae32e --only firestore:rules,hosting
```

La migración inicial ya se aplicó. Compruebe el historial remoto antes de intentar repetirla. Para otro proyecto Firebase, configure `FIREBASE_PROJECT_ID` en los secretos de la función y actualice la configuración pública del cliente. Los dos dominios Firebase de ese proyecto quedan permitidos; dominios adicionales se declaran separados por comas en `ALLOWED_ORIGINS`. Los orígenes locales con puerto se admiten para desarrollo.

Si se publica mediante otra herramienta, envíe `index.ts`, `handler.ts`, `deno.json` y `deno.lock`, conservando el mapa de importación y la verificación Firebase del código.

## Operación y límites

El plan Free incluye 1 GB de archivos, 5 GB de transferencia saliente y 5 GB de transferencia servida desde caché. Las funciones también tienen una cuota. Los proyectos gratuitos pueden pausarse después de una semana sin actividad; revise el panel si las fotos dejan de responder. Consulte los límites vigentes en [Precios de Supabase](https://supabase.com/pricing).

Si falla la escritura de metadatos con rechazo confirmado, la función elimina el objeto incompleto. Si la respuesta se pierde y no puede confirmarse si la escritura terminó, conserva el objeto para evitar borrar una evidencia válida. Antes de retirar un objeto huérfano desde el panel de Storage, compruebe su referencia en Firestore. Un error de conexión durante la carga requiere revisar el detalle antes de volver a adjuntar el archivo.

Las copias de seguridad deben incluir tanto los objetos de Storage como sus referencias de Firestore. Revise espacio y transferencia desde el panel de Supabase; el plan gratuito no equivale a almacenamiento ilimitado ni a disponibilidad garantizada.

## Relación con el enunciado

Supabase permite usar fotografías en el sitio sin activar Blaze. Esta decisión cambia el proveedor de imágenes en producción respecto al requisito literal de Firebase Cloud Storage. La integración de Cloud Storage se conserva en el entorno local con emuladores, documentado en [Entorno local](ENTORNO_LOCAL.md).

## Referencias

- [Buckets privados y acceso a archivos](https://supabase.com/docs/guides/storage/buckets/fundamentals).
- [Verificación de tokens Firebase](https://firebase.google.com/docs/auth/admin/verify-id-tokens).
- [Firestore REST y autenticación](https://firebase.google.com/docs/firestore/use-rest-api).
- [Autorización de Edge Functions](https://supabase.com/docs/guides/functions/auth-headers).

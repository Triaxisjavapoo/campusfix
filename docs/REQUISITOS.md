# Requisitos y trazabilidad

Fuente funcional: `Proyecto_1_UCR.pdf`, IF0009 Desarrollo de Software IV, Proyecto Integrador 1 CampusFix, UCR Sede del Sur, II Ciclo 2026, páginas 1 a 7. Esta matriz relaciona los requisitos con los componentes de la aplicación.

## Alcance

Gestionar el ciclo completo de una incidencia de servicio del campus: reporte, clasificación, asignación, atención, seguimiento, resolución y cierre. La aplicación tiene interfaz Flutter Web, Firebase Authentication, Cloud Firestore y Firebase Hosting. La integración de Cloud Storage se conserva en los emuladores; las fotografías de producción utilizan Supabase Storage como alternativa sin Blaze.

Las fotografías de producción se guardan en Supabase mediante un servicio privado que verifica la sesión Firebase y el acceso al caso. El uso de otro proveedor en producción es una desviación del requisito literal de Cloud Storage del enunciado; la demostración local conserva ese servicio con emuladores. La configuración de producción utiliza el plan gratuito Spark; los datos de las imágenes no se almacenan en Firestore. [CampusFix está publicado](https://campusfix-ae32e.web.app) en el proyecto `campusfix-ae32e`, con Firestore `(default)` en `us-central1` y Authentication por correo/contraseña habilitado.

| Actor | Necesidad |
| --- | --- |
| Usuario reportante | Crear y consultar sus reportes, aportar información y evidencia, conocer su evolución. |
| Técnico o encargado | Atender los casos asignados y documentar avances y solución. |
| Administrador | Clasificar, asignar, cerrar, administrar catálogos y perfiles y supervisar indicadores. |

## Historias de usuario

Los nombres de métodos y archivos se refieren al código del repositorio. La columna de comprobación describe las acciones asociadas a cada criterio.

Las pantallas están en `lib/ui/app.dart`; los controladores `AuthState`, `IncidentState`, `DashboardState` y `ThemeState`, en `lib/state/`. El servicio `lib/data/firebase_repository.dart` realiza las operaciones persistentes de la matriz. `firestore.rules` y `storage.rules` vuelven a validar la autorización y los datos en el servidor.

| HU | Resultado requerido | Implementación y protección | Comprobación |
| --- | --- | --- | --- |
| HU-01 Registro e inicio | Las credenciales válidas crean una sesión y abren el panel del rol. | Authentication y perfil persistido; `lib/data/firebase_repository.dart`, `users/{uid}`. | Registrar un reportante, salir e ingresar otra vez; comparar paneles de tres roles. |
| HU-02 Perfil | Actualizar datos básicos y conservarlos en el siguiente acceso. | Actualización de perfil del repositorio; reglas de `users` impiden cambiar el propio rol. | Cambiar nombre, cerrar sesión y volver a ingresar; intentar promoverse por SDK. |
| HU-03 Roles | El administrador controla las operaciones disponibles. | `UserRole` en `lib/domain/models.dart`, `IncidentPolicy`, reglas de Firestore y Storage. | Administrar una cuenta y comprobar que un reportante no obtiene funciones administrativas. |
| HU-04 Cerrar sesión | Eliminar la sesión y volver al acceso. | Firebase Auth y estado de sesión. | Salir y comprobar que la interfaz operativa desaparece. |
| HU-05 Crear incidencia | Generar identificación, persistir el reporte y dejarlo REPORTADA. | Creación atómica de documento y evento en el repositorio; reglas de `incidents`. | Crear un caso; comprobar ID, autor, fechas, estado y evento inicial. |
| HU-06 Evidencia | Almacenar fotos asociadas al caso. | `supabase_evidence_client.dart`, Edge Function y bucket privado en producción; `firebase_storage` y `storage.rules` en emuladores. | Subir JPEG/PNG/WebP autorizado y rechazar archivos mayores a 5 MiB, formatos inválidos y acceso ajeno. |
| HU-07 Mis incidencias | El reportante ve solamente sus reportes. | Consulta por `reporterId` y autorización sobre el incidente. | Crear casos con dos reportantes; comprobar aislamiento de listados y lecturas. |
| HU-08 Detalle e historial | Mostrar estado, responsables, comentarios e historial cronológico. | Modelos y subcolecciones `events`, `comments`, `evidence`; streams del repositorio. | Abrir un caso con cambios y comparar autor, fecha y orden de sus actuaciones. |
| HU-09 Clasificación | Registrar categoría y prioridad antes de asignar. | Política administrativa y actualización validada de categoría/prioridad. | Clasificar y comprobar que el caso y su evento reflejan ambos campos. |
| HU-10 Asignación | Vincular técnico y cambiar a ASIGNADA. | Asignación del repositorio, validación del técnico activo y reglas. | Asignar y verificar vínculo, estado e historial; rechazar técnico inválido. |
| HU-11 Iniciar atención | Solo el técnico asignado pasa de ASIGNADA a EN_ATENCION. | `IncidentPolicy` y reglas de transición. | Permitir al técnico responsable y denegar a otro técnico, reportante y administrador. |
| HU-12 Seguimiento | Cada avance guarda autor, fecha y texto, con evidencia opcional. | Comentarios y fotografías dentro del caso; acceso por participante. | Agregar un avance y una foto; observarlos desde otra sesión autorizada. |
| HU-13 Resolver | Exigir descripción de solución y dejar RESUELTA. | Validación de transición y texto en cliente y reglas. | Rechazar solución vacía y aceptar solución válida del técnico asignado. |
| HU-14 Cerrar | El administrador cierra únicamente un caso RESUELTA. | Política y reglas de transición `RESUELTA` a `CERRADA`. | Rechazar cierre desde otro estado o rol y aceptar cierre administrativo válido. |
| HU-15 Buscar | Localizar por número visible, texto o categoría. | Búsqueda sobre el listado autorizado y filtro de categoría. | Buscar un número, parte del título/descripción y una categoría. |
| HU-16 Filtrar | Combinar estado, prioridad y responsable. | Filtros del listado operativo y `IncidentFilter`. | Combinar los tres valores y comprobar los resultados y la limpieza de filtros. |
| HU-17 Dashboard | Mostrar total, abiertas, en atención, resueltas y cerradas. | `lib/domain/dashboard_metrics.dart`; presentación del tablero. | Comparar los indicadores con casos conocidos en cada estado. |
| HU-18 Categorías | Mostrar resumen agregado por categoría. | `DashboardMetrics.byCategory`. | Crear casos de varias categorías y comparar sus cantidades. |
| HU-19 Auditoría | Registrar autor y fecha de estados y asignaciones. | Eventos inmutables ligados a la versión y escritura atómica del incidente. | Cambiar estado/asignación; denegar operación sin evento y edición de un evento anterior. |
| HU-20 Publicación | Aplicación accesible por Internet mediante Firebase Hosting. | `firebase.json`, compilación `build/web` y proceso de [Firebase](FIREBASE.md). | Abrir [CampusFix](https://campusfix-ae32e.web.app) e iniciar sesión con una cuenta registrada. |

## Requisitos no funcionales

| Requisito del enunciado | Solución y verificación |
| --- | --- |
| Escritorio y tablet | Diseño adaptable de navegación, tarjetas, formularios y listados; inspección de viewport de escritorio y tablet. |
| Validación de formularios | Campos obligatorios, correo, credenciales, texto de actuación e imágenes; probar entradas inválidas. |
| Acceso autenticado | La sesión abre la operación y las reglas verifican identidad y perfil activo. |
| Reglas de Firestore y Storage | Archivos versionados con denegación por defecto y autorización por rol. |
| Carga, éxito y error claros | Estados de espera y mensajes tras operaciones; probar fallos de acceso y de red. |
| Capas separadas | UI, estado, dominio y repositorio descritos en [Arquitectura](ARQUITECTURA.md). |
| Git | Repositorio con historial de aplicación, seguridad y documentación. |
| Organización y documentación | Código organizado por responsabilidad; README, arquitectura, manual, Firebase, paquetes y entorno local. |

## Decisiones de implementación

- El estado inicial es `REPORTADA`, como exige HU-05. `REPORTAR` en el esquema general del PDF se interpreta como la acción de crear el caso.
- Los códigos persistidos usan `EN_REVISION` y `EN_ATENCION`; la interfaz muestra las etiquetas en español con tildes.
- El número visible utiliza el año y un sufijo del ID de Firestore. Es una referencia única de consulta; no promete una numeración entera continua.
- La cancelación temprana y la reapertura completan los estados alternativos del PDF. Se conserva la actuación anterior y se agrega un evento.
- Los archivos se mantienen privados y se leen con el SDK autenticado. Los metadatos no contienen enlaces públicos permanentes.
- El seguimiento en tiempo real se implementa con listeners de Firestore. No se necesita un servidor WebSocket adicional.

## Componentes documentados

| Componente del proyecto | Ubicación |
| --- | --- |
| Aplicación Flutter Web | `lib/`, `web/`, `pubspec.yaml` y `pubspec.lock`. |
| Configuración Firebase | `firebase.json`, `firestore.rules`, `firestore.indexes.json`, `storage.rules` y configuración del cliente. |
| Requisitos e historias | Este documento. |
| Arquitectura | [ARQUITECTURA.md](ARQUITECTURA.md). |
| UI | Interfaz ejecutable de Flutter Web. |
| Manual | [MANUAL_USUARIO.md](MANUAL_USUARIO.md). |
| Paquetes utilizados | [PAQUETES.md](PAQUETES.md). |
| Entorno local | [ENTORNO_LOCAL.md](ENTORNO_LOCAL.md). |
| Publicación | [CampusFix en Firebase Hosting](https://campusfix-ae32e.web.app); configuración en [FIREBASE.md](FIREBASE.md). |

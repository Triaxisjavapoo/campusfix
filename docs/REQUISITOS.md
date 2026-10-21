# Requisitos y trazabilidad

Fuente funcional: `Proyecto_1_UCR.pdf`, IF0009 Desarrollo de Software IV, Proyecto Integrador 1 CampusFix, UCR Sede del Sur, II Ciclo 2026, páginas 1 a 7. Esta matriz resume sus criterios y señala dónde se implementan; los resultados de ejecución están separados en [Pruebas](PRUEBAS.md).

## Alcance

Gestionar el ciclo completo de una incidencia de servicio del campus: reporte, clasificación, asignación, atención, seguimiento, resolución y cierre. La aplicación tiene interfaz Flutter Web y utiliza los cuatro servicios requeridos: Firebase Authentication, Cloud Firestore, Cloud Storage y Firebase Hosting.

Para esta entrega, el usuario decidió mantener Cloud Storage y demostrar las fotografías gratuitamente mediante los emuladores reales. Storage de producción queda pendiente para evitar activar facturación. Esta decisión conserva el diseño y las reglas del servicio requerido, pero no demuestra fotografías operativas en el sitio público. No se implementa un reemplazo con imágenes en Firestore. [CampusFix está publicado](https://campusfix-ae32e.web.app) en el proyecto `campusfix-ae32e`, con Firestore `(default)` en `us-central1` y Authentication por correo/contraseña habilitado.

| Actor | Necesidad |
| --- | --- |
| Usuario reportante | Crear y consultar sus reportes, aportar información y evidencia, conocer su evolución. |
| Técnico o encargado | Atender los casos asignados y documentar avances y solución. |
| Administrador | Clasificar, asignar, cerrar, administrar catálogos y perfiles y supervisar indicadores. |

## Historias de usuario

Los nombres de métodos y archivos se refieren al código entregado. La columna de comprobación describe cómo verificar el criterio; no equivale a un resultado de prueba.

Las pantallas están en `lib/ui/app.dart`; los controladores `AuthState`, `IncidentState`, `DashboardState` y `ThemeState`, en `lib/state/`. El servicio `lib/data/firebase_repository.dart` realiza las operaciones persistentes de la matriz. `firestore.rules` y `storage.rules` vuelven a validar la autorización y los datos en el servidor.

| HU | Resultado requerido | Implementación y protección | Comprobación |
| --- | --- | --- | --- |
| HU-01 Registro e inicio | Las credenciales válidas crean una sesión y abren el panel del rol. | Authentication y perfil persistido; `lib/data/firebase_repository.dart`, `users/{uid}`. | Registrar un reportante, salir e ingresar otra vez; comparar paneles de tres roles. |
| HU-02 Perfil | Actualizar datos básicos y conservarlos en el siguiente acceso. | Actualización de perfil del repositorio; reglas de `users` impiden cambiar el propio rol. | Cambiar nombre, cerrar sesión y volver a ingresar; intentar promoverse por SDK. |
| HU-03 Roles | El administrador controla las operaciones disponibles. | `UserRole` en `lib/domain/models.dart`, `IncidentPolicy`, reglas de Firestore y Storage. | Administrar una cuenta y comprobar que un reportante no obtiene funciones administrativas. |
| HU-04 Cerrar sesión | Eliminar la sesión y volver al acceso. | Firebase Auth y estado de sesión. | Salir y comprobar que la interfaz operativa desaparece. |
| HU-05 Crear incidencia | Generar identificación, persistir el reporte y dejarlo REPORTADA. | Creación atómica de documento y evento en el repositorio; reglas de `incidents`. | Crear un caso; comprobar ID, autor, fechas, estado y evento inicial. |
| HU-06 Evidencia | Almacenar fotos asociadas al caso. | `firebase_storage`, metadatos de `evidence`, `storage.rules`; demostración en emuladores. Producción pendiente por decisión del usuario. | Subir JPEG/PNG/WebP autorizado y rechazar archivo mayor a 5 MiB o acceso ajeno en emuladores. Repetir en producción cuando se habilite Storage. |
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
| HU-20 Publicación | Entrega accesible por Internet mediante Firebase Hosting. | `firebase.json`, compilación `build/web` y proceso de [Firebase](FIREBASE.md). | **Verificada:** despliegue CLI correcto, HTTP 200 y acceso administrativo en [CampusFix](https://campusfix-ae32e.web.app). |

## Requisitos no funcionales

| Requisito del enunciado | Solución y verificación |
| --- | --- |
| Escritorio y tablet | Diseño adaptable de navegación, tarjetas, formularios y listados; inspección de viewport de escritorio y tablet. |
| Validación de formularios | Campos obligatorios, correo, credenciales, texto de actuación e imágenes; probar entradas inválidas. |
| Acceso autenticado | La sesión abre la operación y las reglas verifican identidad y perfil activo. |
| Reglas de Firestore y Storage | Archivos versionados con denegación por defecto y pruebas de acceso por rol. |
| Carga, éxito y error claros | Estados de espera y mensajes tras operaciones; probar fallos de acceso y de red. |
| Capas separadas | UI, estado, dominio y repositorio descritos en [Arquitectura](ARQUITECTURA.md). |
| Git | Repositorio con commits reales de aplicación y seguridad, más la documentación de entrega; conservar el historial al continuar el desarrollo. |
| Organización y documentación | Código organizado por responsabilidad; README, arquitectura, manual, Firebase, paquetes y pruebas. |

## Decisiones de implementación

- El estado inicial es `REPORTADA`, como exige HU-05. `REPORTAR` en el esquema general del PDF se interpreta como la acción de crear el caso.
- Los códigos persistidos usan `EN_REVISION` y `EN_ATENCION`; la interfaz muestra las etiquetas en español con tildes.
- El número visible utiliza el año y un sufijo del ID de Firestore. Es una referencia única de consulta; no promete una numeración entera continua.
- La cancelación temprana y la reapertura completan los estados alternativos del PDF. Se conserva la actuación anterior y se agrega un evento.
- Los archivos se mantienen privados y se leen con el SDK autenticado. Los metadatos no contienen enlaces públicos permanentes.
- El seguimiento en tiempo real se implementa con listeners de Firestore. No se necesita un servidor WebSocket adicional.

## Entregables

| Entregable del PDF | Ubicación/evidencia |
| --- | --- |
| Aplicación Flutter Web | `lib/`, `web/`, `pubspec.yaml` y `pubspec.lock`. |
| Configuración Firebase | `firebase.json`, `firestore.rules`, `firestore.indexes.json`, `storage.rules` y configuración del cliente. |
| Requisitos e historias | Este documento. |
| Arquitectura | [ARQUITECTURA.md](ARQUITECTURA.md). |
| UI | Interfaz ejecutable y capturas de verificación cuando estén disponibles. |
| Manual | [MANUAL_USUARIO.md](MANUAL_USUARIO.md). |
| Paquetes utilizados | [PAQUETES.md](PAQUETES.md). |
| Pruebas | Pruebas automatizadas del repositorio y resultados reales en [PRUEBAS.md](PRUEBAS.md). |
| Publicación | [CampusFix en Firebase Hosting](https://campusfix-ae32e.web.app), acceso y validaciones comprobados; detalles en [Pruebas](PRUEBAS.md). |

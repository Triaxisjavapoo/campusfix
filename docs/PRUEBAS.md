# Pruebas y verificación

Este documento separa el procedimiento reproducible de los resultados efectivamente observados. La matriz de [Requisitos](REQUISITOS.md) detalla los criterios de aceptación. Nunca ejecute la semilla de demostración contra producción.

El usuario decidió conservar Cloud Storage y demostrar las fotografías gratuitamente con los emuladores reales; Storage de producción permanece pendiente. No se usa Firestore como almacenamiento alternativo de imágenes. El proyecto real es `campusfix-ae32e`, con Firestore `(default)` en `us-central1` y acceso por correo/contraseña habilitado. La actualización visual preparada es **2026.10.21.3**, con [enlace de acceso versionado](https://campusfix-ae32e.web.app/?v=2026.10.21.3). Su comprobación final está pendiente; la última validación completa registrada corresponde a **2026.10.21.2**. Los resultados se distinguen por versión y entorno.

## Preparación

Necesita Node.js **24.12 o superior** según `package.json` y Java/JDK **21 o superior** para los emuladores. Para modificar o probar el código Dart, necesita además Flutter estable. Compruebe `java -version` y `npx firebase --version`. Firebase documenta la instalación, puertos y ejecución en [Emulator Suite](https://firebase.google.com/docs/emulator-suite/install_and_configure).

```powershell
flutter pub get
npm ci
dart analyze lib test
flutter test
npm run test:cache
```

`test/domain_workflow_test.dart` valida políticas de acceso/transición, filtros, indicadores y deserialización. `test/responsive_ui_test.dart` verifica la tabla interactiva y los indicadores en anchos de 1280 y 768, con temas claro y oscuro. No necesitan el proyecto de producción.

`test/session_state_test.dart` comprueba el registro y acceso sin abrir consultas antes de confirmar el perfil, la separación entre sesiones y la identificación de errores de incidencias, categorías y usuarios. `npm run test:cache` ejecuta `tests/cache-update.test.mjs`: verifica el arranque versionado, la migración acotada del worker y la caché de CampusFix, la conservación de otras aplicaciones y los encabezados de las dos configuraciones de Hosting. Estas pruebas Node no requieren emuladores.

Las pruebas de reglas usan los emuladores reales de Firestore y Storage y clientes autenticados simulados de distintos roles:

```powershell
npm run test:rules
```

Este comando levanta los emuladores necesarios, ejecuta `tests/firebase-rules.test.mjs` y los detiene al finalizar. Debe terminar con código cero. Las negativas de permisos esperadas por una prueba no son un fallo si la aserción correspondiente pasa.

Para ejecutar el flujo integrado con Authentication, Firestore y Storage locales:

```powershell
npm run test:integration
```

Ejecuta `tests/firebase-workflow.integration.mjs`, que recorre cuentas de los tres roles, creación, clasificación, asignación, atención, solución, cierre, reapertura, comentarios, suscripciones y fotografía PNG privada. Usa los SDK cliente y las reglas reales de los emuladores; no sustituye las respuestas por mocks.

## Ejecutar la aplicación con Firebase local

La forma directa usa la compilación de emuladores ya incluida en `build/emulator-web`:

```powershell
npm ci
npm run demo
```

Abra [CampusFix local](http://127.0.0.1:5000). El comando usa `firebase.demo.json`, inicia Auth, Firestore, Storage y Hosting, y ejecuta automáticamente la semilla. `Ctrl+C` termina la demostración. `scripts/run-firebase-local.mjs` mantiene su caché de herramientas dentro de `.firebase/local-tooling` e intenta seleccionar un JDK instalado en Windows; si necesita otro, defina `JAVA_HOME` antes de iniciar.

Si modifica la aplicación, regenere esa compilación con:

```powershell
flutter build web --release --output build/emulator-web --dart-define=USE_EMULATORS=true --dart-define=EMULATOR_HOST=localhost
```

Para trabajar en desarrollo con recarga Flutter, use la alternativa siguiente:

1. En una primera terminal, desde la raíz del proyecto:

```powershell
npm run emulators
```

2. En otra terminal, con los emuladores ya iniciados:

```powershell
npm run seed:emulators
```

3. Ejecute Flutter con el modo local. El ID de los SDK debe coincidir con `demo-campusfix`, utilizado por la CLI y la semilla:

```powershell
flutter run -d chrome --web-port 7357 --dart-define=USE_EMULATORS=true --dart-define=EMULATOR_HOST=localhost --dart-define=FIREBASE_PROJECT_ID=demo-campusfix
```

Los emuladores son servicios locales reales de Firebase; no constituyen una demostración almacenada únicamente en memoria del navegador. La consola local permite inspeccionar las cuentas, documentos y archivos durante la sesión. Su dirección predeterminada es [Emulator UI](http://127.0.0.1:4000).

| Servicio | Dirección |
| --- | --- |
| Authentication | `127.0.0.1:9099` |
| Firestore | `127.0.0.1:8080` |
| Storage | `127.0.0.1:9199` |
| Hosting local | `127.0.0.1:5000`, si se usa una compilación web servida por el emulador. |

Las cuentas siguientes son exclusivamente locales y deben usarse con `USE_EMULATORS=true`. Todas tienen la contraseña **`CampusFix2026!`**. La semilla crea también categorías y casos de ejemplo. Consulte `scripts/seed-emulators.mjs` si modifica sus valores.

| Rol | Correo de prueba |
| --- | --- |
| Reportante | `reporter@campusfix.local` |
| Técnico | `tecnico@campusfix.local` |
| Administrador | `admin@campusfix.local` |

Para repetir las pruebas de reglas no deje otra instancia ocupando esos puertos; detenga la sesión de emuladores anterior o ejecute las pruebas primero. Los datos locales no se preservan al reiniciar salvo que se configure expresamente exportación e importación.

## Recorrido funcional de aceptación

| Paso | Acción y resultado esperado |
| --- | --- |
| 1. Identidad | Registrar usuario, entrar, actualizar nombre y salir; al volver, los datos persisten. |
| 2. Reporte | Crear un caso válido; aparece REPORTADA con número, autor y evento inicial. |
| 3. Evidencia | Subir imagen válida y abrirla; rechazar archivo con tamaño/tipo inválido. |
| 4. Aislamiento | Otro reportante no ve ni lee el caso, comentarios o fotografías. |
| 5. Clasificación | El administrador establece categoría/prioridad y registra revisión. |
| 6. Asignación | Un técnico activo queda vinculado; cambia a ASIGNADA y aparece en su lista. |
| 7. Atención | Solo el técnico asignado puede iniciar la atención; registra avance con autor y fecha. |
| 8. Resolución | Texto vacío se rechaza; una solución válida deja RESUELTA. |
| 9. Cierre | Solo un cierre administrativo desde RESUELTA deja CERRADA. |
| 10. Alternativas | Rechazo, cancelación temprana y reapertura respetan sus condiciones y agregan historial. |
| 11. Consulta | Número/texto/categoría y filtros combinados devuelven casos correctos. |
| 12. Tablero | Las cifras generales y agrupadas coinciden con los casos creados. |
| 13. Tiempo real | Dos sesiones autorizadas reflejan un cambio sin recargar manualmente la página. |
| 14. Auditoría | Toda transición/asignación identifica persona y fecha; no se permite editar un evento anterior. |
| 15. Concurrencia | Una acción basada en una versión antigua requiere revisar el caso actualizado. |
| 16. Responsividad | Escritorio y tablet presentan formularios, navegación y detalle sin recortes. |

## Qué prueban las reglas

`tests/firebase-rules.test.mjs` cubre creación de perfiles sin escalamiento de rol, acceso de participantes, bloqueo de usuarios inactivos, campos permitidos, categorías administrativas, estados y asignaciones válidos, solución obligatoria, evento ligado a la modificación, inmutabilidad del historial y restricciones de imágenes en Storage. Revise ese archivo para el inventario exacto de casos y la sección de resultados para confirmar cuáles se ejecutaron.

Los emuladores no demuestran por sí mismos que los servicios de producción estén habilitados ni que el despliegue sea accesible. El acceso a Hosting, Authentication y Firestore de producción se verificó por separado. No se activó Blaze ni se probó Storage de producción, conforme a la decisión del usuario.

## Resultados de la versión 2026.10.21.2

Verificaciones históricas registradas el **21 de octubre de 2026** para **2026.10.21.2**. Las referencias a la versión actual dentro de esta tabla corresponden a esa publicación. Las filas indican qué se volvió a ejecutar para esa corrección y qué corresponde a la entrega anterior; no se atribuyen estos resultados a 2026.10.21.3 ni una nueva ejecución a las suites de reglas o integración Firebase.

| Verificación | Resultado registrado |
| --- | --- |
| `dart analyze lib test` | Correcto: `No issues found`. |
| `flutter test` | **25/25 en la versión actual**: diez pruebas de dominio, dos de widgets y trece de sesiones. Tabla interactiva e indicadores comprobados en 1280 y 768; temas claro y oscuro. Las tres regresiones añadidas identifican la consulta que origina el error: incidencias, categorías o usuarios. |
| `npm run test:cache` | **7/7 en la versión actual**: arranque versionado, retiro exclusivo del worker propio, navegación de migración sin bucle, conservación de la URL y limpieza de recursos de CampusFix previamente identificados. |
| `npm run test:rules` | **20/20 en la entrega anterior**, Firestore y Storage locales; sin fallos. No se volvió a ejecutar para esta corrección de caché. |
| `npm run test:integration` | **8/8 en la entrega anterior**, Auth, Firestore y Storage locales; flujo multiusuario, tiempo real y fotografía privada. No se volvió a ejecutar para esta corrección de caché. |
| Semilla de emuladores | Correcta: tres cuentas con perfiles de sus roles, cinco categorías y tres incidencias con historial. |
| Compilación de producción | Código de salida 0 en la versión actual; archivos generados en `build/web`. |
| Compilación de emuladores | Código de salida 0 en la versión actual; archivos generados en `build/emulator-web`. |
| Firebase Hosting | Despliegue CLI de la versión actual correcto. Solicitudes HEAD a las entradas verificadas devolvieron **200** y `no-cache, no-store, must-revalidate`. HU-20 verificada en [CampusFix actualizado](https://campusfix-ae32e.web.app/?v=2026.10.21.2). |
| Authentication de producción | Proveedor de correo/contraseña habilitado; inicio de sesión administrativo correcto con cliente Firebase y navegador. |
| Firestore de producción | Perfil administrador y cinco categorías leídos correctamente con cliente autenticado; panel y catálogo visibles en navegador. Seis índices comprobados en estado `READY`. |
| UI de producción | Inspección visual de escritorio a 1366; acceso administrativo correcto. Formulario vacío mostró las cuatro validaciones sin guardar un incidente. |
| Actualización en una sesión existente | Versión 2026.10.21.2 verificada en la misma sesión de la cuenta de prueba `test4`, sin el aviso anterior y conservando la sesión. Sello de versión en la esquina inferior derecha y pie Flutter `v1.0.2`. |
| Navegador local contra emuladores | No se logró conectar desde la herramienta de navegador por aislamiento del entorno. No se afirma un recorrido local de navegador; el flujo Firebase completo se verificó mediante la integración 8/8. |
| Tablet | Verificada en pruebas de widgets a 768. La herramienta de navegador no aplicó el cambio de viewport; no se afirma inspección visual de tablet en navegador. |
| Storage de producción | Pendiente por decisión del usuario. La interfaz lo indica y desactiva el botón para adjuntar fotografías en producción. |

El recorrido funcional de la sección anterior es reproducible, pero no se presenta como una ejecución completa de tres roles en el navegador de producción. Las pruebas integradas cubren ese ciclo en Firebase local; las comprobaciones de producción se limitan a las operaciones descritas en la tabla.

## Primera corrección del primer ingreso y cambio de cuenta

Se reprodujo en el navegador de producción un aviso `permission-denied` al registrar un reportante: la instantánea local del perfil permitía abrir las consultas privadas antes de que su escritura quedara confirmada en el servidor. Cerrar sesión y volver a entrar eliminaba el aviso, lo que permitió distinguir esta carrera de un permiso incorrecto del rol.

El repositorio espera instantáneas del perfil confirmadas por el servidor. `AuthState` conserva la sesión en preparación durante el registro y la validación del acceso; `IncidentState` abre sus consultas después. Las suscripciones y operaciones en vuelo comprueban la generación de sesión para evitar que un error anterior aparezca en otra cuenta. Editar el perfil o solicitar recuperación de contraseña conserva las consultas y filtros vigentes.

Verificación histórica de esa primera corrección, anterior a la versión 2026.10.21.2:

- Las diez regresiones nuevas están en `test/session_state_test.dart`. Tres detectaron fallos en una copia aislada del código anterior: registro, login y operación pendiente al cambiar de sesión.
- La suite completa del código corregido pasó **22/22**; `dart analyze lib test` terminó con `No issues found`.
- Se recompilaron los clientes de producción y de emuladores. Firebase Hosting confirmó el despliegue del cliente corregido y el JavaScript publicado coincidió con la compilación local.
- Se verificó un registro nuevo de reportante sin aviso, cambio a técnico en tiempo real y cierre/inicio de sesión de técnico sin aviso, usando cuentas temporales en producción. No se modificaron las cuentas del usuario; las cuentas temporales se eliminaron al terminar.
- Después se identificó que algunos navegadores seguían ejecutando el cliente anterior almacenado en caché. La corrección de distribución y su comprobación están en la sección siguiente.

Las reglas de Firestore y Storage conservan sus restricciones por rol. Esta corrección no modifica el alcance acordado de fotografías en producción.

## Corrección de actualización y caché: 2026.10.21.2

La inspección del cliente anterior mostró que las respuestas HEAD de `/`, `flutter_bootstrap.js` y `main.dart.js` permitían `max-age=3600`. El documento cargado tampoco tenía el marcador de versión nuevo. Por eso un navegador podía continuar ejecutando el cliente anterior aunque Hosting ya contuviera la primera corrección del acceso.

La versión 2026.10.21.2 incorporó `no-cache, no-store, must-revalidate` para la entrada de la aplicación, los JavaScript y `version.json`. `index.html` carga el bootstrap con su versión, y el bootstrap solicita `main.dart.js` con la misma versión. El arranque no registra un nuevo service worker. Retira únicamente el worker Flutter que coincide con la ruta y el alcance de CampusFix y limpia recursos de caché después de identificar el documento de esta aplicación. Conserva Authentication, IndexedDB, localStorage y los recursos de otras aplicaciones.

Las siete pruebas Node de `tests/cache-update.test.mjs` pasaron. También pasaron las 25 pruebas Flutter y el análisis Dart sin problemas, se generaron ambas compilaciones con código de salida 0 y Hosting confirmó el despliegue. Las comprobaciones HEAD posteriores devolvieron 200 y los encabezados sin almacenamiento en caché. En producción se abrió la actualización dentro de la misma sesión de `test4`: desapareció el aviso anterior y se conservó el acceso. Las reglas de seguridad mantienen los permisos por rol.

La publicación comprobada en esa corrección utilizó el [enlace 2026.10.21.2](https://campusfix-ae32e.web.app/?v=2026.10.21.2), el sello **v2026.10.21.2** y el pie Flutter **v1.0.2**. Son marcadores de esa evidencia histórica. Para la siguiente actualización use el enlace y los marcadores de su versión. No se necesita borrar los datos del navegador ni cerrar la sesión. Si aparece el mensaje de actualización que pide cerrar la pestaña porque un worker anterior sigue controlándola, cierre esa pestaña y abra de nuevo el enlace versionado.

En siguientes cambios, incremente conjuntamente la versión del meta, sello y script de `web/index.html` y la de `web/flutter_bootstrap.js`; ajuste la expectativa de versión de las pruebas, ejecute `npm run test:cache` y después compile. Las fuentes deben coincidir. Actualice también el enlace compartido para que no conserve el identificador fijo de una entrega anterior.

## Actualización visual UCR: 2026.10.21.3

La interfaz utiliza la paleta UCR, el encabezado con firma oficial PNG sin modificar, el acceso ilustrado, la navegación lateral y una ilustración vectorial original del campus. Los recursos se incluyen localmente, sin paquetes nuevos. Su procedencia e integridad están en [Identidad UCR](IDENTIDAD_UCR.md).

Resultados de esta actualización visual. Las comprobaciones de 2026.10.21.2 anteriores permanecen como evidencia histórica.

| Verificación de 2026.10.21.3 | Estado |
| --- | --- |
| Análisis Dart | `dart analyze lib test`: `No issues found` tras los cambios visuales UCR. |
| Pruebas Flutter | **25/25** tras los cambios visuales UCR. |
| `npm run test:cache` | **7/7** con los marcadores de versión 2026.10.21.3. |
| Compilaciones de producción y emuladores | Ambas con código de salida 0, en `build/web` y `build/emulator-web`. |
| Despliegue y encabezados de Hosting | Publicación CLI correcta en [CampusFix 2026.10.21.3](https://campusfix-ae32e.web.app/?v=2026.10.21.3). HEAD devolvió HTTP 200 y `no-store` para HTML, bootstrap, main, firma UCR y fuente MaterialIcons. |
| Inspección visual UCR y acceso | Acceso y tablero de escritorio a 1280 × 720; tablero con navegación plegable a 858 × 884. Firma, botones, ilustraciones y temas claro/oscuro comprobados. La cuenta `test5` conservó su sesión sin aviso de permisos. Formulario de nueva incidencia abierto y cerrado sin guardar datos. Marcadores `v2026.10.21.3` y pie Flutter `v1.0.3` confirmados. |

El menú puede desplazarse en ventanas bajas; la marca de la cabecera se reduce para caber en teléfonos estrechos. Estos ajustes se revisaron en código; no se afirma una captura de navegador a 320 px. Las métricas, estados y textos secundarios usan colores legibles según el tema. El icono de CampusFix se dibuja en código para mantener su presencia incluso cuando el navegador conserva una fuente de iconos anterior. Hosting también entrega los assets sin caché persistente para las siguientes actualizaciones. No se cambiaron reglas, cuentas ni datos de Firebase.

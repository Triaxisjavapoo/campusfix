# Pruebas y verificación

Este documento separa el procedimiento reproducible de los resultados efectivamente observados. La matriz de [Requisitos](REQUISITOS.md) detalla los criterios de aceptación. Nunca ejecute la semilla de demostración contra producción.

El usuario decidió conservar Cloud Storage y demostrar las fotografías gratuitamente con los emuladores reales; Storage de producción permanece pendiente. No se usa Firestore como almacenamiento alternativo de imágenes. El proyecto real es `campusfix-ae32e`, con Firestore `(default)` en `us-central1` y acceso por correo/contraseña habilitado. El sitio está publicado en [CampusFix](https://campusfix-ae32e.web.app). Las pruebas locales y las comprobaciones de producción se distinguen abajo.

## Preparación

Necesita Node.js **24.12 o superior** según `package.json` y Java/JDK **21 o superior** para los emuladores. Para modificar o probar el código Dart, necesita además Flutter estable. Compruebe `java -version` y `npx firebase --version`. Firebase documenta la instalación, puertos y ejecución en [Emulator Suite](https://firebase.google.com/docs/emulator-suite/install_and_configure).

```powershell
flutter pub get
npm ci
dart analyze lib test
flutter test
```

`test/domain_workflow_test.dart` valida políticas de acceso/transición, filtros, indicadores y deserialización. `test/responsive_ui_test.dart` verifica la tabla interactiva y los indicadores en anchos de 1280 y 768, con temas claro y oscuro. No necesitan el proyecto de producción. Las pruebas de reglas usan los emuladores reales de Firestore y Storage y clientes autenticados simulados de distintos roles:

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

## Resultados de esta entrega

Verificaciones ejecutadas el **21 de octubre de 2026**. Los resultados se registran por suite y entorno para no confundir la demostración local con el sitio publicado.

| Verificación | Resultado registrado |
| --- | --- |
| `dart analyze lib test` | Correcto: `No issues found`. |
| `flutter test` | **12/12**: diez pruebas de dominio y dos de widgets. Tabla interactiva e indicadores comprobados en 1280 y 768; temas claro y oscuro. |
| `npm run test:rules` | **20/20**, Firestore y Storage locales; sin fallos. |
| `npm run test:integration` | **8/8**, Auth, Firestore y Storage locales; flujo multiusuario, tiempo real y fotografía privada. |
| Semilla de emuladores | Correcta: tres cuentas con perfiles de sus roles, cinco categorías y tres incidencias con historial. |
| Compilación de producción | Código de salida 0; archivos generados en `build/web`. |
| Compilación de emuladores | Código de salida 0; archivos generados en `build/emulator-web`. |
| Firebase Hosting | Despliegue CLI correcto y respuesta HTTP **200** en [CampusFix](https://campusfix-ae32e.web.app). HU-20 verificada. |
| Authentication de producción | Proveedor de correo/contraseña habilitado; inicio de sesión administrativo correcto con cliente Firebase y navegador. |
| Firestore de producción | Perfil administrador y cinco categorías leídos correctamente con cliente autenticado; panel y catálogo visibles en navegador. Seis índices comprobados en estado `READY`. |
| UI de producción | Inspección visual de escritorio a 1366; acceso administrativo correcto. Formulario vacío mostró las cuatro validaciones sin guardar un incidente. |
| Navegador local contra emuladores | No se logró conectar desde la herramienta de navegador por aislamiento del entorno. No se afirma un recorrido local de navegador; el flujo Firebase completo se verificó mediante la integración 8/8. |
| Tablet | Verificada en pruebas de widgets a 768. La herramienta de navegador no aplicó el cambio de viewport; no se afirma inspección visual de tablet en navegador. |
| Storage de producción | Pendiente por decisión del usuario. La interfaz lo indica y desactiva el botón para adjuntar fotografías en producción. |

El recorrido funcional de la sección anterior es reproducible, pero no se presenta como una ejecución completa de tres roles en el navegador de producción. Las pruebas integradas cubren ese ciclo en Firebase local; las comprobaciones de producción se limitan a las operaciones descritas en la tabla.

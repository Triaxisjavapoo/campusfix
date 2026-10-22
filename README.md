# CampusFix

Aplicación Flutter Web para reportar, asignar y atender incidencias del campus. Corresponde al Proyecto Integrador 1 de IF0009, Universidad de Costa Rica, Sede del Sur, II Ciclo 2026.

Utiliza Firebase Authentication para las cuentas, Cloud Firestore para los datos y el seguimiento en tiempo real, Cloud Storage para fotografías privadas y Firebase Hosting para publicar el cliente web. Incluye tres roles: reportante, técnico y administrador.

**Acceso a CampusFix:** [Abrir CampusFix 2026.10.21.3](https://campusfix-ae32e.web.app/?v=2026.10.21.3). La actualización visual UCR está publicada y comprobada en el navegador. Los resultados y su alcance están en [Pruebas](docs/PRUEBAS.md). Authentication por correo/contraseña está habilitado; el proyecto `campusfix-ae32e` tiene Firestore `(default)` en `us-central1`, cinco categorías y una cuenta administradora inicial. Su acceso se entrega en un archivo separado, fuera del código y del paquete compartible.

**Identidad visual UCR:** encabezado con la firma oficial PNG a color sin modificar, azul y celeste UCR, acceso ilustrado, navegación lateral renovada y una ilustración vectorial original del campus. Los recursos se incluyen localmente y no requieren paquetes nuevos. Las fuentes, colores, archivos y criterios de uso se detallan en [Identidad UCR](docs/IDENTIDAD_UCR.md).

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
npm run test:cache
```

Para probar Firebase localmente, siga [la guía de emuladores y pruebas](docs/PRUEBAS.md). Para conectar su proyecto y publicar, siga [la guía completa de Firebase](docs/FIREBASE.md). La publicación requiere la configuración real de una aplicación web del proyecto y acceso autorizado a sus servicios.

## Documentación

| Documento | Contenido |
| --- | --- |
| [Requisitos y trazabilidad](docs/REQUISITOS.md) | Historias HU-01 a HU-20, criterios y correspondencia con la implementación. |
| [Arquitectura](docs/ARQUITECTURA.md) | Capas, modelo Firestore, estados, autorización y evidencia privada. |
| [Identidad UCR](docs/IDENTIDAD_UCR.md) | Fuentes oficiales, paleta, firmas originales, integridad de archivos y aplicación visual. |
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

La versión **2026.10.21.3** incorpora la identidad UCR: análisis Dart sin problemas, **25/25** pruebas Flutter y **7/7** pruebas de actualización. Ambas compilaciones y el despliegue terminaron correctamente. El acceso, el tablero y la sesión existente se comprobaron en el navegador; el tema oscuro conserva la legibilidad y los recursos gráficos se incluyen localmente. Resultados en [Pruebas](docs/PRUEBAS.md).

La versión anterior **2026.10.21.2**, verificada el 21 de octubre de 2026, pasó el análisis Dart, **25/25** pruebas Flutter y **7/7** pruebas de actualización; ambas compilaciones y Hosting terminaron correctamente. La entrega inicial pasó **20/20** pruebas de reglas y **8/8** de integración Firebase. Esos resultados se conservan como evidencia histórica, junto con las comprobaciones de acceso y sesión de producción. Las fotografías de producción permanecen pendientes.

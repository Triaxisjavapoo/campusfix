# Empezar con CampusFix

## Sitio publicado

Abra https://campusfix-ae32e.web.app.

La cuenta administradora es **megamack09@gmail.com**. Su contraseña inicial está en el archivo separado `ACCESO_INICIAL_CampusFix.txt` de esta entrega; no está en el código ni en el ZIP. En **Mi perfil → Cambiar mi contraseña** puede solicitar un enlace a su correo.

Authentication, Firestore y Hosting están activos en el proyecto Spark. Hay cinco categorías listas. Registre las cuentas de su equipo y asigne sus roles en **Usuarios y roles**.

**Fotografías:** por decisión acordada, Cloud Storage se conserva y se demuestra en emuladores gratis. La carga de fotos en el sitio público queda pendiente de activar Storage mediante Blaze. El resto del flujo está publicado.

## Demostración gratuita completa, incluidas fotografías

Requisitos: Node.js **24.12 o superior**, Java **JDK 21 o superior** y conexión a Internet para instalar dependencias y descargar los emuladores la primera vez. No necesita vincular una tarjeta ni usar un proyecto de pago.

1. Extraiga `CampusFix_entrega.zip`.
2. En Windows, abra `iniciar-demo.cmd` dentro de la carpeta `campusfix`. Instala dependencias locales si faltan y arranca los emuladores.
3. Abra **http://127.0.0.1:5000** cuando la terminal anuncie que la demostración está lista.

Alternativa desde una terminal en la carpeta del proyecto:

```powershell
npm ci
npm run demo
```

La entrega incluye el cliente ya compilado en `build/emulator-web`. Si cambia el código, vuelva a construirlo antes de demostrarlo:

```powershell
flutter pub get
flutter build web --release --dart-define-from-file=firebase.emulators.json --output build/emulator-web
```

| Rol | Correo local | Contraseña local |
| --- | --- | --- |
| Administrador | admin@campusfix.local | CampusFix2026! |
| Técnico | tecnico@campusfix.local | CampusFix2026! |
| Reportante | reporter@campusfix.local | CampusFix2026! |

Son cuentas exclusivas de los emuladores. Los datos locales no se envían al proyecto publicado. Ctrl+C detiene la demostración. La semilla se prepara al arrancar; el entorno es desechable y no persiste datos entre arranques.

## Código, manuales y pruebas

- `README.md`: instalación y comandos.
- `docs/MANUAL_USUARIO.md`: uso de cada rol.
- `docs/PAQUETES.md`: paquetes y funcionamiento.
- `docs/FIREBASE.md`: configuración, seguridad y publicación.
- `docs/REQUISITOS.md`: cobertura de HU-01 a HU-20 y alcance acordado.
- `docs/ARQUITECTURA.md`: diseño y modelo de datos.
- `docs/PRUEBAS.md`: resultados reales y sus límites.

El proyecto incluye un repositorio Git local con commits de aplicación, seguridad y documentación, además de las compilaciones de producción y emuladores. Los archivos `pubspec.lock` y `package-lock.json` fijan las dependencias.

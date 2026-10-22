# Inicio rápido

## Acceso al sitio

[Abrir CampusFix](https://campusfix-ae32e.web.app/?v=2026.10.21.4).

El acceso utiliza correo electrónico y contraseña. Las cuentas nuevas tienen el rol de reportante. La administración asigna los roles del personal desde **Usuarios y roles** y gestiona el catálogo desde **Categorías**.

Las credenciales administrativas se mantienen fuera del repositorio. En **Mi perfil → Cambiar mi contraseña** se puede solicitar el enlace de recuperación.

Authentication, Firestore y Hosting están activos en el plan Spark. Las fotografías de producción utilizan Supabase Storage privado. En el detalle de una incidencia, **Fotografías y evidencias → Adjuntar** permite seleccionar JPEG, PNG o WebP de hasta 5 MiB. La demostración local conserva Cloud Storage con emuladores.

## Ejecución local

Requisitos: Flutter estable, Node.js **24.12 o superior** y Java/JDK **21 o superior**. La instalación inicial requiere conexión a Internet para obtener las dependencias y los emuladores.

Desde la carpeta `campusfix`:

```powershell
flutter pub get
npm ci
flutter build web --release --dart-define-from-file=firebase.emulators.json --output build/emulator-web
npm run demo
```

Abrir **http://127.0.0.1:5000** cuando el entorno esté disponible. En Windows, `iniciar-demo.cmd` permite arrancar la demostración si `build/emulator-web` ya contiene el cliente compilado.

## Cuentas de demostración

| Rol | Correo local | Contraseña local |
| --- | --- | --- |
| Administrador | `admin@campusfix.local` | `CampusFix2026!` |
| Técnico | `tecnico@campusfix.local` | `CampusFix2026!` |
| Reportante | `reporter@campusfix.local` | `CampusFix2026!` |

Estas cuentas pertenecen únicamente a los emuladores y no permiten entrar al sitio de producción. La demostración incluye categorías e incidencias de ejemplo con historial.

`Ctrl+C` detiene el entorno. Los datos locales se reinician en cada arranque, salvo que se configure su exportación e importación.

## Documentación

- [Manual de usuario](docs/MANUAL_USUARIO.md): operación de cada rol.
- [Fotografías con Supabase](docs/SUPABASE.md): almacenamiento privado y configuración.
- [Firebase y publicación](docs/FIREBASE.md): servicios, seguridad y despliegue.
- [Entorno local](docs/ENTORNO_LOCAL.md): emuladores y modo de desarrollo.
- [Paquetes](docs/PAQUETES.md): dependencias y funcionamiento.
- [Requisitos](docs/REQUISITOS.md): historias de usuario y alcance funcional.
- [Arquitectura](docs/ARQUITECTURA.md): organización y modelo de datos.
- [Identidad UCR](docs/IDENTIDAD_UCR.md): colores y recursos gráficos.

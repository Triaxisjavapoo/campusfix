# Manual de usuario

CampusFix centraliza el reporte, atención y cierre de incidencias del campus. Abra [CampusFix](https://campusfix-ae32e.web.app). Puede trabajar desde un navegador de escritorio o una tablet con conexión a Internet.

**Alcance actual:** el acceso por correo/contraseña está habilitado y el catálogo inicial contiene cinco categorías. El administrador gestiona las cuentas y sus roles. Las fotografías están disponibles en producción mediante Supabase Storage privado y, en el entorno local, mediante los emuladores de Firebase. Las cuentas del entorno local no pertenecen al sitio público.

## Acceso y perfil

1. Cree una cuenta con su nombre, correo y contraseña, o inicie sesión con una cuenta existente.
2. La cuenta nueva tendrá rol **Reportante**. El administrador asigna los roles del personal.
3. Abra **Perfil** pulsando su identidad en la navegación. En **Mi perfil** puede cambiar **Nombre completo**, guardar los cambios, cambiar entre tema claro/oscuro o solicitar recuperación de contraseña. El correo se muestra como dato de solo lectura.
4. Al terminar en un equipo compartido, use **Cerrar sesión**.

Si recibe un mensaje de cuenta inactiva, contacte a la administración del campus. Una contraseña incorrecta se corrige desde la pantalla de acceso; cambiar el rol no cambia la contraseña.

## Reportante: crear y seguir un caso

1. Abra **Nueva incidencia**.
2. Escriba un título breve y una descripción que permita entender el problema. Indique una ubicación concreta, por ejemplo edificio, piso y aula.
3. Seleccione la categoría y la prioridad disponibles. La administración puede ajustar la clasificación durante la revisión.
4. Guarde. El caso recibe un número visible y comienza en **Reportada**.
5. Abra el detalle para agregar comentarios. Use **Adjuntar** en **Fotografías y evidencias** para subir JPEG, PNG o WebP de hasta 5 MiB por archivo. Espere el mensaje **Fotografía guardada**; pulse la miniatura para ampliar la imagen. Solo pueden consultarla los participantes autorizados del caso y la administración.
6. En **Mis incidencias**, busque el caso por número o texto, o use la categoría y el estado. La lista del reportante contiene sus propios reportes.

En el detalle aparecen el estado actual, la persona responsable, los comentarios, las fotografías y el historial. Las actuaciones incluyen autor y fecha y llegan mediante la actualización en tiempo real; espere la confirmación de guardado antes de cerrar el formulario.

Si el reporte deja de ser necesario antes de iniciar atención y la acción está disponible, puede cancelarlo. Si el resultado requiere revisión, use la reapertura disponible en un caso resuelto, cerrado o rechazado y describa el motivo. El caso vuelve a revisión operativa.

## Administrador: organizar el trabajo

1. Revise **Vista general** y abra **Incidencias**. Combine los filtros de estado, prioridad, categoría y responsable para identificar la carga de trabajo.
2. Abra un reporte nuevo y use **Pasar a revisión**. Verifique la información recibida.
3. Use **Clasificar** para ajustar categoría y prioridad. Si no procede, use **Rechazar reporte** y escriba la explicación.
4. Use **Asignar técnico** y seleccione un técnico activo. El estado cambia a **Asignada** y queda registrado el responsable.
5. Supervise los avances y fotografías desde el detalle.
6. Cuando el técnico lo marque **Resuelta**, revise la solución y use **Cerrar incidencia**. El estado pasa a **Cerrada**.
7. Para retirar un caso definitivamente, abra su detalle y pulse **Eliminar reporte** en **Gestión del caso**. Escriba su número exacto y confirme con **Eliminar permanentemente**. Se borran el reporte, fotografías, comentarios e historial; la operación no se puede deshacer. **Conservar reporte** cierra la confirmación sin borrar. Esta opción solo está disponible para el administrador activo.

Si la conexión interrumpe el borrado, el reporte conserva el aviso de eliminación en curso. Abra de nuevo el caso y use **Reintentar eliminación**. Mientras ese proceso esté pendiente no se admiten comentarios, fotografías ni cambios de estado. Cancelar un reporte es una transición del flujo; eliminarlo retira sus datos permanentemente.

En **Vista general** encontrará el resumen operativo. En **Indicadores** podrá consultar las cantidades de casos, abiertos, en atención, resueltos y cerrados, junto al resumen por categoría y prioridad. Los casos abiertos incluyen las etapas que todavía requieren gestión; los rechazados y cancelados son resultados alternativos. Los indicadores se actualizan con los datos de la operación.

En **Categorías** mantenga el catálogo. En **Usuarios y roles** promueva a técnico las cuentas registradas del personal y desactive los perfiles que deban dejar de operar. La interfaz impide cambiar su propio rol o desactivar su propia cuenta; el operador del proyecto puede recuperar el acceso mediante el procedimiento de primer administrador.

## Técnico: atender y resolver

1. Entre con su cuenta de técnico y abra **Mi trabajo** para revisar sus incidencias asignadas.
2. Abra una incidencia **Asignada** y use **Iniciar atención**. Solo el técnico asignado puede realizar este paso.
3. Registre los avances como comentarios. Incluya lo realizado, lo pendiente y las observaciones necesarias. Adjunte evidencia si corresponde.
4. Al finalizar el trabajo, seleccione **Registrar solución** y escriba la solución aplicada. Una descripción vacía no permite resolver el caso.
5. La incidencia queda **Resuelta** para revisión y cierre del administrador.

Si una incidencia no aparece en su listado, confirme con el administrador que esté asignada a su cuenta. Una reasignación cambia el acceso del técnico a ese caso.

## Demostración gratuita con fotografías

En la carpeta del proyecto, instale las dependencias con `npm ci` y ejecute `npm run demo`. Necesita Node.js 24.12 o superior y Java/JDK 21 o superior. Abra [CampusFix local](http://127.0.0.1:5000): la semilla prepara las cuentas y datos. Las tres cuentas y su contraseña de uso exclusivamente local están en [Entorno local](ENTORNO_LOCAL.md). Cierre con `Ctrl+C`. Esta demostración permite seguir el ciclo de los tres roles y utilizar Storage sin activar facturación del proyecto público.

## Qué significa cada estado

| Estado | Significado |
| --- | --- |
| Reportada | Se recibió la solicitud. |
| En revisión | La administración está validando y clasificando el caso. |
| Asignada | Hay un técnico responsable. |
| En atención | El técnico comenzó la intervención. |
| Resuelta | Se registró una solución y está pendiente el cierre formal. |
| Cerrada | La administración finalizó el caso. |
| Rechazada | El caso no procede; consulte la explicación. |
| Cancelada | El reportante retiró el caso en una etapa temprana. |
| Reabierta | Se solicitó una nueva revisión. |

## Mensajes habituales

| Situación | Acción |
| --- | --- |
| Un campo aparece inválido | Revise el mensaje junto al campo y complételo antes de guardar. |
| La fotografía no se acepta | Compruebe formato y tamaño; use una imagen menor a 5 MiB. |
| El caso cambió mientras lo editaba | Revise el detalle actualizado y repita la acción con la información vigente. |
| No tiene autorización | Confirme su rol, estado de cuenta y relación con el caso. |
| Error de conexión o servicio | Compruebe la red y vuelva a intentar; si persiste, comunique la operación al administrador. |

La evidencia queda restringida a quienes pueden consultar el caso. Para conservar trazabilidad, el historial de estados se agrega como nuevos eventos; no se modifica una actuación anterior desde el formulario.

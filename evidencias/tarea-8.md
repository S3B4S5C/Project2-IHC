# Tarea 8 · Cuidados compartidos

## Proceso

1. El responsable de un cuidado abre **Cuidados compartidos e invitaciones** desde el panel.
2. Selecciona el cuidado, escribe el correo de otro usuario registrado y elige **Consulta** o **Gestión**.
3. El invitado ve la solicitud en **Invitaciones recibidas** y puede **Aceptar** o **Rechazar**.
4. Solo después de aceptar, el cuidado aparece en su panel.
5. El responsable puede cambiar el permiso o **Revocar acceso** desde **Accesos que administro**.

## Estados y consecuencias

| Estado | Consecuencia |
| --- | --- |
| Pendiente | El invitado puede aceptar/rechazar, pero todavía no accede. |
| Rechazada | No concede acceso; el responsable puede volver a invitar. |
| Aceptada + Consulta | Puede ver el cuidado y el historial, sin editar ni completar. |
| Aceptada + Gestión | Puede ver, editar/reprogramar y marcar como realizado; no puede eliminar ni invitar. |
| Revocada | Deja de ver y modificar el cuidado o su historial desde su cuenta. |

Solo el responsable asignado administra las invitaciones. Si no existe responsable asignado, administra el dueño. El dueño conserva el permiso de eliminar su cuidado.

## Autoría e historial

Cada realización y reprogramación crea un evento persistente con **autor_id**, **autor_nombre** y **fecha_hora**. El historial pertenece al dueño del cuidado y conserva estos datos aunque después se revoque el acceso del autor. Los cuidados recurrentes siguen programando la próxima fecha.

## Archivos afectados

- `backend/compartidos/models.py`, `schemas.py`, `router.py` y `permisos.py`: invitaciones, estados, permisos y controles.
- `backend/mascotas/router.py`: acceso a cuidados y realización/edición según permiso.
- `backend/historial/models.py`, `router.py` y `schemas.py`: autor y fecha persistentes.
- `backend/main.py`: creación de tablas y actualización de las columnas existentes.
- `frontend/lib/features/compartidos/screens/compartidos_screen.dart`: flujo de invitaciones.
- `frontend/lib/features/mascotas/screens/home_screen.dart`: acceso a compartidos y botones según permiso.
- `frontend/lib/features/historial/screens/historial_screen.dart`: muestra autor y fecha.

## Comprobación

**Prueba de API:** `cd backend && pytest tests/compartidos/test_cuidados_compartidos.py -q`

**Prueba E2E (con Docker y Flutter):** `cd e2e && npm test -- --workers=1`

El E2E crea tres usuarios, invita desde Flutter, acepta, comprueba el modo consulta, cambia a gestión, realiza el cuidado y revoca. Confirma que el dueño sigue viendo el autor y la fecha del evento.

**Estado de verificación:** código y rutas revisados; las pruebas de Python y Flutter deben ejecutarse en un entorno con las dependencias y servicios levantados. No se registran resultados no ejecutados.

## Commits

- Persistencia: [`ca3b2cc`](https://github.com/S3B4S5C/Project2-IHC/commit/ca3b2cc99fdfb6b47614e0a5a14b0eefff832d27)
- Reglas y permisos: [`b5c41fc`](https://github.com/S3B4S5C/Project2-IHC/commit/b5c41fc36394484abe7cf20369a404bafce9057c)
- Interfaz: [`a70544d`](https://github.com/S3B4S5C/Project2-IHC/commit/a70544d19115fd8fc34d7dd31a86b60bc5eba636)
- Pruebas: [`8a71d07`](https://github.com/S3B4S5C/Project2-IHC/commit/8a71d078a744dc0e65ac9a201c249eb92fe46d30)

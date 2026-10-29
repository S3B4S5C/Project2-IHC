# Clase 17 · Análisis de proyecto recibido

## Proyecto recibido

Repositorio del grupo anterior:

https://github.com/GaboTex2004/Project2-IHC

El proyecto utiliza Flutter para el frontend y FastAPI para el backend.

## Ejecución

Para levantar backend y base de datos:

```bash
docker compose up --build
```

Para ejecutar la aplicación Flutter:

```bash
cd frontend
flutter pub get
flutter run
```

### Comando utilizado

![Ejecución desde terminal](./ejecucion-comando.png)

### Aplicación funcionando

![Aplicación funcionando](./ejecucion-app.png)

## Recorrido: pantalla → acción → regla → datos

### Pantalla

`frontend/lib/features/mascotas/screens/home_screen.dart`

Desde el panel de mascotas la persona puede marcar un cuidado como realizado y acceder posteriormente al historial.

### Acción

El frontend realiza:

```text
PUT /api/mascotas/{id}/completar
```

### Regla

`backend/mascotas/router.py`

La función `completar_cuidado` verifica que:

- el cuidado pertenece al usuario autenticado;
- el cuidado existe;
- no se encuentre ya realizado.

Si la acción es válida, cambia el estado del cuidado y genera un evento de historial.

### Datos

`backend/historial/models.py`

El evento queda persistido en la tabla `eventos` con el usuario, mascota, cuidado, tipo, detalle y fecha.

`backend/historial/router.py` consulta únicamente los eventos del usuario autenticado y los ordena del más reciente al más antiguo.

El frontend obtiene estos datos desde:

`frontend/lib/features/historial/services/historial_service.dart`

y los muestra en:

`frontend/lib/features/historial/screens/historial_screen.dart`

## Impacto para la Tarea 5

La Tarea 5 pide agregar una relación que actualmente no existe:

**Asignar un responsable a un cuidado y permitir marcarlo como realizado.**

Actualmente los cuidados pertenecen a un usuario, pero no tienen un responsable asignado de forma independiente.

Para implementarlo será necesario modificar:

- `backend/mascotas/models.py`: agregar la relación entre el cuidado y un usuario responsable, por ejemplo `responsable_id`.
- `backend/mascotas/schemas.py`: permitir enviar y devolver el responsable del cuidado.
- `backend/mascotas/router.py`: agregar la lógica para asignar o cambiar responsable y conservar la acción existente de marcar como realizado.
- `frontend/lib/features/mascotas/screens/`: permitir seleccionar un responsable y mostrar quién está asignado al cuidado.
- Pruebas del backend para comprobar que la asignación se guarda correctamente.

La relación debe persistir en la base de datos, por lo que después de recargar la aplicación o volver a iniciar sesión el responsable asignado debe continuar asociado al cuidado.

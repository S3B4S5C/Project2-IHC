# Clase 20 · Mejora pequeña de navegación

**Proyecto:** Mascota al Día  
**Repositorio:** https://github.com/S3B4S5C/Project2-IHC  
**Integrantes:** [Completar nombres del equipo]  
**Fecha:** 05/11/2026

## 1. Identificar

**Problema:** en el panel, la acción para registrar un cuidado se encontraba en un botón con solo el ícono `+`. Al abrirlo, aparecía el título «Nueva Mascota» y el botón «Guardar Mascota», aunque la tarea es registrar un cuidado para una mascota.

**Tarea difícil de encontrar:** agregar un cuidado para una mascota desde el panel principal.

## 2. Proponer

**Estructura anterior:**

```text
Panel de cuidados
  └── [+] → Nueva Mascota → Guardar Mascota
```

**Estructura propuesta:**

```text
Panel de cuidados
  └── [ + Agregar cuidado ] → Agregar cuidado → Guardar cuidado
```

**Decisión:** mantener la ubicación y el flujo existentes, pero mostrar el nombre de la acción desde el panel y usar la misma etiqueta en la pantalla y en el botón de confirmación. Así no se agregan pantallas ni pasos nuevos.

## 3. Implementar

- `frontend/lib/features/mascotas/screens/home_screen.dart`: botón flotante extendido con ícono y texto «Agregar cuidado», además de actualizar la indicación del estado vacío.
- `frontend/lib/features/mascotas/screens/agregar_mascota_screen.dart`: título «Agregar cuidado» y acción «Guardar cuidado».
- No se modificó el backend, la persistencia ni la lógica de creación.

**Commit de implementación:** [`0a82370`](https://github.com/S3B4S5C/Project2-IHC/commit/0a823706deba58e4669b70cd8370eb00df93c9de).

## 4. Prueba de descubrimiento de la función

**Consigna sin dar rutas ni indicaciones:** «Desde el panel, busca dónde registrar un nuevo cuidado para una mascota».

**Escenario ilustrativo simulado; no se realizó una prueba presencial con otra persona.**

| Momento | Resultado simulado | Duda o dificultad |
| --- | --- | --- |
| Antes | Con ayuda | El símbolo `+` no especificaba qué se agregaba y «Nueva Mascota» sugería otra tarea. |
| Después | Sin ayuda | La persona localizaría «Agregar cuidado» desde el panel y reconocería «Guardar cuidado» al finalizar. |

**Ajuste aplicado:** hacer visible el nombre de la acción y mantenerlo consistente en todo el recorrido.

## 5. Evidencia antes y después

| Elemento | Antes | Después |
| --- | --- | --- |
| Acceso desde el panel | Ícono `+` | Ícono `+` y texto «Agregar cuidado» |
| Título del formulario | «Nueva Mascota» | «Agregar cuidado» |
| Botón principal del formulario | «Guardar Mascota» | «Guardar cuidado» |
| Estado vacío | «Toca +» | «Usa Agregar cuidado» |

**Referencias de código:** [panel](https://github.com/S3B4S5C/Project2-IHC/blob/main/frontend/lib/features/mascotas/screens/home_screen.dart) y [formulario](https://github.com/S3B4S5C/Project2-IHC/blob/main/frontend/lib/features/mascotas/screens/agregar_mascota_screen.dart).

No se adjuntaron capturas. La comparación se documenta con las etiquetas anteriores y actuales y el diff del commit. Se verificó el cambio en el código, pero no se ejecutó una prueba de usuario externa ni una ejecución Flutter desde este entorno.

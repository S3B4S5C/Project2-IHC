import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants.dart';
import '../../auth/screens/login_screen.dart';

// IMPORTAMOS LA NUEVA PANTALLA
import 'agregar_mascota_screen.dart';
import 'editar_mascota_screen.dart';
import '../../historial/screens/historial_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _nombreUsuario = "Cargando...";
  List<dynamic> _mascotas = [];
  bool _cargando = true;
  bool _errorCarga = false; // true si no se pudo traer la lista
  final _busquedaController = TextEditingController();

  // Variables para los filtros
  String _filtroNombre = "";
  bool? _filtroEstado; // null: Todos, false: Pendientes, true: Realizados
  String? _filtroCuidado;
  DateTime? _filtroFechaInicio;
  DateTime? _filtroFechaFin;
  String? _filtroFechaLabel; // NUEVO: Para mostrar en el Chip
  String? _filtroFechaTipo; // Opción elegida en el desplegable de fecha

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
    _cargarMascotas();
  }

  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombreUsuario = prefs.getString('usuario_nombre') ?? 'Usuario';
    });
  }

  static const _tiposCuidado = ["Vacuna", "Desparasitación", "Control", "Baño"];

  // Cuántos filtros de "Más filtros" están activos (para mostrarlo en el botón)
  int _filtrosSecundariosActivos() {
    int total = 0;
    if (_filtroCuidado != null) total++;
    if (_filtroFechaInicio != null) total++;
    return total;
  }

  void _cambiarEstado(bool? estado) {
    setState(() => _filtroEstado = estado);
    _cargarMascotas();
  }

  // Hick: el tipo de cuidado y la fecha se usan poco, así que se agrupan
  // en una hoja aparte en vez de competir con el estado en el panel.
  void _abrirMasFiltros() {
    String? cuidado = _filtroCuidado;
    String? fechaTipo = _filtroFechaTipo;
    DateTime? inicio = _filtroFechaInicio;
    DateTime? fin = _filtroFechaFin;
    String? fechaLabel = _filtroFechaLabel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Future<void> elegirFecha(String? tipo) async {
            final hoy = DateTime.now();
            if (tipo == '7_dias') {
              inicio = hoy;
              fin = hoy.add(Duration(days: 7));
              fechaLabel = "Próximos 7 días";
            } else if (tipo == 'este_mes') {
              inicio = DateTime(hoy.year, hoy.month, 1);
              fin = DateTime(hoy.year, hoy.month + 1, 0);
              fechaLabel = "Este mes";
            } else if (tipo == 'personalizado') {
              final DateTimeRange? rango = await showDateRangePicker(
                context: ctx,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (rango == null) return; // Si cancela, no cambia nada
              inicio = rango.start;
              fin = rango.end;
              fechaLabel =
                  "${rango.start.day}/${rango.start.month} - ${rango.end.day}/${rango.end.month}";
            } else {
              inicio = null;
              fin = null;
              fechaLabel = null;
            }
            setSheet(() => fechaTipo = tipo);
          }

          Widget opcion(String texto, bool seleccionada, VoidCallback alTocar) {
            return ChoiceChip(
              label: Text(texto),
              selected: seleccionada,
              onSelected: (_) => alTocar(),
            );
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Más filtros",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text("Tipo de cuidado",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      opcion("Todos", cuidado == null,
                          () => setSheet(() => cuidado = null)),
                      for (final tipo in _tiposCuidado)
                        opcion(tipo, cuidado == tipo,
                            () => setSheet(() => cuidado = tipo)),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text("Fecha", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      opcion("Cualquier fecha", fechaTipo == null,
                          () => elegirFecha(null)),
                      opcion("Próximos 7 días", fechaTipo == '7_dias',
                          () => elegirFecha('7_dias')),
                      opcion("Este mes", fechaTipo == 'este_mes',
                          () => elegirFecha('este_mes')),
                      opcion(
                        fechaTipo == 'personalizado'
                            ? fechaLabel!
                            : "Elegir rango...",
                        fechaTipo == 'personalizado',
                        () => elegirFecha('personalizado'),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheet(() {
                              cuidado = null;
                              fechaTipo = null;
                              inicio = null;
                              fin = null;
                              fechaLabel = null;
                            });
                          },
                          child: Text("Limpiar"),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _filtroCuidado = cuidado;
                              _filtroFechaTipo = fechaTipo;
                              _filtroFechaInicio = inicio;
                              _filtroFechaFin = fin;
                              _filtroFechaLabel = fechaLabel;
                            });
                            _cargarMascotas();
                          },
                          child: Text("Aplicar"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _hayFiltros() {
    return _filtroNombre.isNotEmpty ||
        _filtroEstado != null ||
        _filtroCuidado != null ||
        _filtroFechaInicio != null;
  }

  Future<void> _cargarMascotas() async {
    setState(() {
      _cargando = true;
      _errorCarga = false;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    // Construimos los parámetros de la URL
    List<String> queryParams = [];
    if (_filtroNombre.isNotEmpty) queryParams.add("nombre=$_filtroNombre");
    if (_filtroEstado != null) queryParams.add("estado=$_filtroEstado");
    if (_filtroCuidado != null && _filtroCuidado!.isNotEmpty)
      queryParams.add("cuidado=$_filtroCuidado");
    if (_filtroFechaInicio != null)
      queryParams.add(
        "fecha_inicio=${_filtroFechaInicio!.toIso8601String().split('T')[0]}",
      );
    if (_filtroFechaFin != null)
      queryParams.add(
        "fecha_fin=${_filtroFechaFin!.toIso8601String().split('T')[0]}",
      );

    String queryString = queryParams.isNotEmpty
        ? "?${queryParams.join('&')}"
        : "";

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/mascotas/lista$queryString'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _mascotas = json.decode(response.body);
          _cargando = false;
        });
      } else {
        setState(() {
          _cargando = false;
          _errorCarga = true;
        });
      }
    } catch (e) {
      setState(() {
        _cargando = false;
        _errorCarga = true;
      });
    }
  }

  Future<void> _marcarComoRealizado(Map<String, dynamic> mascota) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/mascotas/${mascota['id']}/completar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Cambiamos solo esta tarjeta para que siga visible en su lugar
        setState(() => mascota['estado'] = true);
        _mostrarMensaje(
          '${mascota['cuidado']} de ${mascota['nombre']} marcado como realizado.',
          Colors.green,
        );
      } else {
        _mostrarMensaje(
          'No se pudo marcar como realizado. Inténtalo de nuevo.',
          Colors.red,
        );
      }
    } catch (e) {
      _mostrarMensaje(
        'No se pudo conectar con el servidor. Revisa tu conexión.',
        Colors.red,
      );
    }
  }

  void _confirmarRealizado(Map<String, dynamic> mascota) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text("¿Marcar como realizado?"),
        content: Text(
          "${mascota['cuidado']} de ${mascota['nombre']}. Después ya no podrás editarlo ni reprogramarlo.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _marcarComoRealizado(mascota);
            },
            child: Text("Marcar"),
          ),
        ],
      ),
    );
  }

  void _mostrarMensaje(String mensaje, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: color),
    );
  }

  void _confirmarCerrarSesion() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text("¿Cerrar sesión?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cerrarSesion(context);
            },
            child: Text("Cerrar sesión"),
          ),
        ],
      ),
    );
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('usuario_nombre');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _eliminarMascota(int idMascota) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/mascotas/eliminar/$idMascota'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _mostrarMensaje('Registro eliminado correctamente.', Colors.redAccent);
        _cargarMascotas();
      } else {
        _mostrarMensaje('No se pudo eliminar. Inténtalo de nuevo.', Colors.red);
      }
    } catch (e) {
      _mostrarMensaje(
        'No se pudo conectar con el servidor. Revisa tu conexión.',
        Colors.red,
      );
    }
  }

  void _confirmarEliminar(int idMascota) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text("¿Eliminar registro?"),
        content: Text("Esta acción no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _eliminarMascota(idMascota);
            },
            child: Text("Eliminar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Mascota al Día - Panel"),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          // Fitts: botón con texto e ícono, más grande que un ícono solo
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HistorialScreen()),
              );
            },
            icon: Icon(Icons.history),
            label: Text("Historial"),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: "Cerrar sesión",
            onPressed: _confirmarCerrarSesion,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
            child: Text(
              "Hola, $_nombreUsuario",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),

          // --- 1. BARRA DE BÚSQUEDA ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _busquedaController,
              onChanged: (value) => _filtroNombre = value,
              onSubmitted: (_) => _cargarMascotas(),
              decoration: InputDecoration(
                labelText: 'Buscar mascota por nombre...',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _cargarMascotas,
                ),
              ),
            ),
          ),

          // --- 2. FILTRO FRECUENTE: ESTADO (siempre visible) ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool?>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: null, label: Text("Todos")),
                  ButtonSegment(value: false, label: Text("Pendientes")),
                  ButtonSegment(value: true, label: Text("Realizados")),
                ],
                selected: {_filtroEstado},
                onSelectionChanged: (seleccion) =>
                    _cambiarEstado(seleccion.first),
              ),
            ),
          ),

          // --- 3. MÁS FILTROS + FILTROS ACTIVOS (Chips con la "X") ---
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8.0,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _abrirMasFiltros,
                  icon: Icon(Icons.tune),
                  label: Text(
                    _filtrosSecundariosActivos() > 0
                        ? "Más filtros (${_filtrosSecundariosActivos()})"
                        : "Más filtros",
                  ),
                ),
                if (_filtroNombre.isNotEmpty)
                  Chip(
                    label: Text('Nombre: $_filtroNombre'),
                    deleteIcon: Icon(Icons.close, size: 18),
                    onDeleted: () {
                      _busquedaController.clear();
                      setState(() => _filtroNombre = "");
                      _cargarMascotas();
                    },
                  ),
                if (_filtroCuidado != null && _filtroCuidado!.isNotEmpty)
                  Chip(
                    label: Text('Cuidado: $_filtroCuidado'),
                    deleteIcon: Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() => _filtroCuidado = null);
                      _cargarMascotas();
                    },
                  ),
                if (_filtroFechaInicio != null)
                  Chip(
                    label: Text(_filtroFechaLabel ?? 'Fechas específicas'),
                    deleteIcon: Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _filtroFechaInicio = null;
                        _filtroFechaFin = null;
                        _filtroFechaLabel = null;
                        _filtroFechaTipo = null;
                      });
                      _cargarMascotas();
                    },
                  ),
              ],
            ),
          ),

          Divider(color: Colors.grey),

          // --- 4. LISTADO Y MENSAJE DE ESTADO VACÍO ---
          Expanded(
            child: _cargando
                ? Center(child: CircularProgressIndicator(color: Colors.black))
                : _errorCarga
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "No se pudo cargar tus cuidados. Revisa tu conexión.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _cargarMascotas,
                            child: Text("Reintentar"),
                          ),
                        ],
                      ),
                    ),
                  )
                : _mascotas.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _hayFiltros()
                            ? "No se encontraron cuidados con estos filtros."
                            : "Aún no tienes cuidados registrados. Toca + para agregar el primero.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _mascotas.length,
                    itemBuilder: (context, index) {
                      final mascota = _mascotas[index];
                      final bool estaRealizado = mascota['estado'];
                      final bool puedeEditar = mascota['puede_editar'] ?? true;

                      return Card(
                        color: Colors.grey[200],
                        margin: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.grey, width: 1),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '"${mascota['nombre']}" · ${mascota['tipo']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '${mascota['cuidado']} · ${mascota['fecha']}',
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Responsable: ${mascota['responsable_nombre'] ?? 'Sin asignar'}',
                              ),
                              SizedBox(height: 12),

                              if (!estaRealizado)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                    "Pendiente",
                                    style: TextStyle(
                                      color: Colors.orange[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (!estaRealizado)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () =>
                                        _confirmarRealizado(mascota),
                                    child: Text("Marcar como realizado"),
                                  ),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                    "✓ Realizado",
                                    style: TextStyle(
                                      color: Colors.green[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                              SizedBox(height: 8),

                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: estaRealizado || !puedeEditar
                                            ? Colors.grey[300]
                                            : Colors.white,
                                        foregroundColor: estaRealizado || !puedeEditar
                                            ? Colors.grey[600]
                                            : Colors.black,
                                        side: BorderSide(color: Colors.grey),
                                        elevation: 0,
                                      ),
                                      onPressed: puedeEditar ? () async {
                                        if (estaRealizado) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    "No puedes editar un cuidado que ya fue realizado.",
                                                  ),
                                                ),
                                              );
                                        } else {
                                          final resultado =
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      EditarMascotaScreen(
                                                        mascota: mascota,
                                                      ),
                                                ),
                                              );
                                          if (resultado == true)
                                            _cargarMascotas();
                                        }
                                      } : null,
                                      child: Text("Editar"),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red[100],
                                        foregroundColor: Colors.red[900],
                                        elevation: 0,
                                      ),
                                      onPressed: puedeEditar
                                          ? () => _confirmarEliminar(mascota['id'])
                                          : null,
                                      child: Text("Eliminar"),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AgregarMascotaScreen()),
          );
          if (resultado == true) {
            _cargarMascotas();
          }
        },
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        tooltip: "Agregar cuidado",
        child: Icon(Icons.add),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../services/historial_service.dart';

class HistorialScreen extends StatefulWidget {
  @override
  _HistorialScreenState createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final _historialService = HistorialService();
  List<dynamic> _eventos = [];
  bool _cargando = true;
  bool _errorCarga = false;
  String? _filtroTipo; // null: Todos, "realizado" o "reprogramado"

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() {
      _cargando = true;
      _errorCarga = false;
    });
    final eventos = await _historialService.obtenerHistorial(_filtroTipo);
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (eventos == null) {
        _errorCarga = true;
      } else {
        _eventos = eventos;
      }
    });
  }

  // "2026-10-19T18:40:12" -> "19/10/2026 18:40"
  String _formatearFecha(String fechaHora) {
    final f = DateTime.parse(fechaHora);
    final hora = f.hour.toString().padLeft(2, '0');
    final minuto = f.minute.toString().padLeft(2, '0');
    return "${f.day}/${f.month}/${f.year} $hora:$minuto";
  }

  Widget _mensajeVacio() {
    String texto;
    if (_filtroTipo == 'realizado') {
      texto = "Aún no marcaste ningún cuidado como realizado.";
    } else if (_filtroTipo == 'reprogramado') {
      texto = "Aún no reprogramaste ningún cuidado.";
    } else {
      texto =
          "Todavía no hay movimientos. Cuando marques un cuidado como realizado o le cambies la fecha, aparecerá aquí.";
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Volver a mis cuidados"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaEvento(Map<String, dynamic> evento) {
    final bool esRealizado = evento['tipo'] == 'realizado';
    // Lo primero que se lee es qué pasó y con qué mascota
    final String titulo = esRealizado
        ? "${evento['cuidado']} de ${evento['mascota_nombre']}: realizado"
        : "${evento['cuidado']} de ${evento['mascota_nombre']}: reprogramado";

    return Card(
      color: Colors.grey[200],
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey, width: 1),
      ),
      child: ListTile(
        leading: Icon(
          esRealizado ? Icons.check_circle : Icons.event_repeat,
          color: esRealizado ? Colors.green[800] : Colors.blue[800],
        ),
        title: Text(titulo, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          "${evento['detalle']}\nAutor: ${evento['autor_nombre'] ?? 'No registrado'}\nRegistrado el ${_formatearFecha(evento['fecha_hora'])}",
        ),
        isThreeLine: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Historial de cuidados"),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Hick: solo tres opciones para filtrar
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String?>(
                showSelectedIcon: false,
                // Letra un poco más chica para que "Reprogramados" entre en una línea
                style: SegmentedButton.styleFrom(
                  textStyle: TextStyle(fontSize: 13),
                ),
                segments: [
                  ButtonSegment(value: null, label: Text("Todos")),
                  ButtonSegment(value: 'realizado', label: Text("Realizados")),
                  ButtonSegment(
                    value: 'reprogramado',
                    label: Text("Reprogramados"),
                  ),
                ],
                selected: {_filtroTipo},
                onSelectionChanged: (seleccion) {
                  setState(() => _filtroTipo = seleccion.first);
                  _cargarHistorial();
                },
              ),
            ),
          ),
          Expanded(
            child: _cargando
                ? Center(child: CircularProgressIndicator(color: Colors.black))
                : _errorCarga
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "No se pudo cargar el historial. Revisa tu conexión.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _cargarHistorial,
                          child: Text("Reintentar"),
                        ),
                      ],
                    ),
                  )
                : _eventos.isEmpty
                ? _mensajeVacio()
                : RefreshIndicator(
                    onRefresh: _cargarHistorial,
                    child: ListView.builder(
                      itemCount: _eventos.length,
                      itemBuilder: (context, index) =>
                          _tarjetaEvento(_eventos[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

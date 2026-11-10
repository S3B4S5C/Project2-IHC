import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants.dart';

class CompartidosScreen extends StatefulWidget {
  @override
  State<CompartidosScreen> createState() => _CompartidosScreenState();
}

class _CompartidosScreenState extends State<CompartidosScreen> {
  final _correoController = TextEditingController();
  List<Map<String, dynamic>> _invitaciones = [];
  List<Map<String, dynamic>> _administrados = [];
  int? _cuidadoId;
  String _permiso = 'consulta';
  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _correoController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _cabeceras() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + (prefs.getString('jwt_token') ?? ''),
    };
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final headers = await _cabeceras();
      final respuestas = await Future.wait([
        http.get(Uri.parse(AppConstants.baseUrl + '/compartidos/invitaciones'), headers: headers),
        http.get(Uri.parse(AppConstants.baseUrl + '/mascotas/lista'), headers: headers),
      ]);
      if (respuestas.any((respuesta) => respuesta.statusCode != 200)) {
        throw Exception('No se pudieron consultar las invitaciones');
      }
      final invitaciones = (jsonDecode(respuestas[0].body) as List).cast<Map<String, dynamic>>();
      final cuidados = (jsonDecode(respuestas[1].body) as List)
          .cast<Map<String, dynamic>>()
          .where((cuidado) => cuidado['puede_administrar_accesos'] == true)
          .toList();
      if (!mounted) return;
      setState(() {
        _invitaciones = invitaciones;
        _administrados = cuidados;
        if (!cuidados.any((cuidado) => cuidado['id'] == _cuidadoId)) {
          _cuidadoId = cuidados.isEmpty ? null : cuidados.first['id'] as int;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudieron cargar los cuidados compartidos.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mensaje(String texto, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: error ? Colors.red : Colors.green),
    );
  }

  Future<void> _accion(String metodo, String ruta, [Map<String, dynamic>? datos]) async {
    if (_guardando) return;
    setState(() => _guardando = true);
    try {
      final uri = Uri.parse(AppConstants.baseUrl + '/compartidos' + ruta);
      final headers = await _cabeceras();
      late http.Response respuesta;
      if (metodo == 'PATCH') {
        respuesta = await http.patch(uri, headers: headers, body: jsonEncode(datos));
      } else {
        respuesta = await http.post(uri, headers: headers, body: jsonEncode(datos ?? {}));
      }
      if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
        final detalle = jsonDecode(respuesta.body);
        throw Exception(detalle is Map ? detalle['detail'].toString() : 'No se pudo guardar');
      }
      _correoController.clear();
      await _cargar();
      _mensaje('Cambios guardados.');
    } catch (error) {
      _mensaje(error.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _invitar() {
    final correo = _correoController.text.trim();
    if (_cuidadoId == null || correo.isEmpty) {
      _mensaje('Selecciona un cuidado e ingresa el correo del invitado.', error: true);
      return;
    }
    _accion('POST', '/invitar', {
      'mascota_id': _cuidadoId,
      'invitado_correo': correo,
      'permiso': _permiso,
    });
  }

  String _estado(String estado) {
    switch (estado) {
      case 'pendiente': return 'Pendiente de respuesta';
      case 'aceptada': return 'Aceptada';
      case 'rechazada': return 'Rechazada';
      case 'revocada': return 'Acceso revocado';
      default: return estado;
    }
  }

  Widget _tarjeta(Map<String, dynamic> invitacion, {required bool recibida}) {
    final id = invitacion['id'] as int;
    final estado = invitacion['estado'] as String;
    final activa = estado == 'pendiente' || estado == 'aceptada';
    final puedeAdministrar = invitacion['puede_administrar'] == true;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (invitacion['mascota_nombre'] ?? '').toString() +
                  ' · ' + (invitacion['cuidado'] ?? '').toString(),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(recibida
                ? 'Invita: ' + invitacion['invitador_nombre'].toString()
                : 'Invitado: ' + invitacion['invitado_nombre'].toString() +
                    ' (' + invitacion['invitado_correo'].toString() + ')'),
            Text('Estado: ' + _estado(estado)),
            Text('Permiso: ' + (invitacion['permiso'] == 'gestion' ? 'Gestión' : 'Consulta')),
            if (recibida && estado == 'pendiente')
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _guardando ? null : () => _accion('POST', '/' + id.toString() + '/responder', {'aceptar': true}),
                    child: Text('Aceptar'),
                  ),
                  OutlinedButton(
                    onPressed: _guardando ? null : () => _accion('POST', '/' + id.toString() + '/responder', {'aceptar': false}),
                    child: Text('Rechazar'),
                  ),
                ],
              ),
            if (!recibida && puedeAdministrar && activa)
              Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DropdownButton<String>(
                    value: invitacion['permiso'] as String,
                    items: [
                      DropdownMenuItem(value: 'consulta', child: Text('Consulta')),
                      DropdownMenuItem(value: 'gestion', child: Text('Gestión')),
                    ],
                    onChanged: _guardando
                        ? null
                        : (valor) {
                            if (valor != null) {
                              _accion('PATCH', '/' + id.toString() + '/permiso', {'permiso': valor});
                            }
                          },
                  ),
                  OutlinedButton(
                    onPressed: _guardando ? null : () => _accion('POST', '/' + id.toString() + '/revocar'),
                    child: Text('Revocar acceso'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recibidas = _invitaciones.where((invitacion) => invitacion['recibida'] == true).toList();
    final enviadas = _invitaciones.where((invitacion) => invitacion['recibida'] != true).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Cuidados compartidos'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!),
                    OutlinedButton(onPressed: _cargar, child: Text('Reintentar')),
                  ],
                ))
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text('Invitar a un cuidado', style: Theme.of(context).textTheme.titleMedium),
                      SizedBox(height: 4),
                      Text('Solo el responsable del cuidado administra sus accesos.'),
                      if (_administrados.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text('No tienes cuidados a tu cargo para compartir.'),
                        )
                      else ...[
                        SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: _cuidadoId,
                          isExpanded: true,
                          decoration: InputDecoration(labelText: 'Cuidado', border: OutlineInputBorder()),
                          items: _administrados.map((cuidado) => DropdownMenuItem<int>(
                            value: cuidado['id'] as int,
                            child: Text(cuidado['nombre'].toString() + ' · ' + cuidado['cuidado'].toString()),
                          )).toList(),
                          onChanged: _guardando ? null : (valor) => setState(() => _cuidadoId = valor),
                        ),
                        SizedBox(height: 12),
                        TextField(
                          controller: _correoController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Correo de usuario registrado',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _permiso,
                          decoration: InputDecoration(labelText: 'Permiso', border: OutlineInputBorder()),
                          items: [
                            DropdownMenuItem(value: 'consulta', child: Text('Consulta (solo lectura)')),
                            DropdownMenuItem(value: 'gestion', child: Text('Gestión (editar y realizar)')),
                          ],
                          onChanged: _guardando ? null : (valor) {
                            if (valor != null) setState(() => _permiso = valor);
                          },
                        ),
                        SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _guardando ? null : _invitar,
                          icon: Icon(Icons.person_add_alt_1),
                          label: Text('Enviar invitación'),
                        ),
                      ],
                      Divider(height: 36),
                      Text('Invitaciones recibidas', style: Theme.of(context).textTheme.titleMedium),
                      if (recibidas.isEmpty)
                        Text('No tienes invitaciones.')
                      else
                        ...recibidas.map((invitacion) => _tarjeta(invitacion, recibida: true)),
                      Divider(height: 36),
                      Text('Accesos que administro', style: Theme.of(context).textTheme.titleMedium),
                      if (enviadas.isEmpty)
                        Text('Todavía no enviaste invitaciones.')
                      else
                        ...enviadas.map((invitacion) => _tarjeta(invitacion, recibida: false)),
                    ],
                  ),
                ),
    );
  }
}

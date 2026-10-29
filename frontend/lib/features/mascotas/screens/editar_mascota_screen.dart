import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants.dart';

class EditarMascotaScreen extends StatefulWidget {
  final Map<String, dynamic> mascota;
  EditarMascotaScreen({required this.mascota});
  @override
  _EditarMascotaScreenState createState() => _EditarMascotaScreenState();
}

class _EditarMascotaScreenState extends State<EditarMascotaScreen> {
  late TextEditingController _nombreController;
  late TextEditingController _tipoController;
  late TextEditingController _cuidadoController;
  late TextEditingController _fechaController;
  late TextEditingController _responsableController;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.mascota['nombre']);
    _tipoController = TextEditingController(text: widget.mascota['tipo']);
    _cuidadoController = TextEditingController(text: widget.mascota['cuidado']);
    _fechaController = TextEditingController(text: widget.mascota['fecha']);
    _responsableController = TextEditingController(
      text: widget.mascota['responsable_correo'] ?? '',
    );
  }

  Future<void> _actualizarMascota() async {
    if (_nombreController.text.isEmpty || _fechaController.text.isEmpty) return;

    setState(() => _guardando = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final idMascota = widget.mascota['id'];

    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/mascotas/editar/$idMascota'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          "nombre": _nombreController.text,
          "tipo": _tipoController.text,
          "cuidado": _cuidadoController.text,
          "fecha": _fechaController.text,
          "responsable_correo": _responsableController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cuidado editado y reprogramado correctamente.'),
              backgroundColor: Colors.green,
            ),
          );
        }
        Navigator.pop(context, true); // Retornamos true indicando éxito
      } else {
        // Mostramos el motivo que manda el backend y qué puede hacer la persona
        String motivo = "No se pudo reprogramar el cuidado.";
        try {
          motivo = json.decode(response.body)['detail'];
        } catch (e) {
          // Si la respuesta no trae 'detail' dejamos el mensaje general
        }
        setState(() => _guardando = false);
        _mostrarError("$motivo Revisa la fecha o vuelve a la lista con Cancelar.");
      }
    } catch (e) {
      setState(() => _guardando = false);
      _mostrarError(
        "No se pudo conectar con el servidor. Revisa tu conexión e inténtalo de nuevo.",
      );
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    // Solo se puede reprogramar a partir de mañana (igual que en el backend)
    final hoy = DateTime.now();
    final manana = DateTime(hoy.year, hoy.month, hoy.day + 1);
    DateTime fechaInicial = DateTime.parse(_fechaController.text);
    if (fechaInicial.isBefore(manana)) {
      fechaInicial = manana;
    }

    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: manana,
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (fecha != null) {
      setState(() {
        _fechaController.text =
            "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Editar Mascota"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      // Con scroll para que el teclado no tape el formulario
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Resumen del cuidado con la fecha original, para no tener que recordarla
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border.all(color: Colors.grey),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.mascota['nombre']} · ${widget.mascota['cuidado']}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text('Fecha programada actual: ${widget.mascota['fecha']}'),
                ],
              ),
            ),
            TextField(
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: "Nombre",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _tipoController,
              decoration: InputDecoration(
                labelText: "Tipo",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _cuidadoController,
              decoration: InputDecoration(
                labelText: "Cuidado",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _responsableController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Responsable (correo registrado)",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _fechaController,
              readOnly: true,
              onTap: () => _seleccionarFecha(context),
              decoration: InputDecoration(
                labelText: "Nueva fecha",
                helperText:
                    "Toca para elegir una fecha a partir de mañana.\nSolo los cuidados pendientes se pueden reprogramar.",
                helperMaxLines: 2,
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today, color: Colors.black),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue,
                  foregroundColor: Colors.white,
                ),
                onPressed: _guardando ? null : _actualizarMascota,
                child: Text(_guardando ? "Actualizando..." : "Guardar Cambios"),
              ),
            ),
            SizedBox(height: 12),
            // Salida clara para no guardar una fecha elegida por error
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: BorderSide(color: Colors.grey),
                ),
                onPressed: _guardando
                    ? null
                    : () => Navigator.pop(context, false),
                child: Text("Cancelar"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

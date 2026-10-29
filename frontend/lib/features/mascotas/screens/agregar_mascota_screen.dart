import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants.dart';

class AgregarMascotaScreen extends StatefulWidget {
  @override
  _AgregarMascotaScreenState createState() => _AgregarMascotaScreenState();
}

class _AgregarMascotaScreenState extends State<AgregarMascotaScreen> {
  final _nombreController = TextEditingController();
  final _tipoController = TextEditingController();
  final _cuidadoController = TextEditingController();
  final _fechaController = TextEditingController();
  final _responsableController = TextEditingController();

  bool _guardando = false;

  Future<void> _guardarMascota() async {
    // Avisamos qué campos faltan en vez de no hacer nada
    if (_nombreController.text.trim().isEmpty ||
        _tipoController.text.trim().isEmpty ||
        _cuidadoController.text.trim().isEmpty ||
        _fechaController.text.isEmpty ||
        _responsableController.text.trim().isEmpty) {
      _mostrarMensaje(
        "Completa nombre, tipo, cuidado, fecha y responsable para guardar.",
        Colors.red,
      );
      return;
    }

    setState(() {
      _guardando = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    try {
      // CORRECCIÓN DEL 404: Quitamos la barra final después de mascotas
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/mascotas/crear'),
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        _mostrarMensaje(
          "${_cuidadoController.text} de ${_nombreController.text} guardado para el ${_fechaController.text}.",
          Colors.green,
        );
        if (mounted) Navigator.pop(context, true);
      } else {
        // Mostramos el motivo que manda el backend
        String motivo = "No se pudo guardar el cuidado.";
        try {
          motivo = json.decode(response.body)['detail'].toString();
        } catch (e) {
          // Si no viene 'detail' dejamos el mensaje general
        }
        setState(() {
          _guardando = false;
        });
        _mostrarMensaje(motivo, Colors.red);
      }
    } catch (e) {
      setState(() {
        _guardando = false;
      });
      _mostrarMensaje(
        "No se pudo conectar con el servidor. Revisa tu conexión e inténtalo de nuevo.",
        Colors.red,
      );
    }
  }

  void _mostrarMensaje(String mensaje, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: color),
    );
  }

  // --- FUNCIÓN PARA MOSTRAR EL CALENDARIO ---
  Future<void> _seleccionarFecha(BuildContext context) async {
    // Solo fechas futuras, igual que al editar (a partir de mañana)
    final hoy = DateTime.now();
    final manana = DateTime(hoy.year, hoy.month, hoy.day + 1);

    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: manana,
      firstDate: manana, // Fecha mínima
      lastDate: DateTime(2030), // Fecha máxima
      builder: (context, child) {
        // Le damos tu estilo blanco/negro al calendario
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.lightBlue, // Color del encabezado
              onPrimary: Colors.white, // Texto del encabezado
              onSurface: Colors.black, // Color de los días
            ),
          ),
          child: child!,
        );
      },
    );

    if (fechaSeleccionada != null) {
      // Si eligen una fecha, la formateamos a YYYY-MM-DD sin usar librerías extra
      String anio = fechaSeleccionada.year.toString();
      String mes = fechaSeleccionada.month.toString().padLeft(2, '0');
      String dia = fechaSeleccionada.day.toString().padLeft(2, '0');

      setState(() {
        _fechaController.text = "$anio-$mes-$dia";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Nueva Mascota"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      // Con scroll para que el teclado no tape el formulario
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Llena los datos:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: "Nombre (ej. Luna)",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _tipoController,
              decoration: InputDecoration(
                labelText: "Tipo (ej. perro)",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _cuidadoController,
              decoration: InputDecoration(
                labelText: "Cuidado (ej. vacuna)",
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

            // --- CAMPO DE FECHA CON CALENDARIO ---
            TextField(
              controller: _fechaController,
              readOnly: true, // Evita que se abra el teclado
              onTap: () =>
                  _seleccionarFecha(context), // Abre el calendario al tocar
              decoration: InputDecoration(
                labelText: "Fecha de cuidado",
                helperText: "Toca para elegir una fecha a partir de mañana.",
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
                onPressed: _guardando ? null : _guardarMascota,
                child: _guardando
                    ? Text("Guardando...")
                    : Text("Guardar Mascota"),
              ),
            ),
            SizedBox(height: 12),
            // Igual que en editar: salir sin guardar
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

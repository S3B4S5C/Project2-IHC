import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/auth/screens/login_screen.dart';
import 'features/mascotas/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (const bool.fromEnvironment('E2E_SEMANTICS')) {
    SemanticsBinding.instance.ensureSemantics();
  }
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('jwt_token');

  runApp(MyApp(isLoggedIn: token != null && token.isNotEmpty));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mascota al Día',
      theme: ThemeData(primarySwatch: Colors.blue),
      // Si hay token va directo al Home (ruta privada), sino al Login (ruta pública)
      home: isLoggedIn ? HomeScreen() : LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

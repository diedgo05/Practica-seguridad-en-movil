import 'dart:io' show Platform, exit;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_windowmanager_plus/flutter_windowmanager_plus.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const SecureLoginApp());
}

class SecureLoginApp extends StatelessWidget {
  const SecureLoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Login Seguro',
      // Estilo minimalista y profesional
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isCheckingSecurity = false;
  bool _isFakeGpsDetected = false;

  // Variable para el Modo Demostrativo
  bool _demoFakeGpsActive = false;

  @override
  void initState() {
    super.initState();
    _secureScreen();
  }

  Future<void> _secureScreen() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await FlutterWindowManagerPlus.addFlags(
          FlutterWindowManagerPlus.FLAG_SECURE,
        );
      } catch (e) {
        debugPrint('No se pudo aplicar FLAG_SECURE: $e');
      }
    }
  }

  Future<void> _unsecureScreen() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await FlutterWindowManagerPlus.clearFlags(
          FlutterWindowManagerPlus.FLAG_SECURE,
        );
      } catch (e) {
        debugPrint('No se pudo limpiar FLAG_SECURE: $e');
      }
    }
  }

  Future<void> _handleLoginAttempt() async {
    setState(() {
      _isCheckingSecurity = true;
    });

    // 1. Evaluación del Modo Demostrativo
    if (_demoFakeGpsActive) {
      await Future.delayed(const Duration(seconds: 1)); // Simular tiempo de carga
      setState(() {
        _isFakeGpsDetected = true;
        _isCheckingSecurity = false;
      });
      return;
    }

    // 2. Evaluación Real con Geolocator
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorSnackBar('Debes activar el GPS para iniciar sesión.');
      setState(() => _isCheckingSecurity = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _showErrorSnackBar('Permisos de ubicación denegados.');
        setState(() => _isCheckingSecurity = false);
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (position.isMocked) {
        setState(() {
          _isFakeGpsDetected = true;
          _isCheckingSecurity = false;
        });
      } else {
        // Lógica de éxito real del login
        setState(() => _isCheckingSecurity = false);
        _showSuccessDialog();
      }
    } catch (e) {
      _showErrorSnackBar('Error al verificar la seguridad del dispositivo.');
      setState(() => _isCheckingSecurity = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Acceso Concedido'),
        content: const Text('Entorno seguro verificado. Sesión iniciada.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  // --- INTERFAZ DE USUARIO ---
  @override
  void dispose() {
    _unsecureScreen();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pantalla de Bloqueo si se detecta Fake GPS (Real o Demo)
    if (_isFakeGpsDetected) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acceso Restringido'), centerTitle: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gpp_bad, size: 80, color: Colors.redAccent),
                const SizedBox(height: 20),
                const Text(
                  'Dispositivo no seguro.\nSe detectó una ubicación simulada.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text('Cerrar Aplicación'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (Platform.isAndroid) {
                      SystemNavigator.pop();
                    } else {
                      exit(0);
                    }
                  },
                ),
                // Botón extra para reiniciar el estado durante el desarrollo
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isFakeGpsDetected = false;
                      _demoFakeGpsActive = false; // Apagar el demo al regresar
                    });
                  },
                  child: const Text('Volver al Login (Solo Desarrollo)'),
                )
              ],
            ),
          ),
        ),
      );
    }

    // Pantalla de Login Normal
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acceso Seguro'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_outlined, size: 64, color: Colors.blueGrey),
              const SizedBox(height: 32),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Usuario',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              const TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24),

              // Botón de Inicio de Sesión
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isCheckingSecurity ? null : _handleLoginAttempt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                  child: _isCheckingSecurity
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Iniciar Sesión', style: TextStyle(fontSize: 16)),
                ),
              ),

              const Spacer(),

              // Control Demostrativo (Minimalista)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Modo Demo: Fake GPS',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Switch(
                      value: _demoFakeGpsActive,
                      activeColor: Colors.redAccent,
                      onChanged: (value) {
                        setState(() {
                          _demoFakeGpsActive = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ============================================================
// PQEXPRESS - Pantalla de Login
// Formulario de inicio de sesión
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores de texto
  final _usuarioController = TextEditingController();
  final _claveController = TextEditingController();
  
  // Key del formulario para validación
  final _formKey = GlobalKey<FormState>();
  
  // Estado de visibilidad de contraseña
  bool _mostrarClave = false;
  
  // Estado de carga local
  bool _cargando = false;

  @override
  void dispose() {
    _usuarioController.dispose();
    _claveController.dispose();
    super.dispose();
  }

  /// Maneja el proceso de login
  Future<void> _iniciarSesion() async {
    // Validar formulario
    if (!_formKey.currentState!.validate()) return;

    // Ocultar teclado
    FocusScope.of(context).unfocus();

    setState(() => _cargando = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Intentar login
    final exito = await authProvider.login(
      _usuarioController.text.trim(),
      _claveController.text,
      dispositivo: 'Flutter App - ${Theme.of(context).platform.name}',
    );

    setState(() => _cargando = false);

    if (exito && mounted) {
      // Navegar a home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (mounted) {
      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMensaje ?? 'Error al iniciar sesión'),
          backgroundColor: ColoresApp.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: DecoracionesApp.gradientePrimario,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  _buildLogo(),
                  
                  const SizedBox(height: 40),
                  
                  // Tarjeta de formulario
                  _buildFormulario(),
                  
                  const SizedBox(height: 24),
                  
                  // Información de prueba
                  _buildInfoPrueba(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            gradient: ColoresApp.gradienteSecundario,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: ColoresApp.secundario.withAlpha(100),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.rocket_launch_rounded,
            size: 55,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'PQExpress',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(40),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '✨ Entregas Rápidas y Seguras',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormulario() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: ColoresApp.primario.withAlpha(30),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.badge_rounded, color: ColoresApp.primario, size: 28),
                const SizedBox(width: 10),
                const Text(
                  'Portal del Repartidor',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ColoresApp.textoOscuro,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Campo de usuario
            TextFormField(
              controller: _usuarioController,
              decoration: const InputDecoration(
                labelText: 'Usuario',
                hintText: 'Ingresa tu usuario',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              validator: (valor) {
                if (valor == null || valor.isEmpty) {
                  return 'Por favor ingresa tu usuario';
                }
                if (valor.length < 3) {
                  return 'El usuario debe tener al menos 3 caracteres';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Campo de contraseña
            TextFormField(
              controller: _claveController,
              obscureText: !_mostrarClave,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                hintText: 'Ingresa tu contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _mostrarClave ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _mostrarClave = !_mostrarClave);
                  },
                ),
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _iniciarSesion(),
              validator: (valor) {
                if (valor == null || valor.isEmpty) {
                  return 'Por favor ingresa tu contraseña';
                }
                if (valor.length < 4) {
                  return 'La contraseña debe tener al menos 4 caracteres';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Botón de login
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _cargando ? null : _iniciarSesion,
                child: _cargando
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'INICIAR SESIÓN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPrueba() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white.withOpacity(0.9),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Credenciales de prueba:',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Usuario: repartidor1\nContraseña: 123456',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

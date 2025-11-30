// ============================================================
// PQEXPRESS - Provider de Autenticación
// Gestiona el estado de la sesión del usuario
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';

/// Estados posibles de autenticación
enum EstadoAuth {
  inicial,       // Estado inicial, verificando sesión
  autenticado,   // Usuario con sesión válida
  noAutenticado, // Sin sesión o sesión inválida
  cargando,      // Procesando login/logout
  error,         // Error en la autenticación
}

/// Provider para gestionar la autenticación
class AuthProvider with ChangeNotifier {
  // Servicio de API
  final ApiService _apiService = ApiService();
  
  // Estado actual
  EstadoAuth _estado = EstadoAuth.inicial;
  
  // Usuario autenticado
  Usuario? _usuario;
  
  // Token de sesión
  String? _token;
  
  // Mensaje de error si aplica
  String? _errorMensaje;

  // Keys para SharedPreferences
  static const String _keyToken = 'pqexpress_token';
  static const String _keyUsuario = 'pqexpress_usuario';

  // Getters
  EstadoAuth get estado => _estado;
  Usuario? get usuario => _usuario;
  String? get token => _token;
  String? get errorMensaje => _errorMensaje;
  bool get estaAutenticado => _estado == EstadoAuth.autenticado;
  bool get estaCargando => _estado == EstadoAuth.cargando;
  ApiService get apiService => _apiService;

  /// Constructor - intenta recuperar sesión guardada
  AuthProvider() {
    _inicializar();
  }

  /// Inicializa el provider verificando sesión guardada
  Future<void> _inicializar() async {
    _estado = EstadoAuth.inicial;
    notifyListeners();

    try {
      // Intentar recuperar token guardado
      final prefs = await SharedPreferences.getInstance();
      final tokenGuardado = prefs.getString(_keyToken);

      if (tokenGuardado == null) {
        _estado = EstadoAuth.noAutenticado;
        notifyListeners();
        return;
      }

      // Validar token con el servidor
      _apiService.setToken(tokenGuardado);
      final esValido = await _apiService.validarToken(tokenGuardado);

      if (esValido) {
        // Token válido, obtener perfil
        _token = tokenGuardado;
        _usuario = await _apiService.obtenerPerfil();
        _estado = EstadoAuth.autenticado;
      } else {
        // Token inválido, limpiar
        await _limpiarSesion();
        _estado = EstadoAuth.noAutenticado;
      }
    } catch (e) {
      await _limpiarSesion();
      _estado = EstadoAuth.noAutenticado;
    }

    notifyListeners();
  }

  /// Inicia sesión con credenciales
  Future<bool> login(String usuario, String clave, {String? dispositivo}) async {
    _estado = EstadoAuth.cargando;
    _errorMensaje = null;
    notifyListeners();

    try {
      // Llamar a la API
      final respuesta = await _apiService.login(usuario, clave, dispositivo: dispositivo);

      // Guardar datos
      _token = respuesta.token;
      _usuario = respuesta.usuario;
      
      // Persistir en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, _token!);

      _estado = EstadoAuth.autenticado;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMensaje = e.toString();
      _estado = EstadoAuth.error;
      notifyListeners();
      return false;
    }
  }

  /// Cierra la sesión actual
  Future<void> logout() async {
    _estado = EstadoAuth.cargando;
    notifyListeners();

    try {
      // Intentar cerrar sesión en el servidor
      await _apiService.logout();
    } catch (e) {
      // Ignorar errores de logout
      debugPrint('Error en logout: $e');
    }

    // Limpiar datos locales siempre
    await _limpiarSesion();
    
    _estado = EstadoAuth.noAutenticado;
    notifyListeners();
  }

  /// Limpia todos los datos de sesión
  Future<void> _limpiarSesion() async {
    _token = null;
    _usuario = null;
    _apiService.setToken(null);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUsuario);
  }

  /// Reintenta la autenticación después de un error
  void reintentar() {
    _errorMensaje = null;
    _estado = EstadoAuth.noAutenticado;
    notifyListeners();
  }

  /// Verifica si la sesión sigue siendo válida
  Future<bool> verificarSesion() async {
    if (_token == null) return false;

    try {
      final esValido = await _apiService.validarToken(_token!);
      if (!esValido) {
        await logout();
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Actualiza el perfil del usuario desde el servidor
  Future<void> actualizarPerfil() async {
    if (_token == null) return;

    try {
      _usuario = await _apiService.obtenerPerfil();
      notifyListeners();
    } catch (e) {
      debugPrint('Error al actualizar perfil: $e');
    }
  }
}

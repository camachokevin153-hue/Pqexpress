// ============================================================
// PQEXPRESS - Servicio de API
// Gestiona todas las llamadas HTTP al backend
// ============================================================

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/usuario.dart';
import '../models/envio.dart';
import '../models/confirmacion_entrega.dart';

/// Excepción personalizada para errores de API
class ApiException implements Exception {
  final String mensaje;
  final int? codigoEstatus;
  final String? codigoError;

  ApiException(this.mensaje, {this.codigoEstatus, this.codigoError});

  @override
  String toString() => mensaje;
}

/// Servicio principal para comunicación con el backend
class ApiService {
  // URL base del backend
  final String _baseUrl;
  
  // Token de autenticación actual
  String? _token;

  ApiService({String? baseUrl}) : _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  /// Configura el token de autenticación
  void setToken(String? token) {
    _token = token;
  }

  /// Obtiene el token actual
  String? get token => _token;

  /// Headers con autenticación
  Map<String, String> get _headersConAuth {
    final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  /// Procesa la respuesta HTTP y maneja errores
  dynamic _procesarRespuesta(http.Response respuesta) {
    final cuerpo = respuesta.body.isNotEmpty 
        ? jsonDecode(respuesta.body) 
        : null;

    if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
      return cuerpo;
    }

    // Manejar errores según código de estado
    String mensaje = 'Error desconocido';
    String? codigo;

    if (cuerpo != null && cuerpo is Map) {
      mensaje = cuerpo['detalle'] ?? cuerpo['detail'] ?? 'Error del servidor';
      codigo = cuerpo['codigo']?.toString();
    }

    switch (respuesta.statusCode) {
      case 400:
        throw ApiException('Datos inválidos: $mensaje', 
            codigoEstatus: 400, codigoError: codigo);
      case 401:
        throw ApiException('Sesión expirada o credenciales inválidas', 
            codigoEstatus: 401, codigoError: 'AUTH_ERROR');
      case 403:
        throw ApiException('Acceso denegado: $mensaje', 
            codigoEstatus: 403, codigoError: codigo);
      case 404:
        throw ApiException('Recurso no encontrado', 
            codigoEstatus: 404, codigoError: codigo);
      case 422:
        throw ApiException('Error de validación: $mensaje', 
            codigoEstatus: 422, codigoError: codigo);
      case 500:
        throw ApiException('Error interno del servidor', 
            codigoEstatus: 500, codigoError: codigo);
      default:
        throw ApiException(mensaje, 
            codigoEstatus: respuesta.statusCode, codigoError: codigo);
    }
  }

  /// Maneja errores de conexión
  dynamic _manejarErrorConexion(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    // Detectar errores de conexión comunes
    if (errorStr.contains('socketexception') ||
        errorStr.contains('connection refused') ||
        errorStr.contains('failed to fetch') ||
        errorStr.contains('network') ||
        errorStr.contains('clientexception')) {
      throw ApiException(
        'No se puede conectar al servidor. Verifica que el backend esté corriendo.',
        codigoError: 'CONNECTION_ERROR',
      );
    }
    if (errorStr.contains('timeout') || error is TimeoutException) {
      throw ApiException(
        'Tiempo de espera agotado. El servidor no responde.',
        codigoError: 'TIMEOUT_ERROR',
      );
    }
    if (error is FormatException) {
      throw ApiException(
        'Error al procesar respuesta del servidor',
        codigoError: 'FORMAT_ERROR',
      );
    }
    throw ApiException(
      'Error de conexión: $error',
      codigoError: 'UNKNOWN_ERROR',
    );
  }

  // ============================================================
  // ENDPOINTS DE AUTENTICACIÓN
  // ============================================================

  /// Inicia sesión con usuario y contraseña
  Future<RespuestaLogin> login(String usuario, String clave, {String? dispositivo}) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_baseUrl${ApiConfig.loginEndpoint}'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'usuario': usuario,
          'clave': clave,
          'info_dispositivo': dispositivo,
        }),
      ).timeout(
        Duration(seconds: ApiConfig.connectionTimeout),
      );

      final datos = _procesarRespuesta(respuesta);
      final loginResponse = RespuestaLogin.fromJson(datos);
      
      // Guardar token automáticamente
      _token = loginResponse.token;
      
      return loginResponse;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _manejarErrorConexion(e);
    }
  }

  /// Cierra la sesión actual
  Future<bool> logout() async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_baseUrl${ApiConfig.logoutEndpoint}'),
        headers: _headersConAuth,
      ).timeout(
        Duration(seconds: ApiConfig.connectionTimeout),
      );

      _procesarRespuesta(respuesta);
      _token = null;
      return true;
    } catch (e) {
      _token = null;
      return false;
    }
  }

  /// Obtiene el perfil del usuario actual
  Future<Usuario> obtenerPerfil() async {
    try {
      final respuesta = await http.get(
        Uri.parse('$_baseUrl${ApiConfig.perfilEndpoint}'),
        headers: _headersConAuth,
      ).timeout(
        Duration(seconds: ApiConfig.connectionTimeout),
      );

      final datos = _procesarRespuesta(respuesta);
      return Usuario.fromJson(datos);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _manejarErrorConexion(e);
    }
  }

  /// Valida si un token es válido
  Future<bool> validarToken(String token) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_baseUrl${ApiConfig.validarTokenEndpoint}'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({'token': token}),
      ).timeout(
        Duration(seconds: ApiConfig.connectionTimeout),
      );

      final datos = _procesarRespuesta(respuesta);
      return datos['valido'] == true;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // ENDPOINTS DE ENVÍOS
  // ============================================================

  /// Obtiene todos los envíos del usuario actual
  Future<ListaEnvios> obtenerMisEnvios({String? estatus}) async {
    try {
      String url = '$_baseUrl${ApiConfig.misEnviosEndpoint}';
      if (estatus != null) {
        url += '?estatus=$estatus';
      }

      final respuesta = await http.get(
        Uri.parse(url),
        headers: _headersConAuth,
      ).timeout(
        Duration(seconds: ApiConfig.connectionTimeout),
      );

      final datos = _procesarRespuesta(respuesta);
      return ListaEnvios.fromJson(datos);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _manejarErrorConexion(e);
    }
  }

  /// Obtiene envíos pendientes (asignados)
  Future<ListaEnvios> obtenerEnviosPendientes() async {
    try {
      final respuesta = await http.get(
        Uri.parse('$_baseUrl${ApiConfig.enviosPendientesEndpoint}'),
        headers: _headersConAuth,
      ).timeout(
        Duration(seconds: ApiConfig.connectionTimeout),
      );

      final datos = _procesarRespuesta(respuesta);
      return ListaEnvios.fromJson(datos);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _manejarErrorConexion(e);
    }
  }

  /// Obtiene envíos en ruta
  Future<ListaEnvios> obtenerEnviosEnRuta() async {
    try {
      final respuesta = await http.get(
        Uri.parse('$_baseUrl${ApiConfig.enviosEnRutaEndpoint}'),
        headers: _headersConAuth,
      ).timeout(
        Duration(seconds: ApiConfig.connectionTimeout),
      );

      final datos = _procesarRespuesta(respuesta);
      return ListaEnvios.fromJson(datos);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _manejarErrorConexion(e);
    }
  }

  /// Obtiene el historial de entregas
  Future<ListaEnvios> obtenerHistorial({int limite = 50}) async {
    try {
      final respuesta = await http.get(
        Uri.parse('$_baseUrl${ApiConfig.historialEndpoint}?limite=$limite'),
        headers: _headersConAuth,
      ).timeout(
        Duration(seconds: ApiConfig.connectionTimeout),
      );

      final datos = _procesarRespuesta(respuesta);
      return ListaEnvios.fromJson(datos);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _manejarErrorConexion(e);
    }
  }

  /// Obtiene el detalle de un envío
  Future<Envio> obtenerDetalleEnvio(int idEnvio) async {
    try {
      final respuesta = await http.get(
        Uri.parse('$_baseUrl${ApiConfig.detalleEnvioEndpoint(idEnvio)}'),
        headers: _headersConAuth,
      ).timeout(
        Duration(seconds: ApiConfig.connectionTimeout),
      );

      final datos = _procesarRespuesta(respuesta);
      return Envio.fromJson(datos);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _manejarErrorConexion(e);
    }
  }

  /// Inicia la ruta de un envío (cambia a en_camino)
  Future<Envio> iniciarRuta(int idEnvio, {String? observaciones}) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_baseUrl${ApiConfig.iniciarRutaEndpoint(idEnvio)}'),
        headers: _headersConAuth,
        body: observaciones != null 
            ? jsonEncode({'observaciones': observaciones}) 
            : '{}',
      ).timeout(
        Duration(seconds: ApiConfig.connectionTimeout),
      );

      final datos = _procesarRespuesta(respuesta);
      return Envio.fromJson(datos['envio']);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _manejarErrorConexion(e);
    }
  }

  /// Registra la confirmación de entrega
  Future<ConfirmacionEntrega> confirmarEntrega(
    int idEnvio,
    ConfirmacionEntrega confirmacion,
  ) async {
    try {
      final respuesta = await http.post(
        Uri.parse('$_baseUrl${ApiConfig.confirmarEntregaEndpoint(idEnvio)}'),
        headers: _headersConAuth,
        body: jsonEncode(confirmacion.toJson()),
      ).timeout(
        Duration(seconds: ApiConfig.sendTimeout),
      );

      final datos = _procesarRespuesta(respuesta);
      return ConfirmacionEntrega.fromJson(datos['confirmacion']);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _manejarErrorConexion(e);
    }
  }
}

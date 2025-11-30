// ============================================================
// PQEXPRESS - Configuración de la API
// URLs, timeouts y configuración de conexión al backend
// ============================================================

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Configuración centralizada para la conexión con el backend
class ApiConfig {
  // ============================================================
  // URL BASE DEL BACKEND
  // ============================================================
  
  /// URL para emulador Android (10.0.2.2 es el alias de localhost del host)
  static const String _androidEmulatorUrl = 'http://10.0.2.2:8000/api';
  
  /// URL para web, escritorio y dispositivos iOS
  static const String _localUrl = 'http://localhost:8000/api';
  
  /// URL base automática según la plataforma
  /// - Web: usa localhost
  /// - Android emulador: usa 10.0.2.2
  /// - iOS simulador: usa localhost
  /// - Escritorio: usa localhost
  static String get baseUrl {
    if (kIsWeb) {
      return _localUrl;
    }
    // Usar defaultTargetPlatform que funciona en todas las plataformas
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _androidEmulatorUrl;
    }
    return _localUrl;
  }
  
  /// URL alternativa para cuando el servidor está en localhost
  /// Útil para pruebas en web o escritorio
  static const String localUrl = 'http://localhost:8000/api';
  
  // ============================================================
  // TIMEOUTS DE CONEXIÓN
  // ============================================================
  
  /// Timeout para conexión inicial (en segundos)
  static const int connectionTimeout = 30;
  
  /// Timeout para recibir respuesta (en segundos)
  static const int receiveTimeout = 60;
  
  /// Timeout para enviar datos (en segundos)
  /// Más alto para subida de imágenes
  static const int sendTimeout = 120;
  
  // ============================================================
  // ENDPOINTS DE AUTENTICACIÓN
  // ============================================================
  
  /// Endpoint para iniciar sesión
  static const String loginEndpoint = '/auth/login';
  
  /// Endpoint para cerrar sesión
  static const String logoutEndpoint = '/auth/logout';
  
  /// Endpoint para obtener perfil del usuario actual
  static const String perfilEndpoint = '/auth/me';
  
  /// Endpoint para validar token
  static const String validarTokenEndpoint = '/auth/validar-token';
  
  // ============================================================
  // ENDPOINTS DE ENVÍOS
  // ============================================================
  
  /// Endpoint para listar envíos del usuario
  static const String misEnviosEndpoint = '/envios/mis-envios';
  
  /// Endpoint para listar envíos pendientes
  static const String enviosPendientesEndpoint = '/envios/pendientes';
  
  /// Endpoint para listar envíos en ruta
  static const String enviosEnRutaEndpoint = '/envios/en-ruta';
  
  /// Endpoint para historial de entregas
  static const String historialEndpoint = '/envios/historial';
  
  /// Genera el endpoint para detalle de un envío
  static String detalleEnvioEndpoint(int idEnvio) => '/envios/$idEnvio';
  
  /// Genera el endpoint para iniciar ruta
  static String iniciarRutaEndpoint(int idEnvio) => '/envios/$idEnvio/iniciar-ruta';
  
  /// Genera el endpoint para confirmar entrega
  static String confirmarEntregaEndpoint(int idEnvio) => '/envios/$idEnvio/confirmar-entrega';
  
  // ============================================================
  // CONFIGURACIÓN ADICIONAL
  // ============================================================
  
  /// Headers por defecto para las peticiones
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  /// Genera headers con token de autenticación
  static Map<String, String> authHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
}

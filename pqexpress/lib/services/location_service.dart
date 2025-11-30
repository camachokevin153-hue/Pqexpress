// ============================================================
// PQEXPRESS - Servicio de Ubicación GPS
// Gestiona la obtención de coordenadas del dispositivo
// ============================================================

import 'package:geolocator/geolocator.dart';

/// Resultado de obtener ubicación
class UbicacionResultado {
  final double latitud;
  final double longitud;
  final double precision;
  final double? altitud;
  final double? velocidad;
  final DateTime timestamp;

  UbicacionResultado({
    required this.latitud,
    required this.longitud,
    required this.precision,
    this.altitud,
    this.velocidad,
    required this.timestamp,
  });

  /// Crea desde Position de geolocator
  factory UbicacionResultado.fromPosition(Position posicion) {
    return UbicacionResultado(
      latitud: posicion.latitude,
      longitud: posicion.longitude,
      precision: posicion.accuracy,
      altitud: posicion.altitude,
      velocidad: posicion.speed,
      timestamp: posicion.timestamp,
    );
  }

  @override
  String toString() {
    return 'Ubicación($latitud, $longitud) ±${precision.toStringAsFixed(1)}m';
  }
}

/// Servicio para manejar la ubicación GPS
class LocationService {
  /// Verifica si los servicios de ubicación están habilitados
  Future<bool> serviciosHabilitados() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Verifica y solicita permisos de ubicación
  Future<bool> verificarPermisos() async {
    LocationPermission permiso = await Geolocator.checkPermission();
    
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permiso == LocationPermission.deniedForever) {
      return false;
    }
    
    return true;
  }

  /// Obtiene el estado actual del permiso
  Future<String> obtenerEstadoPermiso() async {
    LocationPermission permiso = await Geolocator.checkPermission();
    
    switch (permiso) {
      case LocationPermission.denied:
        return 'Permiso denegado';
      case LocationPermission.deniedForever:
        return 'Permiso denegado permanentemente';
      case LocationPermission.whileInUse:
        return 'Permiso mientras se usa la app';
      case LocationPermission.always:
        return 'Permiso siempre';
      case LocationPermission.unableToDetermine:
        return 'No se puede determinar';
    }
  }

  /// Abre la configuración de ubicación del sistema
  Future<bool> abrirConfiguracionUbicacion() async {
    return await Geolocator.openLocationSettings();
  }

  /// Abre la configuración de permisos de la app
  Future<bool> abrirConfiguracionApp() async {
    return await Geolocator.openAppSettings();
  }

  /// Obtiene la ubicación actual del dispositivo
  /// 
  /// Parámetros:
  /// - [altaPrecision]: Si es true, usa GPS de alta precisión (más lento pero preciso)
  /// 
  /// Lanza excepciones si:
  /// - Los servicios de ubicación están deshabilitados
  /// - No hay permisos suficientes
  Future<UbicacionResultado> obtenerUbicacionActual({
    bool altaPrecision = true,
  }) async {
    // Verificar servicios de ubicación
    bool servicioHabilitado = await serviciosHabilitados();
    if (!servicioHabilitado) {
      throw Exception('Los servicios de ubicación están deshabilitados. '
          'Por favor, habilítalos en la configuración del dispositivo.');
    }

    // Verificar permisos
    bool tienePermiso = await verificarPermisos();
    if (!tienePermiso) {
      throw Exception('Se requieren permisos de ubicación para continuar. '
          'Por favor, otorga los permisos en la configuración.');
    }

    // Configurar precisión
    LocationSettings configuracion = LocationSettings(
      accuracy: altaPrecision 
          ? LocationAccuracy.high 
          : LocationAccuracy.medium,
      distanceFilter: 0,
    );

    // Obtener posición
    try {
      Position posicion = await Geolocator.getCurrentPosition(
        locationSettings: configuracion,
      );
      
      return UbicacionResultado.fromPosition(posicion);
    } catch (e) {
      throw Exception('Error al obtener ubicación: $e');
    }
  }

  /// Obtiene la última ubicación conocida (más rápido pero puede ser antigua)
  Future<UbicacionResultado?> obtenerUltimaUbicacion() async {
    try {
      Position? posicion = await Geolocator.getLastKnownPosition();
      if (posicion != null) {
        return UbicacionResultado.fromPosition(posicion);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Calcula la distancia entre dos puntos en metros
  double calcularDistancia(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  /// Calcula el bearing (dirección) entre dos puntos
  double calcularDireccion(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    return Geolocator.bearingBetween(lat1, lng1, lat2, lng2);
  }

  /// Stream de actualizaciones de ubicación
  Stream<UbicacionResultado> obtenerStreamUbicacion({
    int distanciaMinima = 10, // metros
  }) {
    LocationSettings configuracion = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanciaMinima,
    );

    return Geolocator.getPositionStream(locationSettings: configuracion)
        .map((posicion) => UbicacionResultado.fromPosition(posicion));
  }

  /// Formatea la distancia para mostrar al usuario
  String formatearDistancia(double metros) {
    if (metros < 1000) {
      return '${metros.toStringAsFixed(0)} m';
    } else {
      return '${(metros / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Formatea el tiempo estimado basado en distancia
  String formatearTiempoEstimado(double metros, {double velocidadKmH = 30}) {
    double horas = metros / 1000 / velocidadKmH;
    int minutos = (horas * 60).round();
    
    if (minutos < 1) {
      return 'Menos de 1 min';
    } else if (minutos < 60) {
      return '$minutos min';
    } else {
      int h = minutos ~/ 60;
      int m = minutos % 60;
      return '${h}h ${m}min';
    }
  }
}

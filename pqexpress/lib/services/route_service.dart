// ============================================================
// PQEXPRESS - Servicio de Rutas (OSRM)
// Obtiene rutas reales por calles usando OpenStreetMap
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Instrucción de navegación
class InstruccionNavegacion {
  final String instruccion;
  final double distancia;
  final double duracion;
  final String tipo;
  final String? nombreCalle;

  InstruccionNavegacion({
    required this.instruccion,
    required this.distancia,
    required this.duracion,
    required this.tipo,
    this.nombreCalle,
  });

  /// Distancia formateada
  String get distanciaFormateada {
    if (distancia < 1000) {
      return '${distancia.toStringAsFixed(0)} m';
    } else {
      return '${(distancia / 1000).toStringAsFixed(1)} km';
    }
  }
}

/// Resultado de una ruta calculada
class RutaResultado {
  /// Lista de coordenadas que forman la ruta
  final List<LatLng> puntos;
  
  /// Distancia total en metros
  final double distanciaTotal;
  
  /// Duración estimada en segundos
  final double duracionTotal;
  
  /// Instrucciones de navegación paso a paso
  final List<InstruccionNavegacion> instrucciones;

  RutaResultado({
    required this.puntos,
    required this.distanciaTotal,
    required this.duracionTotal,
    required this.instrucciones,
  });

  /// Distancia formateada para mostrar
  String get distanciaFormateada {
    if (distanciaTotal < 1000) {
      return '${distanciaTotal.toStringAsFixed(0)} m';
    } else {
      return '${(distanciaTotal / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Duración formateada para mostrar
  String get duracionFormateada {
    int minutos = (duracionTotal / 60).round();
    if (minutos < 1) {
      return 'Menos de 1 min';
    } else if (minutos < 60) {
      return '$minutos min';
    } else {
      int horas = minutos ~/ 60;
      int mins = minutos % 60;
      return '${horas}h ${mins}min';
    }
  }
}

/// Servicio para obtener rutas usando OSRM (Open Source Routing Machine)
class RouteService {
  /// URL base del servidor OSRM público (gratuito, sin API key)
  static const String _osrmBaseUrl = 'https://router.project-osrm.org';

  /// Obtiene una ruta entre dos puntos
  /// 
  /// [origen] - Coordenadas del punto de partida
  /// [destino] - Coordenadas del punto de llegada
  /// 
  /// Retorna una [RutaResultado] con la ruta calculada
  Future<RutaResultado> obtenerRuta(LatLng origen, LatLng destino) async {
    // Construir URL de la API OSRM
    // Formato: /route/v1/driving/lon1,lat1;lon2,lat2
    final url = '$_osrmBaseUrl/route/v1/driving/'
        '${origen.longitude},${origen.latitude};'
        '${destino.longitude},${destino.latitude}'
        '?overview=full&geometries=geojson&steps=true';

    try {
      final respuesta = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 30),
      );

      if (respuesta.statusCode != 200) {
        throw Exception('Error al obtener ruta: ${respuesta.statusCode}');
      }

      final datos = jsonDecode(respuesta.body);

      // Verificar si la ruta se calculó correctamente
      if (datos['code'] != 'Ok') {
        throw Exception('No se pudo calcular la ruta: ${datos['message']}');
      }

      // Obtener la primera ruta (la mejor)
      final ruta = datos['routes'][0];

      // Extraer geometría (coordenadas de la ruta)
      final coordenadas = ruta['geometry']['coordinates'] as List;
      final puntos = coordenadas.map((coord) {
        return LatLng(coord[1].toDouble(), coord[0].toDouble());
      }).toList();

      // Extraer distancia y duración
      final distancia = ruta['distance'].toDouble();
      final duracion = ruta['duration'].toDouble();

      // Extraer instrucciones de navegación
      final instrucciones = <InstruccionNavegacion>[];
      if (ruta['legs'] != null && ruta['legs'].isNotEmpty) {
        final steps = ruta['legs'][0]['steps'] as List;
        for (final step in steps) {
          instrucciones.add(InstruccionNavegacion(
            instruccion: _traducirManiobra(step['maneuver']['type'], step['maneuver']['modifier']),
            distancia: step['distance'].toDouble(),
            duracion: step['duration'].toDouble(),
            tipo: step['maneuver']['type'],
            nombreCalle: step['name']?.toString(),
          ));
        }
      }

      return RutaResultado(
        puntos: puntos,
        distanciaTotal: distancia,
        duracionTotal: duracion,
        instrucciones: instrucciones,
      );
    } catch (e) {
      throw Exception('Error al calcular ruta: $e');
    }
  }

  /// Traduce el tipo de maniobra a español
  String _traducirManiobra(String tipo, String? modificador) {
    String direccion = '';
    if (modificador != null) {
      switch (modificador) {
        case 'left':
          direccion = 'a la izquierda';
          break;
        case 'right':
          direccion = 'a la derecha';
          break;
        case 'slight left':
          direccion = 'ligeramente a la izquierda';
          break;
        case 'slight right':
          direccion = 'ligeramente a la derecha';
          break;
        case 'sharp left':
          direccion = 'fuerte a la izquierda';
          break;
        case 'sharp right':
          direccion = 'fuerte a la derecha';
          break;
        case 'straight':
          direccion = 'recto';
          break;
        case 'uturn':
          direccion = 'vuelta en U';
          break;
      }
    }

    switch (tipo) {
      case 'depart':
        return 'Iniciar recorrido';
      case 'arrive':
        return 'Has llegado a tu destino';
      case 'turn':
        return 'Girar $direccion';
      case 'new name':
        return 'Continuar $direccion';
      case 'merge':
        return 'Incorporarse $direccion';
      case 'on ramp':
        return 'Tomar rampa $direccion';
      case 'off ramp':
        return 'Salir por rampa $direccion';
      case 'fork':
        return 'Tomar bifurcación $direccion';
      case 'end of road':
        return 'Al final de la calle, girar $direccion';
      case 'continue':
        return 'Continuar $direccion';
      case 'roundabout':
        return 'En la rotonda, tomar salida $direccion';
      case 'rotary':
        return 'En la glorieta, tomar salida $direccion';
      case 'roundabout turn':
        return 'En la rotonda, girar $direccion';
      case 'notification':
        return 'Notificación';
      case 'exit roundabout':
        return 'Salir de la rotonda';
      case 'exit rotary':
        return 'Salir de la glorieta';
      default:
        return 'Continuar';
    }
  }

  /// Genera URL para abrir en Google Maps
  String generarUrlGoogleMaps(LatLng origen, LatLng destino) {
    return 'https://www.google.com/maps/dir/?api=1'
        '&origin=${origen.latitude},${origen.longitude}'
        '&destination=${destino.latitude},${destino.longitude}'
        '&travelmode=driving';
  }

  /// Genera URL para abrir en Waze
  String generarUrlWaze(LatLng destino) {
    return 'https://waze.com/ul?ll=${destino.latitude},${destino.longitude}&navigate=yes';
  }

  /// Genera URL para abrir en Apple Maps (solo iOS)
  String generarUrlAppleMaps(LatLng origen, LatLng destino) {
    return 'https://maps.apple.com/?saddr=${origen.latitude},${origen.longitude}'
        '&daddr=${destino.latitude},${destino.longitude}&dirflg=d';
  }
}

// ============================================================
// PQEXPRESS - Modelo de Envío (Paquete)
// Representa un paquete asignado para entrega
// ============================================================

/// Estados posibles de un envío
enum EstatusEnvio {
  asignado,
  enCamino,
  completado,
  fallido;

  /// Convierte string del backend a enum
  static EstatusEnvio fromString(String valor) {
    switch (valor.toLowerCase()) {
      case 'asignado':
        return EstatusEnvio.asignado;
      case 'en_camino':
        return EstatusEnvio.enCamino;
      case 'completado':
        return EstatusEnvio.completado;
      case 'fallido':
        return EstatusEnvio.fallido;
      default:
        return EstatusEnvio.asignado;
    }
  }

  /// Convierte enum a string para mostrar al usuario
  String get etiqueta {
    switch (this) {
      case EstatusEnvio.asignado:
        return 'Pendiente';
      case EstatusEnvio.enCamino:
        return 'En Camino';
      case EstatusEnvio.completado:
        return 'Entregado';
      case EstatusEnvio.fallido:
        return 'Fallido';
    }
  }

  /// Obtiene el valor para enviar al backend
  String get valor {
    switch (this) {
      case EstatusEnvio.asignado:
        return 'asignado';
      case EstatusEnvio.enCamino:
        return 'en_camino';
      case EstatusEnvio.completado:
        return 'completado';
      case EstatusEnvio.fallido:
        return 'fallido';
    }
  }
}

/// Modelo que representa un envío/paquete
class Envio {
  /// ID único del envío
  final int idEnvio;
  
  /// Número de guía único (ej: ENV-2024-0001)
  final String numeroGuia;
  
  /// ID del repartidor asignado
  final int? idRepartidor;
  
  /// Nombre del destinatario
  final String receptorNombre;
  
  /// Teléfono del destinatario
  final String? receptorTelefono;
  
  /// Calle de la dirección
  final String calle;
  
  /// Número exterior
  final String? numeroExterior;
  
  /// Colonia
  final String? colonia;
  
  /// Municipio o ciudad
  final String? municipioCiudad;
  
  /// Código postal
  final String? codigoPostal;
  
  /// Dirección completa formateada
  final String? direccionCompleta;
  
  /// Referencias adicionales para encontrar la dirección
  final String? referenciasAdicionales;
  
  /// Latitud del destino
  final double? latDestino;
  
  /// Longitud del destino
  final double? lngDestino;
  
  /// Estado actual del envío
  final EstatusEnvio estatusEnvio;
  
  /// Fecha de asignación
  final DateTime? fechaAsignacion;
  
  /// Fecha de completado
  final DateTime? fechaCompletado;
  
  /// Observaciones adicionales
  final String? observaciones;
  
  /// Fecha de creación del registro
  final DateTime? creadoEn;
  
  /// Última modificación
  final DateTime? modificadoEn;

  Envio({
    required this.idEnvio,
    required this.numeroGuia,
    this.idRepartidor,
    required this.receptorNombre,
    this.receptorTelefono,
    required this.calle,
    this.numeroExterior,
    this.colonia,
    this.municipioCiudad,
    this.codigoPostal,
    this.direccionCompleta,
    this.referenciasAdicionales,
    this.latDestino,
    this.lngDestino,
    required this.estatusEnvio,
    this.fechaAsignacion,
    this.fechaCompletado,
    this.observaciones,
    this.creadoEn,
    this.modificadoEn,
  });

  /// Crea una instancia desde JSON
  factory Envio.fromJson(Map<String, dynamic> json) {
    return Envio(
      idEnvio: json['id_envio'] as int,
      numeroGuia: json['numero_guia'] as String,
      idRepartidor: json['id_repartidor'] as int?,
      receptorNombre: json['receptor_nombre'] as String,
      receptorTelefono: json['receptor_telefono'] as String?,
      calle: json['calle'] as String,
      numeroExterior: json['numero_exterior'] as String?,
      colonia: json['colonia'] as String?,
      municipioCiudad: json['municipio_ciudad'] as String?,
      codigoPostal: json['codigo_postal'] as String?,
      direccionCompleta: json['direccion_completa'] as String?,
      referenciasAdicionales: json['referencias_adicionales'] as String?,
      latDestino: json['lat_destino'] != null 
          ? (json['lat_destino'] as num).toDouble() 
          : null,
      lngDestino: json['lng_destino'] != null 
          ? (json['lng_destino'] as num).toDouble() 
          : null,
      estatusEnvio: EstatusEnvio.fromString(json['estatus_envio'] as String),
      fechaAsignacion: json['fecha_asignacion'] != null 
          ? DateTime.parse(json['fecha_asignacion'] as String) 
          : null,
      fechaCompletado: json['fecha_completado'] != null 
          ? DateTime.parse(json['fecha_completado'] as String) 
          : null,
      observaciones: json['observaciones'] as String?,
      creadoEn: json['creado_en'] != null 
          ? DateTime.parse(json['creado_en'] as String) 
          : null,
      modificadoEn: json['modificado_en'] != null 
          ? DateTime.parse(json['modificado_en'] as String) 
          : null,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'id_envio': idEnvio,
      'numero_guia': numeroGuia,
      'id_repartidor': idRepartidor,
      'receptor_nombre': receptorNombre,
      'receptor_telefono': receptorTelefono,
      'calle': calle,
      'numero_exterior': numeroExterior,
      'colonia': colonia,
      'municipio_ciudad': municipioCiudad,
      'codigo_postal': codigoPostal,
      'direccion_completa': direccionCompleta,
      'referencias_adicionales': referenciasAdicionales,
      'lat_destino': latDestino,
      'lng_destino': lngDestino,
      'estatus_envio': estatusEnvio.valor,
      'fecha_asignacion': fechaAsignacion?.toIso8601String(),
      'fecha_completado': fechaCompletado?.toIso8601String(),
      'observaciones': observaciones,
      'creado_en': creadoEn?.toIso8601String(),
      'modificado_en': modificadoEn?.toIso8601String(),
    };
  }

  /// Obtiene la dirección formateada para mostrar
  String get direccionFormateada {
    if (direccionCompleta != null && direccionCompleta!.isNotEmpty) {
      return direccionCompleta!;
    }
    
    final partes = <String>[];
    partes.add(calle);
    if (numeroExterior != null && numeroExterior!.isNotEmpty) {
      partes.add('#$numeroExterior');
    }
    if (colonia != null && colonia!.isNotEmpty) {
      partes.add(colonia!);
    }
    if (municipioCiudad != null && municipioCiudad!.isNotEmpty) {
      partes.add(municipioCiudad!);
    }
    if (codigoPostal != null && codigoPostal!.isNotEmpty) {
      partes.add('CP $codigoPostal');
    }
    
    return partes.join(', ');
  }

  /// Verifica si el envío tiene coordenadas GPS
  bool get tieneCoordenadas => latDestino != null && lngDestino != null;

  /// Verifica si está pendiente de entrega
  bool get estaPendiente => estatusEnvio == EstatusEnvio.asignado;

  /// Verifica si está en camino
  bool get estaEnCamino => estatusEnvio == EstatusEnvio.enCamino;

  /// Verifica si ya fue completado
  bool get estaCompletado => estatusEnvio == EstatusEnvio.completado;

  @override
  String toString() {
    return 'Envio(guia: $numeroGuia, destino: $receptorNombre, estado: ${estatusEnvio.etiqueta})';
  }
}

/// Modelo para la lista de envíos
class ListaEnvios {
  final int total;
  final List<Envio> envios;

  ListaEnvios({
    required this.total,
    required this.envios,
  });

  factory ListaEnvios.fromJson(Map<String, dynamic> json) {
    return ListaEnvios(
      total: json['total'] as int,
      envios: (json['envios'] as List<dynamic>)
          .map((e) => Envio.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

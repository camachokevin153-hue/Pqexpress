// ============================================================
// PQEXPRESS - Modelo de Confirmación de Entrega
// Representa el registro de una entrega con evidencia
// ============================================================

/// Resultados posibles de una entrega
enum ResultadoEntrega {
  exitosa,
  rechazada,
  parcial;

  /// Convierte string a enum
  static ResultadoEntrega fromString(String valor) {
    switch (valor.toLowerCase()) {
      case 'exitosa':
        return ResultadoEntrega.exitosa;
      case 'rechazada':
        return ResultadoEntrega.rechazada;
      case 'parcial':
        return ResultadoEntrega.parcial;
      default:
        return ResultadoEntrega.exitosa;
    }
  }

  /// Etiqueta para mostrar al usuario
  String get etiqueta {
    switch (this) {
      case ResultadoEntrega.exitosa:
        return 'Entrega Exitosa';
      case ResultadoEntrega.rechazada:
        return 'Rechazada';
      case ResultadoEntrega.parcial:
        return 'Entrega Parcial';
    }
  }

  /// Valor para el backend
  String get valor {
    switch (this) {
      case ResultadoEntrega.exitosa:
        return 'exitosa';
      case ResultadoEntrega.rechazada:
        return 'rechazada';
      case ResultadoEntrega.parcial:
        return 'parcial';
    }
  }
}

/// Modelo que representa una confirmación de entrega
class ConfirmacionEntrega {
  /// ID de la confirmación
  final int? idConfirmacion;
  
  /// ID del envío relacionado
  final int idEnvio;
  
  /// ID del repartidor que realizó la entrega
  final int? idRepartidor;
  
  /// Latitud GPS donde se realizó la entrega
  final double latConfirmacion;
  
  /// Longitud GPS donde se realizó la entrega
  final double lngConfirmacion;
  
  /// Precisión del GPS en metros
  final double? precisionMetros;
  
  /// Imagen de evidencia en Base64
  final String? imagenEvidencia;
  
  /// Nombre de quien recibió el paquete
  final String? nombreReceptor;
  
  /// Resultado de la entrega
  final ResultadoEntrega resultadoEntrega;
  
  /// Razón si la entrega falló
  final String? razonFallo;
  
  /// Comentarios adicionales
  final String? comentarios;
  
  /// Fecha y hora del registro
  final DateTime? registradoEn;

  ConfirmacionEntrega({
    this.idConfirmacion,
    required this.idEnvio,
    this.idRepartidor,
    required this.latConfirmacion,
    required this.lngConfirmacion,
    this.precisionMetros,
    this.imagenEvidencia,
    this.nombreReceptor,
    this.resultadoEntrega = ResultadoEntrega.exitosa,
    this.razonFallo,
    this.comentarios,
    this.registradoEn,
  });

  /// Crea instancia desde JSON
  factory ConfirmacionEntrega.fromJson(Map<String, dynamic> json) {
    return ConfirmacionEntrega(
      idConfirmacion: json['id_confirmacion'] as int?,
      idEnvio: json['id_envio'] as int,
      idRepartidor: json['id_repartidor'] as int?,
      latConfirmacion: (json['lat_confirmacion'] as num).toDouble(),
      lngConfirmacion: (json['lng_confirmacion'] as num).toDouble(),
      precisionMetros: json['precision_metros'] != null 
          ? (json['precision_metros'] as num).toDouble() 
          : null,
      imagenEvidencia: json['imagen_evidencia'] as String?,
      nombreReceptor: json['nombre_receptor'] as String?,
      resultadoEntrega: ResultadoEntrega.fromString(
          json['resultado_entrega'] as String? ?? 'exitosa'),
      razonFallo: json['razon_fallo'] as String?,
      comentarios: json['comentarios'] as String?,
      registradoEn: json['registrado_en'] != null 
          ? DateTime.parse(json['registrado_en'] as String) 
          : null,
    );
  }

  /// Convierte a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      'lat_confirmacion': latConfirmacion,
      'lng_confirmacion': lngConfirmacion,
      'precision_metros': precisionMetros,
      'imagen_evidencia': imagenEvidencia,
      'nombre_receptor': nombreReceptor,
      'resultado_entrega': resultadoEntrega.valor,
      'razon_fallo': razonFallo,
      'comentarios': comentarios,
    };
  }

  /// Crea una copia con nuevos valores
  ConfirmacionEntrega copyWith({
    int? idConfirmacion,
    int? idEnvio,
    int? idRepartidor,
    double? latConfirmacion,
    double? lngConfirmacion,
    double? precisionMetros,
    String? imagenEvidencia,
    String? nombreReceptor,
    ResultadoEntrega? resultadoEntrega,
    String? razonFallo,
    String? comentarios,
    DateTime? registradoEn,
  }) {
    return ConfirmacionEntrega(
      idConfirmacion: idConfirmacion ?? this.idConfirmacion,
      idEnvio: idEnvio ?? this.idEnvio,
      idRepartidor: idRepartidor ?? this.idRepartidor,
      latConfirmacion: latConfirmacion ?? this.latConfirmacion,
      lngConfirmacion: lngConfirmacion ?? this.lngConfirmacion,
      precisionMetros: precisionMetros ?? this.precisionMetros,
      imagenEvidencia: imagenEvidencia ?? this.imagenEvidencia,
      nombreReceptor: nombreReceptor ?? this.nombreReceptor,
      resultadoEntrega: resultadoEntrega ?? this.resultadoEntrega,
      razonFallo: razonFallo ?? this.razonFallo,
      comentarios: comentarios ?? this.comentarios,
      registradoEn: registradoEn ?? this.registradoEn,
    );
  }

  @override
  String toString() {
    return 'ConfirmacionEntrega(envio: $idEnvio, resultado: ${resultadoEntrega.etiqueta}, GPS: $latConfirmacion, $lngConfirmacion)';
  }
}

/// Modelo para la respuesta de registro de entrega
class RespuestaRegistroEntrega {
  final String mensaje;
  final ConfirmacionEntrega confirmacion;

  RespuestaRegistroEntrega({
    required this.mensaje,
    required this.confirmacion,
  });

  factory RespuestaRegistroEntrega.fromJson(Map<String, dynamic> json) {
    return RespuestaRegistroEntrega(
      mensaje: json['mensaje'] as String,
      confirmacion: ConfirmacionEntrega.fromJson(
          json['confirmacion'] as Map<String, dynamic>),
    );
  }
}

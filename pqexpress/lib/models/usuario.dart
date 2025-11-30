// ============================================================
// PQEXPRESS - Modelo de Usuario (Repartidor)
// Representa la información del agente de entrega
// ============================================================

/// Modelo que representa un repartidor/agente de entrega
class Usuario {
  /// ID único del repartidor en la base de datos
  final int idRepartidor;
  
  /// Nombre de usuario para login
  final String usuario;
  
  /// Correo electrónico (puede ser null)
  final String? correo;
  
  /// Nombre completo del repartidor
  final String nombreCompleto;
  
  /// Número de teléfono (puede ser null)
  final String? numTelefono;
  
  /// Indica si el usuario está activo
  final bool estaActivo;
  
  /// Fecha de registro en el sistema
  final DateTime? fechaAlta;
  
  /// Última vez que inició sesión
  final DateTime? ultimaConexion;

  Usuario({
    required this.idRepartidor,
    required this.usuario,
    this.correo,
    required this.nombreCompleto,
    this.numTelefono,
    this.estaActivo = true,
    this.fechaAlta,
    this.ultimaConexion,
  });

  /// Crea una instancia de Usuario desde un mapa JSON
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      idRepartidor: json['id_repartidor'] as int,
      usuario: json['usuario'] as String,
      correo: json['correo'] as String?,
      nombreCompleto: json['nombre_completo'] as String,
      numTelefono: json['num_telefono'] as String?,
      estaActivo: json['esta_activo'] as bool? ?? true,
      fechaAlta: json['fecha_alta'] != null 
          ? DateTime.parse(json['fecha_alta'] as String) 
          : null,
      ultimaConexion: json['ultima_conexion'] != null 
          ? DateTime.parse(json['ultima_conexion'] as String) 
          : null,
    );
  }

  /// Convierte la instancia a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'id_repartidor': idRepartidor,
      'usuario': usuario,
      'correo': correo,
      'nombre_completo': nombreCompleto,
      'num_telefono': numTelefono,
      'esta_activo': estaActivo,
      'fecha_alta': fechaAlta?.toIso8601String(),
      'ultima_conexion': ultimaConexion?.toIso8601String(),
    };
  }

  /// Obtiene las iniciales del nombre para mostrar en avatar
  String get iniciales {
    final partes = nombreCompleto.split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    } else if (partes.isNotEmpty) {
      return partes[0].substring(0, partes[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'NA';
  }

  /// Obtiene el primer nombre
  String get primerNombre {
    return nombreCompleto.split(' ').first;
  }

  @override
  String toString() {
    return 'Usuario(id: $idRepartidor, usuario: $usuario, nombre: $nombreCompleto)';
  }
}

/// Modelo para la respuesta de login
class RespuestaLogin {
  final String mensaje;
  final String token;
  final String tipoToken;
  final DateTime expiraEn;
  final Usuario usuario;

  RespuestaLogin({
    required this.mensaje,
    required this.token,
    required this.tipoToken,
    required this.expiraEn,
    required this.usuario,
  });

  factory RespuestaLogin.fromJson(Map<String, dynamic> json) {
    return RespuestaLogin(
      mensaje: json['mensaje'] as String,
      token: json['token'] as String,
      tipoToken: json['tipo_token'] as String,
      expiraEn: DateTime.parse(json['expira_en'] as String),
      usuario: Usuario.fromJson(json['usuario'] as Map<String, dynamic>),
    );
  }
}

// ============================================================
// PQEXPRESS - Servicio de Cámara
// Gestiona la captura de fotos para evidencia de entrega
// Compatible con Web, Android e iOS
// ============================================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

/// Resultado de captura de foto - Compatible con Web
class FotoResultado {
  /// Bytes de la imagen (funciona en todas las plataformas)
  final Uint8List bytes;
  
  /// Ruta del archivo temporal (vacío en web)
  final String rutaArchivo;
  
  /// Imagen en formato Base64 (para enviar al servidor)
  final String base64;
  
  /// Tamaño del archivo en bytes
  final int tamanoBytes;
  
  /// Nombre del archivo
  final String nombreArchivo;

  FotoResultado({
    required this.bytes,
    required this.rutaArchivo,
    required this.base64,
    required this.tamanoBytes,
    required this.nombreArchivo,
  });

  /// Tamaño formateado para mostrar
  String get tamanoFormateado {
    if (tamanoBytes < 1024) {
      return '$tamanoBytes B';
    } else if (tamanoBytes < 1024 * 1024) {
      return '${(tamanoBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(tamanoBytes / 1024 / 1024).toStringAsFixed(2)} MB';
    }
  }
}

/// Servicio para manejar la cámara y galería
/// Compatible con Web, Android e iOS
class CameraService {
  final ImagePicker _picker = ImagePicker();

  /// Calidad de compresión de la imagen (0-100)
  final int calidadImagen;
  
  /// Ancho máximo de la imagen en píxeles
  final double anchoMaximo;
  
  /// Alto máximo de la imagen en píxeles
  final double altoMaximo;

  CameraService({
    this.calidadImagen = 70,
    this.anchoMaximo = 1024,
    this.altoMaximo = 1024,
  });

  /// Captura una foto desde la cámara
  /// 
  /// Retorna null si el usuario cancela
  /// Nota: En web puede que la cámara no esté disponible
  Future<FotoResultado?> tomarFoto({
    CameraDevice camara = CameraDevice.rear,
  }) async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: camara,
        maxWidth: anchoMaximo,
        maxHeight: altoMaximo,
        imageQuality: calidadImagen,
      );

      if (foto == null) return null;

      return await _procesarImagen(foto);
    } catch (e) {
      // En web, la cámara puede no estar disponible
      if (kIsWeb) {
        throw Exception('La cámara no está disponible en este navegador. Usa la galería.');
      }
      throw Exception('Error al capturar foto: $e');
    }
  }

  /// Selecciona una foto desde la galería
  /// 
  /// Retorna null si el usuario cancela
  Future<FotoResultado?> seleccionarDeGaleria() async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: anchoMaximo,
        maxHeight: altoMaximo,
        imageQuality: calidadImagen,
      );

      if (foto == null) return null;

      return await _procesarImagen(foto);
    } catch (e) {
      throw Exception('Error al seleccionar imagen: $e');
    }
  }

  /// Procesa la imagen y la convierte a Base64
  /// Compatible con todas las plataformas
  Future<FotoResultado> _procesarImagen(XFile xfile) async {
    // Leer bytes del archivo (funciona en todas las plataformas)
    final bytes = await xfile.readAsBytes();
    
    // Convertir a Base64
    final base64String = base64Encode(bytes);
    
    return FotoResultado(
      bytes: bytes,
      rutaArchivo: kIsWeb ? '' : xfile.path,
      base64: base64String,
      tamanoBytes: bytes.length,
      nombreArchivo: xfile.name,
    );
  }

  /// Verifica si la cámara está disponible
  Future<bool> camaraDisponible() async {
    // En web, la disponibilidad de cámara depende del navegador
    if (kIsWeb) {
      // Asumimos que no está disponible en web para evitar errores
      return false;
    }
    return true;
  }

  /// Convierte bytes a Base64
  String bytesABase64(Uint8List bytes) {
    return base64Encode(bytes);
  }

  /// Decodifica Base64 a bytes
  Uint8List base64ABytes(String base64String) {
    return base64Decode(base64String);
  }
}

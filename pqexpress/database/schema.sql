-- ============================================================
-- PQEXPRESS - Sistema de Gestión de Entregas
-- Script de creación de base de datos MySQL
-- Autor: Desarrollo PQExpress
-- Fecha: Noviembre 2024
-- ============================================================

-- Crear base de datos
CREATE DATABASE IF NOT EXISTS pqexpress_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pqexpress_db;

-- ============================================================
-- TABLA: repartidores
-- Almacena información de los agentes de entrega
-- ============================================================
CREATE TABLE IF NOT EXISTS repartidores (
    id_repartidor INT PRIMARY KEY AUTO_INCREMENT,
    usuario VARCHAR(60) UNIQUE NOT NULL COMMENT 'Nombre de usuario único para login',
    clave_hash VARCHAR(255) NOT NULL COMMENT 'Contraseña encriptada con bcrypt',
    correo VARCHAR(120) UNIQUE COMMENT 'Correo electrónico del repartidor',
    nombre_completo VARCHAR(120) NOT NULL COMMENT 'Nombre real del repartidor',
    num_telefono VARCHAR(25) COMMENT 'Teléfono de contacto',
    esta_activo BOOLEAN DEFAULT TRUE COMMENT 'Indica si el repartidor está activo',
    fecha_alta DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de registro en el sistema',
    ultima_conexion DATETIME COMMENT 'Última vez que inició sesión',
    INDEX idx_usuario (usuario),
    INDEX idx_activo (esta_activo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Tabla de repartidores del sistema';

-- ============================================================
-- TABLA: tokens_sesion
-- Maneja las sesiones activas de los usuarios
-- ============================================================
CREATE TABLE IF NOT EXISTS tokens_sesion (
    id_token INT PRIMARY KEY AUTO_INCREMENT,
    id_repartidor INT NOT NULL,
    jwt_token TEXT NOT NULL COMMENT 'Token JWT generado',
    info_dispositivo VARCHAR(300) COMMENT 'Información del dispositivo',
    direccion_ip VARCHAR(50) COMMENT 'IP desde donde se conectó',
    creado_en DATETIME DEFAULT CURRENT_TIMESTAMP,
    expira_en DATETIME NOT NULL COMMENT 'Fecha/hora de expiración del token',
    token_activo BOOLEAN DEFAULT TRUE COMMENT 'Si el token sigue siendo válido',
    FOREIGN KEY (id_repartidor) REFERENCES repartidores(id_repartidor) ON DELETE CASCADE,
    INDEX idx_repartidor (id_repartidor),
    INDEX idx_activo (token_activo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Tokens de sesión activos';

-- ============================================================
-- TABLA: envios
-- Información de los paquetes a entregar
-- ============================================================
CREATE TABLE IF NOT EXISTS envios (
    id_envio INT PRIMARY KEY AUTO_INCREMENT,
    numero_guia VARCHAR(25) UNIQUE NOT NULL COMMENT 'Número de guía único ej: ENV-2024-0001',
    id_repartidor INT COMMENT 'Repartidor asignado',
    receptor_nombre VARCHAR(120) NOT NULL COMMENT 'Nombre de quien recibirá',
    receptor_telefono VARCHAR(25) COMMENT 'Teléfono del receptor',
    calle VARCHAR(220) NOT NULL,
    numero_exterior VARCHAR(25),
    colonia VARCHAR(120),
    municipio_ciudad VARCHAR(120),
    codigo_postal VARCHAR(12),
    referencias_adicionales TEXT COMMENT 'Referencias para ubicar la dirección',
    lat_destino DECIMAL(10,8) COMMENT 'Latitud del punto de entrega',
    lng_destino DECIMAL(11,8) COMMENT 'Longitud del punto de entrega',
    estatus_envio ENUM('asignado', 'en_camino', 'completado', 'fallido') DEFAULT 'asignado' COMMENT 'Estado actual del envío',
    fecha_asignacion DATETIME COMMENT 'Cuándo se asignó al repartidor',
    fecha_completado DATETIME COMMENT 'Cuándo se marcó como entregado',
    observaciones TEXT COMMENT 'Notas adicionales',
    creado_en DATETIME DEFAULT CURRENT_TIMESTAMP,
    modificado_en DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_repartidor) REFERENCES repartidores(id_repartidor) ON DELETE SET NULL,
    INDEX idx_repartidor (id_repartidor),
    INDEX idx_estatus (estatus_envio),
    INDEX idx_guia (numero_guia)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Paquetes/envíos a entregar';

-- ============================================================
-- TABLA: confirmaciones_entrega
-- Registro de entregas realizadas con evidencia
-- ============================================================
CREATE TABLE IF NOT EXISTS confirmaciones_entrega (
    id_confirmacion INT PRIMARY KEY AUTO_INCREMENT,
    id_envio INT UNIQUE NOT NULL COMMENT 'Envío al que corresponde esta confirmación',
    id_repartidor INT NOT NULL COMMENT 'Repartidor que realizó la entrega',
    lat_confirmacion DECIMAL(10,8) NOT NULL COMMENT 'Latitud GPS donde se entregó',
    lng_confirmacion DECIMAL(11,8) NOT NULL COMMENT 'Longitud GPS donde se entregó',
    precision_metros DECIMAL(10,2) COMMENT 'Precisión del GPS en metros',
    imagen_evidencia LONGTEXT COMMENT 'Foto de evidencia en Base64',
    nombre_receptor VARCHAR(120) COMMENT 'Nombre de quien recibió el paquete',
    resultado_entrega ENUM('exitosa', 'rechazada', 'parcial') NOT NULL DEFAULT 'exitosa',
    razon_fallo TEXT COMMENT 'Motivo si la entrega falló',
    comentarios TEXT COMMENT 'Notas adicionales del repartidor',
    registrado_en DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_envio) REFERENCES envios(id_envio) ON DELETE CASCADE,
    FOREIGN KEY (id_repartidor) REFERENCES repartidores(id_repartidor) ON DELETE CASCADE,
    INDEX idx_envio (id_envio),
    INDEX idx_repartidor (id_repartidor)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Confirmaciones de entrega con evidencia';

-- ============================================================
-- DATOS DE PRUEBA
-- ============================================================

-- Insertar repartidor de prueba
-- Usuario: repartidor1 | Contraseña: 123456
-- Usuario: repartidor2 | Contraseña: 123456
-- Hash generado con bcrypt (12 rounds) - verificado y compatible con bcrypt 5.x
INSERT INTO repartidores (usuario, clave_hash, correo, nombre_completo, num_telefono) VALUES 
('repartidor1', '$2b$12$Ro5nJcjHaB1klSczPlGM6..mZCTvlPnI4vnCUSBDoSosWEGdh6uLq', 'repartidor1@pqexpress.mx', 'Miguel Ángel Hernández Torres', '5512345678'),
('repartidor2', '$2b$12$Ro5nJcjHaB1klSczPlGM6..mZCTvlPnI4vnCUSBDoSosWEGdh6uLq', 'repartidor2@pqexpress.mx', 'Laura Patricia Gómez Ruiz', '5598765432');

-- Insertar envíos de prueba con coordenadas reales de México
INSERT INTO envios (numero_guia, id_repartidor, receptor_nombre, receptor_telefono, calle, numero_exterior, colonia, municipio_ciudad, codigo_postal, lat_destino, lng_destino, estatus_envio, fecha_asignacion) VALUES
('ENV-2024-0001', 1, 'Roberto Sánchez Mendoza', '5541234567', 'Paseo de la Reforma', '505', 'Cuauhtémoc', 'Ciudad de México', '06500', 19.4284, -99.1676, 'asignado', NOW()),
('ENV-2024-0002', 1, 'Elena Ramírez Vega', '5552345678', 'Av. Insurgentes Norte', '1500', 'Lindavista', 'Ciudad de México', '07300', 19.4856, -99.1283, 'asignado', NOW()),
('ENV-2024-0003', 1, 'Francisco Jiménez Luna', '5563456789', 'Calzada de Tlalpan', '1200', 'Portales', 'Ciudad de México', '03300', 19.3689, -99.1439, 'en_camino', NOW()),
('ENV-2024-0004', 1, 'Carmen Ortiz Delgado', '5574567890', 'Av. Universidad', '800', 'Del Valle', 'Ciudad de México', '03100', 19.3807, -99.1775, 'asignado', NOW()),
('ENV-2024-0005', 2, 'Andrés Moreno Castillo', '5585678901', 'Periférico Sur', '4000', 'Pedregal', 'Ciudad de México', '04500', 19.3134, -99.1963, 'asignado', NOW());

-- ============================================================
-- PROCEDIMIENTOS ALMACENADOS ÚTILES
-- ============================================================

DELIMITER //

-- Procedimiento para obtener envíos de un repartidor
CREATE PROCEDURE sp_obtener_envios_repartidor(IN p_id_repartidor INT, IN p_estatus VARCHAR(20))
BEGIN
    IF p_estatus IS NULL OR p_estatus = '' THEN
        SELECT * FROM envios WHERE id_repartidor = p_id_repartidor ORDER BY creado_en DESC;
    ELSE
        SELECT * FROM envios WHERE id_repartidor = p_id_repartidor AND estatus_envio = p_estatus ORDER BY creado_en DESC;
    END IF;
END //

-- Procedimiento para registrar una entrega
CREATE PROCEDURE sp_registrar_entrega(
    IN p_id_envio INT,
    IN p_id_repartidor INT,
    IN p_lat DECIMAL(10,8),
    IN p_lng DECIMAL(11,8),
    IN p_precision DECIMAL(10,2),
    IN p_imagen LONGTEXT,
    IN p_receptor VARCHAR(120),
    IN p_resultado VARCHAR(20),
    IN p_comentarios TEXT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Insertar confirmación
    INSERT INTO confirmaciones_entrega (id_envio, id_repartidor, lat_confirmacion, lng_confirmacion, precision_metros, imagen_evidencia, nombre_receptor, resultado_entrega, comentarios)
    VALUES (p_id_envio, p_id_repartidor, p_lat, p_lng, p_precision, p_imagen, p_receptor, p_resultado, p_comentarios);
    
    -- Actualizar estado del envío
    UPDATE envios SET estatus_envio = 'completado', fecha_completado = NOW() WHERE id_envio = p_id_envio;
    
    COMMIT;
END //

DELIMITER ;

-- ============================================================
-- VISTAS ÚTILES
-- ============================================================

-- Vista de envíos con información completa
CREATE OR REPLACE VIEW vista_envios_completos AS
SELECT 
    e.id_envio,
    e.numero_guia,
    e.receptor_nombre,
    e.receptor_telefono,
    CONCAT(e.calle, ' ', COALESCE(e.numero_exterior, ''), ', ', COALESCE(e.colonia, ''), ', ', COALESCE(e.municipio_ciudad, '')) AS direccion_completa,
    e.codigo_postal,
    e.lat_destino,
    e.lng_destino,
    e.estatus_envio,
    e.referencias_adicionales,
    e.fecha_asignacion,
    e.fecha_completado,
    r.nombre_completo AS nombre_repartidor,
    r.num_telefono AS telefono_repartidor
FROM envios e
LEFT JOIN repartidores r ON e.id_repartidor = r.id_repartidor;

-- Vista de entregas realizadas con detalles
CREATE OR REPLACE VIEW vista_entregas_realizadas AS
SELECT 
    c.id_confirmacion,
    e.numero_guia,
    e.receptor_nombre AS destinatario,
    c.nombre_receptor AS recibio,
    c.resultado_entrega,
    c.lat_confirmacion,
    c.lng_confirmacion,
    c.registrado_en,
    r.nombre_completo AS repartidor
FROM confirmaciones_entrega c
JOIN envios e ON c.id_envio = e.id_envio
JOIN repartidores r ON c.id_repartidor = r.id_repartidor;

-- ============================================================
-- PERMISOS (ejecutar como root si es necesario)
-- ============================================================
-- CREATE USER IF NOT EXISTS 'pqexpress_user'@'localhost' IDENTIFIED BY 'PqExpr3ss_2024!';
-- GRANT ALL PRIVILEGES ON pqexpress_db.* TO 'pqexpress_user'@'localhost';
-- FLUSH PRIVILEGES;

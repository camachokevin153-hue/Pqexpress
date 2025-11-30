# ============================================================
# PQEXPRESS - Modelos ORM (SQLAlchemy)
# Define la estructura de las tablas de la base de datos
# ============================================================

from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, DECIMAL, Enum, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .database import Base
import enum


class EstatusEnvio(str, enum.Enum):
    """Enum para los estados posibles de un envío."""
    ASIGNADO = "asignado"
    EN_CAMINO = "en_camino"
    COMPLETADO = "completado"
    FALLIDO = "fallido"


class ResultadoEntrega(str, enum.Enum):
    """Enum para los resultados posibles de una entrega."""
    EXITOSA = "exitosa"
    RECHAZADA = "rechazada"
    PARCIAL = "parcial"


class Repartidor(Base):
    """
    Modelo para la tabla 'repartidores'.
    Almacena información de los agentes de entrega.
    """
    __tablename__ = "repartidores"
    
    id_repartidor = Column(Integer, primary_key=True, index=True, autoincrement=True)
    usuario = Column(String(60), unique=True, nullable=False, index=True)
    clave_hash = Column(String(255), nullable=False)
    correo = Column(String(120), unique=True)
    nombre_completo = Column(String(120), nullable=False)
    num_telefono = Column(String(25))
    esta_activo = Column(Boolean, default=True, index=True)
    fecha_alta = Column(DateTime, server_default=func.now())
    ultima_conexion = Column(DateTime)
    
    # Relaciones
    tokens = relationship("TokenSesion", back_populates="repartidor", cascade="all, delete-orphan")
    envios = relationship("Envio", back_populates="repartidor")
    confirmaciones = relationship("ConfirmacionEntrega", back_populates="repartidor")
    
    def __repr__(self):
        return f"<Repartidor(id={self.id_repartidor}, usuario='{self.usuario}')>"


class TokenSesion(Base):
    """
    Modelo para la tabla 'tokens_sesion'.
    Maneja las sesiones activas de los usuarios con JWT.
    """
    __tablename__ = "tokens_sesion"
    
    id_token = Column(Integer, primary_key=True, index=True, autoincrement=True)
    id_repartidor = Column(Integer, ForeignKey("repartidores.id_repartidor", ondelete="CASCADE"), nullable=False)
    jwt_token = Column(Text, nullable=False)
    info_dispositivo = Column(String(300))
    direccion_ip = Column(String(50))
    creado_en = Column(DateTime, server_default=func.now())
    expira_en = Column(DateTime, nullable=False)
    token_activo = Column(Boolean, default=True, index=True)
    
    # Relación con Repartidor
    repartidor = relationship("Repartidor", back_populates="tokens")
    
    def __repr__(self):
        return f"<TokenSesion(id={self.id_token}, repartidor_id={self.id_repartidor}, activo={self.token_activo})>"


class Envio(Base):
    """
    Modelo para la tabla 'envios'.
    Información de los paquetes a entregar.
    """
    __tablename__ = "envios"
    
    id_envio = Column(Integer, primary_key=True, index=True, autoincrement=True)
    numero_guia = Column(String(25), unique=True, nullable=False, index=True)
    id_repartidor = Column(Integer, ForeignKey("repartidores.id_repartidor", ondelete="SET NULL"))
    receptor_nombre = Column(String(120), nullable=False)
    receptor_telefono = Column(String(25))
    calle = Column(String(220), nullable=False)
    numero_exterior = Column(String(25))
    colonia = Column(String(120))
    municipio_ciudad = Column(String(120))
    codigo_postal = Column(String(12))
    referencias_adicionales = Column(Text)
    lat_destino = Column(DECIMAL(10, 8))
    lng_destino = Column(DECIMAL(11, 8))
    estatus_envio = Column(
        Enum('asignado', 'en_camino', 'completado', 'fallido', name='estatus_envio_enum'),
        default='asignado',
        index=True
    )
    fecha_asignacion = Column(DateTime)
    fecha_completado = Column(DateTime)
    observaciones = Column(Text)
    creado_en = Column(DateTime, server_default=func.now())
    modificado_en = Column(DateTime, server_default=func.now(), onupdate=func.now())
    
    # Relaciones
    repartidor = relationship("Repartidor", back_populates="envios")
    confirmacion = relationship("ConfirmacionEntrega", back_populates="envio", uselist=False)
    
    @property
    def direccion_completa(self):
        """Retorna la dirección formateada completa."""
        partes = [self.calle]
        if self.numero_exterior:
            partes.append(f"#{self.numero_exterior}")
        if self.colonia:
            partes.append(f", {self.colonia}")
        if self.municipio_ciudad:
            partes.append(f", {self.municipio_ciudad}")
        if self.codigo_postal:
            partes.append(f", CP {self.codigo_postal}")
        return " ".join(partes)
    
    def __repr__(self):
        return f"<Envio(id={self.id_envio}, guia='{self.numero_guia}', estado='{self.estatus_envio}')>"


class ConfirmacionEntrega(Base):
    """
    Modelo para la tabla 'confirmaciones_entrega'.
    Registro de entregas realizadas con evidencia fotográfica y GPS.
    """
    __tablename__ = "confirmaciones_entrega"
    
    id_confirmacion = Column(Integer, primary_key=True, index=True, autoincrement=True)
    id_envio = Column(Integer, ForeignKey("envios.id_envio", ondelete="CASCADE"), unique=True, nullable=False)
    id_repartidor = Column(Integer, ForeignKey("repartidores.id_repartidor", ondelete="CASCADE"), nullable=False)
    lat_confirmacion = Column(DECIMAL(10, 8), nullable=False)
    lng_confirmacion = Column(DECIMAL(11, 8), nullable=False)
    precision_metros = Column(DECIMAL(10, 2))
    imagen_evidencia = Column(Text)  # Base64 de la imagen
    nombre_receptor = Column(String(120))
    resultado_entrega = Column(
        Enum('exitosa', 'rechazada', 'parcial', name='resultado_entrega_enum'),
        default='exitosa',
        nullable=False
    )
    razon_fallo = Column(Text)
    comentarios = Column(Text)
    registrado_en = Column(DateTime, server_default=func.now())
    
    # Relaciones
    envio = relationship("Envio", back_populates="confirmacion")
    repartidor = relationship("Repartidor", back_populates="confirmaciones")
    
    def __repr__(self):
        return f"<ConfirmacionEntrega(id={self.id_confirmacion}, envio_id={self.id_envio}, resultado='{self.resultado_entrega}')>"

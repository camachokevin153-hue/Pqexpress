# ============================================================
# PQEXPRESS - Schemas Pydantic
# Validación de datos de entrada y salida de la API
# ============================================================

from pydantic import BaseModel, Field, EmailStr, validator
from typing import Optional, List
from datetime import datetime
from enum import Enum


# ============================================================
# ENUMS
# ============================================================

class EstatusEnvioEnum(str, Enum):
    """Estados posibles de un envío."""
    ASIGNADO = "asignado"
    EN_CAMINO = "en_camino"
    COMPLETADO = "completado"
    FALLIDO = "fallido"


class ResultadoEntregaEnum(str, Enum):
    """Resultados posibles de una entrega."""
    EXITOSA = "exitosa"
    RECHAZADA = "rechazada"
    PARCIAL = "parcial"


# ============================================================
# SCHEMAS DE AUTENTICACIÓN
# ============================================================

class LoginRequest(BaseModel):
    """Schema para solicitud de inicio de sesión."""
    usuario: str = Field(..., min_length=3, max_length=60, description="Nombre de usuario")
    clave: str = Field(..., min_length=4, max_length=100, description="Contraseña")
    info_dispositivo: Optional[str] = Field(None, max_length=300, description="Información del dispositivo")
    
    class Config:
        json_schema_extra = {
            "example": {
                "usuario": "repartidor1",
                "clave": "123456",
                "info_dispositivo": "Android 14 - Samsung Galaxy S24"
            }
        }


class LoginResponse(BaseModel):
    """Schema para respuesta de inicio de sesión exitoso."""
    mensaje: str = Field(..., description="Mensaje de resultado")
    token: str = Field(..., description="Token JWT para autenticación")
    tipo_token: str = Field(default="Bearer", description="Tipo de token")
    expira_en: datetime = Field(..., description="Fecha y hora de expiración")
    usuario: "RepartidorResponse" = Field(..., description="Datos del usuario")
    
    class Config:
        json_schema_extra = {
            "example": {
                "mensaje": "Inicio de sesión exitoso",
                "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                "tipo_token": "Bearer",
                "expira_en": "2024-11-30T08:00:00",
                "usuario": {
                    "id_repartidor": 1,
                    "usuario": "repartidor1",
                    "nombre_completo": "Miguel Ángel Hernández Torres"
                }
            }
        }


class TokenValidationRequest(BaseModel):
    """Schema para validar un token."""
    token: str = Field(..., description="Token JWT a validar")


class TokenValidationResponse(BaseModel):
    """Schema para respuesta de validación de token."""
    valido: bool = Field(..., description="Si el token es válido")
    mensaje: str = Field(..., description="Mensaje descriptivo")
    usuario: Optional["RepartidorResponse"] = Field(None, description="Datos del usuario si el token es válido")


# ============================================================
# SCHEMAS DE REPARTIDOR
# ============================================================

class RepartidorBase(BaseModel):
    """Schema base para repartidor."""
    usuario: str = Field(..., min_length=3, max_length=60)
    correo: Optional[EmailStr] = None
    nombre_completo: str = Field(..., min_length=2, max_length=120)
    num_telefono: Optional[str] = Field(None, max_length=25)


class RepartidorCreate(RepartidorBase):
    """Schema para crear un nuevo repartidor."""
    clave: str = Field(..., min_length=6, max_length=100, description="Contraseña (mínimo 6 caracteres)")


class RepartidorResponse(BaseModel):
    """Schema para respuesta con datos de repartidor."""
    id_repartidor: int
    usuario: str
    correo: Optional[str] = None
    nombre_completo: str
    num_telefono: Optional[str] = None
    esta_activo: bool = True
    fecha_alta: Optional[datetime] = None
    ultima_conexion: Optional[datetime] = None
    
    class Config:
        from_attributes = True


# ============================================================
# SCHEMAS DE ENVÍO
# ============================================================

class EnvioBase(BaseModel):
    """Schema base para envío."""
    receptor_nombre: str = Field(..., min_length=2, max_length=120)
    receptor_telefono: Optional[str] = Field(None, max_length=25)
    calle: str = Field(..., min_length=3, max_length=220)
    numero_exterior: Optional[str] = Field(None, max_length=25)
    colonia: Optional[str] = Field(None, max_length=120)
    municipio_ciudad: Optional[str] = Field(None, max_length=120)
    codigo_postal: Optional[str] = Field(None, max_length=12)
    referencias_adicionales: Optional[str] = None
    lat_destino: Optional[float] = Field(None, ge=-90, le=90)
    lng_destino: Optional[float] = Field(None, ge=-180, le=180)
    observaciones: Optional[str] = None


class EnvioCreate(EnvioBase):
    """Schema para crear un nuevo envío."""
    id_repartidor: Optional[int] = None


class EnvioResponse(BaseModel):
    """Schema para respuesta con datos de envío."""
    id_envio: int
    numero_guia: str
    id_repartidor: Optional[int] = None
    receptor_nombre: str
    receptor_telefono: Optional[str] = None
    calle: str
    numero_exterior: Optional[str] = None
    colonia: Optional[str] = None
    municipio_ciudad: Optional[str] = None
    codigo_postal: Optional[str] = None
    direccion_completa: Optional[str] = None
    referencias_adicionales: Optional[str] = None
    lat_destino: Optional[float] = None
    lng_destino: Optional[float] = None
    estatus_envio: str
    fecha_asignacion: Optional[datetime] = None
    fecha_completado: Optional[datetime] = None
    observaciones: Optional[str] = None
    creado_en: Optional[datetime] = None
    modificado_en: Optional[datetime] = None
    
    class Config:
        from_attributes = True
    
    @validator('lat_destino', 'lng_destino', pre=True)
    def convert_decimal_to_float(cls, v):
        """Convierte Decimal a float para serialización JSON."""
        if v is not None:
            return float(v)
        return v


class EnvioListResponse(BaseModel):
    """Schema para lista de envíos."""
    total: int = Field(..., description="Total de envíos")
    envios: List[EnvioResponse] = Field(..., description="Lista de envíos")


class IniciarRutaRequest(BaseModel):
    """Schema para iniciar ruta de un envío."""
    observaciones: Optional[str] = Field(None, description="Observaciones al iniciar ruta")


class IniciarRutaResponse(BaseModel):
    """Schema para respuesta de iniciar ruta."""
    mensaje: str
    envio: EnvioResponse


# ============================================================
# SCHEMAS DE CONFIRMACIÓN DE ENTREGA
# ============================================================

class ConfirmacionEntregaRequest(BaseModel):
    """Schema para registrar una entrega."""
    lat_confirmacion: float = Field(..., ge=-90, le=90, description="Latitud GPS de la entrega")
    lng_confirmacion: float = Field(..., ge=-180, le=180, description="Longitud GPS de la entrega")
    precision_metros: Optional[float] = Field(None, ge=0, description="Precisión del GPS en metros")
    imagen_evidencia: Optional[str] = Field(None, description="Foto de evidencia en Base64")
    nombre_receptor: Optional[str] = Field(None, max_length=120, description="Nombre de quien recibió")
    resultado_entrega: ResultadoEntregaEnum = Field(
        default=ResultadoEntregaEnum.EXITOSA, 
        description="Resultado de la entrega"
    )
    razon_fallo: Optional[str] = Field(None, description="Razón si la entrega falló")
    comentarios: Optional[str] = Field(None, description="Comentarios adicionales")
    
    class Config:
        json_schema_extra = {
            "example": {
                "lat_confirmacion": 19.4326,
                "lng_confirmacion": -99.1332,
                "precision_metros": 5.5,
                "imagen_evidencia": "base64_encoded_image_data...",
                "nombre_receptor": "Juan Pérez",
                "resultado_entrega": "exitosa",
                "comentarios": "Entrega sin novedad"
            }
        }


class ConfirmacionEntregaResponse(BaseModel):
    """Schema para respuesta de confirmación de entrega."""
    id_confirmacion: int
    id_envio: int
    id_repartidor: int
    lat_confirmacion: float
    lng_confirmacion: float
    precision_metros: Optional[float] = None
    nombre_receptor: Optional[str] = None
    resultado_entrega: str
    razon_fallo: Optional[str] = None
    comentarios: Optional[str] = None
    registrado_en: Optional[datetime] = None
    
    class Config:
        from_attributes = True
    
    @validator('lat_confirmacion', 'lng_confirmacion', 'precision_metros', pre=True)
    def convert_decimal_to_float(cls, v):
        """Convierte Decimal a float para serialización JSON."""
        if v is not None:
            return float(v)
        return v


class RegistrarEntregaResponse(BaseModel):
    """Schema para respuesta completa de registro de entrega."""
    mensaje: str
    confirmacion: ConfirmacionEntregaResponse
    envio: EnvioResponse


# ============================================================
# SCHEMAS DE ERROR
# ============================================================

class ErrorResponse(BaseModel):
    """Schema para respuestas de error."""
    detalle: str = Field(..., description="Mensaje de error")
    codigo: Optional[str] = Field(None, description="Código de error interno")
    
    class Config:
        json_schema_extra = {
            "example": {
                "detalle": "Credenciales inválidas",
                "codigo": "AUTH_001"
            }
        }


class MensajeResponse(BaseModel):
    """Schema para respuestas simples con mensaje."""
    mensaje: str = Field(..., description="Mensaje de resultado")
    exito: bool = Field(default=True, description="Si la operación fue exitosa")


# Actualizar referencias forward
LoginResponse.model_rebuild()
TokenValidationResponse.model_rebuild()

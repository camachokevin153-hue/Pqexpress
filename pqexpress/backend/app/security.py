# ============================================================
# PQEXPRESS - Módulo de Seguridad
# Manejo de JWT, bcrypt y validación de sesiones
# ============================================================

from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
import bcrypt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from dotenv import load_dotenv
import os

from .database import get_db
from .models import Repartidor, TokenSesion

# Cargar variables de entorno
load_dotenv()

# ============================================================
# CONFIGURACIÓN
# ============================================================

# Configuración JWT desde variables de entorno
JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "clave_secreta_por_defecto_cambiar")
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
JWT_EXPIRATION_MINUTES = int(os.getenv("JWT_EXPIRATION_MINUTES", "480"))  # 8 horas

# Esquema de seguridad HTTP Bearer para JWT
security = HTTPBearer()


# ============================================================
# FUNCIONES DE HASH DE CONTRASEÑAS
# ============================================================

def hashear_clave(clave: str) -> str:
    """
    Genera un hash bcrypt de la contraseña.
    
    Args:
        clave: Contraseña en texto plano.
        
    Returns:
        str: Hash bcrypt de la contraseña (60 caracteres).
        
    Example:
        >>> hash = hashear_clave("mi_contraseña")
        >>> print(hash)  # $2b$12$...
    """
    clave_bytes = clave.encode('utf-8')
    salt = bcrypt.gensalt(rounds=12)
    hash_bytes = bcrypt.hashpw(clave_bytes, salt)
    return hash_bytes.decode('utf-8')


def verificar_clave(clave_plana: str, clave_hash: str) -> bool:
    """
    Verifica si una contraseña coincide con su hash.
    
    Args:
        clave_plana: Contraseña en texto plano a verificar.
        clave_hash: Hash bcrypt almacenado.
        
    Returns:
        bool: True si la contraseña coincide, False en caso contrario.
        
    Example:
        >>> hash = hashear_clave("123456")
        >>> verificar_clave("123456", hash)  # True
        >>> verificar_clave("654321", hash)  # False
    """
    try:
        clave_bytes = clave_plana.encode('utf-8')
        hash_bytes = clave_hash.encode('utf-8')
        return bcrypt.checkpw(clave_bytes, hash_bytes)
    except Exception:
        return False


# ============================================================
# FUNCIONES DE JWT
# ============================================================

def crear_token_acceso(datos: dict, minutos_expiracion: Optional[int] = None) -> tuple[str, datetime]:
    """
    Crea un token JWT con los datos proporcionados.
    
    Args:
        datos: Diccionario con datos a incluir en el token (payload).
        minutos_expiracion: Minutos hasta expiración (usa default si no se especifica).
        
    Returns:
        tuple: (token_jwt, fecha_expiracion)
        
    Example:
        >>> token, expira = crear_token_acceso({"sub": "1", "usuario": "repartidor1"})
    """
    # Copiar datos para no modificar el original
    a_codificar = datos.copy()
    
    # Calcular fecha de expiración
    if minutos_expiracion is None:
        minutos_expiracion = JWT_EXPIRATION_MINUTES
    expiracion = datetime.utcnow() + timedelta(minutes=minutos_expiracion)
    
    # Agregar claim de expiración
    a_codificar.update({"exp": expiracion})
    
    # Generar token
    token_jwt = jwt.encode(a_codificar, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)
    
    return token_jwt, expiracion


def decodificar_token(token: str) -> Optional[dict]:
    """
    Decodifica y valida un token JWT.
    
    Args:
        token: Token JWT a decodificar.
        
    Returns:
        dict: Payload del token si es válido, None si es inválido o expirado.
        
    Example:
        >>> payload = decodificar_token("eyJhbGciOiJIUzI1NiIs...")
        >>> if payload:
        ...     print(payload["sub"])  # ID del usuario
    """
    try:
        payload = jwt.decode(token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])
        return payload
    except JWTError as e:
        print(f"Error al decodificar token: {e}")
        return None


# ============================================================
# FUNCIONES DE SESIÓN
# ============================================================

def invalidar_sesiones_anteriores(db: Session, id_repartidor: int) -> int:
    """
    Invalida todas las sesiones activas anteriores de un repartidor.
    Esto garantiza que solo haya una sesión activa por usuario.
    
    Args:
        db: Sesión de base de datos.
        id_repartidor: ID del repartidor.
        
    Returns:
        int: Número de sesiones invalidadas.
    """
    resultado = db.query(TokenSesion).filter(
        TokenSesion.id_repartidor == id_repartidor,
        TokenSesion.token_activo == True
    ).update({"token_activo": False})
    db.commit()
    return resultado


def crear_sesion(
    db: Session, 
    id_repartidor: int, 
    token: str, 
    expiracion: datetime,
    dispositivo: Optional[str] = None,
    ip: Optional[str] = None
) -> TokenSesion:
    """
    Crea una nueva sesión en la base de datos.
    
    Args:
        db: Sesión de base de datos.
        id_repartidor: ID del repartidor.
        token: Token JWT generado.
        expiracion: Fecha/hora de expiración.
        dispositivo: Información del dispositivo (opcional).
        ip: Dirección IP (opcional).
        
    Returns:
        TokenSesion: Objeto de sesión creado.
    """
    nueva_sesion = TokenSesion(
        id_repartidor=id_repartidor,
        jwt_token=token,
        info_dispositivo=dispositivo,
        direccion_ip=ip,
        expira_en=expiracion,
        token_activo=True
    )
    db.add(nueva_sesion)
    db.commit()
    db.refresh(nueva_sesion)
    return nueva_sesion


def validar_sesion_activa(db: Session, token: str) -> Optional[TokenSesion]:
    """
    Verifica que un token tenga una sesión activa en la base de datos.
    
    Args:
        db: Sesión de base de datos.
        token: Token JWT a validar.
        
    Returns:
        TokenSesion: Objeto de sesión si está activa, None en caso contrario.
    """
    sesion = db.query(TokenSesion).filter(
        TokenSesion.jwt_token == token,
        TokenSesion.token_activo == True,
        TokenSesion.expira_en > datetime.utcnow()
    ).first()
    return sesion


def cerrar_sesion(db: Session, token: str) -> bool:
    """
    Cierra una sesión invalidando el token.
    
    Args:
        db: Sesión de base de datos.
        token: Token JWT a invalidar.
        
    Returns:
        bool: True si se cerró la sesión, False si no existía.
    """
    resultado = db.query(TokenSesion).filter(
        TokenSesion.jwt_token == token
    ).update({"token_activo": False})
    db.commit()
    return resultado > 0


# ============================================================
# DEPENDENCIAS DE FASTAPI PARA AUTENTICACIÓN
# ============================================================

async def obtener_usuario_actual(
    credenciales: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> Repartidor:
    """
    Dependencia de FastAPI para obtener el usuario autenticado.
    Valida el token JWT y verifica que la sesión esté activa en BD.
    
    Args:
        credenciales: Credenciales HTTP Bearer (token).
        db: Sesión de base de datos.
        
    Returns:
        Repartidor: Usuario autenticado.
        
    Raises:
        HTTPException: Si el token es inválido o la sesión no está activa.
        
    Example:
        @app.get("/perfil")
        async def obtener_perfil(usuario: Repartidor = Depends(obtener_usuario_actual)):
            return usuario
    """
    # Excepción para credenciales inválidas
    excepcion_credenciales = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token de autenticación inválido o expirado",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    token = credenciales.credentials
    
    # Decodificar token JWT
    payload = decodificar_token(token)
    if payload is None:
        raise excepcion_credenciales
    
    # Obtener ID del usuario del payload
    id_usuario: str = payload.get("sub")
    if id_usuario is None:
        raise excepcion_credenciales
    
    # Verificar que la sesión esté activa en BD
    sesion = validar_sesion_activa(db, token)
    if sesion is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sesión expirada o invalidada. Por favor inicie sesión nuevamente.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Obtener usuario de la base de datos
    usuario = db.query(Repartidor).filter(
        Repartidor.id_repartidor == int(id_usuario)
    ).first()
    
    if usuario is None:
        raise excepcion_credenciales
    
    if not usuario.esta_activo:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Usuario desactivado. Contacte al administrador."
        )
    
    return usuario


async def obtener_token_actual(
    credenciales: HTTPAuthorizationCredentials = Depends(security)
) -> str:
    """
    Dependencia simple para obtener solo el token sin validar completamente.
    Útil para el endpoint de logout.
    
    Args:
        credenciales: Credenciales HTTP Bearer.
        
    Returns:
        str: Token JWT.
    """
    return credenciales.credentials

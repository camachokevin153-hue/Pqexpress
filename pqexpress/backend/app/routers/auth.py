# ============================================================
# PQEXPRESS - Router de Autenticación
# Endpoints: login, logout, validar token, obtener perfil
# ============================================================

from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from datetime import datetime

from ..database import get_db
from ..models import Repartidor
from ..schemas import (
    LoginRequest, LoginResponse, TokenValidationRequest, TokenValidationResponse,
    RepartidorResponse, MensajeResponse, ErrorResponse
)
from ..security import (
    verificar_clave, crear_token_acceso, decodificar_token,
    invalidar_sesiones_anteriores, crear_sesion, validar_sesion_activa,
    cerrar_sesion, obtener_usuario_actual, obtener_token_actual
)

# Crear router con prefijo y tags para documentación
router = APIRouter(
    prefix="/auth",
    tags=["Autenticación"],
    responses={
        401: {"model": ErrorResponse, "description": "No autorizado"},
        403: {"model": ErrorResponse, "description": "Acceso prohibido"},
    }
)


@router.post(
    "/login",
    response_model=LoginResponse,
    summary="Iniciar sesión",
    description="Autentica al repartidor y retorna un token JWT. Invalida sesiones anteriores."
)
async def login(
    datos_login: LoginRequest,
    request: Request,
    db: Session = Depends(get_db)
):
    """
    Endpoint para iniciar sesión.
    
    - Valida credenciales (usuario y contraseña)
    - Invalida sesiones anteriores del usuario
    - Genera nuevo token JWT
    - Guarda la sesión en la base de datos
    - Actualiza última conexión del usuario
    
    **Credenciales de prueba:**
    - Usuario: repartidor1
    - Contraseña: 123456
    """
    # Buscar usuario en la base de datos
    usuario = db.query(Repartidor).filter(
        Repartidor.usuario == datos_login.usuario
    ).first()
    
    # Validar que el usuario existe
    if not usuario:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario o contraseña incorrectos",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Validar contraseña con bcrypt
    if not verificar_clave(datos_login.clave, usuario.clave_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario o contraseña incorrectos",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Verificar que el usuario esté activo
    if not usuario.esta_activo:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Tu cuenta está desactivada. Contacta al administrador."
        )
    
    # Invalidar sesiones anteriores (solo una sesión activa por usuario)
    invalidar_sesiones_anteriores(db, usuario.id_repartidor)
    
    # Crear nuevo token JWT
    datos_token = {
        "sub": str(usuario.id_repartidor),
        "usuario": usuario.usuario,
        "nombre": usuario.nombre_completo
    }
    token, expiracion = crear_token_acceso(datos_token)
    
    # Obtener IP del cliente
    ip_cliente = request.client.host if request.client else None
    
    # Guardar sesión en la base de datos
    crear_sesion(
        db=db,
        id_repartidor=usuario.id_repartidor,
        token=token,
        expiracion=expiracion,
        dispositivo=datos_login.info_dispositivo,
        ip=ip_cliente
    )
    
    # Actualizar última conexión del usuario
    usuario.ultima_conexion = datetime.utcnow()
    db.commit()
    
    # Construir respuesta
    return LoginResponse(
        mensaje="Inicio de sesión exitoso",
        token=token,
        tipo_token="Bearer",
        expira_en=expiracion,
        usuario=RepartidorResponse.model_validate(usuario)
    )


@router.post(
    "/logout",
    response_model=MensajeResponse,
    summary="Cerrar sesión",
    description="Invalida el token actual y cierra la sesión."
)
async def logout(
    token: str = Depends(obtener_token_actual),
    db: Session = Depends(get_db)
):
    """
    Endpoint para cerrar sesión.
    
    - Invalida el token actual en la base de datos
    - El token ya no será válido para futuras solicitudes
    """
    # Cerrar la sesión (invalidar token en BD)
    sesion_cerrada = cerrar_sesion(db, token)
    
    if sesion_cerrada:
        return MensajeResponse(
            mensaje="Sesión cerrada correctamente",
            exito=True
        )
    else:
        return MensajeResponse(
            mensaje="No se encontró una sesión activa",
            exito=False
        )


@router.get(
    "/me",
    response_model=RepartidorResponse,
    summary="Obtener perfil",
    description="Retorna la información del usuario autenticado."
)
async def obtener_perfil(
    usuario_actual: Repartidor = Depends(obtener_usuario_actual)
):
    """
    Endpoint para obtener información del usuario actual.
    
    Requiere token de autenticación válido.
    """
    return RepartidorResponse.model_validate(usuario_actual)


@router.post(
    "/validar-token",
    response_model=TokenValidationResponse,
    summary="Validar token",
    description="Verifica si un token JWT es válido y la sesión está activa."
)
async def validar_token(
    datos: TokenValidationRequest,
    db: Session = Depends(get_db)
):
    """
    Endpoint para validar un token JWT.
    
    Verifica:
    - Que el token sea un JWT válido y no esté expirado
    - Que exista una sesión activa en la base de datos
    
    Útil para verificar sesión al iniciar la app.
    """
    # Decodificar token
    payload = decodificar_token(datos.token)
    
    if payload is None:
        return TokenValidationResponse(
            valido=False,
            mensaje="Token inválido o expirado",
            usuario=None
        )
    
    # Verificar sesión activa en BD
    sesion = validar_sesion_activa(db, datos.token)
    
    if sesion is None:
        return TokenValidationResponse(
            valido=False,
            mensaje="Sesión no encontrada o expirada",
            usuario=None
        )
    
    # Obtener usuario
    usuario = db.query(Repartidor).filter(
        Repartidor.id_repartidor == sesion.id_repartidor
    ).first()
    
    if usuario is None or not usuario.esta_activo:
        return TokenValidationResponse(
            valido=False,
            mensaje="Usuario no encontrado o desactivado",
            usuario=None
        )
    
    return TokenValidationResponse(
        valido=True,
        mensaje="Token válido",
        usuario=RepartidorResponse.model_validate(usuario)
    )


@router.get(
    "/verificar",
    response_model=MensajeResponse,
    summary="Verificar autenticación",
    description="Endpoint simple para verificar que el usuario está autenticado."
)
async def verificar_autenticacion(
    usuario_actual: Repartidor = Depends(obtener_usuario_actual)
):
    """
    Endpoint simple para verificar autenticación.
    
    Útil para health checks que requieren autenticación.
    """
    return MensajeResponse(
        mensaje=f"Autenticado como {usuario_actual.nombre_completo}",
        exito=True
    )

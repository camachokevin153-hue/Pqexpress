# ============================================================
# PQEXPRESS - Router de Envíos (Paquetes)
# Endpoints: listar, detalle, iniciar ruta, registrar entrega
# ============================================================

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_
from datetime import datetime
from typing import Optional, List

from ..database import get_db
from ..models import Repartidor, Envio, ConfirmacionEntrega
from ..schemas import (
    EnvioResponse, EnvioListResponse, IniciarRutaRequest, IniciarRutaResponse,
    ConfirmacionEntregaRequest, ConfirmacionEntregaResponse, RegistrarEntregaResponse,
    MensajeResponse, ErrorResponse
)
from ..security import obtener_usuario_actual

# Crear router con prefijo y tags
router = APIRouter(
    prefix="/envios",
    tags=["Envíos"],
    responses={
        401: {"model": ErrorResponse, "description": "No autorizado"},
        404: {"model": ErrorResponse, "description": "No encontrado"},
    }
)


def convertir_envio_a_response(envio: Envio) -> EnvioResponse:
    """
    Convierte un objeto Envio de SQLAlchemy a EnvioResponse de Pydantic.
    Maneja la conversión de Decimal a float y la propiedad direccion_completa.
    """
    return EnvioResponse(
        id_envio=envio.id_envio,
        numero_guia=envio.numero_guia,
        id_repartidor=envio.id_repartidor,
        receptor_nombre=envio.receptor_nombre,
        receptor_telefono=envio.receptor_telefono,
        calle=envio.calle,
        numero_exterior=envio.numero_exterior,
        colonia=envio.colonia,
        municipio_ciudad=envio.municipio_ciudad,
        codigo_postal=envio.codigo_postal,
        direccion_completa=envio.direccion_completa,
        referencias_adicionales=envio.referencias_adicionales,
        lat_destino=float(envio.lat_destino) if envio.lat_destino else None,
        lng_destino=float(envio.lng_destino) if envio.lng_destino else None,
        estatus_envio=envio.estatus_envio,
        fecha_asignacion=envio.fecha_asignacion,
        fecha_completado=envio.fecha_completado,
        observaciones=envio.observaciones,
        creado_en=envio.creado_en,
        modificado_en=envio.modificado_en
    )


@router.get(
    "/mis-envios",
    response_model=EnvioListResponse,
    summary="Listar mis envíos",
    description="Obtiene la lista de envíos asignados al repartidor actual."
)
async def listar_mis_envios(
    estatus: Optional[str] = Query(
        None, 
        description="Filtrar por estado: asignado, en_camino, completado, fallido"
    ),
    usuario_actual: Repartidor = Depends(obtener_usuario_actual),
    db: Session = Depends(get_db)
):
    """
    Lista todos los envíos asignados al repartidor autenticado.
    
    - Puede filtrar por estado usando el parámetro 'estatus'
    - Ordena por fecha de creación (más recientes primero)
    """
    # Construir query base
    query = db.query(Envio).filter(
        Envio.id_repartidor == usuario_actual.id_repartidor
    )
    
    # Aplicar filtro de estado si se especificó
    if estatus:
        # Validar que sea un estado válido
        estados_validos = ['asignado', 'en_camino', 'completado', 'fallido']
        if estatus.lower() not in estados_validos:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Estado inválido. Estados válidos: {', '.join(estados_validos)}"
            )
        query = query.filter(Envio.estatus_envio == estatus.lower())
    
    # Ordenar por fecha de creación descendente
    envios = query.order_by(Envio.creado_en.desc()).all()
    
    # Convertir a response
    envios_response = [convertir_envio_a_response(e) for e in envios]
    
    return EnvioListResponse(
        total=len(envios_response),
        envios=envios_response
    )


@router.get(
    "/pendientes",
    response_model=EnvioListResponse,
    summary="Listar envíos pendientes",
    description="Obtiene los envíos asignados que aún no se han iniciado."
)
async def listar_pendientes(
    usuario_actual: Repartidor = Depends(obtener_usuario_actual),
    db: Session = Depends(get_db)
):
    """
    Lista solo los envíos en estado 'asignado' (pendientes de iniciar ruta).
    """
    envios = db.query(Envio).filter(
        Envio.id_repartidor == usuario_actual.id_repartidor,
        Envio.estatus_envio == 'asignado'
    ).order_by(Envio.fecha_asignacion.desc()).all()
    
    envios_response = [convertir_envio_a_response(e) for e in envios]
    
    return EnvioListResponse(
        total=len(envios_response),
        envios=envios_response
    )


@router.get(
    "/en-ruta",
    response_model=EnvioListResponse,
    summary="Listar envíos en ruta",
    description="Obtiene los envíos que están actualmente en camino."
)
async def listar_en_ruta(
    usuario_actual: Repartidor = Depends(obtener_usuario_actual),
    db: Session = Depends(get_db)
):
    """
    Lista solo los envíos en estado 'en_camino' (ruta iniciada).
    """
    envios = db.query(Envio).filter(
        Envio.id_repartidor == usuario_actual.id_repartidor,
        Envio.estatus_envio == 'en_camino'
    ).order_by(Envio.fecha_asignacion.desc()).all()
    
    envios_response = [convertir_envio_a_response(e) for e in envios]
    
    return EnvioListResponse(
        total=len(envios_response),
        envios=envios_response
    )


@router.get(
    "/historial",
    response_model=EnvioListResponse,
    summary="Historial de entregas",
    description="Obtiene el historial de envíos completados."
)
async def obtener_historial(
    limite: int = Query(50, ge=1, le=200, description="Límite de resultados"),
    usuario_actual: Repartidor = Depends(obtener_usuario_actual),
    db: Session = Depends(get_db)
):
    """
    Lista los envíos completados o fallidos (historial).
    
    - Ordena por fecha de completado (más recientes primero)
    - Límite máximo de 200 resultados
    """
    envios = db.query(Envio).filter(
        Envio.id_repartidor == usuario_actual.id_repartidor,
        or_(
            Envio.estatus_envio == 'completado',
            Envio.estatus_envio == 'fallido'
        )
    ).order_by(Envio.fecha_completado.desc()).limit(limite).all()
    
    envios_response = [convertir_envio_a_response(e) for e in envios]
    
    return EnvioListResponse(
        total=len(envios_response),
        envios=envios_response
    )


@router.get(
    "/{id_envio}",
    response_model=EnvioResponse,
    summary="Detalle de envío",
    description="Obtiene el detalle completo de un envío específico."
)
async def obtener_envio(
    id_envio: int,
    usuario_actual: Repartidor = Depends(obtener_usuario_actual),
    db: Session = Depends(get_db)
):
    """
    Obtiene el detalle de un envío por su ID.
    
    - Solo puede ver envíos asignados al usuario actual
    """
    envio = db.query(Envio).filter(
        Envio.id_envio == id_envio,
        Envio.id_repartidor == usuario_actual.id_repartidor
    ).first()
    
    if not envio:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Envío no encontrado o no tienes acceso a él"
        )
    
    return convertir_envio_a_response(envio)


@router.post(
    "/{id_envio}/iniciar-ruta",
    response_model=IniciarRutaResponse,
    summary="Iniciar ruta",
    description="Marca un envío como 'en_camino' para iniciar la entrega."
)
async def iniciar_ruta(
    id_envio: int,
    datos: Optional[IniciarRutaRequest] = None,
    usuario_actual: Repartidor = Depends(obtener_usuario_actual),
    db: Session = Depends(get_db)
):
    """
    Inicia la ruta de entrega de un envío.
    
    - Cambia el estado de 'asignado' a 'en_camino'
    - Solo funciona si el envío está en estado 'asignado'
    - Registra la fecha de inicio
    """
    # Buscar el envío
    envio = db.query(Envio).filter(
        Envio.id_envio == id_envio,
        Envio.id_repartidor == usuario_actual.id_repartidor
    ).first()
    
    if not envio:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Envío no encontrado o no tienes acceso a él"
        )
    
    # Validar estado actual
    if envio.estatus_envio != 'asignado':
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"No se puede iniciar ruta. Estado actual: {envio.estatus_envio}"
        )
    
    # Actualizar estado
    envio.estatus_envio = 'en_camino'
    if datos and datos.observaciones:
        envio.observaciones = datos.observaciones
    
    db.commit()
    db.refresh(envio)
    
    return IniciarRutaResponse(
        mensaje="Ruta iniciada correctamente",
        envio=convertir_envio_a_response(envio)
    )


@router.post(
    "/{id_envio}/confirmar-entrega",
    response_model=RegistrarEntregaResponse,
    summary="Registrar entrega",
    description="Registra la confirmación de entrega con foto y GPS."
)
async def registrar_entrega(
    id_envio: int,
    datos: ConfirmacionEntregaRequest,
    usuario_actual: Repartidor = Depends(obtener_usuario_actual),
    db: Session = Depends(get_db)
):
    """
    Registra la confirmación de entrega de un paquete.
    
    **Datos requeridos:**
    - Coordenadas GPS donde se realizó la entrega
    - Foto de evidencia (Base64)
    
    **Proceso:**
    1. Valida que el envío exista y esté en ruta
    2. Crea el registro de confirmación con GPS y foto
    3. Actualiza el estado del envío a 'completado'
    
    **IMPORTANTE:** Esta es la funcionalidad principal del sistema.
    """
    # Buscar el envío
    envio = db.query(Envio).filter(
        Envio.id_envio == id_envio,
        Envio.id_repartidor == usuario_actual.id_repartidor
    ).first()
    
    if not envio:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Envío no encontrado o no tienes acceso a él"
        )
    
    # Validar estado actual (debe estar en_camino o asignado)
    if envio.estatus_envio not in ['en_camino', 'asignado']:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"No se puede registrar entrega. Estado actual: {envio.estatus_envio}"
        )
    
    # Verificar que no exista ya una confirmación
    confirmacion_existente = db.query(ConfirmacionEntrega).filter(
        ConfirmacionEntrega.id_envio == id_envio
    ).first()
    
    if confirmacion_existente:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Este envío ya tiene una confirmación de entrega registrada"
        )
    
    # Crear la confirmación de entrega
    confirmacion = ConfirmacionEntrega(
        id_envio=id_envio,
        id_repartidor=usuario_actual.id_repartidor,
        lat_confirmacion=datos.lat_confirmacion,
        lng_confirmacion=datos.lng_confirmacion,
        precision_metros=datos.precision_metros,
        imagen_evidencia=datos.imagen_evidencia,
        nombre_receptor=datos.nombre_receptor,
        resultado_entrega=datos.resultado_entrega.value,
        razon_fallo=datos.razon_fallo,
        comentarios=datos.comentarios
    )
    
    db.add(confirmacion)
    
    # Actualizar estado del envío
    if datos.resultado_entrega.value == 'exitosa':
        envio.estatus_envio = 'completado'
    else:
        envio.estatus_envio = 'fallido'
    
    envio.fecha_completado = datetime.utcnow()
    
    db.commit()
    db.refresh(confirmacion)
    db.refresh(envio)
    
    # Construir respuesta
    confirmacion_response = ConfirmacionEntregaResponse(
        id_confirmacion=confirmacion.id_confirmacion,
        id_envio=confirmacion.id_envio,
        id_repartidor=confirmacion.id_repartidor,
        lat_confirmacion=float(confirmacion.lat_confirmacion),
        lng_confirmacion=float(confirmacion.lng_confirmacion),
        precision_metros=float(confirmacion.precision_metros) if confirmacion.precision_metros else None,
        nombre_receptor=confirmacion.nombre_receptor,
        resultado_entrega=confirmacion.resultado_entrega,
        razon_fallo=confirmacion.razon_fallo,
        comentarios=confirmacion.comentarios,
        registrado_en=confirmacion.registrado_en
    )
    
    return RegistrarEntregaResponse(
        mensaje="Entrega registrada exitosamente",
        confirmacion=confirmacion_response,
        envio=convertir_envio_a_response(envio)
    )


@router.get(
    "/{id_envio}/confirmacion",
    response_model=ConfirmacionEntregaResponse,
    summary="Ver confirmación de entrega",
    description="Obtiene los detalles de la confirmación de un envío completado."
)
async def obtener_confirmacion(
    id_envio: int,
    usuario_actual: Repartidor = Depends(obtener_usuario_actual),
    db: Session = Depends(get_db)
):
    """
    Obtiene la confirmación de entrega de un envío.
    
    Útil para ver los detalles de entregas anteriores.
    """
    # Verificar acceso al envío
    envio = db.query(Envio).filter(
        Envio.id_envio == id_envio,
        Envio.id_repartidor == usuario_actual.id_repartidor
    ).first()
    
    if not envio:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Envío no encontrado"
        )
    
    # Buscar confirmación
    confirmacion = db.query(ConfirmacionEntrega).filter(
        ConfirmacionEntrega.id_envio == id_envio
    ).first()
    
    if not confirmacion:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Este envío no tiene confirmación de entrega"
        )
    
    return ConfirmacionEntregaResponse(
        id_confirmacion=confirmacion.id_confirmacion,
        id_envio=confirmacion.id_envio,
        id_repartidor=confirmacion.id_repartidor,
        lat_confirmacion=float(confirmacion.lat_confirmacion),
        lng_confirmacion=float(confirmacion.lng_confirmacion),
        precision_metros=float(confirmacion.precision_metros) if confirmacion.precision_metros else None,
        nombre_receptor=confirmacion.nombre_receptor,
        resultado_entrega=confirmacion.resultado_entrega,
        razon_fallo=confirmacion.razon_fallo,
        comentarios=confirmacion.comentarios,
        registrado_en=confirmacion.registrado_en
    )

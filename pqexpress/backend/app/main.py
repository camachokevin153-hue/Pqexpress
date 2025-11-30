# ============================================================
# PQEXPRESS - Aplicación Principal FastAPI
# Punto de entrada del backend
# ============================================================

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from dotenv import load_dotenv
import os

# Importar routers
from .routers import auth_router, envios_router
from .database import engine, Base

# Cargar variables de entorno
load_dotenv()

# ============================================================
# CONFIGURACIÓN DE LA APLICACIÓN
# ============================================================

# Crear instancia de FastAPI con metadata
app = FastAPI(
    title="PQExpress API",
    description="""
    ## API REST para el Sistema de Gestión de Entregas PQExpress
    
    Esta API permite a los repartidores:
    
    * 🔐 **Autenticación**: Iniciar/cerrar sesión de forma segura
    * 📦 **Gestión de Envíos**: Ver envíos asignados, iniciar rutas
    * 📍 **Confirmación de Entregas**: Registrar entregas con GPS y foto
    * 📋 **Historial**: Consultar entregas realizadas
    
    ### Tecnologías
    - **Framework**: FastAPI
    - **Base de Datos**: MySQL
    - **Autenticación**: JWT + bcrypt
    
    ### Credenciales de Prueba
    - **Usuario**: repartidor1
    - **Contraseña**: 123456
    """,
    version="1.0.0",
    contact={
        "name": "Equipo PQExpress",
        "email": "soporte@pqexpress.mx"
    },
    license_info={
        "name": "Uso Educativo",
    },
    docs_url="/docs",        # Swagger UI
    redoc_url="/redoc",      # ReDoc
    openapi_url="/openapi.json"
)

# ============================================================
# CONFIGURACIÓN DE CORS
# ============================================================

# Obtener orígenes permitidos desde variables de entorno
# Por defecto permite todos los orígenes (útil para desarrollo)
allowed_origins = os.getenv("ALLOWED_ORIGINS", "*")

# Si es "*", permitir todos los orígenes
if allowed_origins == "*":
    origins = ["*"]
else:
    # Separar por comas si hay múltiples orígenes
    origins = [origin.strip() for origin in allowed_origins.split(",")]

# Agregar middleware CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],      # Permitir todos los métodos HTTP
    allow_headers=["*"],      # Permitir todos los headers
    expose_headers=["*"]
)

# ============================================================
# MANEJADORES DE EXCEPCIONES GLOBALES
# ============================================================

@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    """Manejador personalizado para excepciones HTTP."""
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "detalle": exc.detail,
            "codigo": f"HTTP_{exc.status_code}"
        }
    )


@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    """Manejador para excepciones no controladas."""
    # En producción, no exponer detalles del error
    debug_mode = os.getenv("DEBUG_MODE", "False").lower() == "true"
    
    if debug_mode:
        detalle = str(exc)
    else:
        detalle = "Error interno del servidor. Contacte al administrador."
    
    return JSONResponse(
        status_code=500,
        content={
            "detalle": detalle,
            "codigo": "INTERNAL_ERROR"
        }
    )

# ============================================================
# REGISTRAR ROUTERS
# ============================================================

# Router de autenticación: /api/auth/*
app.include_router(auth_router, prefix="/api")

# Router de envíos: /api/envios/*
app.include_router(envios_router, prefix="/api")

# ============================================================
# ENDPOINTS RAÍZ Y DE SALUD
# ============================================================

@app.get("/", tags=["Root"])
async def root():
    """
    Endpoint raíz de la API.
    Muestra información básica y enlaces útiles.
    """
    return {
        "aplicacion": "PQExpress API",
        "version": "1.0.0",
        "estado": "funcionando",
        "documentacion": {
            "swagger": "/docs",
            "redoc": "/redoc"
        },
        "mensaje": "¡Bienvenido a la API de PQExpress!"
    }


@app.get("/health", tags=["Root"])
async def health_check():
    """
    Endpoint de health check para verificar estado del servicio.
    """
    return {
        "estado": "saludable",
        "servicio": "PQExpress API",
        "base_datos": "conectada"
    }


@app.get("/api", tags=["Root"])
async def api_info():
    """
    Información sobre la API.
    """
    return {
        "nombre": "PQExpress API",
        "version": "1.0.0",
        "endpoints": {
            "autenticacion": "/api/auth",
            "envios": "/api/envios"
        },
        "documentacion": "/docs"
    }


# ============================================================
# EVENTO DE INICIO
# ============================================================

@app.on_event("startup")
async def startup_event():
    """
    Evento que se ejecuta al iniciar la aplicación.
    """
    print("=" * 60)
    print("🚀 PQExpress API iniciada")
    print("=" * 60)
    print("📚 Documentación: http://localhost:8000/docs")
    print("📦 API Base: http://localhost:8000/api")
    print("=" * 60)


@app.on_event("shutdown")
async def shutdown_event():
    """
    Evento que se ejecuta al cerrar la aplicación.
    """
    print("=" * 60)
    print("👋 PQExpress API cerrada")
    print("=" * 60)

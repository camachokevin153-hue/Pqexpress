# ============================================================
# PQEXPRESS - Configuración de Base de Datos
# Conexión a MySQL usando SQLAlchemy
# ============================================================

from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv
import os

# Cargar variables de entorno
load_dotenv()

# Obtener configuración de la base de datos desde variables de entorno
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "3306")
DB_NAME = os.getenv("DB_NAME", "pqexpress_db")
DB_USER = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")

# Construir URL de conexión MySQL
# Formato: mysql+pymysql://usuario:contraseña@host:puerto/nombre_base_datos
DATABASE_URL = f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}?charset=utf8mb4"

# Crear motor de SQLAlchemy
# pool_pre_ping: Verifica conexión antes de usarla (evita errores por conexiones cerradas)
# pool_recycle: Recicla conexiones cada 3600 segundos (1 hora)
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_recycle=3600,
    echo=False  # Cambiar a True para ver queries SQL en consola (debug)
)

# Crear fábrica de sesiones
# autocommit=False: No hace commit automático, debemos hacerlo manualmente
# autoflush=False: No sincroniza automáticamente con la BD
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Clase base para modelos ORM
Base = declarative_base()


def get_db():
    """
    Generador de sesiones de base de datos.
    Usado como dependencia en FastAPI para inyectar la sesión en los endpoints.
    
    Yields:
        Session: Sesión de SQLAlchemy para interactuar con la BD.
        
    Example:
        @app.get("/items")
        def get_items(db: Session = Depends(get_db)):
            return db.query(Item).all()
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def verificar_conexion():
    """
    Verifica que la conexión a la base de datos funcione correctamente.
    
    Returns:
        bool: True si la conexión es exitosa, False en caso contrario.
    """
    try:
        db = SessionLocal()
        db.execute("SELECT 1")
        db.close()
        return True
    except Exception as e:
        print(f"Error de conexión a la base de datos: {e}")
        return False

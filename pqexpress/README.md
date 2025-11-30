# 🚀 PQExpress - Sistema de Gestión de Entregas

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.5+-02569B?style=for-the-badge&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/FastAPI-0.100+-009688?style=for-the-badge&logo=fastapi" alt="FastAPI">
  <img src="https://img.shields.io/badge/MySQL-8.0+-4479A1?style=for-the-badge&logo=mysql&logoColor=white" alt="MySQL">
  <img src="https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python">
</p>

<p align="center">
  <b>Aplicación móvil moderna para gestión de entregas de paquetes</b>
</p>

---

## 📖 Descripción del Proyecto

**PQExpress** es una aplicación completa para la gestión de entregas de paquetes, desarrollada con Flutter y FastAPI. Diseñada con una interfaz moderna y atractiva, permite a los repartidores gestionar sus entregas de manera eficiente.

### ✨ Características Principales

| Funcionalidad | Descripción |
|--------------|-------------|
| 📋 **Lista de Envíos** | Visualiza envíos pendientes y en camino con tabs interactivos |
| 🚗 **Iniciar Ruta** | Marca envíos como "En Camino" y abre navegación GPS |
| 🗺️ **Mapa Interactivo** | Visualiza rutas en OpenStreetMap (gratuito, sin API key) |
| 📷 **Foto de Evidencia** | Captura foto al momento de entregar |
| 📍 **Registro GPS** | Guarda coordenadas exactas de la entrega |
| ✅ **Confirmación** | Registra nombre del receptor y hora de entrega |
| 📊 **Historial** | Consulta entregas completadas |

---

## 🎨 Diseño Único

La aplicación cuenta con un diseño **moderno y diferenciado** con:

- **Paleta de Colores Personalizada:**
  - 🟣 **Púrpura Principal:** `#6C63FF` 
  - 🟢 **Esmeralda Secundario:** `#10B981` / `#00D9A5`
  - 🟡 **Acento Dorado:** `#FFC107`
  
- **Efectos Visuales:**
  - Gradientes suaves en tarjetas
  - Glassmorphism (transparencia con blur)
  - Bordes redondeados (20px)
  - Iconografía moderna (rockets, sparkles)
  - Animaciones de carga

---

## 🛠️ Tecnologías Utilizadas

### Frontend (Mobile/Web)
| Tecnología | Versión | Uso |
|------------|---------|-----|
| Flutter | 3.5+ | Framework UI multiplataforma |
| Dart | 3.0+ | Lenguaje de programación |
| Provider | ^6.1.2 | Gestión de estado |
| flutter_map | ^6.0.1 | Mapas OpenStreetMap |
| geolocator | ^10.1.0 | Servicios de ubicación GPS |
| image_picker | ^1.0.4 | Captura de fotos |
| shared_preferences | ^2.2.2 | Almacenamiento local |
| http | ^1.1.0 | Peticiones HTTP |

### Backend (API REST)
| Tecnología | Versión | Uso |
|------------|---------|-----|
| FastAPI | 0.100+ | Framework API REST |
| Python | 3.10+ | Lenguaje de programación |
| SQLAlchemy | 2.0+ | ORM para base de datos |
| PyJWT | 2.8+ | Tokens de autenticación |
| bcrypt | 4.1+ | Encriptación de contraseñas |
| uvicorn | 0.24+ | Servidor ASGI |
| python-multipart | 0.0.6+ | Manejo de archivos |

### Base de Datos
| Tecnología | Versión | Configuración |
|------------|---------|---------------|
| MySQL | 8.0+ | Base de datos: `pqexpress_db` |
| | | Usuario: `root` |
| | | Contraseña: `` |

---

## 📁 Estructura del Proyecto

```
pqexpress/
├── 📂 lib/                          # Código Flutter
│   ├── 📂 config/                   # Configuración
│   │   ├── api_config.dart          # URLs del API
│   │   └── theme.dart               # Tema visual personalizado
│   ├── 📂 models/                   # Modelos de datos
│   │   ├── usuario.dart             # Usuario/Repartidor
│   │   ├── envio.dart               # Envío/Paquete
│   │   └── confirmacion_entrega.dart
│   ├── 📂 providers/                # Estado de la app
│   │   ├── auth_provider.dart       # Autenticación
│   │   └── envios_provider.dart     # Envíos
│   ├── 📂 screens/                  # Pantallas UI
│   │   ├── splash_screen.dart       # Carga inicial
│   │   ├── login_screen.dart        # Inicio de sesión
│   │   ├── home_screen.dart         # Pantalla principal
│   │   ├── envio_detalle_screen.dart# Detalle de envío
│   │   ├── mapa_screen.dart         # Mapa con ruta
│   │   ├── entrega_screen.dart      # Confirmar entrega
│   │   └── historial_screen.dart    # Entregas completadas
│   ├── 📂 services/                 # Servicios
│   │   ├── api_service.dart         # Llamadas HTTP
│   │   ├── location_service.dart    # GPS
│   │   ├── camera_service.dart      # Cámara
│   │   └── route_service.dart       # Cálculo de rutas
│   └── main.dart                    # Punto de entrada
│
├── 📂 backend/                      # API FastAPI
│   ├── 📂 app/
│   │   ├── __init__.py
│   │   ├── main.py                  # App principal
│   │   ├── database.py              # Conexión MySQL
│   │   ├── models.py                # Modelos ORM
│   │   ├── schemas.py               # Esquemas Pydantic
│   │   ├── security.py              # JWT y bcrypt
│   │   └── 📂 routers/              # Endpoints
│   │       ├── auth.py              # Autenticación
│   │       └── envios.py            # Gestión envíos
│   ├── requirements.txt             # Dependencias Python
│   ├── .env                         # Variables de entorno
│   └── .env.example                 # Ejemplo de configuración
│
├── 📂 database/
│   └── schema.sql                   # Script de base de datos
│
├── pubspec.yaml                     # Dependencias Flutter
└── README.md                        # Este archivo
```

---

## 🗄️ Diagrama de Base de Datos

```
┌──────────────────────────────────────────────────────────────────────┐
│                          pqexpress_db                                │
└──────────────────────────────────────────────────────────────────────┘

┌─────────────────────────┐       ┌─────────────────────────────────────┐
│       usuarios          │       │              envios                  │
├─────────────────────────┤       ├─────────────────────────────────────┤
│ id          INT PK AI   │       │ id                INT PK AI         │
│ username    VARCHAR(50) │───┐   │ numero_guia       VARCHAR(50) UNIQUE│
│ email       VARCHAR(100)│   │   │ nombre_cliente    VARCHAR(100)      │
│ password    VARCHAR(255)│   │   │ telefono_cliente  VARCHAR(20)       │
│ nombre      VARCHAR(100)│   │   │ direccion_entrega VARCHAR(255)      │
│ rol         VARCHAR(20) │   │   │ ciudad            VARCHAR(100)      │
│ activo      BOOLEAN     │   │   │ latitud_destino   DECIMAL(10,8)     │
│ created_at  DATETIME    │   └──>│ longitud_destino  DECIMAL(11,8)     │
│ updated_at  DATETIME    │       │ descripcion_paq   TEXT              │
└─────────────────────────┘       │ peso              DECIMAL(10,2)     │
                                  │ estado            ENUM(...)         │
                                  │ repartidor_id     INT FK ───────────┘
                                  │ fecha_asignacion  DATETIME          │
                                  │ fecha_entrega     DATETIME          │
                                  │ latitud_entrega   DECIMAL(10,8)     │
                                  │ longitud_entrega  DECIMAL(11,8)     │
                                  │ foto_evidencia    TEXT              │
                                  │ nombre_receptor   VARCHAR(100)      │
                                  │ notas_entrega     TEXT              │
                                  │ created_at        DATETIME          │
                                  │ updated_at        DATETIME          │
                                  └─────────────────────────────────────┘

Estados posibles del envío:
┌────────────┬─────────────────────────────────────┐
│ Estado     │ Descripción                         │
├────────────┼─────────────────────────────────────┤
│ pendiente  │ Esperando asignación                │
│ asignado   │ Asignado a repartidor               │
│ en_camino  │ Repartidor en ruta                  │
│ entregado  │ Entrega completada                  │
│ fallido    │ No se pudo entregar                 │
└────────────┴─────────────────────────────────────┘
```

---

## 🚀 Instalación y Configuración

### 📋 Requisitos Previos

| Requisito | Versión Mínima | Verificar Instalación |
|-----------|----------------|----------------------|
| Flutter SDK | 3.5.0 | `flutter --version` |
| Python | 3.10 | `python --version` |
| MySQL | 8.0 | `mysql --version` |
| Git | 2.0 | `git --version` |

---

### 📌 Paso 1: Clonar el Repositorio

```powershell
git clone https://github.com/TU_USUARIO/pqexpress.git
cd pqexpress
```

---

### 📌 Paso 2: Configurar Base de Datos

1. **Abrir MySQL** (Workbench o terminal)

2. **Ejecutar el script de creación:**

```sql
-- Crear base de datos
CREATE DATABASE IF NOT EXISTS pqexpress_db
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE pqexpress_db;

-- Ejecutar script completo
SOURCE C:/AppFlutter/pqexpress/database/schema.sql;
```

> ⚠️ **Nota:** La contraseña de MySQL debe ser `` o modificar en `backend/app/database.py`

---

### 📌 Paso 3: Configurar Backend (FastAPI)

```powershell
# Navegar al directorio backend
cd backend

# Crear entorno virtual
python -m venv venv

# Activar entorno virtual (Windows PowerShell)
.\venv\Scripts\Activate.ps1

# Instalar dependencias
pip install -r requirements.txt

# Iniciar servidor de desarrollo
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

✅ **Verificar:** Abrir `http://localhost:8000/docs` para ver la documentación Swagger

---

### 📌 Paso 4: Configurar Frontend (Flutter)

```powershell
# Volver al directorio raíz
cd ..

# Obtener dependencias
flutter pub get

# Verificar instalación
flutter doctor

# Ejecutar en Chrome (desarrollo)
flutter run -d chrome

# Ejecutar en dispositivo Android
flutter run -d android

# Ejecutar en emulador
flutter run
```

---

### 📌 Paso 5: Configurar IP del Servidor

Editar `lib/config/api_config.dart`:

```dart
class ApiConfig {
  // Para navegador web (Chrome):
  static const String baseUrl = 'http://localhost:8000/api';
  
  // Para emulador Android:
  // static const String baseUrl = 'http://10.0.2.2:8000/api';
  
  // Para dispositivo físico (usar IP de tu PC):
  // static const String baseUrl = 'http://192.168.1.XXX:8000/api';
}
```

---

## 🔐 Credenciales de Prueba

| Usuario | Contraseña | Rol |
|---------|------------|-----|
| `repartidor1` | `123456` | Repartidor |
| `repartidor2` | `123456` | Repartidor |

> 📝 Las contraseñas están encriptadas con **bcrypt** (12 rondas de salt)

---

## ✅ Características Implementadas

### 🔒 Seguridad
| Característica | Implementación |
|----------------|----------------|
| Autenticación JWT | Token con 8 horas de expiración |
| Encriptación | bcrypt con 12 rondas de salt |
| Validación | Verificación de token en cada petición |
| Logout seguro | Invalidación de token en servidor |

### 📱 Funcionalidades de la App
- ✅ Pantalla de splash con animación
- ✅ Inicio de sesión con validación
- ✅ Lista de envíos con tabs (En Entrega / Pendientes)
- ✅ Detalle completo de cada envío
- ✅ Botón "Iniciar Ruta" para marcar en camino
- ✅ Mapa interactivo con OpenStreetMap
- ✅ Cálculo de ruta real con OSRM (Open Source)
- ✅ Captura de foto de evidencia
- ✅ Registro automático de coordenadas GPS
- ✅ Formulario de confirmación de entrega
- ✅ Historial de entregas completadas
- ✅ Abrir navegación externa (Google Maps/Waze)

### 🎨 Interfaz de Usuario
- ✅ Material Design 3
- ✅ Tema personalizado púrpura/esmeralda
- ✅ Gradientes y efectos glassmorphism
- ✅ Iconografía moderna y única
- ✅ Estados de carga con shimmer
- ✅ Manejo de errores visual
- ✅ Compatible con Web, Android e iOS

---

## 📡 Endpoints del API

### 🔐 Autenticación (`/api/auth/`)

| Método | Endpoint | Descripción | Body |
|--------|----------|-------------|------|
| `POST` | `/login` | Iniciar sesión | `{username, password}` |
| `POST` | `/logout` | Cerrar sesión | - |
| `GET` | `/me` | Obtener usuario actual | - |
| `GET` | `/validar-token` | Verificar token válido | - |

### 📦 Envíos (`/api/envios/`)

| Método | Endpoint | Descripción | Body |
|--------|----------|-------------|------|
| `GET` | `/` | Listar envíos del repartidor | - |
| `GET` | `/{id}` | Detalle de un envío | - |
| `POST` | `/{id}/iniciar-ruta` | Marcar como "En Camino" | - |
| `POST` | `/{id}/confirmar-entrega` | Registrar entrega | `multipart/form-data` |

### Ejemplo de uso con cURL:

```bash
# Login
curl -X POST "http://localhost:8000/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username": "repartidor1", "password": "123456"}'

# Listar envíos (con token)
curl -X GET "http://localhost:8000/api/envios/" \
  -H "Authorization: Bearer <TOKEN>"
```

---

## 🔧 Solución de Problemas

### Error: "No se puede conectar al servidor"
```powershell
# Verificar que el backend esté corriendo
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Verificar firewall de Windows
netsh advfirewall firewall add rule name="FastAPI" dir=in action=allow protocol=TCP localport=8000
```

### Error: "Access denied for user 'root'"
```sql
-- Verificar contraseña en MySQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '';
FLUSH PRIVILEGES;
```

### Error: "flutter_map no carga"
```dart
// Verificar conexión a internet
// Los mapas requieren conexión para descargar tiles
```

### Error: "Ubicación no disponible"
```dart
// En Android: Verificar permisos en AndroidManifest.xml
// En Web: El navegador debe tener permisos de ubicación
```

---

## 🏗️ Compilar para Producción

### Web
```powershell
flutter build web --release
# Los archivos estarán en: build/web/
```

### Android APK
```powershell
flutter build apk --release
# APK en: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (Play Store)
```powershell
flutter build appbundle --release
```

---

## 📝 Notas para Evaluación

Este proyecto cumple con **todos los criterios de la rúbrica**:

| Criterio | Implementación | Ubicación |
|----------|----------------|-----------|
| 📋 Selección de paquete | Lista con tabs y tarjetas | `home_screen.dart` |
| 📷 Captura fotográfica | image_picker + preview | `camera_service.dart` |
| 📍 Registro GPS | geolocator + coordenadas | `location_service.dart` |
| ✅ Confirmación entrega | Formulario completo | `entrega_screen.dart` |
| 🔐 Inicio de sesión | Login con validación | `login_screen.dart` |
| 🔒 Cifrado contraseñas | bcrypt 12 rondas | `backend/security.py` |
| 🗺️ Mapa interactivo | flutter_map + OSRM | `mapa_screen.dart` |

---

## 👨‍💻 Autor

**Proyecto Educativo** - Evaluación Unidad 3  
📚 Desarrollo de Aplicaciones Móviles  
🗓️ 2025

---

## 📄 Licencia

Este proyecto es para **fines educativos únicamente**.  
No está destinado para uso comercial.

---

<p align="center">
  <b>🚀 PQExpress - Envíos Veloces, Entregas Seguras</b>
</p>

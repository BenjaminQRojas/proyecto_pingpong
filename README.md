# Ping Pong IoT - Control de Lanzador de Pelotas

Aplicación Flutter para controlar un lanzador de pelotas de ping pong via MQTT, con base de datos PostgreSQL para guardar sesiones de entrenamiento.

## Estructura del Proyecto

```
lib/
├── main.dart                    # Punto ─de entrada de la aplicación
│
├── core/                       # Componentes centrales y reutilizables
│   ├── models/
│   │   └── ping_pong_shot.dart    # Modelo de datos para un tiro
│   ├── theme/
│   │   └── app_theme.dart          # Configuración del tema oscuro
│   └── widgets/
│       ├── widgets.dart           # Exporta todos los widgets
│       ├── app_button.dart        # Botón personalizado (sólido/outline)
│       ├── app_card.dart          # Tarjeta contenedor con gradiente
│       ├── app_badge.dart         # Insignia/etiqueta colored
│       ├── app_slider.dart        # Slider horizontal con etiquetas
│       ├── vertical_slider.dart   # Slider vertical rotado 90°
│       └── app_text_field.dart    # Campo de texto estilizado
│
├── services/                   # Servicios externos y lógica de negocio
│   ├── mqtt_service.dart        # Cliente MQTT para comunicación con ESP32
│   └── database_service.dart    # Servicio de base de datos PostgreSQL
│
└── features/                  # Funcionalidades de la app organizadas
    ├── home/
    │   └── home_screen.dart     # Pantalla principal con navegación (4 pestañas)
    │
    ├── control/screens/
    │   ├── dashboard_screen.dart           # Panel principal de control
    │   ├── physics_calibration_screen.dart # Calibración de física
    │   └── technical_settings_screen.dart  # Configuración técnica
    │
    └── stats/
        └── stats_screen.dart   # Historial de sesiones de entrenamiento
```

## Descripción de Archivos Principales

### lib/main.dart
- Punto de entrada de la aplicación Flutter
- Configura el estilo de la barra de estado (transparente)
- Crea el Provider para MqttService (estado global)
- Define el tema oscuro de la app
- Usa Provider para gestión de estado reactivo

### lib/core/models/ping_pong_shot.dart
Modelo de datos para un tiro de ping pong:
- `topMotorSpeed`: Velocidad del motor superior (0-100)
- `bottomMotorSpeed`: Velocidad del motor inferior (0-100)
- `horizontalAngle`: Ángulo horizontal de lanzamiento (0-90°)
- `interval`: Intervalo entre lanzamientos (segundos)

### lib/core/theme/app_theme.dart
Define la apariencia visual de toda la aplicación:
- Paleta de colores (primary, secondary, success, error, backgrounds)
- Tema oscuro (dark theme) para MaterialApp
- Estilos de: AppBar, Card, Botones, Inputs, Sliders, NavigationBar

### lib/core/widgets/ (6 widgets reutilizables)

| Widget | Descripción |
|--------|-------------|
| `app_button.dart` | Botón personalizado (sólido/outline), icono opcional, color personalizado |
| `app_card.dart` | Contenedor con borde, fondo y opcional gradiente |
| `app_badge.dart` | Insignia/etiqueta pequeña colored |
| `app_slider.dart` | Slider horizontal con etiqueta de valor |
| `vertical_slider.dart` | Slider rotado 90° para controles verticales |
| `app_text_field.dart` | Campo de texto con label y estilo consistente |

### lib/services/mqtt_service.dart
Gestiona comunicación MQTT con el dispositivo físico:

**Configuración:**
- Broker por defecto: 192.168.1.100:1883
- Auto-reconexión habilitada
- Keep-alive: 60 segundos

**Métodos principales:**
- `configure(brokerIp, port)`: Configura el broker
- `connect()`: Conecta al broker MQTT
- `disconnect()`: Desconecta
- `sendShotCommand(shot)`: Envía configuración de tiro
- `emergencyStop()`: Envía comando de parada de emergencia

**Topics:**
- Suscripción: `pingpong/status`, `pingpong/data`
- Publicación: `pingpong/control`, `pingpong/emergency`

### lib/services/database_service.dart
Gestiona base de datos PostgreSQL para sesiones:

**Configuración:**
- Host: localhost:5432
- Database: pingpong
- User: postgres
- Password: postgres
- Sin SSL

**Tabla sessions:**
- `id`: INTEGER PRIMARY KEY (auto)
- `created_at`: TIMESTAMP
- `player_name`: VARCHAR
- `shot_config`: JSONB

**Métodos:**
- `insertSession(shot, playerName)`: Guardar sesión
- `getSessions(limit)`: Obtener historial de sesiones

## Pantallas

### Dashboard (Control)
- Indicador de conexión MQTT (verde/rojo)
- Botón grande INICIAR con animación de pulso cuando activo
- Contador de pelotas lanzadas
- Slider de FRECUENCIA (10-120 BPM)
- Slider de OSCILACIÓN HORIZONTAL (0-90°)
- 4 PRESETS RÁPIDOS: Topspin, Backspin, Random, Pro-Drills
- Botón de PARADA DE EMERGENCIA (rojo, prominente)

### Physics Calibration
- Visualizador de trayectoria (CustomPainter)
- Slider para motor SUPERIOR (velocidad)
- Slider para motor INFERIOR (velocidad)
- Indicador de tipo de spin: Topspin, Backspin, Neutral

### Technical Settings
- Campo para IP del broker MQTT
- Campo para puerto MQTT
- Botón de PROBAR CONEXIÓN
- Indicador de estado de conexión
- Info del sistema: versión firmware, hardware, versión app

### Stats (Estadísticas)
- Lista de sesiones pasadas (scrollable)
- Cada sesión muestra: fecha, jugador, configuración, ID

## Flujo de Datos

```
┌────────────────┐              ┌─────────────┐              ┌───────────────┐
│  App Flutter   │   MQTT       │ MQTT Broker │   MQTT       │ ESP32/Arduino │
│                │◄────────────►│             │◄────────────►│ (Lanzador)    │
│ ┌────────────┐ │              └─────────────┘              └───────────────┘
│ │ MqttService│ │ (envía comandos, recibe estado)
│ └────────────┘ │
│ ┌───────────┐  │   Directo      ┌────────────┐
│ │DatabaseSvc│  │►──────────────►│ PostgreSQL │
│ └───────────┘  │                │ (sesiones) │
└────────────────┘                └────────────┘

```

**Notas importantes:**
- El MQTT Broker NO conecta a la base de datos - Son sistemas independientes
- La app tiene dos conexiones independientes:
  - MQTT: comunicación con el dispositivo físico (ESP32)
  - PostgreSQL: almacenamiento directo de sesiones
- El flujo de guardado de sesión va directo: App → PostgreSQL (no pasa por MQTT)
- El ESP32 envía datos de sensores (temperatura, velocidad, etc.) por MQTT

## Tecnologías Usadas

- **Flutter (Dart)** - Framework UI
- **Provider** - Gestión de estado
- **mqtt_client** - Cliente MQTT
- **postgres** - Conexión a PostgreSQL
- **Material Design 3** - Componentes UI

## Instalación

```bash
# Instalar dependencias
flutter pub get

# Ejecutar en modo desarrollo
flutter run

# Generar APK
flutter build apk --release
```

## Requisitos

- Flutter SDK 3.x
- PostgreSQL (para almacenamiento de sesiones)
- Broker MQTT (Mosquitto u otro)
- Dispositivo ESP32/Arduino con el lanzador
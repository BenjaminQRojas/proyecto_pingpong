# Ping Pong IoT - Control de Lanzador de Pelotas

Aplicación Flutter para controlar un lanzador de pelotas de ping pong vía MQTT, con base de datos SQLite local para guardar sesiones de entrenamiento.

## Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada de la aplicación
│
├── config/
│   └── app_config.dart          # Configuración (broker MQTT, topics)
│
├── core/                       # Componentes centrales y reutilizables
│   ├── models/
│   │   ├── ping_pong_shot.dart    # Modelo de datos para un tiro
│   │   └── sensor_reading.dart    # Lecturas de sensores del ESP32
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
│   └── database_service.dart    # Servicio de base de datos SQLite
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

esp32_code/
└── esp32_motores.ino           # Firmware para ESP32 (control de motores, servo, sensor IR)
```

## Descripción de Archivos Principales

### lib/main.dart
- Punto de entrada de la aplicación Flutter
- Inicializa SQLite con soporte para desktop (Linux, macOS, Windows) mediante `sqflite_ffi`
- Crea los providers para MqttService (estado global) y DatabaseService
- Define el tema oscuro de la app

### lib/config/app_config.dart
- Broker MQTT por defecto: `broker.hivemq.com:1883`
- Prefijo de topics: `infinitedecimal/pingpong`

### lib/core/models/ping_pong_shot.dart
Modelo de datos para un tiro de ping pong:
- `topMotorSpeed`: Velocidad del motor superior (0-100)
- `bottomMotorSpeed`: Velocidad del motor inferior (0-100)
- `horizontalAngle`: Ángulo horizontal de lanzamiento (0-180)
- `interval`: Intervalo entre lanzamientos (segundos)
- Incluye métodos: `toJson()`, `fromJson()`, `copyWith()`, `toMap()`, `fromMap()`

### lib/core/models/sensor_reading.dart
Modelo para lecturas de sensores del ESP32:
- `ballsReturned`: Conteo de pelotas devueltas
- `voltage`: Voltaje del dispositivo
- `payloadJson`: Payload MQTT original

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
- Broker por defecto: `broker.hivemq.com:1883` (configurable en la app)
- Auto-reconexión habilitada
- Keep-alive: 20 segundos
- Soporte TLS en puerto 8883
- Fallback automático a puerto estándar sin TLS

**Métodos principales:**
- `configure(brokerIp, port)`: Configura el broker
- `connect()`: Conecta al broker MQTT
- `disconnect()`: Desconecta
- `sendShotCommand(shot, {start, stop})`: Envía configuración/control de tiro
- `sendServoCommand(horizontal)`: Control manual del servo
- `sendOscillationConfig(enabled, {min, max})`: Activa/desactiva oscilación automática
- `emergencyStop()`: Envía comando de parada de emergencia

**Topics:**
- Suscripción: `infinitedecimal/pingpong/status`, `infinitedecimal/pingpong/data`
- Publicación: `infinitedecimal/pingpong/control`, `infinitedecimal/pingpong/emergency`, `infinitedecimal/pingpong/servo`

### lib/services/database_service.dart
Gestiona base de datos SQLite local para sesiones y lecturas de sensores:

**Tablas:**

`training_sessions`:
| Columna | Tipo | Descripción |
|---------|------|-------------|
| id | INTEGER PK | Auto-increment |
| created_at | TEXT | Fecha ISO 8601 |
| player_name | TEXT | Nombre del jugador |
| preset | TEXT | Preajuste usado (topspin, backspin, etc.) |
| duration_seconds | INTEGER | Duración de la sesión |
| ball_count | INTEGER | Pelotas lanzadas |
| top_motor_speed | INTEGER | Velocidad motor superior |
| bottom_motor_speed | INTEGER | Velocidad motor inferior |
| horizontal_angle | INTEGER | Ángulo del cabezal |
| launch_interval | REAL | Intervalo entre lanzamientos |

`sensor_readings`:
| Columna | Tipo | Descripción |
|---------|------|-------------|
| id | INTEGER PK | Auto-increment |
| session_id | INTEGER | FK a training_sessions |
| timestamp | TEXT | Fecha ISO 8601 |
| topic | TEXT | Topic MQTT |
| balls_returned | INTEGER | Pelotas devueltas |
| voltage | REAL | Voltaje del dispositivo |
| payload_json | TEXT | Payload MQTT original |

**Métodos:**
- `insertSession(shot, {playerName, preset, durationSeconds, ballCount})`: Guardar sesión
- `getSessions({limit})`: Obtener historial de sesiones
- `deleteSession(id)`: Eliminar sesión y sus lecturas asociadas
- `insertSensorReading(reading)`: Guardar lectura de sensor
- `getSensorReadings({sessionId, limit})`: Obtener lecturas

## Pantallas

### Dashboard (Control)
- Indicador de conexión MQTT (verde/rojo)
- Botón grande INICIAR/DETENER con animación de pulso cuando activo
- Contador de pelotas lanzadas y devueltas
- Sliders de velocidad para MOTOR SUPERIOR e INFERIOR (0-100%)
- Slider de FRECUENCIA (10-120 BPM)
- Control de CABEZAL: posición manual (0-180°) u oscilación automática (rango configurable)
- 4 PRESETS RÁPIDOS: Topspin, Backspin, Aleatorio, Pro-Drill
- Botón de PARADA DE EMERGENCIA (rojo, prominente)

### Physics Calibration (Calibración de Física)
- Visualizador de trayectoria (CustomPainter) con cuadrícula y animación
- Sliders verticales para motor SUPERIOR e INFERIOR
- Indicador de tipo de spin: Topspin, Backspin, Neutral
- Diferencia de RPM y ángulo de trayectoria
- 3 preajustes rápidos: Topspin Máx, Neutral, Backspin Máx

### Technical Settings (Configuración Técnica)
- Campo para dirección y puerto del broker MQTT
- Botón de PROBAR CONEXIÓN
- Indicador de estado de conexión y mensajes enviados
- Gestión de sesiones de entrenamiento (listado y eliminación)
- Información del sistema: versión de firmware, hardware, versión de app

### Stats (Estadísticas)
- Lista de sesiones pasadas (scrollable)
- Cada sesión muestra: fecha, jugador, preajuste, pelotas lanzadas, configuración de motores
- Opción de eliminar sesiones individuales

## Flujo de Datos

```
┌────────────────┐              ┌─────────────┐              ┌───────────────┐
│  App Flutter   │   MQTT       │ MQTT Broker │   MQTT       │ ESP32/Arduino │
│                │◄────────────►│             │◄────────────►│ (Lanzador)    │
│ ┌────────────┐ │              └─────────────┘              └───────────────┘
│ │ MqttService│ │ (envía comandos, recibe estado/sensores)
│ └────────────┘ │
│ ┌───────────┐  │   Directo      ┌────────────┐
│ │DatabaseSvc│  │►──────────────►│  SQLite    │
│ └───────────┘  │                │ (local.db) │
└────────────────┘                └────────────┘
```

**Notas importantes:**
- El MQTT Broker NO conecta a la base de datos - Son sistemas independientes
- La app tiene dos conexiones independientes:
  - MQTT: comunicación con el dispositivo físico (ESP32)
  - SQLite: almacenamiento local de sesiones y lecturas
- El flujo de guardado de sesión va directo: App → SQLite (no pasa por MQTT)
- El ESP32 envía datos de sensores (conteo de pelotas, voltaje) por MQTT

## Firmware ESP32 (`esp32_code/esp32_motores.ino`)

Controla:
- **Motores DC** (superior, inferior, alimentador) mediante PWM LEDC (5 kHz, 8 bits)
- **Servo horizontal** (0-180°) con oscilación automática configurable
- **Sensor IR-08H** para conteo de pelotas devueltas (interrupción con debounce)
- **Conexión WiFi y MQTT** con reconexión automática
- **Parada de emergencia** por MQTT con prioridad

Pines:
| Componente | Pin |
|------------|-----|
| Motor Superior | 27 |
| Motor Inferior | 26 |
| Motor Alimentador | 25 |
| Servo Horizontal | 13 |
| Sensor IR | 34 |
| LED indicador | 2 |

## Tecnologías Usadas

- **Flutter (Dart)** - Framework UI
- **Provider** - Gestión de estado
- **mqtt_client** - Cliente MQTT
- **sqflite / sqflite_common_ffi** - Base de datos SQLite local
- **Material Design 3** - Componentes UI
- **Arduino (C++)** - Firmware ESP32

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
- Broker MQTT (HiveMQ público por defecto)
- Dispositivo ESP32 con el firmware del lanzador

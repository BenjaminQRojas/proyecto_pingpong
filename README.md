# Ping Pong IoT

App Flutter para controlar un lanzador de ping pong vía MQTT + SQLite local.

## Stack

- **Flutter / Dart** — UI
- **Provider** — notifica cambios del MQTT a la interfaz
- **mqtt_client** — comunicación MQTT
- **sqflite** — base de datos local
- **ESP32 (Arduino)** — firmware del lanzador

## Pantallas

| Pantalla | Función |
|----------|---------|
| **Dashboard** | Iniciar/detener lanzamiento, velocidad motores, frecuencia, servo, oscilación, presets, parada de emergencia |
| **Calibración** | Ajustar motores superior/inferior, visualizar trayectoria |
| **Ajustes** | Configurar broker MQTT, probar conexión, ver/eliminar sesiones |
| **Estadísticas** | Historial de sesiones de entrenamiento |

## Configuración

- Broker MQTT por defecto: `broker.hivemq.com:1883`
- Topics: `infinitedecimal/pingpong/{control,emergency,servo,status,data}`
- DB local: `pingpong.db` (SQLite)

## Instalación

```bash
flutter pub get
flutter run
flutter build apk --release
```

## Firmware ESP32

`esp32_code/esp32_motores.ino` — controla motores DC (PWM), servo horizontal, sensor IR y conexión MQTT.

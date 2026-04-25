#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

// Configuración de Red
const char* ssid = "ARRIS-2B0A";
const char* password = "coquimbo120";

// Configuración MQTT
const char* mqtt_server = "broker.hivemq.com";
const int mqtt_port = 1883;

WiFiClient espClient;
PubSubClient client(espClient);

// Topics
const char* TOPIC_CONTROL = "infinitedecimal/pingpong/control";
const char* TOPIC_EMERGENCY = "infinitedecimal/pingpong/emergency";
const char* TOPIC_STATUS = "infinitedecimal/pingpong/status";

// Pines de motores DC
const int MOTOR_SUPERIOR_PIN = 27;  // GPIO27
const int MOTOR_INFERIOR_PIN = 26;  // GPIO26
const int LED_PIN = 2;

// Variables de control
bool motorsActive = false;
int topMotorSpeed = 0;      // 0-100
int bottomMotorSpeed = 0;   // 0-100

void setup_wifi() {
  delay(10);
  Serial.println("\nConectando a " + String(ssid));
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi conectado - IP: " + WiFi.localIP().toString());
}

void setMotorSpeed(int motorPin, int speed) {
  // Asegurar rango 0-100 antes de mapear
  speed = constrain(speed, 0, 100);
  int pwmValue = map(speed, 0, 100, 0, 255);
  analogWrite(motorPin, pwmValue);
}

void stopAllMotors() {
  setMotorSpeed(MOTOR_SUPERIOR_PIN, 0);
  setMotorSpeed(MOTOR_INFERIOR_PIN, 0);
  motorsActive = false;
  digitalWrite(LED_PIN, LOW);
  Serial.println("Motores DETENIDOS");
}

void startMotors() {
  setMotorSpeed(MOTOR_SUPERIOR_PIN, topMotorSpeed);
  setMotorSpeed(MOTOR_INFERIOR_PIN, bottomMotorSpeed);
  motorsActive = true;
  digitalWrite(LED_PIN, HIGH);
  Serial.printf("Motores ACTIVADOS - Sup: %d%%, Inf: %d%%\n", topMotorSpeed, bottomMotorSpeed);
}

void initMotors() {
  pinMode(MOTOR_SUPERIOR_PIN, OUTPUT);
  pinMode(MOTOR_INFERIOR_PIN, OUTPUT);
  pinMode(LED_PIN, OUTPUT);
  stopAllMotors();
  Serial.println("Motores inicializados");
}

void callback(char* topic, byte* payload, unsigned int length) {
  Serial.print("Mensaje recibido en [");
  Serial.print(topic);
  Serial.println("]");
  
  // Convertir payload a string de forma segura
  String jsonString = "";
  for (int i = 0; i < length; i++) {
    jsonString += (char)payload[i];
  }

  // ArduinoJson v7 usa JsonDocument (memoria dinámica automática)
  JsonDocument doc;
  DeserializationError error = deserializeJson(doc, jsonString);
  
  if (error) {
    Serial.print("Error en JSON: ");
    Serial.println(error.c_str());
    return;
  }

  const char* action = doc["action"] | ""; // Valor por defecto vacío si no existe
  int priority = doc["priority"] | -1;

  // 1. Manejo de Emergencia
  if (String(topic) == TOPIC_EMERGENCY || priority == 0) {
    if (String(action) == "STOP") {
      Serial.println("!!! PARADA DE EMERGENCIA !!!");
      stopAllMotors();
    }
    return;
  }

  // 2. Manejo de Control
  if (String(topic) == TOPIC_CONTROL) {
    if (doc.containsKey("topMotorSpeed")) {
      topMotorSpeed = doc["topMotorSpeed"];
    }
    if (doc.containsKey("bottomMotorSpeed")) {
      bottomMotorSpeed = doc["bottomMotorSpeed"];
    }

    if (String(action) == "START") {
      startMotors();
    } else if (String(action) == "STOP") {
      stopAllMotors(); // Corregido el nombre aquí
    } else if (motorsActive) {
      // Si ya están activos, actualizar velocidades en tiempo real
      startMotors();
    }
  }
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Intentando conexión MQTT...");
    String clientId = "ESP32_Lanzador_" + String(random(0, 1000));
    
    if (client.connect(clientId.c_str())) {
      Serial.println("CONECTADO");
      client.subscribe(TOPIC_CONTROL);
      client.subscribe(TOPIC_EMERGENCY);
      Serial.println("Suscrito a topics");
    } else {
      Serial.print("Error rc=");
      Serial.print(client.state());
      Serial.println(" reintentando en 5s...");
      delay(5000);
    }
  }
}

void setup() {
  Serial.begin(115200);
  initMotors();
  setup_wifi();
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();
}
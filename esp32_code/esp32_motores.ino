#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <ESP32Servo.h>

const char* ssid = "chimpancini_bananini";
const char* password = "bananitas123";
const char* mqtt_server = "broker.hivemq.com";
const int mqtt_port = 1883;

WiFiClient espClient;
PubSubClient client(espClient);

const char* TOPIC_CONTROL   = "infinitedecimal/pingpong/control";
const char* TOPIC_EMERGENCY = "infinitedecimal/pingpong/emergency";
const char* TOPIC_STATUS    = "infinitedecimal/pingpong/status";
const char* TOPIC_SERVO     = "infinitedecimal/pingpong/servo";
const char* TOPIC_DATA      = "infinitedecimal/pingpong/data";

const int MOTOR_SUPERIOR_PIN = 27;
const int MOTOR_INFERIOR_PIN = 26;
const int MOTOR_FEEDER_PIN = 25;
const int LED_PIN = 2;

const int SERVO_HORIZONTAL_PIN = 13;

const int IR_SENSOR_PIN = 34;

const int PWM_FREQ = 5000;
const int PWM_RESOLUTION = 8;
const int MOTOR_CHANNEL_SUP = 6;
const int MOTOR_CHANNEL_INF = 7;
const int MOTOR_CHANNEL_FEEDER = 8;

bool motorsActive = false;
int topMotorSpeed = 75;
int bottomMotorSpeed = 75;
const int FEEDER_SPEED = 60;

Servo servoHorizontal;
int servoH_angle = 90;

bool oscillationActive = false;
int oscMin = 30;
int oscMax = 150;
int oscDirection = 1;
unsigned long lastOscStep = 0;
const int OSC_STEP_MS = 80;
const int OSC_STEP_DEG = 2;

bool ignoreNextMessage = false;

volatile int ballsReturned = 0;
volatile unsigned long lastBallTime = 0;
const unsigned long DEBOUNCE_MS = 200;
unsigned long lastPublishData = 0;
const unsigned long DATA_INTERVAL = 500;

void initVariant() {
  pinMode(MOTOR_SUPERIOR_PIN, OUTPUT);
  pinMode(MOTOR_INFERIOR_PIN, OUTPUT);
  pinMode(MOTOR_FEEDER_PIN, OUTPUT);
  digitalWrite(MOTOR_SUPERIOR_PIN, LOW);
  digitalWrite(MOTOR_INFERIOR_PIN, LOW);
  digitalWrite(MOTOR_FEEDER_PIN, LOW);
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
}

void setup_wifi() {
  delay(10);
  Serial.print("\nConectando a WiFi: ");
  Serial.println(ssid);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi conectado");
  Serial.print("IP: ");
  Serial.println(WiFi.localIP().toString());
}

void initMotors() {
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  delay(10);

  ledcAttach(MOTOR_SUPERIOR_PIN, PWM_FREQ, PWM_RESOLUTION);
  ledcAttach(MOTOR_INFERIOR_PIN, PWM_FREQ, PWM_RESOLUTION);
  ledcAttach(MOTOR_FEEDER_PIN, PWM_FREQ, PWM_RESOLUTION);

  ledcWrite(MOTOR_SUPERIOR_PIN, 0);
  ledcWrite(MOTOR_INFERIOR_PIN, 0);
  ledcWrite(MOTOR_FEEDER_PIN, 0);
  motorsActive = false;

  Serial.println("Motores inicializados (LEDC PWM 5kHz, 8bit)");
}

void setMotorSpeed(int motorPin, int speed) {
  speed = constrain(speed, 0, 100);
  int pwmValue = map(speed, 0, 100, 0, 255);
  ledcWrite(motorPin, pwmValue);
  Serial.print("  PWM pin ");
  Serial.print(motorPin);
  Serial.print(": ");
  Serial.print(speed);
  Serial.print("% (");
  Serial.print(pwmValue);
  Serial.println("/255)");
}

void startMotors() {
  Serial.println(">>> ACTIVANDO MOTORES <<<");
  setMotorSpeed(MOTOR_SUPERIOR_PIN, topMotorSpeed);
  setMotorSpeed(MOTOR_INFERIOR_PIN, bottomMotorSpeed);
  setMotorSpeed(MOTOR_FEEDER_PIN, FEEDER_SPEED);
  motorsActive = true;
  digitalWrite(LED_PIN, HIGH);
  Serial.printf("  Velocidad -> Sup: %d%%, Inf: %d%%, Alimentador: %d%%\n",
    topMotorSpeed, bottomMotorSpeed, FEEDER_SPEED);
  Serial.println(">>> MOTORES ACTIVOS <<<");
}

void stopAllMotors() {
  Serial.println(">>> DETENIENDO MOTORES <<<");
  ledcWrite(MOTOR_SUPERIOR_PIN, 0);
  ledcWrite(MOTOR_INFERIOR_PIN, 0);
  ledcWrite(MOTOR_FEEDER_PIN, 0);
  motorsActive = false;
  digitalWrite(LED_PIN, LOW);
  Serial.println("  PWM: 0/255 (0%)");
  Serial.println(">>> MOTORES DETENIDOS <<<");
}

void initServos() {
  servoHorizontal.attach(SERVO_HORIZONTAL_PIN, 500, 2500);
  servoHorizontal.write(90);
  servoH_angle = 90;
  Serial.println("Servo horizontal inicializado (500-2500us, default 90°)");
}

void setServos(int h) {
  servoH_angle = constrain(h, 0, 180);
  servoHorizontal.write(servoH_angle);
  Serial.printf("  Servo Horizontal: %d°\n", servoH_angle);
}

void servosStop() {
  Serial.println(">>> SERVOS A REPOSO (90°) <<<");
  setServos(90);
}

void IRAM_ATTR onBallDetected() {
  unsigned long now = millis();
  if (now - lastBallTime >= DEBOUNCE_MS) {
    ballsReturned++;
    lastBallTime = now;
  }
}

void initIRSensor() {
  pinMode(IR_SENSOR_PIN, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(IR_SENSOR_PIN), onBallDetected, FALLING);
  ballsReturned = 0;
  Serial.println("Sensor IR-08H inicializado (pin 34, FALLING edge)");
}

void publishSensorData() {
  if (!client.connected()) return;

  JsonDocument doc;
  doc["balls_returned"] = ballsReturned;
  doc["voltage"] = 3.3;

  String jsonString;
  serializeJson(doc, jsonString);

  client.publish(TOPIC_DATA, jsonString.c_str());
}

void callback(char* topic, byte* payload, unsigned int length) {
  Serial.println("");
  Serial.println("========================================");
  Serial.print("Topic: ");
  Serial.println(topic);

  if (ignoreNextMessage) {
    ignoreNextMessage = false;
    if (String(topic) == TOPIC_EMERGENCY) {
      String jsonString = "";
      for (int i = 0; i < length; i++) {
        jsonString += (char)payload[i];
      }
      JsonDocument doc;
      DeserializationError error = deserializeJson(doc, jsonString);
      if (!error) {
        const char* action = doc["action"] | "";
        if (String(action) == "STOP") {
          stopAllMotors();
          servosStop();
        }
      }
    } else {
      Serial.println("  (ignorado - mensaje retenido)");
      Serial.println("========================================");
      return;
    }
  }

  String jsonString = "";
  for (int i = 0; i < length; i++) {
    jsonString += (char)payload[i];
  }
  Serial.print("Payload: ");
  Serial.println(jsonString);

  JsonDocument doc;
  DeserializationError error = deserializeJson(doc, jsonString);

  if (error) {
    Serial.print("ERROR: JSON inválido -> ");
    Serial.println(error.c_str());
    Serial.println("========================================");
    return;
  }

  const char* action = doc["action"] | "";
  int priority = doc["priority"] | -1;

  if (String(topic) == TOPIC_EMERGENCY || priority == 0) {
    Serial.print("¡EVENTO DE EMERGENCIA! action=");
    Serial.println(action);
    if (String(action) == "STOP") {
      stopAllMotors();
      servosStop();
    }
    Serial.println("========================================");
    return;
  }

  if (String(topic) == TOPIC_SERVO) {
    if (doc.containsKey("oscillate")) {
      bool osc = doc["oscillate"];
      if (osc) {
        oscillationActive = true;
        if (doc.containsKey("min")) oscMin = doc["min"];
        if (doc.containsKey("max")) oscMax = doc["max"];
        if (oscMin < 0) oscMin = 0;
        if (oscMax > 180) oscMax = 180;
        if (oscMin >= oscMax) oscMax = oscMin + 10;
        oscDirection = 1;
        servoH_angle = oscMin;
        setServos(servoH_angle);
        Serial.printf("OSCILACIÓN ACTIVADA: min=%d, max=%d\n", oscMin, oscMax);
      } else {
        oscillationActive = false;
        setServos(90);
        Serial.println("OSCILACIÓN DESACTIVADA → servo a 90°");
      }
    } else if (doc.containsKey("horizontal")) {
      oscillationActive = false;
      servoH_angle = doc["horizontal"];
      setServos(servoH_angle);
      Serial.printf("  Servo manual: %d°\n", servoH_angle);
    }
    Serial.println("========================================");
    return;
  }

  if (String(topic) == TOPIC_CONTROL) {
    if (doc.containsKey("topMotorSpeed")) {
      int newSpeed = doc["topMotorSpeed"];
      Serial.printf("  topMotorSpeed: %d -> %d\n", topMotorSpeed, newSpeed);
      topMotorSpeed = newSpeed;
    }
    if (doc.containsKey("bottomMotorSpeed")) {
      int newSpeed = doc["bottomMotorSpeed"];
      Serial.printf("  bottomMotorSpeed: %d -> %d\n", bottomMotorSpeed, newSpeed);
      bottomMotorSpeed = newSpeed;
    }
    if (doc.containsKey("horizontalAngle") && !oscillationActive) {
      servoH_angle = doc["horizontalAngle"];
      setServos(servoH_angle);
    }

    Serial.print("  action: \"");
    Serial.print(action);
    Serial.println("\"");

    if (String(action) == "START") {
      startMotors();
    } else if (String(action) == "STOP") {
      stopAllMotors();
    } else if (motorsActive) {
      Serial.println("  Motores activos -> actualizando velocidad...");
      startMotors();
    } else {
      Serial.println("  Motores inactivos. Enviar action=START para activar.");
    }
  }

  if (String(topic) == TOPIC_STATUS) {
    Serial.println("  Mensaje de estado recibido (sin accion)");
  }

  Serial.println("========================================");
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Conectando MQTT...");
    String clientId = "ESP32_Lanzador_" + String(random(0, 1000));

    if (client.connect(clientId.c_str())) {
      Serial.println("CONECTADO");
      ignoreNextMessage = true;
      client.subscribe(TOPIC_CONTROL);
      client.subscribe(TOPIC_EMERGENCY);
      client.subscribe(TOPIC_SERVO);
      Serial.print("Suscrito a: ");
      Serial.print(TOPIC_CONTROL);
      Serial.print(", ");
      Serial.print(TOPIC_EMERGENCY);
      Serial.print(", ");
      Serial.print(TOPIC_SERVO);
      Serial.print(", ");
      Serial.println(TOPIC_DATA);
    } else {
      Serial.print("Error rc=");
      Serial.print(client.state());
      Serial.println(" (reintento en 5s)");
      delay(5000);
    }
  }
}

void setup() {
  pinMode(MOTOR_SUPERIOR_PIN, OUTPUT);
  pinMode(MOTOR_INFERIOR_PIN, OUTPUT);
  pinMode(MOTOR_FEEDER_PIN, OUTPUT);
  digitalWrite(MOTOR_SUPERIOR_PIN, LOW);
  digitalWrite(MOTOR_INFERIOR_PIN, LOW);
  digitalWrite(MOTOR_FEEDER_PIN, LOW);
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  delay(50);

  Serial.begin(115200);
  Serial.println("");
  Serial.println("========================================");
  Serial.println("  PING PONG IoT - ESP32 Lanzador");
  Serial.println("========================================");

  initServos();
  initMotors();
  initIRSensor();
  setup_wifi();

  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);

  Serial.println("Setup completado. Esperando comandos MQTT...");
  Serial.println("");
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  if (oscillationActive) {
    unsigned long now = millis();
    if (now - lastOscStep >= OSC_STEP_MS) {
      lastOscStep = now;
      servoH_angle += oscDirection * OSC_STEP_DEG;
      if (servoH_angle >= oscMax) {
        servoH_angle = oscMax;
        oscDirection = -1;
      } else if (servoH_angle <= oscMin) {
        servoH_angle = oscMin;
        oscDirection = 1;
      }
      setServos(servoH_angle);
    }
  }

  unsigned long now = millis();
  if (now - lastPublishData >= DATA_INTERVAL) {
    lastPublishData = now;
    publishSensorData();
  }
}

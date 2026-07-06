class SensorReading {
  final int? id;
  final int? sessionId;
  final String timestamp;
  final String topic;
  final int? ballsReturned;
  final double? voltage;
  final String? payloadJson;

  const SensorReading({
    this.id,
    this.sessionId,
    required this.timestamp,
    required this.topic,
    this.ballsReturned,
    this.voltage,
    this.payloadJson,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'session_id': sessionId,
      'timestamp': timestamp,
      'topic': topic,
      'balls_returned': ballsReturned,
      'voltage': voltage,
      'payload_json': payloadJson,
    };
  }

  factory SensorReading.fromMap(Map<String, dynamic> map) {
    return SensorReading(
      id: map['id'] as int?,
      sessionId: map['session_id'] as int?,
      timestamp: map['timestamp'] as String,
      topic: map['topic'] as String,
      ballsReturned: map['balls_returned'] as int?,
      voltage: map['voltage'] as double?,
      payloadJson: map['payload_json'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'timestamp': timestamp,
    'topic': topic,
    'ballsReturned': ballsReturned,
    'voltage': voltage,
    'payloadJson': payloadJson,
  };

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      id: json['id'] as int?,
      sessionId: json['sessionId'] as int?,
      timestamp: json['timestamp'] as String,
      topic: json['topic'] as String,
      ballsReturned: json['ballsReturned'] as int?,
      voltage: json['voltage'] as double?,
      payloadJson: json['payloadJson'] as String?,
    );
  }
}

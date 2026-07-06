class PingPongShot {
  final int topMotorSpeed;
  final int bottomMotorSpeed;
  final int horizontalAngle;
  final double interval;

  const PingPongShot({
    required this.topMotorSpeed,
    required this.bottomMotorSpeed,
    required this.horizontalAngle,
    required this.interval,
  });

  Map<String, dynamic> toJson() => {
    'topMotorSpeed': topMotorSpeed,
    'bottomMotorSpeed': bottomMotorSpeed,
    'horizontalAngle': horizontalAngle,
    'interval': interval,
  };

  factory PingPongShot.fromJson(Map<String, dynamic> json) => PingPongShot(
    topMotorSpeed: json['topMotorSpeed'] as int,
    bottomMotorSpeed: json['bottomMotorSpeed'] as int,
    horizontalAngle: json['horizontalAngle'] as int,
    interval: (json['interval'] as num).toDouble(),
  );

  PingPongShot copyWith({
    int? topMotorSpeed,
    int? bottomMotorSpeed,
    int? horizontalAngle,
    double? interval,
  }) => PingPongShot(
    topMotorSpeed: topMotorSpeed ?? this.topMotorSpeed,
    bottomMotorSpeed: bottomMotorSpeed ?? this.bottomMotorSpeed,
    horizontalAngle: horizontalAngle ?? this.horizontalAngle,
    interval: interval ?? this.interval,
  );

  Map<String, dynamic> toMap() => {
    'top_motor_speed': topMotorSpeed,
    'bottom_motor_speed': bottomMotorSpeed,
    'horizontal_angle': horizontalAngle,
    'launch_interval': interval,
  };

  factory PingPongShot.fromMap(Map<String, dynamic> map) => PingPongShot(
    topMotorSpeed: map['top_motor_speed'] as int? ?? 0,
    bottomMotorSpeed: map['bottom_motor_speed'] as int? ?? 0,
    horizontalAngle: map['horizontal_angle'] as int? ?? 90,
    interval: (map['launch_interval'] as num?)?.toDouble() ?? 1.0,
  );
}

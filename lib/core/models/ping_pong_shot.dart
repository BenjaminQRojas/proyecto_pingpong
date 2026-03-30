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
}

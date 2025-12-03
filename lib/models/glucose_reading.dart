/// Glucose reading model from sensor
class GlucoseReading {
  final String id;
  final String patientId;
  final double value; // mg/dL
  final DateTime timestamp;
  final String? trend; // 'rising', 'falling', 'stable', 'rising_fast', 'falling_fast'
  final String source; // 'sensor', 'manual', 'calibration'
  
  GlucoseReading({
    required this.id,
    required this.patientId,
    required this.value,
    required this.timestamp,
    this.trend,
    this.source = 'sensor',
  });

  /// Get glucose status based on value
  GlucoseStatus get status {
    if (value < 70) return GlucoseStatus.low;
    if (value < 180) return GlucoseStatus.normal;
    if (value < 250) return GlucoseStatus.high;
    return GlucoseStatus.veryHigh;
  }

  /// TODO: [PLACEHOLDER] Implement fromJson when sensor API is connected
  factory GlucoseReading.fromJson(Map<String, dynamic> json) {
    return GlucoseReading(
      id: json['id'] ?? '',
      patientId: json['patientId'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      trend: json['trend'],
      source: json['source'] ?? 'sensor',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'trend': trend,
      'source': source,
    };
  }
}

enum GlucoseStatus {
  low,
  normal,
  high,
  veryHigh,
}

extension GlucoseStatusExtension on GlucoseStatus {
  String get label {
    switch (this) {
      case GlucoseStatus.low:
        return 'Niska';
      case GlucoseStatus.normal:
        return 'Normalna';
      case GlucoseStatus.high:
        return 'Wysoka';
      case GlucoseStatus.veryHigh:
        return 'Bardzo wysoka';
    }
  }
}

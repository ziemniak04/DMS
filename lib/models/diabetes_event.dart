/// Event model for tracking diabetes-related events
class DiabetesEvent {
  final String id;
  final String patientId;
  final EventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final String? notes;

  DiabetesEvent({
    required this.id,
    required this.patientId,
    required this.type,
    required this.timestamp,
    required this.data,
    this.notes,
  });

  /// TODO: [PLACEHOLDER] Implement fromJson when Firebase is connected
  factory DiabetesEvent.fromJson(Map<String, dynamic> json) {
    return DiabetesEvent(
      id: json['id'] ?? '',
      patientId: json['patientId'] ?? '',
      type: EventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EventType.note,
      ),
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      data: json['data'] ?? {},
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'notes': notes,
    };
  }
}

enum EventType {
  bloodGlucose,    // Manual blood glucose measurement
  insulin,         // Insulin dose
  meal,            // Meal with carbs
  activity,        // Physical activity
  fastingGlucose,  // Fasting glucose (morning)
  note,            // General note
}

extension EventTypeExtension on EventType {
  String get label {
    switch (this) {
      case EventType.bloodGlucose:
        return 'Blood Glucose';
      case EventType.insulin:
        return 'Insulin';
      case EventType.meal:
        return 'Meal';
      case EventType.activity:
        return 'Activity';
      case EventType.fastingGlucose:
        return 'Fasting Glucose';
      case EventType.note:
        return 'Note';
    }
  }

  String get description {
    switch (this) {
      case EventType.bloodGlucose:
        return 'Finger prick measurement or calibration';
      case EventType.insulin:
        return 'Fast-acting or long-acting insulin dose';
      case EventType.meal:
        return 'Carbohydrates consumed';
      case EventType.activity:
        return 'Duration and intensity';
      case EventType.fastingGlucose:
        return 'Wake-up time measurement';
      case EventType.note:
        return 'Add information';
    }
  }

  String get icon {
    switch (this) {
      case EventType.bloodGlucose:
        return '🩸';
      case EventType.insulin:
        return '💉';
      case EventType.meal:
        return '🍽️';
      case EventType.activity:
        return '🏃';
      case EventType.fastingGlucose:
        return '☀️';
      case EventType.note:
        return '📝';
    }
  }
}

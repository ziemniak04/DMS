/// User model representing both patients and doctors
class User {
  final String id;
  final String email;
  final String name;
  final String role; // 'patient' or 'doctor'
  final String? profileImageUrl;
  final DateTime? createdAt;
  
  // Doctor-specific fields
  final String? specialization;
  final String? licenseNumber;
  
  // Patient-specific fields
  final String? doctorId;
  final DateTime? dateOfBirth;
  final String? diabetesType;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.profileImageUrl,
    this.createdAt,
    this.specialization,
    this.licenseNumber,
    this.doctorId,
    this.dateOfBirth,
    this.diabetesType,
  });

  bool get isDoctor => role == 'doctor';
  bool get isPatient => role == 'patient';

  /// TODO: [PLACEHOLDER] Implement fromJson when Firebase is connected
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'patient',
      profileImageUrl: json['profileImageUrl'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      specialization: json['specialization'],
      licenseNumber: json['licenseNumber'],
      doctorId: json['doctorId'],
      dateOfBirth: json['dateOfBirth'] != null 
          ? DateTime.parse(json['dateOfBirth']) 
          : null,
      diabetesType: json['diabetesType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt?.toIso8601String(),
      'specialization': specialization,
      'licenseNumber': licenseNumber,
      'doctorId': doctorId,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'diabetesType': diabetesType,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? profileImageUrl,
    DateTime? createdAt,
    String? specialization,
    String? licenseNumber,
    String? doctorId,
    DateTime? dateOfBirth,
    String? diabetesType,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      specialization: specialization ?? this.specialization,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      doctorId: doctorId ?? this.doctorId,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      diabetesType: diabetesType ?? this.diabetesType,
    );
  }
}

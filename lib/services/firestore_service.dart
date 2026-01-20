import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dms_app/models/user.dart';
import 'package:dms_app/models/glucose_reading.dart';
import 'package:dms_app/models/diabetes_event.dart';

/// Firestore Database Service
///
/// Handles all Firestore database operations
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get usersCollection => _db.collection('users');
  CollectionReference get glucoseReadingsCollection =>
      _db.collection('glucoseReadings');
  CollectionReference get diabetesEventsCollection =>
      _db.collection('diabetesEvents');

  /// Create a new user document
  Future<void> createUser(User user) async {
    try {
      await usersCollection.doc(user.id).set(user.toJson());
    } catch (e) {
      throw 'Error creating user: ${e.toString()}';
    }
  }

  /// Get user by ID
  Future<User?> getUserById(String userId) async {
    try {
      final doc = await usersCollection.doc(userId).get();
      if (doc.exists) {
        return User.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw 'Error fetching user: ${e.toString()}';
    }
  }

  /// Update user data
  Future<void> updateUser(User user) async {
    try {
      await usersCollection.doc(user.id).update(user.toJson());
    } catch (e) {
      throw 'Error updating user: ${e.toString()}';
    }
  }

  /// Delete user
  Future<void> deleteUser(String userId) async {
    try {
      await usersCollection.doc(userId).delete();
    } catch (e) {
      throw 'Error deleting user: ${e.toString()}';
    }
  }

  /// Get all patients (for doctors)
  Future<List<User>> getAllPatients() async {
    try {
      final snapshot = await usersCollection
          .where('role', isEqualTo: 'patient')
          .get();

      return snapshot.docs
          .map((doc) => User.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw 'Error fetching patients: ${e.toString()}';
    }
  }

  /// Get patients by doctor ID
  Future<List<User>> getPatientsByDoctorId(String doctorId) async {
    try {
      final snapshot = await usersCollection
          .where('role', isEqualTo: 'patient')
          .where('doctorId', isEqualTo: doctorId)
          .get();

      return snapshot.docs
          .map((doc) => User.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw 'Error fetching patients: ${e.toString()}';
    }
  }

  /// Get doctor by ID
  Future<User?> getDoctorById(String doctorId) async {
    try {
      final doc = await usersCollection.doc(doctorId).get();
      if (doc.exists) {
        final user = User.fromJson(doc.data() as Map<String, dynamic>);
        if (user.isDoctor) {
          return user;
        }
      }
      return null;
    } catch (e) {
      throw 'Error fetching doctor: ${e.toString()}';
    }
  }

  /// Assign patient to doctor
  Future<void> assignPatientToDoctor(String patientId, String doctorId) async {
    try {
      await usersCollection.doc(patientId).update({'doctorId': doctorId});
    } catch (e) {
      throw 'Error assigning patient to doctor: ${e.toString()}';
    }
  }

  /// Stream of user data
  Stream<User?> getUserStream(String userId) {
    return usersCollection.doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return User.fromJson(snapshot.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  /// Stream of patients for a doctor
  Stream<List<User>> getPatientsStream(String doctorId) {
    return usersCollection
        .where('role', isEqualTo: 'patient')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => User.fromJson(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  /// Get glucose readings for a patient
  Future<List<GlucoseReading>> getGlucoseReadings(String patientId, {int hours = 24}) async {
    try {
      print('Querying glucose readings for patientId: $patientId');

      // Simplified query without timestamp filter to avoid index requirements
      final snapshot = await glucoseReadingsCollection
          .where('patientId', isEqualTo: patientId)
          .get();

      print('Found ${snapshot.docs.length} glucose reading documents');

      // Debug: print raw timestamp values and types for first few docs
      for (var i = 0; i < snapshot.docs.length && i < 5; i++) {
        final data = snapshot.docs[i].data() as Map<String, dynamic>?;
        final ts = data != null ? data['timestamp'] : null;
        print('DEBUG glucose doc ${i} timestamp raw: $ts (type: ${ts?.runtimeType})');
      }

      final readings = snapshot.docs
          .map((doc) => GlucoseReading.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Sort by timestamp in memory and filter by time range
      readings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final cutoffTime = DateTime.now().subtract(Duration(hours: hours));
      final filteredReadings = readings.where((reading) =>
        reading.timestamp.isAfter(cutoffTime)
      ).toList();

      print('Filtered to ${filteredReadings.length} readings within time range');

      return filteredReadings;
    } catch (e) {
      print('Error getting glucose readings: $e');
      throw 'Error fetching glucose readings: ${e.toString()}';
    }
  }

  /// Get diabetes events for a patient
  Future<List<DiabetesEvent>> getDiabetesEvents(String patientId, {int hours = 24}) async {
    try {
      print('Querying diabetes events for userId: $patientId');

      // Simplified query without timestamp filter to avoid index requirements
      final snapshot = await diabetesEventsCollection
          .where('userId', isEqualTo: patientId)
          .get();

      print('Found ${snapshot.docs.length} diabetes event documents');

      // Debug: print raw timestamp values and types for first few event docs
      for (var i = 0; i < snapshot.docs.length && i < 5; i++) {
        final data = snapshot.docs[i].data() as Map<String, dynamic>?;
        final ts = data != null ? data['timestamp'] : null;
        print('DEBUG event doc ${i} timestamp raw: $ts (type: ${ts?.runtimeType})');
      }

      final events = snapshot.docs
          .map((doc) => DiabetesEvent.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Sort by timestamp in memory and filter by time range
      events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final cutoffTime = DateTime.now().subtract(Duration(hours: hours));
      final filteredEvents = events.where((event) =>
        event.timestamp.isAfter(cutoffTime)
      ).toList();

      print('Filtered to ${filteredEvents.length} events within time range');

      return filteredEvents;
    } catch (e) {
      print('Error getting diabetes events: $e');
      throw 'Error fetching diabetes events: ${e.toString()}';
    }
  }

  /// Stream of glucose readings for a patient
  Stream<List<GlucoseReading>> getGlucoseReadingsStream(String patientId, {int hours = 24}) {
    final cutoffTime = DateTime.now().subtract(Duration(hours: hours));
    
    return glucoseReadingsCollection
        .where('patientId', isEqualTo: patientId)
        .where('timestamp', isGreaterThanOrEqualTo: cutoffTime.toIso8601String())
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GlucoseReading.fromJson(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  /// Stream of diabetes events for a patient
  Stream<List<DiabetesEvent>> getDiabetesEventsStream(String patientId, {int hours = 24}) {
    final cutoffTime = DateTime.now().subtract(Duration(hours: hours));
    
    return diabetesEventsCollection
        .where('userId', isEqualTo: patientId)
        .where('timestamp', isGreaterThanOrEqualTo: cutoffTime.toIso8601String())
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DiabetesEvent.fromJson(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }
}

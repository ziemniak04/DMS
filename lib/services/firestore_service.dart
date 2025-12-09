import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dms_app/models/user.dart';

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
      throw 'Błąd podczas tworzenia użytkownika: ${e.toString()}';
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
      throw 'Błąd podczas pobierania użytkownika: ${e.toString()}';
    }
  }

  /// Update user data
  Future<void> updateUser(User user) async {
    try {
      await usersCollection.doc(user.id).update(user.toJson());
    } catch (e) {
      throw 'Błąd podczas aktualizacji użytkownika: ${e.toString()}';
    }
  }

  /// Delete user
  Future<void> deleteUser(String userId) async {
    try {
      await usersCollection.doc(userId).delete();
    } catch (e) {
      throw 'Błąd podczas usuwania użytkownika: ${e.toString()}';
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
      throw 'Błąd podczas pobierania pacjentów: ${e.toString()}';
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
      throw 'Błąd podczas pobierania pacjentów: ${e.toString()}';
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
      throw 'Błąd podczas pobierania lekarza: ${e.toString()}';
    }
  }

  /// Assign patient to doctor
  Future<void> assignPatientToDoctor(String patientId, String doctorId) async {
    try {
      await usersCollection.doc(patientId).update({'doctorId': doctorId});
    } catch (e) {
      throw 'Błąd podczas przypisywania pacjenta do lekarza: ${e.toString()}';
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
}

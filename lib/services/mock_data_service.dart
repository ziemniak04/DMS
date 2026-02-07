import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dms_app/models/glucose_reading.dart';

/// Service for generating realistic mock data for Type 1 Diabetes simulation
class MockDataService {
  static const String mockEmail = 'mocked@test.pl';

  /// Maximum age of mock data before it's considered stale and regenerated
  static const int maxDataAgeDays = 7;

  /// Check if mock data already exists for a user and is still fresh
  static Future<bool> hasMockData(String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Check for actual readings and verify freshness
      final readingsSnapshot = await firestore
          .collection('glucoseReadings')
          .where('patientId', isEqualTo: userId)
          .get();

      if (readingsSnapshot.docs.isEmpty) {
        return false;
      }

      // Find the most recent timestamp to check for staleness
      DateTime? mostRecent;
      for (final doc in readingsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        final tsRaw = data?['timestamp'];
        if (tsRaw is String) {
          try {
            final ts = DateTime.parse(tsRaw);
            if (mostRecent == null || ts.isAfter(mostRecent)) {
              mostRecent = ts;
            }
          } catch (_) {}
        }
      }

      if (mostRecent == null) {
        return false;
      }

      final age = DateTime.now().difference(mostRecent);
      if (age.inDays > maxDataAgeDays) {
        debugPrint('Mock data is stale (${age.inDays} days old), will regenerate');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error checking for existing mock data: $e');
      return false;
    }
  }

  /// Generate and store mock data for a user (only if data doesn't exist)
  static Future<void> generateMockData(String userId) async {
    final firestore = FirebaseFirestore.instance;

    debugPrint('Checking if mock data exists for userId: $userId');

    // Check if data already exists
    if (await hasMockData(userId)) {
      debugPrint('Mock data already exists for userId: $userId, skipping generation');
      return;
    }

    debugPrint('Generating mock data for userId: $userId');

    // Create a status document to prevent concurrent generation
    try {
      await firestore.collection('mock_data_status').doc(userId).set({
        'userId': userId,
        'generatedAt': FieldValue.serverTimestamp(),
        'status': 'generating',
      });
    } catch (e) {
      debugPrint('Status document might already exist, proceeding with generation');
    }

    // Create user document first
    await _createMockUserDocument(userId);

    // Clear existing data for this user (just in case)
    await _clearExistingData(userId);

    // Generate data for the last 7 days
    final now = DateTime.now();
    for (int day = 6; day >= 0; day--) {
      final date = now.subtract(Duration(days: day));
      await _generateDayData(userId, date);
    }

    // Update status to completed
    await firestore.collection('mock_data_status').doc(userId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });

    debugPrint('Mock data generation completed for userId: $userId');
  }

  static Future<void> _createMockUserDocument(String userId) async {
    final firestore = FirebaseFirestore.instance;

    await firestore.collection('users').doc(userId).set({
      'id': userId,
      'email': mockEmail,
      'name': 'Mock Patient',
      'role': 'patient',
      'dateOfBirth': DateTime(1990, 1, 1).toIso8601String(),
      'diabetesType': 'Type 1',
    });
  }

  static Future<void> _clearExistingData(String userId) async {
    final firestore = FirebaseFirestore.instance;

    // Clear glucose readings
    final glucoseQuery = await firestore
      .collection('glucoseReadings')
      .where('patientId', isEqualTo: userId)
      .get();
    for (var doc in glucoseQuery.docs) {
      await doc.reference.delete();
    }

    // Clear events
    final eventsQuery = await firestore
      .collection('diabetesEvents')
      .where('userId', isEqualTo: userId)
      .get();
    for (var doc in eventsQuery.docs) {
      await doc.reference.delete();
    }
  }

  static Future<void> _generateDayData(String userId, DateTime date) async {
    final random = Random(date.millisecondsSinceEpoch);

    // Generate daily schedule
    final breakfastTime = DateTime(date.year, date.month, date.day, 7 + random.nextInt(2), 30 + random.nextInt(30));
    final lunchTime = DateTime(date.year, date.month, date.day, 12 + random.nextInt(2), random.nextInt(60));
    final dinnerTime = DateTime(date.year, date.month, date.day, 18 + random.nextInt(2), random.nextInt(60));
    final bedtime = DateTime(date.year, date.month, date.day, 22 + random.nextInt(2), random.nextInt(60));
    final waketime = DateTime(date.year, date.month, date.day, 7 + random.nextInt(2), random.nextInt(60));

    // Generate glucose readings throughout the day
    await _generateGlucoseReadings(userId, date, breakfastTime, lunchTime, dinnerTime, bedtime, waketime, random);

    // Generate meal events
    await _generateMealEvents(userId, breakfastTime, lunchTime, dinnerTime, random);

    // Generate insulin events
    await _generateInsulinEvents(userId, breakfastTime, lunchTime, dinnerTime, random);

    // Generate sleep event
    await _generateSleepEvent(userId, bedtime, waketime);
  }

  static Future<void> _generateGlucoseReadings(
    String userId,
    DateTime date,
    DateTime breakfastTime,
    DateTime lunchTime,
    DateTime dinnerTime,
    DateTime bedtime,
    DateTime waketime,
    Random random,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final readings = <GlucoseReading>[];

    // Start from 6 AM to midnight
    DateTime currentTime = DateTime(date.year, date.month, date.day, 6, 0);
    final endTime = DateTime(date.year, date.month, date.day, 23, 59);

    double currentGlucose = 120 + random.nextInt(40) - 20; // Start around 100-140 mg/dL

    while (currentTime.isBefore(endTime)) {
      // Skip if during sleep (reduce readings)
      final isSleeping = currentTime.isAfter(bedtime) || currentTime.isBefore(waketime);
      if (isSleeping && random.nextDouble() > 0.3) {
        currentTime = currentTime.add(Duration(minutes: 15 + random.nextInt(30)));
        continue;
      }

      // Adjust glucose based on meals and time
      if (currentTime.isAfter(breakfastTime.subtract(Duration(minutes: 30))) &&
          currentTime.isBefore(breakfastTime.add(Duration(hours: 2)))) {
        // Post-breakfast spike
        currentGlucose += random.nextInt(60) - 10;
      } else if (currentTime.isAfter(lunchTime.subtract(Duration(minutes: 30))) &&
          currentTime.isBefore(lunchTime.add(Duration(hours: 2)))) {
        // Post-lunch spike
        currentGlucose += random.nextInt(50) - 5;
      } else if (currentTime.isAfter(dinnerTime.subtract(Duration(minutes: 30))) &&
          currentTime.isBefore(dinnerTime.add(Duration(hours: 2)))) {
        // Post-dinner spike
        currentGlucose += random.nextInt(40) - 5;
      } else if (isSleeping) {
        // Gradual decrease during sleep
        currentGlucose -= random.nextInt(10);
      } else {
        // Random fluctuations
        currentGlucose += random.nextInt(20) - 10;
      }

      // Keep glucose in realistic range (40-400 mg/dL)
      currentGlucose = currentGlucose.clamp(40.0, 400.0);

      readings.add(GlucoseReading(
        id: '',
        patientId: userId,
        value: currentGlucose,
        timestamp: currentTime,
        source: 'Mock CGM',
      ));

      // Next reading in 5-15 minutes
      currentTime = currentTime.add(Duration(minutes: 5 + random.nextInt(10)));
    }

    // Save readings to Firestore (use canonical collection and patientId field)
    for (var reading in readings) {
      await firestore.collection('glucoseReadings').add(reading.toJson());
    }
  }

  static Future<void> _generateMealEvents(
    String userId,
    DateTime breakfastTime,
    DateTime lunchTime,
    DateTime dinnerTime,
    Random random,
  ) async {
    final firestore = FirebaseFirestore.instance;

    final meals = [
      {'time': breakfastTime, 'type': 'Breakfast', 'carbs': 45 + random.nextInt(20)},
      {'time': lunchTime, 'type': 'Lunch', 'carbs': 60 + random.nextInt(30)},
      {'time': dinnerTime, 'type': 'Dinner', 'carbs': 50 + random.nextInt(25)},
    ];

    for (var meal in meals) {
      await firestore.collection('diabetesEvents').add({
        'userId': userId,
        'type': 'meal',
        'timestamp': (meal['time'] as DateTime).toIso8601String(),
        'data': {
          'mealType': meal['type'],
          'carbohydrates': meal['carbs'],
          'description': 'Mock ${meal['type']} meal',
        },
      });
    }
  }

  static Future<void> _generateInsulinEvents(
    String userId,
    DateTime breakfastTime,
    DateTime lunchTime,
    DateTime dinnerTime,
    Random random,
  ) async {
    final firestore = FirebaseFirestore.instance;

    final insulinDoses = [
      {'time': breakfastTime.subtract(Duration(minutes: 15)), 'type': 'Rapid-acting', 'dose': 4 + random.nextInt(4)},
      {'time': lunchTime.subtract(Duration(minutes: 15)), 'type': 'Rapid-acting', 'dose': 5 + random.nextInt(4)},
      {'time': dinnerTime.subtract(Duration(minutes: 15)), 'type': 'Rapid-acting', 'dose': 4 + random.nextInt(4)},
    ];

    for (var dose in insulinDoses) {
      await firestore.collection('diabetesEvents').add({
        'userId': userId,
        'type': 'insulin',
        'timestamp': (dose['time'] as DateTime).toIso8601String(),
        'data': {
          'insulinType': dose['type'],
          'dose': dose['dose'],
          'units': 'units',
        },
      });
    }
  }

  static Future<void> _generateSleepEvent(String userId, DateTime bedtime, DateTime waketime) async {
    final firestore = FirebaseFirestore.instance;

    await firestore.collection('diabetesEvents').add({
      'userId': userId,
      'type': 'sleep',
      'timestamp': bedtime.toIso8601String(),
      'data': {
        'duration': waketime.difference(bedtime).inHours,
        'quality': 'Good',
      },
    });
  }
}
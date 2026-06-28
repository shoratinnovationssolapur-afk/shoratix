import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/student_model.dart';
import '../models/trainer_model.dart';
import '../models/course_model.dart';
import '../models/fee_model.dart';
import '../models/placement_model.dart';
import '../models/attendance_model.dart';
import '../models/announcement_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Unified Collection References
  final CollectionReference userCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference courseCollection = FirebaseFirestore.instance.collection('courses');
  final CollectionReference placementCollection = FirebaseFirestore.instance.collection('placements');
  final CollectionReference eventCollection = FirebaseFirestore.instance.collection('events');
  final CollectionReference lectureCollection = FirebaseFirestore.instance.collection('lectures');
  final CollectionReference notificationCollection = FirebaseFirestore.instance.collection('notifications');
  final CollectionReference placedStudentsCollection = FirebaseFirestore.instance.collection('placed_students');
  final CollectionReference announcementCollection = FirebaseFirestore.instance.collection('announcements');
  final CollectionReference metadataCollection = FirebaseFirestore.instance.collection('metadata');

  // Check user role
  Future<String> getUserRole(String uid) async {
    try {
      print("🎯 DB DEBUG: Looking up role in 'users' collection for UID: $uid");
      DocumentSnapshot doc = await userCollection.doc(uid).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        final String role = data['role'] ?? 'student';
        print("🎯 DB DEBUG: Match found! Role string parsed: $role");
        return role;
      }
      print("⚠️ DB DEBUG: Document does not exist in 'users' collection for UID: $uid");
      return 'unknown';
    } catch (e) {
      print("❌ DB DEBUG: getUserRole crashed with error: $e");
      return 'unknown';
    }
  }

  // Live Trainer Data Stream
// Live Trainer Data Stream
  Stream<TrainerModel?> getTrainerData(String uid) {
    print("📡 STREAM DEBUG: Listening to user document for trainer stats on UID: $uid");
    return userCollection.doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        try {
          // Explicitly cast snapshot.data() to Map<String, dynamic>
          return TrainerModel.fromMap(snapshot.data() as Map<String, dynamic>);
        } catch (e) {
          print("❌ STREAM MAP ERROR: Failed to parse map data to TrainerModel: $e");
          return null;
        }
      }
      return null;
    });

  }

  // Get Live Student Data Stream
  Stream<StudentModel> getStudentData(String uid) {
    return userCollection.doc(uid).snapshots().map((snap) {
      if (snap.exists && snap.data() != null) {
        return StudentModel.fromMap(snap.data() as Map<String, dynamic>);
      } else {
        return StudentModel(uid: uid, name: '', email: '', phone: '', studentId: '', branch: '');
      }
    });
  }

  // Update Student Data Profile
  Future<void> updateStudentData(StudentModel student) async {
    return await userCollection.doc(student.uid).set(student.toMap(), SetOptions(merge: true));
  }

  // Find Student by Student ID String
  Future<StudentModel?> getStudentByStudentId(String studentId) async {
    final querySnapshot = await userCollection
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      return StudentModel.fromMap(querySnapshot.docs.first.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Schedule Event (Trainer Panel)
  Future<void> scheduleEvent(HubEvent event) async {
    try {
      await eventCollection.doc(event.id).set(event.toMap()).timeout(const Duration(seconds: 15));
      await addNotification(
        title: "New ${event.type.toUpperCase()} Scheduled",
        message: "${event.title} is scheduled for ${DateFormat('MMM d, h:mm a').format(event.dateTime)}",
        branch: event.branch,
      );
    } catch (e) {
      throw Exception("Failed to schedule event: ${e.toString()}");
    }
  }

  // Get Events by Branch
  Stream<List<HubEvent>> getEvents(List<String> interests) {
    if (interests.isEmpty) return Stream.value([]);
    return eventCollection
        .where('branch', whereIn: interests)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => HubEvent.fromMap(doc.data() as Map<String, dynamic>)).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    });
  }

  // Post Recorded Lecture or Notes Metadata Reference
  Future<void> postLecture(Map<String, dynamic> lecture) async {
    try {
      await lectureCollection.add(lecture).timeout(const Duration(seconds: 15));
      await addNotification(
        title: "New Resource Added",
        message: "New ${lecture['type'] ?? 'resource'} added: ${lecture['title']}",
        branch: lecture['branch'],
      );
    } catch (e) {
      throw Exception("Database Error: ${e.toString()}");
    }
  }

  // Get Lectures/Notes Stream Filtered by Branch
  Stream<List<Map<String, dynamic>>> getLectures(List<String> interests) {
    if (interests.isEmpty) return Stream.value([]);
    return lectureCollection
        .where('branch', whereIn: interests)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      list.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
      return list;
    });
  }

  // Global Multi-Format Heartbeat Engine
  Future<void> updateHeartbeat(String uid) async {
    final now = DateTime.now();
    final dateId = "${now.year}-${now.month}-${now.day}";
    final userDocRef = userCollection.doc(uid);
    final attendanceRef = userDocRef.collection('attendance').doc(dateId);

    try {
      final userSnapshot = await userDocRef.get();
      if (!userSnapshot.exists) return;

      final userData = userSnapshot.data() as Map<String, dynamic>;
      final String role = userData['role'] ?? 'student';

      await userDocRef.update({'lastActive': now.toIso8601String()});

      if (role == 'student') {
        final attendanceDoc = await attendanceRef.get();
        if (!attendanceDoc.exists) {
          await attendanceRef.set({
            'date': now.toIso8601String(),
            'isPresent': false,
            'reason': 'Not checked in',
            'timestamp': now.toIso8601String(),
            'lastUpdated': now.toIso8601String(),
          });
          await _recalculateAttendancePercentage(uid);
        } else {
          final data = attendanceDoc.data() as Map<String, dynamic>;
          if (data['isPresent'] == true) {
            final lastUpdated = DateTime.parse(data['lastUpdated'] ?? data['date']);
            if (now.difference(lastUpdated).inMinutes > 45) {
              await markAttendance(uid, false);
            } else {
              await attendanceRef.update({'lastUpdated': now.toIso8601String()});
            }
          }
        }
        await syncAttendanceHistory(uid);
      }
    } catch (e) {
      print("Failed processing background heartbeat framework: $e");
    }
  }

  // Mark Attendance manually/automatically
  Future<void> markAttendance(String uid, bool isPresent) async {
    final attendanceRef = userCollection.doc(uid).collection('attendance');
    final now = DateTime.now();
    final dateId = "${now.year}-${now.month}-${now.day}";

    await attendanceRef.doc(dateId).set({
      'date': now.toIso8601String(),
      'isPresent': isPresent,
      'lastUpdated': now.toIso8601String(),
      'timestamp': now.toIso8601String(),
    }, SetOptions(merge: true));

    await _recalculateAttendancePercentage(uid);
  }

  // Fill in tracking blocks for missed profile days
  Future<void> syncAttendanceHistory(String uid) async {
    final now = DateTime.now();
    final studentDoc = await userCollection.doc(uid).get();
    if (!studentDoc.exists) return;

    final data = studentDoc.data() as Map<String, dynamic>;
    if (data['lastActive'] == null) return;

    DateTime lastActive = DateTime.parse(data['lastActive']);
    DateTime checkDate = DateTime(lastActive.year, lastActive.month, lastActive.day).add(const Duration(days: 1));
    DateTime today = DateTime(now.year, now.month, now.day);

    bool addedAbsence = false;
    while (checkDate.isBefore(today)) {
      final dateId = "${checkDate.year}-${checkDate.month}-${checkDate.day}";
      final missedAttendanceRef = userCollection.doc(uid).collection('attendance').doc(dateId);
      final missedDoc = await missedAttendanceRef.get();

      if (!missedDoc.exists) {
        await missedAttendanceRef.set({
          'date': checkDate.toIso8601String(),
          'isPresent': false,
          'reason': 'Did not open app',
          'timestamp': checkDate.toIso8601String(),
          'lastUpdated': checkDate.toIso8601String(),
        });
        addedAbsence = true;
      }
      checkDate = checkDate.add(const Duration(days: 1));
    }

    if (addedAbsence) {
      await _recalculateAttendancePercentage(uid);
    }
  }

  Future<void> _recalculateAttendancePercentage(String uid) async {
    final attendanceRef = userCollection.doc(uid).collection('attendance');
    final allRecords = await attendanceRef.get();

    if (allRecords.docs.isEmpty) return;

    int total = allRecords.docs.length;
    int present = allRecords.docs.where((doc) => doc.data()['isPresent'] == true).length;
    double percentage = (present / total) * 100;

    await userCollection.doc(uid).update({
      'attendancePercentage': percentage,
    });
  }

  // Get Live Attendance Log Record List
// Get Live Attendance Log Record List
  Stream<List<AttendanceModel>> getAttendance(String uid) {
    return userCollection
        .doc(uid)
        .collection('attendance')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        // Explicitly cast doc.data() from Object to Map<String, dynamic>
        return AttendanceModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Get Fees Structure Data map tracking
  Stream<FeeModel> getFees(String uid) {
    return userCollection.doc(uid).collection('fees').doc('status').snapshots().map((snap) {
      if (snap.exists && snap.data() != null) {
        return FeeModel.fromMap(snap.data()!);
      } else {
        return FeeModel(totalFees: 50000, paidAmount: 0, monthlyAmount: 5000);
      }
    });
  }

  // Process Fee Ledger Transactions
  Future<void> processPayment(String uid, double amount) async {
    final feeRef = userCollection.doc(uid).collection('fees').doc('status');
    final doc = await feeRef.get();

    FeeModel currentFees = doc.exists && doc.data() != null
        ? FeeModel.fromMap(doc.data()!)
        : FeeModel(totalFees: 50000, paidAmount: 0, monthlyAmount: 5000);

    final newPaidAmount = currentFees.paidAmount + amount;
    final now = DateTime.now();
    final nextDueDate = DateTime(now.year, now.month + 1, now.day);

    final newHistory = List<PaymentHistory>.from(currentFees.history);
    newHistory.insert(0, PaymentHistory(
      amount: amount,
      date: now,
      transactionId: "TRX-${now.millisecondsSinceEpoch}",
      status: 'Success',
    ));

    await feeRef.set({
      'totalFees': currentFees.totalFees,
      'paidAmount': newPaidAmount,
      'monthlyAmount': currentFees.monthlyAmount,
      'nextDueDate': nextDueDate.toIso8601String(),
      'history': newHistory.map((e) => e.toMap()).toList(),
    });
  }

  // Course Enrollment Mapping
  Future<void> enrollInCourse(String uid, String courseName) async {
    final studentRef = userCollection.doc(uid);
    await studentRef.update({
      'enrolledCourses': FieldValue.arrayUnion([courseName]),
    });

    final feeRef = studentRef.collection('fees').doc('status');
    final feeDoc = await feeRef.get();
    if (!feeDoc.exists) {
      await feeRef.set({
        'totalFees': 50000,
        'paidAmount': 0,
        'monthlyAmount': 5000,
        'nextDueDate': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'history': [],
      });
    }
  }

  // Generative Sequence for Student Tracking Counters
  Future<String> getNextStudentId() async {
    final docRef = metadataCollection.doc('student_counter');
    return await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        transaction.set(docRef, {'current': 1001});
        return "SH-1001";
      }
      final data = snapshot.data() as Map<String, dynamic>;
      int nextId = data['current'] + 1;
      transaction.update(docRef, {'current': nextId});
      return "SH-$nextId";
    });
  }

  // Notifications Infrastructure
  Future<void> addNotification({required String title, required String message, required String branch}) async {
    await notificationCollection.add({
      'title': title,
      'message': message,
      'branch': branch,
      'time': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<Map<String, dynamic>>> getNotifications(List<String> interests) {
    if (interests.isEmpty) return Stream.value([]);
    return notificationCollection
        .where('branch', whereIn: interests)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      list.sort((a, b) => (b['time'] ?? '').compareTo(a['time'] ?? ''));
      return list;
    });
  }

  // Post Announcement Layout Configuration
  Future<void> postAnnouncement(AnnouncementModel announcement) async {
    try {
      await announcementCollection.add(announcement.toMap());
      await addNotification(
        title: "New Announcement: ${announcement.title}",
        message: announcement.message,
        branch: announcement.branch,
      );
    } catch (e) {
      throw Exception("Failed to post announcement: $e");
    }
  }

  Stream<List<AnnouncementModel>> getAnnouncements(List<String> interests) {
    if (interests.isEmpty) return Stream.value([]);
    return announcementCollection
        .where('branch', whereIn: interests)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => AnnouncementModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Stream<List<CourseModel>> get courses {
    return courseCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => CourseModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  Stream<List<PlacementModel>> get placements {
    return placementCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => PlacementModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  Stream<List<PlacedStudent>> get placedStudents {
    return placedStudentsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => PlacedStudent.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  Future<void> deleteEvent(String id) async {
    await eventCollection.doc(id).delete();
  }
}
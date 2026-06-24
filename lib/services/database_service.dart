import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  // Collection References
  final CollectionReference studentCollection = FirebaseFirestore.instance.collection('students');
  final CollectionReference trainerCollection = FirebaseFirestore.instance.collection('trainers');
  final CollectionReference courseCollection = FirebaseFirestore.instance.collection('courses');
  final CollectionReference placementCollection = FirebaseFirestore.instance.collection('placements');
  final CollectionReference eventCollection = FirebaseFirestore.instance.collection('events');
  final CollectionReference lectureCollection = FirebaseFirestore.instance.collection('lectures');
  final CollectionReference notificationCollection = FirebaseFirestore.instance.collection('notifications');

  // Check user role
  Future<String> getUserRole(String uid) async {
    final studentDoc = await studentCollection.doc(uid).get();
    if (studentDoc.exists) return 'student';
    final trainerDoc = await trainerCollection.doc(uid).get();
    if (trainerDoc.exists) return 'trainer';
    return 'unknown';
  }

  // Get Trainer Data
  Stream<TrainerModel?> getTrainerData(String uid) {
    return trainerCollection.doc(uid).snapshots().map((snap) {
      if (snap.exists) {
        return TrainerModel.fromMap(snap.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Schedule Event (Trainer)
  Future<void> scheduleEvent(HubEvent event) async {
    try {
      await eventCollection.doc(event.id).set(event.toMap()).timeout(const Duration(seconds: 15));

      // Notify students of the branch
      await addNotification(
        title: "New ${event.type.toUpperCase()} Scheduled",
        message: "${event.title} is scheduled for ${DateFormat('MMM d, h:mm a').format(event.dateTime)}",
        branch: event.branch,
      );
    } catch (e) {
      throw Exception("Failed to schedule event: ${e.toString()}");
    }
  }

  // Get Events by Branch/Course
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

  // Post Recorded Lecture (Trainer)
  Future<void> postLecture(Map<String, dynamic> lecture) async {
    try {
      await lectureCollection.add(lecture).timeout(const Duration(seconds: 15));

      // Notify students of the branch
      await addNotification(
        title: "New Resource Added",
        message: "New ${lecture['type'] ?? 'lecture/notes'} added: ${lecture['title']}",
        branch: lecture['branch'],
      );
    } catch (e) {
      throw Exception("Database Error: ${e.toString()}");
    }
  }

  // Upload file to Firebase Storage (Supports Web & Mobile)
  Future<String> uploadFile(dynamic fileSource, String folder, {String? fileName}) async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        throw StateError("Please sign in with a trainer account before uploading files.");
      }

      final String name = _sanitizeStorageFileName(
        fileName ?? DateTime.now().millisecondsSinceEpoch.toString(),
      );
      final Reference ref = FirebaseStorage.instance.ref().child(folder).child(name);
      final SettableMetadata metadata = SettableMetadata(
        contentType: _contentTypeForFileName(name),
      );

      UploadTask uploadTask;
      if (kIsWeb) {
        if (fileSource is! Uint8List) {
          throw ArgumentError("Web uploads require file bytes.");
        }
        uploadTask = ref.putData(fileSource, metadata);
      } else {
        if (fileSource is! File) {
          throw ArgumentError("Mobile uploads require a local file.");
        }
        if (!await fileSource.exists()) {
          throw StateError("The selected file is no longer available on this device.");
        }
        uploadTask = ref.putFile(fileSource, metadata);
      }

      final TaskSnapshot snapshot = await uploadTask.timeout(const Duration(minutes: 15));
      return await snapshot.ref.getDownloadURL();
    } on TimeoutException {
      throw Exception("Upload timed out. Try a smaller file or a stronger internet connection.");
    } on FirebaseException catch (e) {
      throw Exception(e.message ?? "Upload failed (${e.code}).");
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  String _sanitizeStorageFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[^\w\-.]'), '_');
  }

  String _contentTypeForFileName(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      case 'webm':
        return 'video/webm';
      case 'pdf':
        return 'application/pdf';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  // Get Lectures by Branch/Course
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

  // Notifications
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

  final CollectionReference placedStudentsCollection = FirebaseFirestore.instance.collection('placed_students');
  final CollectionReference announcementCollection = FirebaseFirestore.instance.collection('announcements');
  final CollectionReference metadataCollection = FirebaseFirestore.instance.collection('metadata');

  // Update Student Data
  Future updateStudentData(StudentModel student) async {
    return await studentCollection.doc(student.uid).set(student.toMap());
  }

  // Get Next Student ID
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

  // Get Student Stream
  Stream<StudentModel> getStudentData(String uid) {
    return studentCollection.doc(uid).snapshots().map((snap) {
      if (snap.exists) {
        return StudentModel.fromMap(snap.data() as Map<String, dynamic>);
      } else {
        // Return an empty model or handle as needed
        return StudentModel(uid: uid, name: '', email: '', phone: '', studentId: '', branch: '');
      }
    });
  }

  // Find Student by Student ID
  Future<StudentModel?> getStudentByStudentId(String studentId) async {
    final querySnapshot = await studentCollection
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      return StudentModel.fromMap(querySnapshot.docs.first.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Get Courses
  Stream<List<CourseModel>> get courses {
    return courseCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return CourseModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Get Fees for a student
  Stream<FeeModel> getFees(String uid) {
    return studentCollection.doc(uid).collection('fees').doc('status').snapshots().map((snap) {
      if (snap.exists) {
        return FeeModel.fromMap(snap.data() as Map<String, dynamic>);
      } else {
        return FeeModel(totalFees: 50000, paidAmount: 0, monthlyAmount: 5000);
      }
    });
  }

  // Process Fee Payment
  Future<void> processPayment(String uid, double amount) async {
    final feeRef = studentCollection.doc(uid).collection('fees').doc('status');
    final doc = await feeRef.get();
    
    FeeModel currentFees;
    if (doc.exists) {
      currentFees = FeeModel.fromMap(doc.data() as Map<String, dynamic>);
    } else {
      currentFees = FeeModel(totalFees: 50000, paidAmount: 0, monthlyAmount: 5000);
    }

    final newPaidAmount = currentFees.paidAmount + amount;
    final now = DateTime.now();
    // Set next due date to 1 month from now
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

  // Enroll in a course
  Future<void> enrollInCourse(String uid, String courseName) async {
    final studentRef = studentCollection.doc(uid);
    await studentRef.update({
      'enrolledCourses': FieldValue.arrayUnion([courseName]),
    });
    
    // Also initialize fees if not exists
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

  // Get Attendance for a student
  Stream<List<AttendanceModel>> getAttendance(String uid) {
    return studentCollection
        .doc(uid)
        .collection('attendance')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AttendanceModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Mark Attendance and Update Percentage
  Future<void> markAttendance(String uid, bool isPresent) async {
    final attendanceRef = studentCollection.doc(uid).collection('attendance');
    final now = DateTime.now();
    final dateId = "${now.year}-${now.month}-${now.day}";

    // Add attendance record
    await attendanceRef.doc(dateId).set({
      'date': now.toIso8601String(), // This represents the day
      'isPresent': isPresent,
      'lastUpdated': now.toIso8601String(),
      'timestamp': now.toIso8601String(), // Exact recording time
    });

    await _recalculateAttendancePercentage(uid);
  }

  // Heartbeat to track activity and auto-mark attendance
  Future<void> updateHeartbeat(String uid) async {
    final now = DateTime.now();
    final dateId = "${now.year}-${now.month}-${now.day}";
    final attendanceRef = studentCollection.doc(uid).collection('attendance').doc(dateId);

    // 1. Update lastActive in student profile
    await studentCollection.doc(uid).update({
      'lastActive': now.toIso8601String(),
    });

    // 2. Ensure today's record exists. If not, default to Absent
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
      // 3. Logic: If user was present but is now inactive for > 45 mins
      final data = attendanceDoc.data() as Map<String, dynamic>;
      if (data['isPresent'] == true) {
        final lastUpdated = DateTime.parse(data['lastUpdated'] ?? data['date']);
        if (now.difference(lastUpdated).inMinutes > 45) {
          await markAttendance(uid, false);
        } else {
          await attendanceRef.update({
            'lastUpdated': now.toIso8601String(),
          });
        }
      }
    }

    // 4. Sync missed days (days where the app wasn't opened at all)
    await syncAttendanceHistory(uid);
  }

  // Fill gaps for days when the student didn't open the app
  Future<void> syncAttendanceHistory(String uid) async {
    final now = DateTime.now();
    final studentDoc = await studentCollection.doc(uid).get();
    if (!studentDoc.exists) return;

    final data = studentDoc.data() as Map<String, dynamic>;
    if (data['lastActive'] == null) return;

    DateTime lastActive = DateTime.parse(data['lastActive']);
    DateTime checkDate = DateTime(lastActive.year, lastActive.month, lastActive.day).add(const Duration(days: 1));
    DateTime today = DateTime(now.year, now.month, now.day);

    bool addedAbsence = false;
    while (checkDate.isBefore(today)) {
      final dateId = "${checkDate.year}-${checkDate.month}-${checkDate.day}";
      final missedAttendanceRef = studentCollection.doc(uid).collection('attendance').doc(dateId);
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
    final attendanceRef = studentCollection.doc(uid).collection('attendance');
    final allRecords = await attendanceRef.get();
    
    if (allRecords.docs.isEmpty) return;

    int total = allRecords.docs.length;
    int present = allRecords.docs.where((doc) => doc.data()['isPresent'] == true).length;
    double percentage = (present / total) * 100;

    await studentCollection.doc(uid).update({
      'attendancePercentage': percentage,
    });
  }

  // Get Placements
  Stream<List<PlacementModel>> get placements {
    return placementCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return PlacementModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Get Placed Students Gallery
  Stream<List<PlacedStudent>> get placedStudents {
    return placedStudentsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return PlacedStudent.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Post Announcement
  Future<void> postAnnouncement(AnnouncementModel announcement) async {
    try {
      await announcementCollection.add(announcement.toMap());
      
      // Also add to notifications for that branch
      await addNotification(
        title: "New Announcement: ${announcement.title}",
        message: announcement.message,
        branch: announcement.branch,
      );
    } catch (e) {
      throw Exception("Failed to post announcement: $e");
    }
  }

  // Get Announcements
  Stream<List<AnnouncementModel>> getAnnouncements(List<String> interests) {
    if (interests.isEmpty) return Stream.value([]);
    return announcementCollection
        .where('branch', whereIn: interests)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return AnnouncementModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  // Delete Event
  Future<void> deleteEvent(String id) async {
    await eventCollection.doc(id).delete();
  }
}

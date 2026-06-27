import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/student_model.dart';
import '../models/trainer_model.dart';
import '../services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for direct registration routing if needed
import 'package:firebase_messaging/firebase_messaging.dart';

class UserAuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? _user;
  StudentModel? _studentModel;
  TrainerModel? _trainerModel;
  String _userRole = 'student';
  bool _isLoading = false;

  User? get user => _user;
  StudentModel? get studentModel => _studentModel;
  TrainerModel? get trainerModel => _trainerModel;
  String get userRole => _userRole;
  bool get isLoading => _isLoading;

  UserAuthProvider() {
    _authService.user.listen((User? user) {
      _user = user;
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        _studentModel = null;
        _trainerModel = null;
        _userRole = 'student';
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData(String uid) async {
    if (uid == 'debug_trainer_id' || uid == 'debug_student_id') return;

    try {
      print("🔍 DB LOG: Fetching user role for UID: $uid");
      _userRole = await _dbService.getUserRole(uid);
      print("🔍 DB LOG: User role found: $_userRole");

      if (_userRole == 'student') {
        _dbService.getStudentData(uid).listen((student) {
          print("🔍 DB LOG: Student profile loaded into provider state!");
          _studentModel = student;
          try {
            FirebaseMessaging.instance.subscribeToTopic('branch_${student.branch}');
          } catch (_) {}
          notifyListeners();
        }, onError: (error) {
          print("❌ DB STREAM ERROR (Student): $error");
        });
      } else if (_userRole == 'trainer') {
        _dbService.getTrainerData(uid).listen((trainer) {
          if (trainer != null) {
            print("🔍 DB LOG: Trainer profile loaded into provider state!");
            _trainerModel = trainer;
            notifyListeners();
          }
        }, onError: (error) {
          print("❌ DB STREAM ERROR (Trainer): $error");
        });
      } else {
        print("⚠️ DB WARNING: User role is empty or unknown! Forcing notification update.");
        notifyListeners(); // Prevents dashboard from locking up if role doesn't resolve
      }
    } catch (e) {
      print("❌ CRITICAL ERROR IN AUTH DATA LOADING: $e");
      notifyListeners();
    }
  }

  Future<String?> signIn(String identifier, String password, String expectedRole, String branch) async {
    _isLoading = true;
    notifyListeners();

    final email = identifier.trim().toLowerCase();
    final pwd = password.trim();

    if (expectedRole == 'trainer' && email == 'trainer@shorat.com' && pwd == 'trainer123') {
      setDebugTrainer(branch);
      _isLoading = false;
      notifyListeners();
      return null;
    }

    if (expectedRole == 'student' && (email == 'student@shorat.com' || email == 'sh-debug') && pwd == 'student123') {
      setDebugStudent(branch);
      _isLoading = false;
      notifyListeners();
      return null;
    }

    try {
      String finalEmail = email;

      if (!identifier.contains('@')) {
        final student = await _dbService.getStudentByStudentId(identifier);
        if (student == null) {
          _isLoading = false;
          notifyListeners();
          return "No student found with this ID.";
        }
        finalEmail = student.email;
      }

      UserCredential? result = await _authService.signIn(finalEmail, pwd).timeout(const Duration(seconds: 15));

      if (result?.user != null) {
        String actualRole = await _dbService.getUserRole(result!.user!.uid);
        if (actualRole != expectedRole) {
          await _authService.signOut();
          _isLoading = false;
          notifyListeners();
          return "Access Denied: You are not registered as a $expectedRole.";
        }
        _userRole = actualRole;
      }

      _isLoading = false;
      notifyListeners();
      return null;
    } on TimeoutException {
      _isLoading = false;
      notifyListeners();
      return "Connection timed out. Please check your internet.";
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message ?? "An error occurred during sign in.";
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  /// Dynamic Registration Engine
  /// Accepts either StudentModel or TrainerModel payloads seamlessly
  Future<String?> register(String email, String password, dynamic userModel) async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Create the credentials record inside Firebase Auth account management
      UserCredential credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String uid = credential.user!.uid;

      // 2. Extract specific model configurations dynamically
      if (userModel is StudentModel) {
        StudentModel adjustedStudent = StudentModel(
          uid: uid,
          name: userModel.name,
          email: userModel.email,
          phone: userModel.phone,
          studentId: userModel.studentId,
          branch: userModel.branch,
          role: 'student',
          enrolledCourses: userModel.enrolledCourses,
        );

        // Save using your existing database management service rules
        await FirebaseFirestore.instance.collection('users').doc(uid).set(adjustedStudent.toMap());
        _studentModel = adjustedStudent;
        _userRole = 'student';
      } else if (userModel is TrainerModel) {
        TrainerModel adjustedTrainer = TrainerModel(
          uid: uid,
          name: userModel.name,
          email: userModel.email,
          branch: userModel.branch,
          role: 'trainer',
        );

        // Save trainer details under the unified metadata document system mapping
        await FirebaseFirestore.instance.collection('users').doc(uid).set(adjustedTrainer.toMap());
        _trainerModel = adjustedTrainer;
        _userRole = 'trainer';
      }

      _isLoading = false;
      notifyListeners();
      return null; // Registration success
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message ?? "An error occurred during registration.";
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _trainerModel = null;
    _studentModel = null;
    notifyListeners();
  }

  void setDebugTrainer(String branch) {
    _userRole = 'trainer';
    _trainerModel = TrainerModel(
      uid: 'debug_trainer_id',
      name: 'Debug Trainer',
      email: 'trainer@shorat.com',
      branch: branch,
    );
    notifyListeners();
  }

  void setDebugStudent(String branch) {
    _userRole = 'student';
    _studentModel = StudentModel(
      uid: 'debug_student_id',
      name: 'Debug Student',
      email: 'student@shorat.com',
      phone: '0000000000',
      studentId: 'SH-DEBUG',
      branch: branch,
      enrolledCourses: ["Flutter Dev"],
      attendancePercentage: 85.0,
    );
    notifyListeners();
  }
}
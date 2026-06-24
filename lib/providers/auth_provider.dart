import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/student_model.dart';
import '../models/trainer_model.dart';
import '../services/database_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class UserAuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();
  
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
    // Skip loading for debug IDs
    if (uid == 'debug_trainer_id' || uid == 'debug_student_id') return;

    _userRole = await _dbService.getUserRole(uid);
    if (_userRole == 'student') {
      _dbService.getStudentData(uid).listen((student) {
        _studentModel = student;
        try {
          FirebaseMessaging.instance.subscribeToTopic('branch_${student.branch}');
        } catch (_) {}
        notifyListeners();
      });
    } else if (_userRole == 'trainer') {
      _dbService.getTrainerData(uid).listen((trainer) {
        if (trainer != null) {
          _trainerModel = trainer;
          notifyListeners();
        }
      });
    }
  }

  Future<String?> signIn(String identifier, String password, String expectedRole, String branch) async {
    _isLoading = true;
    notifyListeners();

    final email = identifier.trim().toLowerCase();
    final pwd = password.trim();

    // GLOBAL BYPASS LOGIC
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

  Future<String?> register(String email, String password, StudentModel student) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.register(email, password, student).timeout(const Duration(seconds: 15));
      _isLoading = false;
      notifyListeners();
      return null;
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

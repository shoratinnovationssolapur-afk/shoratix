import 'package:firebase_auth/firebase_auth.dart';
import '../models/student_model.dart';
import 'database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _db = DatabaseService();

  // Auth change user stream
  Stream<User?> get user => _auth.authStateChanges();

  // Register with email & password
  Future<UserCredential?> register(String email, String password, StudentModel student) async {
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    User? user = result.user;
    if (user != null) {
      // Create a new document for the student with the uid
      await _db.updateStudentData(student.copyWith(uid: user.uid));
    }
    return result;
  }

  // Sign in with email & password
  Future<UserCredential?> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Sign out
  Future signOut() async {
    return await _auth.signOut();
  }
}

// Extension to help with StudentModel updates
extension on StudentModel {
  StudentModel copyWith({String? uid}) {
    return StudentModel(
      uid: uid ?? this.uid,
      name: name,
      email: email,
      phone: phone,
      studentId: studentId,
      branch: branch,
      enrolledCourses: enrolledCourses,
      attendancePercentage: attendancePercentage,
      profileImageUrl: profileImageUrl,
    );
  }
}

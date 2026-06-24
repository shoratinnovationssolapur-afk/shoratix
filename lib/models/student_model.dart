class StudentModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String studentId;
  final String branch;
  final List<String> enrolledCourses;
  final double attendancePercentage;
  final String profileImageUrl;
  final DateTime? lastActive;
  final String role; // Added role field

  StudentModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.studentId,
    required this.branch,
    this.enrolledCourses = const [],
    this.attendancePercentage = 0.0,
    this.profileImageUrl = '',
    this.lastActive,
    this.role = 'student', // Default to student
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'studentId': studentId,
      'branch': branch,
      'enrolledCourses': enrolledCourses,
      'attendancePercentage': attendancePercentage,
      'profileImageUrl': profileImageUrl,
      'lastActive': lastActive?.toIso8601String(),
      'role': role,
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      studentId: map['studentId'] ?? '',
      branch: map['branch'] ?? '',
      enrolledCourses: List<String>.from(map['enrolledCourses'] ?? []),
      attendancePercentage: (map['attendancePercentage'] ?? 0.0).toDouble(),
      profileImageUrl: map['profileImageUrl'] ?? '',
      lastActive: map['lastActive'] != null ? DateTime.parse(map['lastActive']) : null,
      role: map['role'] ?? 'student',
    );
  }

  StudentModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? studentId,
    String? branch,
    List<String>? enrolledCourses,
    double? attendancePercentage,
    String? profileImageUrl,
    DateTime? lastActive,
  }) {
    return StudentModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      studentId: studentId ?? this.studentId,
      branch: branch ?? this.branch,
      enrolledCourses: enrolledCourses ?? this.enrolledCourses,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String id; // Student ID or Trainer ID
  final String branch;
  final String role; // 'student' or 'trainer'
  final String profileImageUrl;
  final List<String> enrolledCourses; // For students
  final double attendancePercentage; // For students

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.id,
    required this.branch,
    required this.role,
    this.profileImageUrl = '',
    this.enrolledCourses = const [],
    this.attendancePercentage = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'id': id,
      'branch': branch,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'enrolledCourses': enrolledCourses,
      'attendancePercentage': attendancePercentage,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      id: map['id'] ?? map['studentId'] ?? '',
      branch: map['branch'] ?? '',
      role: map['role'] ?? 'student',
      profileImageUrl: map['profileImageUrl'] ?? '',
      enrolledCourses: List<String>.from(map['enrolledCourses'] ?? []),
      attendancePercentage: (map['attendancePercentage'] ?? 0.0).toDouble(),
    );
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? id,
    String? branch,
    String? role,
    String? profileImageUrl,
    List<String>? enrolledCourses,
    double? attendancePercentage,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      id: id ?? this.id,
      branch: branch ?? this.branch,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      enrolledCourses: enrolledCourses ?? this.enrolledCourses,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
    );
  }
}

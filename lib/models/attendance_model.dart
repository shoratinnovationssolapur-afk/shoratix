class AttendanceModel {
  final DateTime date;
  final bool isPresent;
  final String? reason;
  final DateTime timestamp;

  AttendanceModel({
    required this.date,
    required this.isPresent,
    this.reason,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'isPresent': isPresent,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      date: DateTime.parse(map['date']),
      isPresent: map['isPresent'] ?? false,
      reason: map['reason'],
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp']) 
          : DateTime.parse(map['date']), // Fallback to date if timestamp missing
    );
  }
}

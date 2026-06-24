enum PlacementType { job, internship }

class PlacementModel {
  final String id;
  final String companyName;
  final String companyLogoUrl;
  final String position;
  final String location;
  final String package;
  final PlacementType type;
  final String description;
  final DateTime deadline;
  final String applyUrl;

  PlacementModel({
    required this.id,
    required this.companyName,
    required this.companyLogoUrl,
    required this.position,
    required this.location,
    required this.package,
    required this.type,
    required this.description,
    required this.deadline,
    required this.applyUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyName': companyName,
      'companyLogoUrl': companyLogoUrl,
      'position': position,
      'location': location,
      'package': package,
      'type': type.name,
      'description': description,
      'deadline': deadline.toIso8601String(),
      'applyUrl': applyUrl,
    };
  }

  factory PlacementModel.fromMap(Map<String, dynamic> map) {
    return PlacementModel(
      id: map['id'] ?? '',
      companyName: map['companyName'] ?? '',
      companyLogoUrl: map['companyLogoUrl'] ?? '',
      position: map['position'] ?? '',
      location: map['location'] ?? '',
      package: map['package'] ?? '',
      type: PlacementType.values.firstWhere((e) => e.name == map['type'], orElse: () => PlacementType.job),
      description: map['description'] ?? '',
      deadline: DateTime.parse(map['deadline']),
      applyUrl: map['applyUrl'] ?? '',
    );
  }
}

class PlacedStudent {
  final String name;
  final String company;
  final String package;
  final String imageUrl;
  final String offerLetterUrl;

  PlacedStudent({
    required this.name,
    required this.company,
    required this.package,
    required this.imageUrl,
    required this.offerLetterUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'company': company,
      'package': package,
      'imageUrl': imageUrl,
      'offerLetterUrl': offerLetterUrl,
    };
  }

  factory PlacedStudent.fromMap(Map<String, dynamic> map) {
    return PlacedStudent(
      name: map['name'] ?? '',
      company: map['company'] ?? '',
      package: map['package'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      offerLetterUrl: map['offerLetterUrl'] ?? '',
    );
  }
}

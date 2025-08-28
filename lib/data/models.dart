import 'package:flutter/foundation.dart';

@immutable
class ApiKeyModel {
  final String id; // unique
  final String name;
  final String value; // stored locally; consider OS keychain for production

  const ApiKeyModel({
    required this.id,
    required this.name,
    required this.value,
  });

  ApiKeyModel copyWith({String? id, String? name, String? value}) =>
      ApiKeyModel(
        id: id ?? this.id,
        name: name ?? this.name,
        value: value ?? this.value,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'value': value};

  factory ApiKeyModel.fromJson(Map<String, dynamic> json) => ApiKeyModel(
    id: json['id'] as String,
    name: json['name'] as String,
    value: json['value'] as String,
  );
}

@immutable
class UserProfileModel {
  final String displayName;
  final String? section; // e.g., Section-A
  final String? group; // e.g., Group-1
  final int? semester; // 1..8
  final String? rollNo; // optional
  final String? branch; // CSE/ECE/EEE/ICS/AIML

  const UserProfileModel({
    required this.displayName,
    this.section,
    this.group,
    this.semester,
    this.rollNo,
    this.branch,
  });

  UserProfileModel copyWith({
    String? displayName,
    String? section,
    String? group,
    int? semester,
    String? rollNo,
    String? branch,
  }) => UserProfileModel(
    displayName: displayName ?? this.displayName,
    section: section ?? this.section,
    group: group ?? this.group,
    semester: semester ?? this.semester,
    rollNo: rollNo ?? this.rollNo,
    branch: branch ?? this.branch,
  );

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    if (section != null) 'section': section,
    if (group != null) 'group': group,
    if (semester != null) 'semester': semester,
    if (rollNo != null) 'rollNo': rollNo,
    if (branch != null) 'branch': branch,
  };

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      UserProfileModel(
        displayName: (json['displayName'] as String?) ?? 'You',
        section: json['section'] as String?,
        group: json['group'] as String?,
        semester: json['semester'] as int?,
        rollNo: json['rollNo'] as String?,
        branch: json['branch'] as String?,
      );
}

@immutable
class SpaceModel {
  final String id;
  final String name;
  final String emoji;
  final String description; // free text
  final String goals; // free text
  final String guide; // free text

  const SpaceModel({
    required this.id,
    required this.name,
    required this.emoji,
    this.description = '',
    this.goals = '',
    this.guide = '',
  });

  SpaceModel copyWith({
    String? id,
    String? name,
    String? emoji,
    String? description,
    String? goals,
    String? guide,
  }) => SpaceModel(
    id: id ?? this.id,
    name: name ?? this.name,
    emoji: emoji ?? this.emoji,
    description: description ?? this.description,
    goals: goals ?? this.goals,
    guide: guide ?? this.guide,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    if (description.isNotEmpty) 'description': description,
    if (goals.isNotEmpty) 'goals': goals,
    if (guide.isNotEmpty) 'guide': guide,
  };

  factory SpaceModel.fromJson(Map<String, dynamic> json) => SpaceModel(
    id: json['id'] as String,
    name: json['name'] as String,
    emoji: json['emoji'] as String? ?? '📚',
    description: json['description'] as String? ?? '',
    goals: json['goals'] as String? ?? '',
    guide: json['guide'] as String? ?? '',
  );
}

@immutable
class StudentModel {
  final String rollNo; // unique key
  final String name;
  final String section; // e.g., Section-A/B/C
  final String group; // e.g., Group-1/Group-2
  final int? semester; // optional, computed later

  const StudentModel({
    required this.rollNo,
    required this.name,
    required this.section,
    required this.group,
    this.semester,
  });

  StudentModel copyWith({
    String? rollNo,
    String? name,
    String? section,
    String? group,
    int? semester,
  }) => StudentModel(
    rollNo: rollNo ?? this.rollNo,
    name: name ?? this.name,
    section: section ?? this.section,
    group: group ?? this.group,
    semester: semester ?? this.semester,
  );

  Map<String, dynamic> toJson() => {
    'rollNo': rollNo,
    'name': name,
    'section': section,
    'group': group,
    if (semester != null) 'semester': semester,
  };

  factory StudentModel.fromJson(Map<String, dynamic> json) => StudentModel(
    rollNo: json['rollNo'] as String,
    name: json['name'] as String,
    section: json['section'] as String,
    group: json['group'] as String,
    semester: json['semester'] as int?,
  );
}

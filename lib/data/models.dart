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

  const UserProfileModel({required this.displayName});

  UserProfileModel copyWith({String? displayName}) =>
      UserProfileModel(displayName: displayName ?? this.displayName);

  Map<String, dynamic> toJson() => {'displayName': displayName};

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      UserProfileModel(displayName: (json['displayName'] as String?) ?? 'You');
}

@immutable
class SpaceModel {
  final String id;
  final String name;
  final String emoji;

  const SpaceModel({required this.id, required this.name, required this.emoji});

  SpaceModel copyWith({String? id, String? name, String? emoji}) => SpaceModel(
    id: id ?? this.id,
    name: name ?? this.name,
    emoji: emoji ?? this.emoji,
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'emoji': emoji};

  factory SpaceModel.fromJson(Map<String, dynamic> json) => SpaceModel(
    id: json['id'] as String,
    name: json['name'] as String,
    emoji: json['emoji'] as String? ?? '📚',
  );
}

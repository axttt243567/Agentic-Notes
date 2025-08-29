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

@immutable
class ChatMessageModel {
  final String id; // unique within session
  final String role; // 'user' | 'model'
  final String text;
  final List<String>? imageUrls;
  final DateTime ts;

  const ChatMessageModel({
    required this.id,
    required this.role,
    required this.text,
    this.imageUrls,
    required this.ts,
  });

  ChatMessageModel copyWith({
    String? id,
    String? role,
    String? text,
    List<String>? imageUrls,
    DateTime? ts,
  }) => ChatMessageModel(
    id: id ?? this.id,
    role: role ?? this.role,
    text: text ?? this.text,
    imageUrls: imageUrls ?? this.imageUrls,
    ts: ts ?? this.ts,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role,
    'text': text,
    if (imageUrls != null && imageUrls!.isNotEmpty) 'imageUrls': imageUrls,
    'ts': ts.toIso8601String(),
  };

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      ChatMessageModel(
        id: json['id'] as String,
        role: json['role'] as String,
        text: json['text'] as String? ?? '',
        imageUrls: (json['imageUrls'] as List?)?.cast<String>(),
        ts:
            DateTime.tryParse(json['ts'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

@immutable
class ChatSessionModel {
  final String id; // unique
  final String title;
  final String model; // e.g., gemini-2.5-flash-lite
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
  final String? spaceId; // optional link to a space
  final String? lastSnippet; // for quick preview in list
  final List<ChatMessageModel> messages; // persisted inline for simplicity

  const ChatSessionModel({
    required this.id,
    required this.title,
    required this.model,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
    this.spaceId,
    this.lastSnippet,
    required this.messages,
  });

  ChatSessionModel copyWith({
    String? id,
    String? title,
    String? model,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? messageCount,
    String? spaceId,
    String? lastSnippet,
    List<ChatMessageModel>? messages,
  }) => ChatSessionModel(
    id: id ?? this.id,
    title: title ?? this.title,
    model: model ?? this.model,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    messageCount: messageCount ?? this.messageCount,
    spaceId: spaceId ?? this.spaceId,
    lastSnippet: lastSnippet ?? this.lastSnippet,
    messages: messages ?? this.messages,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'model': model,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'messageCount': messageCount,
    if (spaceId != null) 'spaceId': spaceId,
    if (lastSnippet != null) 'lastSnippet': lastSnippet,
    'messages': messages.map((m) => m.toJson()).toList(growable: false),
  };

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) =>
      ChatSessionModel(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Chat',
        model: json['model'] as String? ?? 'gemini-2.5-flash-lite',
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        messageCount: (json['messageCount'] as num?)?.toInt() ?? 0,
        spaceId: json['spaceId'] as String?,
        lastSnippet: json['lastSnippet'] as String?,
        messages: ((json['messages'] as List?) ?? const [])
            .map(
              (e) =>
                  ChatMessageModel.fromJson((e as Map).cast<String, dynamic>()),
            )
            .toList(growable: false),
      );
}

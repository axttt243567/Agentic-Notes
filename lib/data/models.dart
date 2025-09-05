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
  final String tone; // e.g., Chatty, Witty, Straight shooting, etc.
  final bool advancedContext; // when true, inject rich space context into chat
  final String metadataJson; // user-editable JSON driving space context
  final bool prefConcise; // prefer concise answers
  final bool prefExamples; // prefer examples
  final bool prefClarify; // ask clarifying questions when needed

  const SpaceModel({
    required this.id,
    required this.name,
    required this.emoji,
    this.description = '',
    this.goals = '',
    this.guide = '',
    this.tone = '',
    this.advancedContext = true,
    this.metadataJson = '',
    this.prefConcise = false,
    this.prefExamples = true,
    this.prefClarify = true,
  });

  SpaceModel copyWith({
    String? id,
    String? name,
    String? emoji,
    String? description,
    String? goals,
    String? guide,
    String? tone,
    bool? advancedContext,
    String? metadataJson,
    bool? prefConcise,
    bool? prefExamples,
    bool? prefClarify,
  }) => SpaceModel(
    id: id ?? this.id,
    name: name ?? this.name,
    emoji: emoji ?? this.emoji,
    description: description ?? this.description,
    goals: goals ?? this.goals,
    guide: guide ?? this.guide,
    tone: tone ?? this.tone,
    advancedContext: advancedContext ?? this.advancedContext,
    metadataJson: metadataJson ?? this.metadataJson,
    prefConcise: prefConcise ?? this.prefConcise,
    prefExamples: prefExamples ?? this.prefExamples,
    prefClarify: prefClarify ?? this.prefClarify,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    if (description.isNotEmpty) 'description': description,
    if (goals.isNotEmpty) 'goals': goals,
    if (guide.isNotEmpty) 'guide': guide,
    if (tone.isNotEmpty) 'tone': tone,
    'advancedContext': advancedContext,
    if (metadataJson.isNotEmpty) 'metadataJson': metadataJson,
    'prefConcise': prefConcise,
    'prefExamples': prefExamples,
    'prefClarify': prefClarify,
  };

  factory SpaceModel.fromJson(Map<String, dynamic> json) => SpaceModel(
    id: json['id'] as String,
    name: json['name'] as String,
    emoji: json['emoji'] as String? ?? '📚',
    description: json['description'] as String? ?? '',
    goals: json['goals'] as String? ?? '',
    guide: json['guide'] as String? ?? '',
    tone: json['tone'] as String? ?? '',
    advancedContext: (json['advancedContext'] as bool?) ?? true,
    metadataJson: json['metadataJson'] as String? ?? '',
    prefConcise: (json['prefConcise'] as bool?) ?? false,
    prefExamples: (json['prefExamples'] as bool?) ?? true,
    prefClarify: (json['prefClarify'] as bool?) ?? true,
  );
}

@immutable
class SpaceComboHistoryModel {
  final String spaceId; // unique per space
  final String content; // concatenated interactions text
  final DateTime updatedAt;

  const SpaceComboHistoryModel({
    required this.spaceId,
    required this.content,
    required this.updatedAt,
  });

  SpaceComboHistoryModel copyWith({String? content, DateTime? updatedAt}) =>
      SpaceComboHistoryModel(
        spaceId: spaceId,
        content: content ?? this.content,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
    'spaceId': spaceId,
    'content': content,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SpaceComboHistoryModel.fromJson(Map<String, dynamic> json) =>
      SpaceComboHistoryModel(
        spaceId: json['spaceId'] as String,
        content: json['content'] as String? ?? '',
        updatedAt:
            DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
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

@immutable
class MemoryItemModel {
  final String id; // unique
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MemoryItemModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  MemoryItemModel copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MemoryItemModel(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory MemoryItemModel.fromJson(Map<String, dynamic> json) =>
      MemoryItemModel(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

@immutable
class ChatAnalyticsModel {
  final String sessionId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSeconds;
  final int totalMessages;
  final int userRequestCount;
  final int modelResponseCount;
  final int userCharsTotal;
  final int modelCharsTotal;
  final int userTokensTotal; // estimated
  final int modelTokensTotal; // estimated
  final double avgModelTokensPerResponse;

  const ChatAnalyticsModel({
    required this.sessionId,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    required this.totalMessages,
    required this.userRequestCount,
    required this.modelResponseCount,
    required this.userCharsTotal,
    required this.modelCharsTotal,
    required this.userTokensTotal,
    required this.modelTokensTotal,
    required this.avgModelTokensPerResponse,
  });

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt.toIso8601String(),
    'durationSeconds': durationSeconds,
    'totalMessages': totalMessages,
    'userRequestCount': userRequestCount,
    'modelResponseCount': modelResponseCount,
    'userCharsTotal': userCharsTotal,
    'modelCharsTotal': modelCharsTotal,
    'userTokensTotal': userTokensTotal,
    'modelTokensTotal': modelTokensTotal,
    'avgModelTokensPerResponse': avgModelTokensPerResponse,
  };

  factory ChatAnalyticsModel.fromJson(Map<String, dynamic> json) =>
      ChatAnalyticsModel(
        sessionId: json['sessionId'] as String,
        startedAt:
            DateTime.tryParse(json['startedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        endedAt:
            DateTime.tryParse(json['endedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
        totalMessages: (json['totalMessages'] as num?)?.toInt() ?? 0,
        userRequestCount: (json['userRequestCount'] as num?)?.toInt() ?? 0,
        modelResponseCount: (json['modelResponseCount'] as num?)?.toInt() ?? 0,
        userCharsTotal: (json['userCharsTotal'] as num?)?.toInt() ?? 0,
        modelCharsTotal: (json['modelCharsTotal'] as num?)?.toInt() ?? 0,
        userTokensTotal: (json['userTokensTotal'] as num?)?.toInt() ?? 0,
        modelTokensTotal: (json['modelTokensTotal'] as num?)?.toInt() ?? 0,
        avgModelTokensPerResponse:
            (json['avgModelTokensPerResponse'] as num?)?.toDouble() ?? 0,
      );
}

@immutable
class SubMemoryPieceModel {
  final String id; // unique
  final String sessionId;
  final List<String> messageIds; // provenance
  final String title;
  final String content;
  final List<String> hashtags; // 10-20 ideally
  final String summary; // 1-3 sentences
  final DateTime createdAt;

  const SubMemoryPieceModel({
    required this.id,
    required this.sessionId,
    required this.messageIds,
    required this.title,
    required this.content,
    required this.hashtags,
    required this.summary,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'messageIds': messageIds,
    'title': title,
    'content': content,
    'hashtags': hashtags,
    'summary': summary,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SubMemoryPieceModel.fromJson(Map<String, dynamic> json) =>
      SubMemoryPieceModel(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        messageIds: ((json['messageIds'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(growable: false),
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        hashtags: ((json['hashtags'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(growable: false),
        summary: json['summary'] as String? ?? '',
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

@immutable
class CoreMemorySectionModel {
  final String id; // unique
  final String sessionId;
  final String title;
  final String summary;
  final List<String> hashtags; // core tags for the section
  final List<SubMemoryPieceModel> pieces; // grouped pieces
  final DateTime createdAt;
  final DateTime updatedAt;

  const CoreMemorySectionModel({
    required this.id,
    required this.sessionId,
    required this.title,
    required this.summary,
    required this.hashtags,
    required this.pieces,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'title': title,
    'summary': summary,
    'hashtags': hashtags,
    'pieces': pieces.map((e) => e.toJson()).toList(growable: false),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory CoreMemorySectionModel.fromJson(Map<String, dynamic> json) =>
      CoreMemorySectionModel(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        title: json['title'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        hashtags: ((json['hashtags'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(growable: false),
        pieces: ((json['pieces'] as List?) ?? const [])
            .map(
              (e) => SubMemoryPieceModel.fromJson(
                (e as Map).cast<String, dynamic>(),
              ),
            )
            .toList(growable: false),
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

@immutable
class MemoryIndexModel {
  final String sessionId; // owner session
  final DateTime generatedAt;
  final ChatAnalyticsModel analytics;
  final List<CoreMemorySectionModel> sections;
  final String? sessionSummary; // ~30 words
  final List<String>? sessionHashtags; // 10-20 like #word1_word2

  const MemoryIndexModel({
    required this.sessionId,
    required this.generatedAt,
    required this.analytics,
    required this.sections,
    this.sessionSummary,
    this.sessionHashtags,
  });

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'generatedAt': generatedAt.toIso8601String(),
    'analytics': analytics.toJson(),
    'sections': sections.map((s) => s.toJson()).toList(growable: false),
    if (sessionSummary != null) 'sessionSummary': sessionSummary,
    if (sessionHashtags != null) 'sessionHashtags': sessionHashtags,
  };

  factory MemoryIndexModel.fromJson(Map<String, dynamic> json) =>
      MemoryIndexModel(
        sessionId: json['sessionId'] as String,
        generatedAt:
            DateTime.tryParse(json['generatedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        analytics: ChatAnalyticsModel.fromJson(
          (json['analytics'] as Map).cast<String, dynamic>(),
        ),
        sections: ((json['sections'] as List?) ?? const [])
            .map(
              (e) => CoreMemorySectionModel.fromJson(
                (e as Map).cast<String, dynamic>(),
              ),
            )
            .toList(growable: false),
        sessionSummary: json['sessionSummary'] as String?,
        sessionHashtags: (json['sessionHashtags'] as List?)
            ?.map((e) => e.toString())
            .toList(),
      );
}

@immutable
class ScheduleModel {
  final String id; // unique
  final String title; // e.g., Subject name
  final String emoji; // visual marker
  final String? spaceId; // optional link to a space
  final String? categoryId; // optional link to a routine category
  final List<int> daysOfWeek; // 1=Mon ... 7=Sun
  final String? timeOfDay; // HH:mm (24h)
  final String? endTimeOfDay; // HH:mm (24h) optional end time
  final int? durationMinutes; // optional duration in minutes
  final String? room; // optional classroom identifier
  final DateTime createdAt;
  final DateTime updatedAt;

  const ScheduleModel({
    required this.id,
    required this.title,
    required this.emoji,
    this.spaceId,
    this.categoryId,
    required this.daysOfWeek,
    this.timeOfDay,
    this.endTimeOfDay,
    this.durationMinutes,
    this.room,
    required this.createdAt,
    required this.updatedAt,
  });

  ScheduleModel copyWith({
    String? id,
    String? title,
    String? emoji,
    String? spaceId,
    String? categoryId,
    List<int>? daysOfWeek,
    String? timeOfDay,
    String? endTimeOfDay,
    int? durationMinutes,
    String? room,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ScheduleModel(
    id: id ?? this.id,
    title: title ?? this.title,
    emoji: emoji ?? this.emoji,
    spaceId: spaceId ?? this.spaceId,
    categoryId: categoryId ?? this.categoryId,
    daysOfWeek: daysOfWeek ?? this.daysOfWeek,
    timeOfDay: timeOfDay ?? this.timeOfDay,
    endTimeOfDay: endTimeOfDay ?? this.endTimeOfDay,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    room: room ?? this.room,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'emoji': emoji,
    if (spaceId != null) 'spaceId': spaceId,
    if (categoryId != null) 'categoryId': categoryId,
    'daysOfWeek': daysOfWeek,
    if (timeOfDay != null) 'timeOfDay': timeOfDay,
    if (endTimeOfDay != null) 'endTimeOfDay': endTimeOfDay,
    if (durationMinutes != null) 'durationMinutes': durationMinutes,
    if (room != null) 'room': room,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ScheduleModel.fromJson(Map<String, dynamic> json) => ScheduleModel(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    emoji: json['emoji'] as String? ?? '📘',
    spaceId: json['spaceId'] as String?,
    categoryId: json['categoryId'] as String?,
    daysOfWeek: ((json['daysOfWeek'] as List?) ?? const [])
        .map((e) => (e as num).toInt())
        .toList(growable: false),
    timeOfDay: json['timeOfDay'] as String?,
    endTimeOfDay: json['endTimeOfDay'] as String?,
    durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
    room: json['room'] as String?,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt:
        DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}

@immutable
class RoutineCategoryModel {
  final String id; // unique
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RoutineCategoryModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  RoutineCategoryModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => RoutineCategoryModel(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory RoutineCategoryModel.fromJson(Map<String, dynamic> json) =>
      RoutineCategoryModel(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

@immutable
class AttendanceEntryModel {
  final String id; // unique: scheduleId|yyyy-MM-dd
  final String scheduleId;
  final String date; // yyyy-MM-dd
  final bool present; // true=Present, false=Absent
  final DateTime ts; // when marked

  const AttendanceEntryModel({
    required this.id,
    required this.scheduleId,
    required this.date,
    required this.present,
    required this.ts,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'scheduleId': scheduleId,
    'date': date,
    'present': present,
    'ts': ts.toIso8601String(),
  };

  factory AttendanceEntryModel.fromJson(Map<String, dynamic> json) =>
      AttendanceEntryModel(
        id: json['id'] as String,
        scheduleId: json['scheduleId'] as String,
        date: json['date'] as String,
        present: (json['present'] as bool?) ?? false,
        ts:
            DateTime.tryParse(json['ts'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

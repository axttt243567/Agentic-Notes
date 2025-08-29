import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import 'models.dart';

class DatabaseService {
  static const _boxProfile = 'profile_box';
  static const _boxApiKeys = 'api_keys_box';
  static const _boxSpaces = 'spaces_box';
  static const _boxStudents = 'students_box';
  static const _boxChatSessions = 'chat_sessions_box';
  static const _activeKeyField = 'active_api_key_id';
  static const _suggestLevelField =
      'suggest_level'; // 'less' | 'balanced' | 'more'
  static const _preferredModelField = 'preferred_model';

  late final Box _profile;
  late final Box _apiKeys;
  late final Box _spaces;
  late final Box _students;
  late final Box _chatSessions;

  final _profileCtrl = StreamController<UserProfileModel>.broadcast();
  final _apiKeysCtrl = StreamController<List<ApiKeyModel>>.broadcast();
  final _activeKeyCtrl = StreamController<String?>.broadcast();
  final _spacesCtrl = StreamController<List<SpaceModel>>.broadcast();
  final _suggestLevelCtrl = StreamController<String>.broadcast();
  final _preferredModelCtrl = StreamController<String>.broadcast();
  final _chatSessionsCtrl =
      StreamController<List<ChatSessionModel>>.broadcast();

  Stream<UserProfileModel> get profileStream => _profileCtrl.stream;
  Stream<List<ApiKeyModel>> get apiKeysStream => _apiKeysCtrl.stream;
  Stream<String?> get activeApiKeyStream => _activeKeyCtrl.stream;
  Stream<List<SpaceModel>> get spacesStream => _spacesCtrl.stream;
  Stream<String> get suggestLevelStream => _suggestLevelCtrl.stream;
  Stream<String> get preferredModelStream => _preferredModelCtrl.stream;
  Stream<List<ChatSessionModel>> get chatSessionsStream =>
      _chatSessionsCtrl.stream;

  UserProfileModel get currentProfile => _readProfile();
  List<ApiKeyModel> get currentApiKeys => _readApiKeys();
  String? get currentActiveApiKeyId => _readActiveApiKeyId();
  List<SpaceModel> get currentSpaces => _readSpaces();
  String get currentSuggestLevel => _readSuggestLevel();
  String get currentPreferredModel => _readPreferredModel();
  List<ChatSessionModel> get currentChatSessions => _readChatSessions();

  static Future<DatabaseService> init() async {
    await Hive.initFlutter();
    final svc = DatabaseService();
    svc._profile = await Hive.openBox(_boxProfile);
    svc._apiKeys = await Hive.openBox(_boxApiKeys);
    svc._spaces = await Hive.openBox(_boxSpaces);
    svc._students = await Hive.openBox(_boxStudents);
    svc._chatSessions = await Hive.openBox(_boxChatSessions);

    // Seed defaults if empty
    if (!svc._profile.containsKey('user')) {
      await svc._profile.put(
        'user',
        const UserProfileModel(displayName: 'You').toJson(),
      );
    }
    if (!svc._profile.containsKey(_suggestLevelField)) {
      await svc._profile.put(_suggestLevelField, 'balanced');
    }
    if (!svc._profile.containsKey(_preferredModelField)) {
      await svc._profile.put(_preferredModelField, 'gemini-2.5-flash-lite');
    }
    svc._emitAll();

    // Watch for changes and emit
    svc._profile.watch().listen((_) => svc._emitProfile());
    svc._apiKeys.watch().listen((_) => svc._emitApiKeys());
    svc._spaces.watch().listen((_) => svc._emitSpaces());
    svc._students.watch().listen((_) => svc._emitStudents());
    svc._chatSessions.watch().listen((_) => svc._emitChatSessions());
    svc._profile
        .watch(key: _activeKeyField)
        .listen((_) => svc._emitActiveKey());
    svc._profile
        .watch(key: _suggestLevelField)
        .listen((_) => svc._emitSuggestLevel());
    svc._profile
        .watch(key: _preferredModelField)
        .listen((_) => svc._emitPreferredModel());
    return svc;
  }

  void dispose() {
    _profileCtrl.close();
    _apiKeysCtrl.close();
    _activeKeyCtrl.close();
    _spacesCtrl.close();
    _suggestLevelCtrl.close();
    _preferredModelCtrl.close();
  }

  // Profile operations
  Future<void> setDisplayName(String name) async {
    final profile = _readProfile().copyWith(displayName: name);
    await _profile.put('user', profile.toJson());
    _emitProfile();
  }

  Future<void> setProfileDetails({
    String? section,
    String? group,
    int? semester,
    String? rollNo,
    String? branch,
  }) async {
    final profile = _readProfile().copyWith(
      section: section,
      group: group,
      semester: semester,
      rollNo: rollNo,
      branch: branch,
    );
    await _profile.put('user', profile.toJson());
    _emitProfile();
  }

  // API key operations
  Future<void> upsertApiKey(ApiKeyModel key) async {
    await _apiKeys.put(key.id, key.toJson());
    _emitApiKeys();
  }

  Future<void> deleteApiKey(String id) async {
    await _apiKeys.delete(id);
    // If the deleted key was active, clear active
    if (_readActiveApiKeyId() == id) {
      await _profile.delete(_activeKeyField);
      _emitActiveKey();
    }
    _emitApiKeys();
  }

  Future<void> setActiveApiKeyId(String id) async {
    await _profile.put(_activeKeyField, id);
    _emitActiveKey();
  }

  Future<void> clearActiveApiKey() async {
    await _profile.delete(_activeKeyField);
    _emitActiveKey();
  }

  // Suggestion level operations
  Future<void> setSuggestLevel(String level) async {
    await _profile.put(_suggestLevelField, level);
    _emitSuggestLevel();
  }

  // Preferred model operations
  Future<void> setPreferredModel(String model) async {
    await _profile.put(_preferredModelField, model);
    _emitPreferredModel();
  }

  // Spaces operations
  Future<void> upsertSpace(SpaceModel space) async {
    await _spaces.put(space.id, space.toJson());
    _emitSpaces();
  }

  Future<void> deleteSpace(String id) async {
    await _spaces.delete(id);
    _emitSpaces();
  }

  // Students operations
  Future<void> upsertStudentsBulk(List<StudentModel> students) async {
    if (students.isEmpty) return;
    final Map<String, Map<String, dynamic>> entries = {
      for (final s in students) s.rollNo: s.toJson(),
    };
    await _students.putAll(entries);
    _emitStudents();
  }

  // Chat sessions operations
  Future<void> upsertChatSession(ChatSessionModel session) async {
    await _chatSessions.put(session.id, session.toJson());
    _emitChatSessions();
  }

  Future<void> deleteChatSession(String id) async {
    await _chatSessions.delete(id);
    _emitChatSessions();
  }

  ChatSessionModel? getChatSession(String id) {
    final json = _chatSessions.get(id) as Map?;
    if (json == null) return null;
    return ChatSessionModel.fromJson(json.cast<String, dynamic>());
  }

  Future<void> upsertStudent(StudentModel student) async {
    await _students.put(student.rollNo, student.toJson());
    _emitStudents();
  }

  List<StudentModel> queryStudentsByNamePrefix(
    String prefix, {
    int limit = 10,
  }) {
    final lq = prefix.toLowerCase();
    if (lq.isEmpty) return const [];
    final results = <StudentModel>[];
    for (final key in _students.keys) {
      final json = (_students.get(key) as Map).cast<String, dynamic>();
      final s = StudentModel.fromJson(json);
      if (s.name.toLowerCase().startsWith(lq)) {
        results.add(s);
        if (results.length >= limit) break;
      }
    }
    return results;
  }

  List<StudentModel> queryStudentsByRollPrefix(
    String prefix, {
    int limit = 10,
  }) {
    final lq = prefix.toLowerCase();
    if (lq.isEmpty) return const [];
    final results = <StudentModel>[];
    for (final key in _students.keys) {
      final json = (_students.get(key) as Map).cast<String, dynamic>();
      final s = StudentModel.fromJson(json);
      if (s.rollNo.toLowerCase().startsWith(lq)) {
        results.add(s);
        if (results.length >= limit) break;
      }
    }
    return results;
  }

  StudentModel? findStudentByExact(String query) {
    final q = query.trim();
    if (q.isEmpty) return null;
    final lq = q.toLowerCase();
    // Try key by roll first for O(1)
    final byRoll = _students.get(q);
    if (byRoll != null) {
      return StudentModel.fromJson((byRoll as Map).cast<String, dynamic>());
    }
    for (final key in _students.keys) {
      final json = (_students.get(key) as Map).cast<String, dynamic>();
      final s = StudentModel.fromJson(json);
      if (s.name.toLowerCase() == lq) return s;
      if (s.rollNo.toLowerCase() == lq) return s;
    }
    return null;
  }

  // Reads
  UserProfileModel _readProfile() {
    final json = (_profile.get('user') as Map?)?.cast<String, dynamic>();
    return json == null
        ? const UserProfileModel(displayName: 'You')
        : UserProfileModel.fromJson(json);
  }

  List<ApiKeyModel> _readApiKeys() {
    return _apiKeys.keys
        .map((k) {
          final json = (_apiKeys.get(k) as Map).cast<String, dynamic>();
          return ApiKeyModel.fromJson(json);
        })
        .toList(growable: false);
  }

  String? _readActiveApiKeyId() {
    final v = _profile.get(_activeKeyField);
    return v == null ? null : v as String;
  }

  List<SpaceModel> _readSpaces() {
    return _spaces.keys
        .map((k) {
          final json = (_spaces.get(k) as Map).cast<String, dynamic>();
          return SpaceModel.fromJson(json);
        })
        .toList(growable: false);
  }

  String _readSuggestLevel() {
    final v = _profile.get(_suggestLevelField) as String?;
    return v ?? 'balanced';
  }

  String _readPreferredModel() {
    final v = _profile.get(_preferredModelField) as String?;
    return v ?? 'gemini-2.5-flash-lite';
  }

  List<ChatSessionModel> _readChatSessions() {
    final items = <ChatSessionModel>[];
    for (final k in _chatSessions.keys) {
      final json = (_chatSessions.get(k) as Map).cast<String, dynamic>();
      items.add(ChatSessionModel.fromJson(json));
    }
    // sort by updatedAt desc
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  void _emitAll() {
    _emitProfile();
    _emitApiKeys();
    _emitActiveKey();
    _emitSpaces();
    _emitSuggestLevel();
  }

  void _emitProfile() => _profileCtrl.add(_readProfile());
  void _emitApiKeys() => _apiKeysCtrl.add(_readApiKeys());
  void _emitActiveKey() => _activeKeyCtrl.add(_readActiveApiKeyId());
  void _emitSpaces() => _spacesCtrl.add(_readSpaces());
  void _emitSuggestLevel() => _suggestLevelCtrl.add(_readSuggestLevel());
  void _emitPreferredModel() => _preferredModelCtrl.add(_readPreferredModel());
  void _emitStudents() {
    /* no external stream yet */
  }
  void _emitChatSessions() => _chatSessionsCtrl.add(_readChatSessions());

  /// Danger zone: wipes all persisted app data and re-seeds minimal defaults.
  /// This clears profile, API keys, spaces, students, and chat sessions.
  /// After completion, streams are emitted with the fresh state.
  Future<void> wipeAllData() async {
    await Future.wait([
      _profile.clear(),
      _apiKeys.clear(),
      _spaces.clear(),
      _students.clear(),
      _chatSessions.clear(),
    ]);

    // Re-seed minimal defaults expected by the UI
    await _profile.put(
      'user',
      const UserProfileModel(displayName: 'You').toJson(),
    );
    await _profile.put(_suggestLevelField, 'balanced');
    await _profile.put(_preferredModelField, 'gemini-2.5-flash-lite');

    _emitAll();
    _emitChatSessions();
  }
}

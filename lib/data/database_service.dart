import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import 'models.dart';

class DatabaseService {
  static const _boxProfile = 'profile_box';
  static const _boxApiKeys = 'api_keys_box';
  static const _boxSpaces = 'spaces_box';
  static const _boxStudents = 'students_box';
  static const _boxChatSessions = 'chat_sessions_box';
  static const _boxMemories = 'memories_box';
  static const _boxMemoryIndex = 'memory_index_box';
  static const _boxSchedules = 'schedules_box';
  static const _boxAttendance = 'attendance_box';
  static const _boxRoutineCategories = 'routine_categories_box';
  static const _boxSpaceComboHistory = 'space_combo_history_box';
  static const _activeKeyField = 'active_api_key_id';
  static const _suggestLevelField =
      'suggest_level'; // 'less' | 'balanced' | 'more'
  static const _preferredModelField = 'preferred_model';
  static const _pexelsApiKeyField = 'pexels_api_key';

  late final Box _profile;
  late final Box _apiKeys;
  late final Box _spaces;
  late final Box _students;
  late final Box _chatSessions;
  late final Box _memories;
  late final Box _memoryIndex;
  late final Box _schedules;
  late final Box _attendance;
  late final Box _routineCategories;
  late final Box _spaceComboHistory;

  final _profileCtrl = StreamController<UserProfileModel>.broadcast();
  final _apiKeysCtrl = StreamController<List<ApiKeyModel>>.broadcast();
  final _activeKeyCtrl = StreamController<String?>.broadcast();
  final _spacesCtrl = StreamController<List<SpaceModel>>.broadcast();
  final _suggestLevelCtrl = StreamController<String>.broadcast();
  final _preferredModelCtrl = StreamController<String>.broadcast();
  final _pexelsKeyCtrl = StreamController<String?>.broadcast();
  final _chatSessionsCtrl =
      StreamController<List<ChatSessionModel>>.broadcast();
  final _memoriesCtrl = StreamController<List<MemoryItemModel>>.broadcast();
  final _memoryIndexCtrl =
      StreamController<Map<String, MemoryIndexModel>>.broadcast();
  final _schedulesCtrl = StreamController<List<ScheduleModel>>.broadcast();
  final _attendanceCtrl =
      StreamController<Map<String, AttendanceEntryModel>>.broadcast();
  final _routineCategoriesCtrl =
      StreamController<List<RoutineCategoryModel>>.broadcast();
  final _spaceComboHistoryCtrl =
      StreamController<Map<String, SpaceComboHistoryModel>>.broadcast();

  Stream<UserProfileModel> get profileStream => _profileCtrl.stream;
  Stream<List<ApiKeyModel>> get apiKeysStream => _apiKeysCtrl.stream;
  Stream<String?> get activeApiKeyStream => _activeKeyCtrl.stream;
  Stream<List<SpaceModel>> get spacesStream => _spacesCtrl.stream;
  Stream<String> get suggestLevelStream => _suggestLevelCtrl.stream;
  Stream<String> get preferredModelStream => _preferredModelCtrl.stream;
  Stream<String?> get pexelsApiKeyStream => _pexelsKeyCtrl.stream;
  Stream<List<ChatSessionModel>> get chatSessionsStream =>
      _chatSessionsCtrl.stream;
  Stream<List<MemoryItemModel>> get memoriesStream => _memoriesCtrl.stream;
  Stream<Map<String, MemoryIndexModel>> get memoryIndexStream =>
      _memoryIndexCtrl.stream;
  Stream<List<ScheduleModel>> get schedulesStream => _schedulesCtrl.stream;
  Stream<Map<String, AttendanceEntryModel>> get attendanceStream =>
      _attendanceCtrl.stream;
  Stream<List<RoutineCategoryModel>> get routineCategoriesStream =>
      _routineCategoriesCtrl.stream;

  UserProfileModel get currentProfile => _readProfile();
  List<ApiKeyModel> get currentApiKeys => _readApiKeys();
  String? get currentActiveApiKeyId => _readActiveApiKeyId();
  List<SpaceModel> get currentSpaces => _readSpaces();
  String get currentSuggestLevel => _readSuggestLevel();
  String get currentPreferredModel => _readPreferredModel();
  String? get currentPexelsApiKey => _readPexelsApiKey();
  List<ChatSessionModel> get currentChatSessions => _readChatSessions();
  List<MemoryItemModel> get currentMemories => _readMemories();
  Map<String, MemoryIndexModel> get currentMemoryIndex => _readMemoryIndex();
  List<ScheduleModel> get currentSchedules => _readSchedules();
  Map<String, AttendanceEntryModel> get currentAttendance => _readAttendance();
  List<RoutineCategoryModel> get currentRoutineCategories =>
      _readRoutineCategories();
  Map<String, SpaceComboHistoryModel> get currentSpaceComboHistory =>
      _readSpaceComboHistory();
  Stream<Map<String, SpaceComboHistoryModel>> get spaceComboHistoryStream =>
      _spaceComboHistoryCtrl.stream;

  static Future<DatabaseService> init() async {
    await Hive.initFlutter();
    final svc = DatabaseService();
    svc._profile = await Hive.openBox(_boxProfile);
    svc._apiKeys = await Hive.openBox(_boxApiKeys);
    svc._spaces = await Hive.openBox(_boxSpaces);
    svc._students = await Hive.openBox(_boxStudents);
    svc._chatSessions = await Hive.openBox(_boxChatSessions);
    svc._memories = await Hive.openBox(_boxMemories);
    svc._memoryIndex = await Hive.openBox(_boxMemoryIndex);
    svc._schedules = await Hive.openBox(_boxSchedules);
    svc._attendance = await Hive.openBox(_boxAttendance);
    svc._routineCategories = await Hive.openBox(_boxRoutineCategories);
    svc._spaceComboHistory = await Hive.openBox(_boxSpaceComboHistory);

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
    // Do not seed pexels key; user provided
    svc._emitAll();

    // Watch for changes and emit
    svc._profile.watch().listen((_) => svc._emitProfile());
    svc._apiKeys.watch().listen((_) => svc._emitApiKeys());
    svc._spaces.watch().listen((_) => svc._emitSpaces());
    svc._students.watch().listen((_) => svc._emitStudents());
    svc._chatSessions.watch().listen((_) => svc._emitChatSessions());
    svc._memories.watch().listen((_) => svc._emitMemories());
    svc._memoryIndex.watch().listen((_) => svc._emitMemoryIndex());
    svc._schedules.watch().listen((_) => svc._emitSchedules());
    svc._attendance.watch().listen((_) => svc._emitAttendance());
    svc._routineCategories.watch().listen((_) => svc._emitRoutineCategories());
    svc._spaceComboHistory.watch().listen((_) => svc._emitSpaceComboHistory());
    svc._profile
        .watch(key: _activeKeyField)
        .listen((_) => svc._emitActiveKey());
    svc._profile
        .watch(key: _suggestLevelField)
        .listen((_) => svc._emitSuggestLevel());
    svc._profile
        .watch(key: _preferredModelField)
        .listen((_) => svc._emitPreferredModel());
    svc._profile
        .watch(key: _pexelsApiKeyField)
        .listen((_) => svc._emitPexelsKey());
    return svc;
  }

  void dispose() {
    _profileCtrl.close();
    _apiKeysCtrl.close();
    _activeKeyCtrl.close();
    _spacesCtrl.close();
    _suggestLevelCtrl.close();
    _preferredModelCtrl.close();
    _pexelsKeyCtrl.close();
    _schedulesCtrl.close();
    _attendanceCtrl.close();
    _routineCategoriesCtrl.close();
    _spaceComboHistoryCtrl.close();
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

  // Pexels API key operations
  Future<void> setPexelsApiKey(String? key) async {
    if (key == null || key.trim().isEmpty) {
      await _profile.delete(_pexelsApiKeyField);
    } else {
      await _profile.put(_pexelsApiKeyField, key.trim());
    }
    _emitPexelsKey();
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

  // Memories operations
  Future<void> upsertMemory(MemoryItemModel memory) async {
    await _memories.put(memory.id, memory.toJson());
    _emitMemories();
  }

  Future<void> deleteMemory(String id) async {
    await _memories.delete(id);
    _emitMemories();
  }

  // Memory index per session
  Future<void> upsertMemoryIndex(MemoryIndexModel idx) async {
    await _memoryIndex.put(idx.sessionId, idx.toJson());
    _emitMemoryIndex();
  }

  MemoryIndexModel? getMemoryIndex(String sessionId) {
    final json = _memoryIndex.get(sessionId) as Map?;
    if (json == null) return null;
    return MemoryIndexModel.fromJson(json.cast<String, dynamic>());
  }

  // Schedules operations
  Future<void> upsertSchedule(ScheduleModel schedule) async {
    await _schedules.put(schedule.id, schedule.toJson());
    _emitSchedules();
  }

  Future<void> deleteSchedule(String id) async {
    await _schedules.delete(id);
    _emitSchedules();
  }

  // Attendance operations
  Future<void> upsertAttendance(AttendanceEntryModel entry) async {
    await _attendance.put(entry.id, entry.toJson());
    _emitAttendance();
  }

  AttendanceEntryModel? getAttendanceById(String id) {
    final json = _attendance.get(id) as Map?;
    if (json == null) return null;
    return AttendanceEntryModel.fromJson(json.cast<String, dynamic>());
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

  String? _readPexelsApiKey() {
    final v = _profile.get(_pexelsApiKeyField) as String?;
    return v;
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

  List<ChatSessionModel> getChatSessionsBySpace(String spaceId) {
    return _readChatSessions().where((s) => s.spaceId == spaceId).toList();
  }

  List<MemoryItemModel> _readMemories() {
    final items = <MemoryItemModel>[];
    for (final k in _memories.keys) {
      final json = (_memories.get(k) as Map).cast<String, dynamic>();
      items.add(MemoryItemModel.fromJson(json));
    }
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  // Space combo history operations
  Future<void> upsertSpaceComboHistory(SpaceComboHistoryModel item) async {
    await _spaceComboHistory.put(item.spaceId, item.toJson());
    _emitSpaceComboHistory();
  }

  SpaceComboHistoryModel? getSpaceComboHistory(String spaceId) {
    final json = (_spaceComboHistory.get(spaceId) as Map?)
        ?.cast<String, dynamic>();
    if (json == null) return null;
    return SpaceComboHistoryModel.fromJson(json);
  }

  /// Rebuilds the combined chat history text for a given space by
  /// concatenating all messages from sessions linked to that space.
  Future<void> rebuildSpaceComboHistory(String spaceId) async {
    final sessions =
        _readChatSessions().where((s) => s.spaceId == spaceId).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final buf = StringBuffer();
    for (final s in sessions) {
      if (s.messages.isEmpty) continue;
      buf.writeln('# ${s.title.isEmpty ? 'Chat' : s.title}');
      for (final m in s.messages) {
        final t = (m.text).trim();
        if (t.isEmpty) continue;
        final role = m.role == 'user' ? 'User' : 'Assistant';
        buf.writeln('$role: $t');
      }
      buf.writeln();
    }
    final content = buf.toString().trim();
    final now = DateTime.now();
    final model = SpaceComboHistoryModel(
      spaceId: spaceId,
      content: content,
      updatedAt: now,
    );
    await upsertSpaceComboHistory(model);
  }

  Map<String, MemoryIndexModel> _readMemoryIndex() {
    final map = <String, MemoryIndexModel>{};
    for (final k in _memoryIndex.keys) {
      final json = (_memoryIndex.get(k) as Map).cast<String, dynamic>();
      final m = MemoryIndexModel.fromJson(json);
      map[m.sessionId] = m;
    }
    return map;
  }

  Map<String, SpaceComboHistoryModel> _readSpaceComboHistory() {
    final map = <String, SpaceComboHistoryModel>{};
    for (final k in _spaceComboHistory.keys) {
      final json = (_spaceComboHistory.get(k) as Map).cast<String, dynamic>();
      final m = SpaceComboHistoryModel.fromJson(json);
      map[m.spaceId] = m;
    }
    return map;
  }

  // Routine categories operations
  Future<void> upsertRoutineCategory(RoutineCategoryModel category) async {
    await _routineCategories.put(category.id, category.toJson());
    _emitRoutineCategories();
  }

  Future<void> deleteRoutineCategory(String id) async {
    await _routineCategories.delete(id);
    _emitRoutineCategories();
  }

  List<ScheduleModel> _readSchedules() {
    final items = <ScheduleModel>[];
    for (final k in _schedules.keys) {
      final json = (_schedules.get(k) as Map).cast<String, dynamic>();
      items.add(ScheduleModel.fromJson(json));
    }
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  Map<String, AttendanceEntryModel> _readAttendance() {
    final map = <String, AttendanceEntryModel>{};
    for (final k in _attendance.keys) {
      final json = (_attendance.get(k) as Map).cast<String, dynamic>();
      final m = AttendanceEntryModel.fromJson(json);
      map[m.id] = m;
    }
    return map;
  }

  List<RoutineCategoryModel> _readRoutineCategories() {
    final items = <RoutineCategoryModel>[];
    for (final k in _routineCategories.keys) {
      final json = (_routineCategories.get(k) as Map).cast<String, dynamic>();
      items.add(RoutineCategoryModel.fromJson(json));
    }
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
  void _emitPexelsKey() => _pexelsKeyCtrl.add(_readPexelsApiKey());
  void _emitStudents() {
    /* no external stream yet */
  }
  void _emitChatSessions() => _chatSessionsCtrl.add(_readChatSessions());
  void _emitMemories() => _memoriesCtrl.add(_readMemories());
  void _emitMemoryIndex() => _memoryIndexCtrl.add(_readMemoryIndex());
  void _emitSchedules() => _schedulesCtrl.add(_readSchedules());
  void _emitAttendance() => _attendanceCtrl.add(_readAttendance());
  void _emitRoutineCategories() =>
      _routineCategoriesCtrl.add(_readRoutineCategories());
  void _emitSpaceComboHistory() =>
      _spaceComboHistoryCtrl.add(_readSpaceComboHistory());

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
      _memories.clear(),
      _memoryIndex.clear(),
      _schedules.clear(),
      _attendance.clear(),
      _routineCategories.clear(),
      _spaceComboHistory.clear(),
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
    _emitMemories();
    _emitMemoryIndex();
    _emitSchedules();
    _emitAttendance();
    _emitRoutineCategories();
    _emitSpaceComboHistory();
  }
}

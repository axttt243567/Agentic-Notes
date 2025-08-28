import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'onboarding.dart';
import 'data/database_service.dart';
import 'data/chat_service.dart';
import 'data/models.dart';
import 'data/student_suggestions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await DatabaseService.init();
  // Seed students (one-time) from kStudentSuggestions if students box is empty
  // We infer emptiness by checking a quick roll key that should exist if seeded.
  // We don't expose box size; perform a cheap guess: attempt to find known roll
  final probe = db.findStudentByExact('24BTAML01');
  if (probe == null) {
    final List<StudentModel> toSeed = kStudentSuggestions
        .map(
          (s) => StudentModel(
            rollNo: s.rollNo,
            name: s.name,
            section: s.section ?? 'Section-A',
            group: s.group,
          ),
        )
        .toList(growable: false);
    await db.upsertStudentsBulk(toSeed);
  }
  final chat = ChatService(db);
  runApp(
    DBProvider(
      database: db,
      child: ChatProvider(chat: chat, child: const MyApp()),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agentic Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        canvasColor: const Color(0xFF000000),
        cardColor: const Color(0xFF0A0A0A),
        dividerColor: const Color(0xFF2F3336),
        colorScheme: const ColorScheme.dark(
          // Twitter/X palette
          primary: Color(0xFF1D9BF0),
          secondary: Color(0xFF1D9BF0),
          surface: Color(0xFF000000),
          surfaceContainerHighest: Color(0xFF0A0A0A),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFFE7E9EA),
          outline: Color(0xFF2F3336),
          outlineVariant: Color(0xFF2F3336),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF000000),
          foregroundColor: Color(0xFFE7E9EA),
          elevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        iconTheme: const IconThemeData(color: Color(0xFFE7E9EA)),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF0A0A0A),
          side: const BorderSide(color: Color(0xFF2F3336)),
          shape: const StadiumBorder(),
          labelStyle: const TextStyle(color: Color(0xFFE7E9EA)),
          selectedColor: Color(0xFF1D9BF0).withValues(alpha: 0.18),
          secondarySelectedColor: Color(0xFF1D9BF0).withValues(alpha: 0.18),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: false,
          hintStyle: const TextStyle(color: Color(0xFF71767B)),
          labelStyle: const TextStyle(color: Color(0xFF71767B)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2F3336)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1D9BF0), width: 1.5),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF1D9BF0),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFE7E9EA)),
          bodySmall: TextStyle(color: Color(0xFF71767B)),
        ),
      ),
      themeMode: ThemeMode.dark,
      home: const OnboardingFlow(),
    );
  }
}

class DBProvider extends InheritedWidget {
  final DatabaseService database;
  const DBProvider({super.key, required this.database, required super.child});

  static DatabaseService of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DBProvider>()!.database;

  @override
  bool updateShouldNotify(covariant DBProvider oldWidget) =>
      oldWidget.database != database;
}

class ChatProvider extends InheritedWidget {
  final ChatService chat;
  const ChatProvider({super.key, required this.chat, required super.child});

  static ChatService of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChatProvider>()!.chat;

  @override
  bool updateShouldNotify(covariant ChatProvider oldWidget) =>
      oldWidget.chat != chat;
}

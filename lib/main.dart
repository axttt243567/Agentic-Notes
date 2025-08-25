import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'onboarding.dart';
import 'data/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await DatabaseService.init();
  runApp(DBProvider(database: db, child: const MyApp()));
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
        scaffoldBackgroundColor: Colors.black,
        canvasColor: Colors.black,
        cardColor: Colors.black,
        dividerColor: Colors.white12,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Color(0xFF2A2A2A),
          surface: Colors.black,
          onPrimary: Colors.black,
          onSecondary: Colors.white,
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF111111),
          foregroundColor: Colors.white,
          elevation: 0,
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

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'api.dart';
import 'theme.dart';
import 'screens/auth.dart';
import 'screens/student.dart';
import 'screens/teacher.dart';
import 'screens/admin.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Session.i.restore();
  runApp(const TafraApp());
}

class TafraApp extends StatelessWidget {
  const TafraApp({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: Session.i,
      builder: (_, __) => MaterialApp(
            title: 'طفرة التعليمية',
            debugShowCheckedModeBanner: false,
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
            theme: buildTheme(false), darkTheme: buildTheme(true), themeMode: ThemeMode.system,
            builder: (c, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
            home: Session.i.user == null ? const AuthScreen()
                : switch (Session.i.role) { 'admin' => const AdminHome(), 'teacher' => const TeacherHome(), _ => const StudentShell() },
          ));
}

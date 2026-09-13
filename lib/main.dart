import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:todo_app/pages/splash_page.dart';
import 'package:todo_app/pages/login_page.dart';
import 'package:todo_app/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  await Hive.openBox("MyBox");

  // Initialize notification service
  await NotificationService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    var box = Hive.box('MyBox');
    var profile = box.get("PROFILEDATA");
    bool isRegistered = profile != null && profile["isRegistered"] == true;

    return MaterialApp(
      title: 'Sorted',
      debugShowCheckedModeBanner: false,
      home: isRegistered ? const splashPage() : const LoginPage(),
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4B483),
          brightness: Brightness.dark,
          primary: const Color(0xFFD4B483),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
      ),
    );
  }
}

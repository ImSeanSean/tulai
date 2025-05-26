import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tulai/screens/home_page.dart';
import 'package:tulai/screens/landing_page.dart';
import 'package:tulai/screens/student/enrollment_page.dart';

Future<void> main() async {
  //Initialize Supabase
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ALS Enrollment System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        primaryColor: const Color(0xff0C15A6),
        secondaryHeaderColor: const Color(0xff40AD5F),
        splashColor: const Color(0xffD00C0C),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPage(),
        '/homepage': (context) => const HomePage(),
        '/enrollment': (context) => const EnrollmentPage(),
      },
    );
  }
}

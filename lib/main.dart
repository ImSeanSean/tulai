import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tulai/screens/home_page.dart';
import 'package:tulai/screens/landing_page.dart';
import 'package:tulai/screens/student/enrollment_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  //Initialize Supabase
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
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
        splashColor: const Color.fromARGB(255, 5, 175, 53),
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

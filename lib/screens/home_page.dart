import 'package:flutter/material.dart';
import 'package:tulai/screens/teacher/enrollees.dart';
import 'package:tulai/screens/teacher/settings.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  final List<NavigationDestination> destinations = const [
    NavigationDestination(
      icon: Icon(Icons.people),
      label: 'Enrollees',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  Widget _getBody() {
    switch (selectedIndex) {
      case 0:
        return Enrollees(
          key: UniqueKey(),
        );
      case 1:
        return TeacherSettings(
          key: UniqueKey(),
        );
      default:
        return const Center(child: Text('Welcome'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(1.0),
          child: Image.asset(
            'assets/images/deped-logo.png',
            fit: BoxFit.contain,
          ),
        ),
        title: Text(
          'ALS Enrollment System',
          style: TextStyle(
            color: Theme.of(context).splashColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/images/als-logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      body: _getBody(), // Dynamically switch body
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: WidgetStateProperty.all(
            const IconThemeData(
              color: Colors.white,
            ),
          ),
        ),
        child: NavigationBar(
          indicatorColor: const Color.fromARGB(255, 19, 43, 93),
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.75),
          destinations: destinations,
          selectedIndex: selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              selectedIndex = index;
            });
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tulai/core/app_config.dart';

class TeacherSettings extends StatelessWidget {
  const TeacherSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              width: double.infinity,
              color: Colors.grey.withOpacity(0.7),
              child: const Text(
                "Settings",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18),
              ),
            ),
            Container(
              height: 1,
              width: double.infinity,
              color: Colors.blueGrey.withOpacity(0.4),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 20),
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.blue),
                    title: const Text('Logout'),
                    onTap: () => {
                      AppConfig().userType = UserType.none,
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (route) => false,
                      ),
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

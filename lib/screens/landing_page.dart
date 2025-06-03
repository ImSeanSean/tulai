import 'package:flutter/material.dart';
import 'package:tulai/core/app_config.dart';
import 'package:tulai/widgets/button.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(
              height: 200,
              child: Image(image: AssetImage('assets/images/als-logo.png')),
            ),
            Text(
              'Welcome',
              style: TextStyle(
                  fontSize: 30,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Button(
                  label: 'I am a Student',
                  backgroundColor: Theme.of(context).primaryColor,
                  onPressed: () {
                    AppConfig().userType = UserType.student;
                    Navigator.pushNamed(context, '/enrollment');
                  },
                ),
                const SizedBox(width: 20),
                Button(
                  label: 'I am a Teacher',
                  backgroundColor: Theme.of(context).secondaryHeaderColor,
                  onPressed: () {
                    AppConfig().userType = UserType.teacher;
                    Navigator.pushNamed(context, '/homepage');
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

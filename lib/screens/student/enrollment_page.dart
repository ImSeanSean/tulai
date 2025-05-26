import 'package:flutter/material.dart';
import 'package:tulai/core/app_config.dart';
import 'package:tulai/screens/student/enrollment_question.dart';

class EnrollmentPage extends StatefulWidget {
  const EnrollmentPage({super.key});

  @override
  State<EnrollmentPage> createState() => _EnrollmentPageState();
}

class _EnrollmentPageState extends State<EnrollmentPage> {
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff40AD5F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () {
                      AppConfig().formLanguage = FormLanguage.english;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EnrollmentQuestions(),
                        ),
                      );
                    },
                    child: const Text(
                      'English',
                      style: TextStyle(color: Colors.white, fontSize: 17),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff40AD5F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () {
                      AppConfig().formLanguage = FormLanguage.filipino;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EnrollmentQuestions(),
                        ),
                      );
                    },
                    child: const Text(
                      'Filipino o Tagalog',
                      style: TextStyle(color: Colors.white, fontSize: 17),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tulai/core/app_config.dart';
import 'package:tulai/screens/student/enrollment_question.dart';
import 'package:tulai/widgets/appbar.dart';

class EnrollmentPage extends StatefulWidget {
  const EnrollmentPage({super.key});

  @override
  State<EnrollmentPage> createState() => _EnrollmentPageState();
}

class _EnrollmentPageState extends State<EnrollmentPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // optional padding from edges
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // align all children left horizontally
          children: [
            IconButton(
              iconSize: 30,
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.23,
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 400,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff2241A0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 20),
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
                        style: TextStyle(color: Colors.white, fontSize: 25),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: 400,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff40AD5F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 20),
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
                        style: TextStyle(color: Colors.white, fontSize: 25),
                      ),
                    ),
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

import 'package:flutter/material.dart';
import 'package:tulai/core/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tulai/screens/student/enrollment_review.dart';

class EnrollmentQuestions extends StatefulWidget {
  const EnrollmentQuestions({super.key});

  @override
  State<EnrollmentQuestions> createState() => _EnrollmentQuestionsState();
}

class _EnrollmentQuestionsState extends State<EnrollmentQuestions> {
  late final List<String> allQuestions;
  int _currentQuestionIndex = 0;
  final Map<String, String> answers = {};

  @override
  void initState() {
    super.initState();
    allQuestions = [
      ...formQuestionsName,
      ...formQuestionsAddress,
      ...formQuestionsOthers,
      ...formQuestionsFatherGuardian,
      ...formQuestionsMotherGuardian,
      ...formQuestionsEducationalInfo,
    ];
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < allQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _onAnswerChanged(String value) {
    final question = allQuestions[_currentQuestionIndex];
    answers[question] = value;
  }

  String _getCurrentSectionTitle() {
    final q = allQuestions[_currentQuestionIndex];
    if (formQuestionsName.contains(q)) return 'Name';
    if (formQuestionsAddress.contains(q)) return 'Address';
    if (formQuestionsOthers.contains(q)) return 'Other Info';
    if (formQuestionsFatherGuardian.contains(q)) return 'Father/Guardian';
    if (formQuestionsMotherGuardian.contains(q)) return 'Mother/Guardian';
    if (formQuestionsEducationalInfo.contains(q)) return 'Educational Info';
    return 'Enrollment';
  }

  Future<void> insertStudent() async {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase.from('student').insert([
        {
          'last_name': answers['Last Name'],
          'first_name': answers['First Name'],
          'middle_name': answers['Middle Name'],
          'name_extension': answers['Name Extension'],
          'house_street': answers['House No./Street/Sitio'],
          'barangay': answers['Barangay'],
          'municipality': answers['Municipality/City'],
          'province': answers['Province'],
          'birthdate': answers['Birthdate (mm/dd/yyyy)'],
          'sex': answers['Sex (Male/Female)'],
          'place_of_birth': answers['Place of Birth (Municipality/City)'],
          'civil_status': answers[
              'Civil Status (Single, Married, Separated, Widower, Solo Parent)'],
          'religion': answers['Religion'],
          'ip_group': answers['IP (Specify ethnic group):'],
          'mother_tongue': answers['Mother Tongue'],
          'contact_number': answers['Contact Number/s'],
          'pwd': answers['PWD (Yes/No)'],
          'father_last_name': answers['Father/Guardian Last Name'],
          'father_first_name': answers['Father/Guardian First Name'],
          'father_middle_name': answers['Father/Guardian Middle Name'],
          'father_occupation': answers['Father/Guardian Occupation'],
          'mother_last_name': answers['Mother/Guardian Last Name'],
          'mother_first_name': answers['Mother/Guardian First Name'],
          'mother_middle_name': answers['Mother/Guardian Middle Name'],
          'mother_occupation': answers['Mother/Guardian Occupation'],
          'last_school_attended': answers['Last School Attended'],
          'last_grade_level': answers['Last grade level completed'],
          'reason_no_schooling':
              answers['Why did you not attend/complete schooling?'],
          'attended_als': answers[
              'Have you attended ALS learning sessions before? (Yes/No)'],
        }
      ]);

      if (response != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student information submitted!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = allQuestions[_currentQuestionIndex];
    final currentAnswer = answers[currentQuestion] ?? '';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Enrollment - ${_getCurrentSectionTitle()}",
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 27, 126, 55)),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          currentQuestion,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: TextField(
                          onChanged: _onAnswerChanged,
                          controller:
                              TextEditingController(text: currentAnswer),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter your answer',
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: _currentQuestionIndex == 0
                                ? null
                                : _previousQuestion,
                            child: const Text('Previous'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff40AD5F),
                            ),
                            onPressed: () async {
                              if (_currentQuestionIndex ==
                                  allQuestions.length - 1) {
                                // Navigate to review screen
                                final confirmed = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EnrollmentReview(answers: answers),
                                  ),
                                );

                                if (confirmed == true) {
                                  insertStudent(); // Submit only if user confirms
                                }
                              } else {
                                _nextQuestion();
                              }
                            },
                            child: Text(
                              _currentQuestionIndex == allQuestions.length - 1
                                  ? 'Submit'
                                  : 'Next',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Question ${_currentQuestionIndex + 1} of ${allQuestions.length}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

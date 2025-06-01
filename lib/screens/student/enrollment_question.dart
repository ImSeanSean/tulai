import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:tulai/core/app_config.dart';
import 'package:tulai/core/constants.dart';
import 'package:tulai/screens/student/enrollment_review.dart';
import 'package:tulai/screens/student/enrollment_success.dart';
import 'package:tulai/services/gemini.dart';
import 'package:tulai/services/student_db.dart';
import 'package:permission_handler/permission_handler.dart';

class EnrollmentQuestions extends StatefulWidget {
  const EnrollmentQuestions({super.key});

  @override
  State<EnrollmentQuestions> createState() => _EnrollmentQuestionsState();
}

class _EnrollmentQuestionsState extends State<EnrollmentQuestions> {
  // Speech to Text
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _wordsSpoken = "";
  double _confidenceLevel = 0;

  late final List<String> allQuestions;
  int _currentQuestionIndex = 0;
  final Map<String, String> answers = {};
  final TextEditingController _answerController = TextEditingController();
  String? _lastQuestion;

  @override
  void initState() {
    super.initState();
    initSpeech();

    if (AppConfig().formLanguage == FormLanguage.filipino) {
      allQuestions = [
        ...formQuestionsNameFilipino,
        ...formQuestionsAddressFilipino,
        ...formQuestionsOthersFilipino,
        ...formQuestionsFatherGuardianFilipino,
        ...formQuestionsMotherGuardianFilipino,
        ...formQuestionsEducationalInfoFilipino,
      ];
    } else {
      allQuestions = [
        ...formQuestionsName,
        ...formQuestionsAddress,
        ...formQuestionsOthers,
        ...formQuestionsFatherGuardian,
        ...formQuestionsMotherGuardian,
        ...formQuestionsEducationalInfo,
      ];
    }
  }

  void initSpeech() async {
    bool available = false;

    final status = await Permission.microphone.request();
    if (status.isGranted) {
      available = await _speechToText.initialize(
        onError: (e) => print('[Speech ERROR] $e'),
        onStatus: (s) => print('[Speech STATUS] $s'),
      );
      print('[DEBUG] Speech available: $available');

      if (available) {
        var locales = await _speechToText.locales();
        print('[Speech] Available Locales:');
        for (var locale in locales) {
          print('  - ${locale.name} (${locale.localeId})');
        }

        var currentLocale = await _speechToText.systemLocale();
        print('[Speech] System Locale: ${currentLocale?.localeId}');
      }
    } else {
      print('[ERROR] Microphone permission not granted');
    }

    print('[Speech] Final available: $available');

    setState(() {
      _speechEnabled = available;
    });

    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition is not available')),
      );
    }
  }

  void _startListening() async {
    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        partialResults: false,
        localeId: 'en_US', // or "fil_PH" if Filipino
      );
      setState(() {});
    } catch (e) {
      print("[ERROR] Failed to start listening: $e");
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _confidenceLevel = 0;
    });
  }

  void _onSpeechResult(result) async {
    setState(() {
      _wordsSpoken = result.recognizedWords;
      _confidenceLevel = result.confidence;

      final currentQuestion = allQuestions[_currentQuestionIndex];
      _answerController.text = _wordsSpoken;
      answers[currentQuestion] = _wordsSpoken;
    });

    final currentField = allQuestions[_currentQuestionIndex];
    List<String> suggestions = [];

    // Determine which handler to use based on the current question
    if (formQuestionsName.contains(currentField)) {
      suggestions = await handleNameField(currentField, _wordsSpoken);
    } else if (formQuestionsAddress.contains(currentField)) {
      suggestions = await handleAddressField(currentField, _wordsSpoken);
    } else if (formQuestionsOthers.contains(currentField)) {
      suggestions = await handleOtherField(currentField, _wordsSpoken);
    } else if (formQuestionsFatherGuardian.contains(currentField)) {
      suggestions = await handleNameField(currentField, _wordsSpoken);
    } else if (formQuestionsMotherGuardian.contains(currentField)) {
      suggestions = await handleNameField(currentField, _wordsSpoken);
    } else if (formQuestionsEducationalInfo.contains(currentField)) {
      suggestions = await handleNameField(currentField, _wordsSpoken);
    }

    // Use or display suggestions as needed
    print("Suggested answers: $suggestions");
    print("Confidence Level: $_confidenceLevel");
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < allQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
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
    try {
      // Create Student instance from your answers map
      final student = Student(
        lastName: answers['Last Name'],
        firstName: answers['First Name'],
        middleName: answers['Middle Name'],
        nameExtension: answers['Name Extension'],
        houseStreetSitio: answers['House No./Street/Sitio'],
        barangay: answers['Barangay'],
        municipalityCity: answers['Municipality/City'],
        province: answers['Province'],
        birthdate: DateTime.tryParse(answers['Birthdate (mm/dd/yyyy)'] ?? ''),
        sex: answers['Sex (Male/Female)'],
        placeOfBirth: answers['Place of Birth (Municipality/City)'],
        civilStatus: answers[
            'Civil Status (Single, Married, Separated, Widower, Solo Parent)'],
        religion: answers['Religion'],
        ethnicGroup: answers['IP (Specify ethnic group):'],
        motherTongue: answers['Mother Tongue'],
        contactNumber: answers['Contact Number/s'],
        isPWD: (answers['PWD (Yes/No)']?.toLowerCase() == 'yes'),
        fatherLastName: answers['Father/Guardian Last Name'],
        fatherFirstName: answers['Father/Guardian First Name'],
        fatherMiddleName: answers['Father/Guardian Middle Name'],
        fatherOccupation: answers['Father/Guardian Occupation'],
        motherLastName: answers['Mother/Guardian Last Name'],
        motherFirstName: answers['Mother/Guardian First Name'],
        motherMiddleName: answers['Mother/Guardian Middle Name'],
        motherOccupation: answers['Mother/Guardian Occupation'],
        lastSchoolAttended: answers['Last School Attended'],
        lastGradeLevelCompleted: answers['Last grade level completed'],
        reasonForIncompleteSchooling:
            answers['Why did you not attend/complete schooling?'],
        hasAttendedALS:
            (answers['Have you attended ALS learning sessions before? (Yes/No)']
                    ?.toLowerCase() ==
                'yes'),
      );

      // Insert student using your helper class
      await StudentDatabase.insertStudent(student);

      print('Student inserted successfully!');
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const EnrollmentSuccess(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      print('Error inserting student: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = allQuestions[_currentQuestionIndex];
    if (_lastQuestion != currentQuestion) {
      _answerController.text = answers[currentQuestion] ?? '';
      _lastQuestion = currentQuestion;
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(1.0),
          child: Image.asset(
            'assets/images/deped-logo.png',
            fit: BoxFit.contain,
          ),
        ),
        title: Text(
          "Enrollment - ${_getCurrentSectionTitle()}",
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
                            controller: _answerController,
                            onChanged: _onAnswerChanged,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter your answer',
                            ),
                          )),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton(
                            onPressed: _currentQuestionIndex == 0
                                ? null
                                : _previousQuestion,
                            child: const Text('Previous'),
                          ),
                          IconButton(
                            onPressed: _speechEnabled
                                ? () {
                                    print("[DEBUG] IconButton pressed");
                                    print(
                                        "[DEBUG] _speechEnabled: $_speechEnabled");
                                    print(
                                        "[DEBUG] _speechToText.isListening: ${_speechToText.isListening}");

                                    if (_speechToText.isListening) {
                                      print(
                                          "[DEBUG] Stopping speech recognition...");
                                      _stopListening();
                                    } else {
                                      print(
                                          "[DEBUG] Starting speech recognition...");
                                      _startListening();
                                    }
                                  }
                                : () {
                                    print(
                                        "[DEBUG] IconButton pressed but _speechEnabled is false");
                                  },
                            icon: Icon(
                              _speechToText.isListening
                                  ? Icons.mic
                                  : Icons.mic_none,
                              color: _speechToText.isListening
                                  ? Colors.red
                                  : const Color(0xffEF8C4B),
                            ),
                            iconSize: 32,
                            tooltip: _speechToText.isListening
                                ? "Stop Listening"
                                : "Start Listening",
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
                                  insertStudent();
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

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }
}

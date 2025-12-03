// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:tulai/components/ai_assistant_modal.dart';
import 'package:tulai/core/app_config.dart';
import 'package:tulai/core/constants.dart';
import 'package:tulai/core/design_system.dart';
import 'package:tulai/screens/student/enrollment_review.dart';
import 'package:tulai/screens/student/enrollment_waiting.dart';
import 'package:tulai/services/gemini.dart';
import 'package:tulai/services/student_db.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tulai/widgets/appbar.dart';

class QuestionSection {
  final String section;
  final String question;
  QuestionSection(this.section, this.question);
}

class EnrollmentQuestions extends StatefulWidget {
  const EnrollmentQuestions({super.key});

  @override
  State<EnrollmentQuestions> createState() => _EnrollmentQuestionsState();
}

class _EnrollmentQuestionsState extends State<EnrollmentQuestions> {
  // Speech to Text
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _errorText = "";
  String _wordsSpoken = "";
  double _confidenceLevel = 0;
  String _lastProcessed = "";
  List<String> suggestions = [];

  late final List<QuestionSection> allQuestions;
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
        ...formQuestionsNameFilipino.map((q) => QuestionSection('enrollee', q)),
        ...formQuestionsAddressFilipino
            .map((q) => QuestionSection('address', q)),
        ...formQuestionsOthersFilipino.map((q) => QuestionSection('others', q)),
        ...formQuestionsFatherGuardianFilipino
            .map((q) => QuestionSection('father', q)),
        ...formQuestionsMotherGuardianFilipino
            .map((q) => QuestionSection('mother', q)),
        ...formQuestionsEducationalInfoFilipino
            .map((q) => QuestionSection('education', q)),
      ];
    } else {
      allQuestions = [
        ...formQuestionsName.map((q) => QuestionSection('enrollee', q)),
        ...formQuestionsAddress.map((q) => QuestionSection('address', q)),
        ...formQuestionsOthers.map((q) => QuestionSection('others', q)),
        ...formQuestionsFatherGuardian.map((q) => QuestionSection('father', q)),
        ...formQuestionsMotherGuardian.map((q) => QuestionSection('mother', q)),
        ...formQuestionsEducationalInfo
            .map((q) => QuestionSection('education', q)),
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

    if (mounted) {
      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition is not available')),
        );
      }
    }
  }

  void _startListening() async {
    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
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

  void _onSpeechResult(SpeechRecognitionResult result) async {
    // Only process final results
    if (!result.finalResult) return;

    final newTranscript = result.recognizedWords.trim();

    // Prevent re-processing the same recognized words
    if (newTranscript == _lastProcessed) return;
    _lastProcessed = newTranscript;

    // Store the transcript temporarily, don't set it in the field yet
    setState(() {
      _wordsSpoken = newTranscript;
      _confidenceLevel = result.confidence;
    });

    final currentQ = allQuestions[_currentQuestionIndex];
    final currentField = currentQ.question;
    List<String> newSuggestions = [];

    print("🔊 Words Spoken: '$_wordsSpoken'");
    print("📝 Current Field: '$currentField'");

    final isFilipino = AppConfig().formLanguage == FormLanguage.filipino;

    if ((isFilipino ? formQuestionsNameFilipino : formQuestionsName)
            .contains(currentField) ||
        (isFilipino
                ? formQuestionsFatherGuardianFilipino
                : formQuestionsFatherGuardian)
            .contains(currentField) ||
        (isFilipino
                ? formQuestionsMotherGuardianFilipino
                : formQuestionsMotherGuardian)
            .contains(currentField)) {
      print("🔍 Using name field handler");
      newSuggestions = await handleNameField(currentField, _wordsSpoken);
    } else if ((isFilipino
            ? formQuestionsAddressFilipino
            : formQuestionsAddress)
        .contains(currentField)) {
      print("🔍 Using address field handler");
      newSuggestions = await handleAddressField(currentField, _wordsSpoken);
    } else if ((isFilipino ? formQuestionsOthersFilipino : formQuestionsOthers)
        .contains(currentField)) {
      print("🔍 Using other field handler");
      newSuggestions = await handleOtherField(currentField, _wordsSpoken);
    } else if ((isFilipino
            ? formQuestionsEducationalInfoFilipino
            : formQuestionsEducationalInfo)
        .contains(currentField)) {
      print("🔍 Using educational field handler");
      newSuggestions =
          await handleEducationalInformationField(currentField, _wordsSpoken);
    } else {
      print("❓ No handler matched for field: '$currentField'");
    }

    setState(() {
      suggestions = newSuggestions;
    });

    // Check if we have an error message in the suggestions
    bool hasErrorMessage =
        newSuggestions.any((suggestion) => suggestion.startsWith("ERROR:"));

    if (suggestions.isEmpty) {
      _errorText = "Your response is not valid. Please try again.";
    } else if (hasErrorMessage) {
      // Extract the error message and display it
      String errorMessage =
          newSuggestions.firstWhere((s) => s.startsWith("ERROR:"));
      _errorText = errorMessage.replaceFirst("ERROR:", "").trim();
      // Remove the error from suggestions so it doesn't appear as a clickable suggestion
      suggestions =
          newSuggestions.where((s) => !s.startsWith("ERROR:")).toList();
      // Don't update the text field when there's an error
    } else {
      // Only update the text field and answers when there's no error
      final currentQ = allQuestions[_currentQuestionIndex];
      final formattedText = _wordsSpoken
          .toLowerCase()
          .split(' ')
          .map((word) =>
              word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
          .join(' ');

      setState(() {
        _answerController.text = formattedText;
        answers['${currentQ.section}:${currentQ.question}'] = formattedText;
      });

      _errorText = ""; // Clear error text when we have valid suggestions
    }

    print("✅ Suggested answers: $suggestions");
    print("📊 Confidence Level: $_confidenceLevel");
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

  bool _shouldUseDropdown(String question) {
    final dropdownQuestions = [
      'Sex (Male/Female)',
      'Kasarian (Lalaki/Babae)',
      'Civil Status (Single, Married, Separated, Widower, Solo Parent)',
      'Katayuang Sibil (Binata, Dalaga, Kasal, Hiwalay, Biyudo/a, Solo Parent)',
      'PWD (Yes/No)',
      'PWD (Oo/Hindi)',
      'Have you attended ALS learning sessions before? (Yes/No)',
      'Nakapag-attend ka na ba ng ALS learning sessions? (Oo/Hindi)',
      'Name Extension',
      'Ekstensyon ng Pangalan',
    ];
    return dropdownQuestions.contains(question);
  }

  List<String> _getDropdownOptions(String question) {
    final isFilipino = AppConfig().formLanguage == FormLanguage.filipino;

    if (question.contains('Sex') || question.contains('Kasarian')) {
      return isFilipino ? ['Lalaki', 'Babae'] : ['Male', 'Female'];
    }
    if (question.contains('Civil Status') ||
        question.contains('Katayuang Sibil')) {
      return isFilipino
          ? ['Binata', 'Dalaga', 'Kasal', 'Hiwalay', 'Biyudo/a', 'Solo Parent']
          : ['Single', 'Married', 'Separated', 'Widowed', 'Solo Parent'];
    }
    if (question.contains('PWD')) {
      return isFilipino ? ['Oo', 'Hindi'] : ['Yes', 'No'];
    }
    if (question.contains('ALS learning sessions') ||
        question.contains('Nakapag-attend')) {
      return isFilipino ? ['Oo', 'Hindi'] : ['Yes', 'No'];
    }
    if (question.contains('Name Extension') ||
        question.contains('Ekstensyon')) {
      return ['Jr.', 'Sr.', 'II', 'III', 'IV', 'V'];
    }
    return [];
  }

  TextCapitalization _getTextCapitalization(String question) {
    // Name fields should capitalize words
    if (question.contains('Name') ||
        question.contains('Pangalan') ||
        question.contains('Apelyido') ||
        question.contains('Occupation') ||
        question.contains('Trabaho')) {
      return TextCapitalization.words;
    }
    // Address fields should capitalize words
    if (question.contains('Barangay') ||
        question.contains('Municipality') ||
        question.contains('City') ||
        question.contains('Province') ||
        question.contains('Bayan') ||
        question.contains('Lungsod') ||
        question.contains('Lalawigan') ||
        question.contains('Place of Birth') ||
        question.contains('Lugar ng Kapanganakan') ||
        question.contains('Street') ||
        question.contains('Sitio') ||
        question.contains('Kalye')) {
      return TextCapitalization.words;
    }
    // Religion and other text fields
    if (question.contains('Religion') ||
        question.contains('Relihiyon') ||
        question.contains('ethnic group') ||
        question.contains('grupo') ||
        question.contains('Mother Tongue') ||
        question.contains('Wika') ||
        question.contains('School') ||
        question.contains('Paaralan')) {
      return TextCapitalization.words;
    }
    // Sentences for reason fields
    if (question.contains('Why') || question.contains('Bakit')) {
      return TextCapitalization.sentences;
    }
    return TextCapitalization.none;
  }

  Future<void> _handleNextOrSkip() async {
    final q = allQuestions[_currentQuestionIndex];
    final key = '${q.section}:${q.question}';
    final currentAnswer = answers[key]?.trim() ?? '';
    final isFilipino = AppConfig().formLanguage == FormLanguage.filipino;

    // Check if this is a required field (Last Name or First Name)
    final isRequiredField = (q.section == 'enrollee') &&
        (q.question == 'Last Name' ||
            q.question == 'First Name' ||
            q.question == 'Apelyido' ||
            q.question == 'Pangalan');

    // If answer is empty
    if (currentAnswer.isEmpty) {
      // If it's a required field, show error and don't allow skip
      if (isRequiredField) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              isFilipino ? 'Kinakailangan ang Sagot' : 'Answer Required',
              style: TulaiTextStyles.heading3.copyWith(
                color: TulaiColors.error,
              ),
            ),
            content: Text(
              isFilipino
                  ? 'Ang tanong na ito ay kinakailangan. Mangyaring magbigay ng sagot para magpatuloy.'
                  : 'This question is required. Please provide an answer to continue.',
              style: TulaiTextStyles.bodyMedium,
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TulaiColors.primary,
                ),
                child: Text(
                  'OK',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
        return; // Don't proceed
      }

      // For optional fields, show skip confirmation
      final shouldSkip = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            isFilipino ? 'Laktawan ang Tanong?' : 'Skip Question?',
            style: TulaiTextStyles.heading3,
          ),
          content: Text(
            isFilipino
                ? 'Walang sagot na naibigay. Gusto mo bang laktawan ang tanong na ito?'
                : 'No answer provided. Would you like to skip this question?',
            style: TulaiTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                isFilipino ? 'Hindi' : 'No',
                style: TextStyle(color: TulaiColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: TulaiColors.primary,
              ),
              child: Text(
                isFilipino ? 'Oo, Laktawan' : 'Yes, Skip',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (shouldSkip == true) {
        // Set answer to N/A for skipped questions
        answers[key] = 'N/A';
        suggestions = [];
        _nextQuestion();
      }
      // If false or null, stay on current question
    } else {
      // Answer provided, proceed normally
      suggestions = [];
      _nextQuestion();
    }
  }

  void _onAnswerChanged(String value) {
    final q = allQuestions[_currentQuestionIndex];
    answers['${q.section}:${q.question}'] = value;
  }

  String _getCurrentSectionTitle() {
    final section = allQuestions[_currentQuestionIndex].section;
    final isFilipino = AppConfig().formLanguage == FormLanguage.filipino;
    switch (section) {
      case 'enrollee':
        return isFilipino ? "Pangalan ng Mag-eenroll" : "Enrollee's Name";
      case 'address':
        return isFilipino ? "Tirahan" : "Address";
      case 'others':
        return isFilipino
            ? "Iba Pang Personal na Impormasyon"
            : "Other Personal Information";
      case 'father':
        return isFilipino
            ? "Pangalan ng Ama/Tagapangalaga"
            : "Father/Guardian's Name";
      case 'mother':
        return isFilipino
            ? "Pangalan ng Ina/Tagapangalaga"
            : "Mother/Guardian's Name";
      case 'education':
        return isFilipino
            ? "Impormasyon sa Edukasyon"
            : "Educational Information";
      default:
        return isFilipino ? "Pagpaparehistro" : "Enrollment";
    }
  }

  String? _normalizeSex(String? value) {
    if (value == null || value.isEmpty) return null;
    final lower = value.toLowerCase();
    if (lower == 'lalaki' || lower == 'male') return 'Male';
    if (lower == 'babae' || lower == 'female') return 'Female';
    return value;
  }

  String? _normalizeCivilStatus(String? value) {
    if (value == null || value.isEmpty) return null;
    final lower = value.toLowerCase();
    if (lower == 'binata' || lower == 'dalaga' || lower == 'single')
      return 'Single';
    if (lower == 'kasal' || lower == 'married') return 'Married';
    if (lower == 'hiwalay' || lower == 'separated') return 'Separated';
    if (lower == 'biyudo/a' ||
        lower == 'balo' ||
        lower == 'widowed' ||
        lower == 'widower') return 'Widowed';
    if (lower.contains('solo parent')) return 'Solo Parent';
    return value;
  }

  String? _normalizeReligion(String? value) {
    if (value == null || value.isEmpty) return null;
    final lower = value.toLowerCase();
    if (lower.contains('catholic') || lower == 'katoliko')
      return 'Roman Catholic';
    if (lower.contains('islam') || lower.contains('muslim')) return 'Islam';
    if (lower.contains('iglesia')) return 'Iglesia ni Cristo';
    if (lower.contains('born again')) return 'Born Again Christian';
    if (lower.contains('adventist') || lower.contains('seventh'))
      return 'Seventh-day Adventist';
    if (lower.contains('buddhis')) return 'Buddhism';
    return 'Other';
  }

  Future<void> insertStudent() async {
    try {
      // Fetch the active batch (is_active = true)
      final batchResponse = await supabase
          .from('batches')
          .select('id')
          .eq('is_active', true)
          .single();
      final batchId = batchResponse['id'];

      // Create pending submission record from answers map
      final submissionData = {
        'last_name': answers['enrollee:Last Name'],
        'first_name': answers['enrollee:First Name'],
        'middle_name': answers['enrollee:Middle Name'],
        'name_extension': answers['enrollee:Name Extension'],
        'house_street_sitio': answers['address:House No./Street/Sitio'],
        'barangay': answers['address:Barangay'],
        'municipality_city': answers['address:Municipality/City'],
        'province': answers['address:Province'],
        'birthdate': answers['others:Birthdate (mm/dd/yyyy)'],
        'sex': _normalizeSex(answers['others:Sex (Male/Female)']),
        'place_of_birth': answers['others:Place of Birth (Municipality/City)'],
        'civil_status': _normalizeCivilStatus(answers[
            'others:Civil Status (Single, Married, Separated, Widower, Solo Parent)']),
        'religion': _normalizeReligion(answers['others:Religion']),
        'ethnic_group': answers['others:IP (Specify ethnic group):'],
        'mother_tongue': answers['others:Mother Tongue'],
        'contact_number': answers['others:Contact Number/s'],
        'is_pwd': (answers['others:PWD (Yes/No)']?.toLowerCase() == 'yes'),
        'father_last_name': answers['father:Father/Guardian Last Name'],
        'father_first_name': answers['father:Father/Guardian First Name'],
        'father_middle_name': answers['father:Father/Guardian Middle Name'],
        'father_occupation': answers['father:Father/Guardian Occupation'],
        'mother_last_name': answers['mother:Mother/Guardian Last Name'],
        'mother_first_name': answers['mother:Mother/Guardian First Name'],
        'mother_middle_name': answers['mother:Mother/Guardian Middle Name'],
        'mother_occupation': answers['mother:Mother/Guardian Occupation'],
        'last_school_attended': answers['education:Last School Attended'],
        'last_grade_level_completed':
            answers['education:Last grade level completed'],
        'reason_for_incomplete_schooling':
            answers['education:Why did you not attend/complete schooling?'],
        'has_attended_als': (answers[
                    'education:Have you attended ALS learning sessions before? (Yes/No)']
                ?.toLowerCase() ==
            'yes'),
        'submitted_at': DateTime.now().toIso8601String(),
        'batch_id': batchId,
      };

      // Insert into pending_submissions table instead of students
      await supabase.from('pending_submissions').insert(submissionData);

      print('Submission sent for review!');
      if (!mounted) return;

      // Navigate to waiting screen instead of success screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const EnrollmentWaiting(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      print('Error submitting data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQ = allQuestions[_currentQuestionIndex];
    final currentKey = '${currentQ.section}:${currentQ.question}';
    if (_lastQuestion != currentKey) {
      _answerController.text = answers[currentKey] ?? '';
      _lastQuestion = currentKey;
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: TulaiColors.backgroundSecondary,
      appBar: const CustomAppBar(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(TulaiSpacing.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Header with centered section title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left: Back button
                          Container(
                            decoration: BoxDecoration(
                              color: TulaiColors.backgroundPrimary,
                              borderRadius:
                                  BorderRadius.circular(TulaiBorderRadius.md),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              icon: Icon(
                                Icons.arrow_back,
                                size: 28,
                                color: TulaiColors.primary,
                              ),
                            ),
                          ),
                          // Center: Section title
                          Expanded(
                            child: Text(
                              _getCurrentSectionTitle(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: TulaiColors.primary,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          // Right: AI Assistant button
                          Container(
                            decoration: BoxDecoration(
                              color: TulaiColors.backgroundPrimary,
                              borderRadius:
                                  BorderRadius.circular(TulaiBorderRadius.md),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Image.asset(
                                'assets/images/tulai-logo.png',
                                width: 60,
                                height: 60,
                              ),
                              tooltip: 'AI Assistant',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      const AiAssistantModal(),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: TulaiSpacing.md),
                      // Question with enhanced styling
                      Container(
                        padding: const EdgeInsets.all(TulaiSpacing.lg),
                        child: Text(
                          currentQ.question,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: TulaiColors.textPrimary,
                            height: 1.2,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: TulaiSpacing.lg),
                      // Input field and microphone with enhanced design
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Container(
                              decoration: BoxDecoration(
                                color: TulaiColors.backgroundPrimary,
                                borderRadius:
                                    BorderRadius.circular(TulaiBorderRadius.lg),
                                border: Border.all(
                                  color: TulaiColors.borderMedium,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: _shouldUseDropdown(currentQ.question)
                                  ? DropdownButtonFormField<String>(
                                      value: answers['${currentQ.section}:${currentQ.question}']
                                                  ?.isNotEmpty ==
                                              true
                                          ? answers[
                                              '${currentQ.section}:${currentQ.question}']
                                          : null,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Select an option',
                                        hintStyle: TextStyle(
                                          color: TulaiColors.textMuted,
                                          fontSize: 24,
                                        ),
                                        contentPadding: const EdgeInsets.all(
                                            TulaiSpacing.md),
                                      ),
                                      style: TextStyle(
                                        fontSize: 26,
                                        color: TulaiColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      dropdownColor:
                                          TulaiColors.backgroundPrimary,
                                      icon: Icon(Icons.arrow_drop_down,
                                          color: TulaiColors.primary, size: 32),
                                      isExpanded: true,
                                      items:
                                          _getDropdownOptions(currentQ.question)
                                              .map((option) => DropdownMenuItem(
                                                    value: option,
                                                    child: Text(option),
                                                  ))
                                              .toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          _answerController.text = value;
                                          _onAnswerChanged(value);
                                          setState(() {});
                                        }
                                      },
                                    )
                                  : TextField(
                                      style: TextStyle(
                                        fontSize: 26,
                                        color: TulaiColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      controller: _answerController,
                                      onChanged: _onAnswerChanged,
                                      textCapitalization:
                                          _getTextCapitalization(
                                              currentQ.question),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Enter your answer',
                                        hintStyle: TextStyle(
                                          color: TulaiColors.textMuted,
                                          fontSize: 24,
                                        ),
                                        contentPadding: const EdgeInsets.all(
                                            TulaiSpacing.md),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: TulaiSpacing.sm),
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _speechToText.isListening
                                    ? [TulaiColors.error, Colors.red[700]!]
                                    : [
                                        TulaiColors.secondary,
                                        TulaiColors.accent
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius:
                                  BorderRadius.circular(TulaiBorderRadius.lg),
                              boxShadow: [
                                BoxShadow(
                                  color: (_speechToText.isListening
                                          ? TulaiColors.error
                                          : TulaiColors.secondary)
                                      .withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
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
                                color: Colors.white,
                                size: 28,
                              ),
                              tooltip: _speechToText.isListening
                                  ? "Stop Listening"
                                  : "Start Listening",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: TulaiSpacing.lg),
                      // Suggestions section with improved design
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(TulaiSpacing.md),
                        decoration: BoxDecoration(
                          color: TulaiColors.backgroundPrimary,
                          borderRadius:
                              BorderRadius.circular(TulaiBorderRadius.lg),
                          border: Border.all(
                            color: TulaiColors.borderLight,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: suggestions.isNotEmpty
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.lightbulb_outline,
                                        color: TulaiColors.secondary,
                                        size: 24,
                                      ),
                                      const SizedBox(width: TulaiSpacing.sm),
                                      Text(
                                        'Suggestions:',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: TulaiColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: TulaiSpacing.md),
                                  Wrap(
                                    spacing: TulaiSpacing.sm,
                                    runSpacing: TulaiSpacing.sm,
                                    children: suggestions
                                        .map(
                                          (s) => InkWell(
                                            onTap: () {
                                              print('Selected suggestion: $s');
                                              _answerController.text = s;
                                              answers[currentKey] = s;
                                              setState(() {});
                                            },
                                            borderRadius: BorderRadius.circular(
                                                TulaiBorderRadius.lg),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: TulaiSpacing.lg,
                                                vertical: TulaiSpacing.md,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    TulaiColors.secondary,
                                                    TulaiColors.accent
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        TulaiBorderRadius.lg),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: TulaiColors.secondary
                                                        .withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                s,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Icon(
                                    _errorText.isNotEmpty
                                        ? Icons.error_outline
                                        : Icons.info_outline,
                                    color: _errorText.isNotEmpty
                                        ? TulaiColors.error
                                        : TulaiColors.textMuted,
                                    size: 24,
                                  ),
                                  const SizedBox(width: TulaiSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      _errorText.isNotEmpty
                                          ? _errorText
                                          : 'No suggestions yet',
                                      style: TextStyle(
                                        color: _errorText.isNotEmpty
                                            ? TulaiColors.error
                                            : TulaiColors.textMuted,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05),
                      // Navigation buttons with improved styling
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: Container(
                              height: 50,
                              margin:
                                  const EdgeInsets.only(right: TulaiSpacing.sm),
                              child: ElevatedButton(
                                onPressed: _currentQuestionIndex == 0
                                    ? null
                                    : () {
                                        setState(() {
                                          suggestions = [];
                                        });
                                        _previousQuestion();
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      TulaiColors.backgroundPrimary,
                                  foregroundColor: TulaiColors.primary,
                                  side: BorderSide(
                                    color: TulaiColors.primary,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        TulaiBorderRadius.lg),
                                  ),
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                ),
                                child: const Text(
                                  'Previous',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: TulaiSpacing.md),
                          Expanded(
                            child: Container(
                              height: 50,
                              margin:
                                  const EdgeInsets.only(left: TulaiSpacing.sm),
                              child: ElevatedButton(
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
                                    await _handleNextOrSkip();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: TulaiColors.secondary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        TulaiBorderRadius.lg),
                                  ),
                                  elevation: 8,
                                  shadowColor:
                                      TulaiColors.secondary.withOpacity(0.4),
                                ),
                                child: Text(
                                  _currentQuestionIndex ==
                                          allQuestions.length - 1
                                      ? 'Submit'
                                      : 'Next',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: TulaiSpacing.md),
                      // Progress indicator with improved design
                      Column(
                        children: [
                          Text(
                            'Question ${_currentQuestionIndex + 1} of ${allQuestions.length}',
                            style: TextStyle(
                              color: TulaiColors.textMuted,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: TulaiSpacing.sm),
                          Container(
                            width: double.infinity,
                            height: 6,
                            decoration: BoxDecoration(
                              color: TulaiColors.borderLight,
                              borderRadius:
                                  BorderRadius.circular(TulaiBorderRadius.sm),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: (_currentQuestionIndex + 1) /
                                  allQuestions.length,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      TulaiColors.primary,
                                      TulaiColors.secondary
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      TulaiBorderRadius.sm),
                                ),
                              ),
                            ),
                          ),
                        ],
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

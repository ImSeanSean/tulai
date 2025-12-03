import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tulai/core/design_system.dart';
import 'package:tulai/screens/student/enrollment_waiting.dart';

class VoiceEnrollmentPage extends StatefulWidget {
  final bool isFilipino;

  const VoiceEnrollmentPage({super.key, this.isFilipino = false});

  @override
  State<VoiceEnrollmentPage> createState() => _VoiceEnrollmentPageState();
}

class _VoiceEnrollmentPageState extends State<VoiceEnrollmentPage>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  late final GenerativeModel _aiModel;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isListening = false;
  bool _speechEnabled = false;
  bool _isSpeaking = false;
  bool _isProcessing = false;
  String _lastWords = '';

  // Conversation history
  final List<Map<String, String>> _conversation = [];

  // Enrollment data
  final Map<String, dynamic> _enrollmentData = {};
  int _currentStep = 0;

  late final List<Map<String, dynamic>> _questions;

  void _initializeQuestions() {
    if (widget.isFilipino) {
      _questions = [
        {
          'field': 'greeting',
          'question':
              'Kumusta! Ako ang iyong tutulong sa pag-eenroll. Narito ako para tulungan ka sa Alternative Learning System ngayong araw. Magsimula na tayo!',
          'type': 'greeting',
          'followUp': 'Ayos! Magsimula tayo sa iyong basic na impormasyon.'
        },
        {
          'field': 'fullName',
          'question':
              'Sabihin mo ang iyong buong pangalan. Pwede mong sabihin ang iyong unang pangalan, gitnang pangalan, at apelyido nang sabay-sabay.',
          'followUp': 'Salamat, {value}!',
          'type': 'composite'
        },
        {
          'field': 'fullAddress',
          'question':
              'Ngayon, sabihin mo ang iyong buong address. Pwede mong sabihin ang numero ng bahay, kalye, barangay, bayan o lungsod, at lalawigan nang sabay-sabay.',
          'followUp': 'Salamat!',
          'type': 'composite'
        },
        {
          'field': 'birthdate',
          'question':
              'Kailan ka ipinanganak? Sabihin mo ang buwan, araw, at taon.',
          'followUp': 'Salamat. Ipinanganak ka noong {value}.'
        },
        {
          'field': 'sex',
          'question': 'Ano ang kasarian mo? Lalaki o babae?',
          'followUp': 'Okay, {value}.'
        },
        {
          'field': 'placeOfBirth',
          'question': 'Saan ka ipinanganak? Ano ang bayan o lungsod?',
          'followUp': 'Salamat.',
          'optional': true
        },
        {
          'field': 'civilStatus',
          'question':
              'Ano ang katayuang sibil mo? Binata, dalaga, kasal, hiwalay, o balo?',
          'followUp': 'Naintindihan.',
          'optional': true
        },
        {
          'field': 'religion',
          'question': 'Ano ang relihiyon mo?',
          'followUp': 'Salamat.',
          'optional': true
        },
        {
          'field': 'ethnicGroup',
          'question':
              'Bahagi ka ba ng indigenous people o ethnic group? Kung oo, ano ang grupo? Kung hindi, sabihin mo "wala".',
          'followUp': 'Okay.',
          'optional': true
        },
        {
          'field': 'motherTongue',
          'question': 'Ano ang inang wika mo?',
          'followUp': 'Salamat.',
          'optional': true
        },
        {
          'field': 'contactNumber',
          'question': 'Ano ang numero ng telepono mo?',
          'followUp': 'Salamat, {value}.'
        },
        {
          'field': 'isPWD',
          'question': 'May kapansanan ka ba? Sabihin mo oo o hindi.',
          'followUp': 'Naintindihan.',
          'optional': true
        },
        {
          'field': 'fatherInfo',
          'question':
              'Ngayon, sabihin mo ang impormasyon ng iyong ama o tagapag-alaga. Pwede mong sabihin ang kanyang buong pangalan at trabaho nang sabay-sabay.',
          'followUp': 'Salamat sa impormasyon tungkol sa iyong ama.',
          'optional': true,
          'type': 'composite'
        },
        {
          'field': 'motherInfo',
          'question':
              'Ngayon para sa ina mo. Sabihin mo ang kanyang buong pangalan at trabaho nang sabay-sabay.',
          'followUp': 'Salamat sa impormasyon tungkol sa iyong ina.',
          'optional': true,
          'type': 'composite'
        },
        {
          'field': 'lastSchoolAttended',
          'question': 'Ano ang huling paaralan na iyong pinag-aralan?',
          'followUp': 'Salamat.',
          'optional': true
        },
        {
          'field': 'lastGradeLevelCompleted',
          'question': 'Ano ang huling antas na natapos mo?',
          'followUp': 'Okay.',
          'optional': true
        },
        {
          'field': 'reasonForIncompleteSchooling',
          'question': 'Bakit hindi ka nakapag-aral o nakatapos?',
          'followUp': 'Naintindihan. Salamat sa pagsasabi.',
          'optional': true
        },
        {
          'field': 'hasAttendedALS',
          'question': 'Nakadalo ka na ba sa ALS dati? Sabihin mo oo o hindi.',
          'followUp': 'Salamat.',
          'optional': true
        },
        {
          'field': 'complete',
          'question':
              'Yun lang ang kailangan ko! I-sesave ko na ang iyong enrollment. Salamat sa iyong pasensya!',
          'type': 'complete'
        },
      ];
    } else {
      _questions = [
        {
          'field': 'greeting',
          'question':
              'Hello! I\'m your enrollment assistant. I\'m here to help you enroll in our Alternative Learning System today. Let\'s get started!',
          'type': 'greeting',
          'followUp': 'Great! Let\'s begin with your basic information.'
        },
        {
          'field': 'fullName',
          'question':
              'Please tell me your full name. You can say your first name, middle name, and last name all at once, or just your first and last name.',
          'followUp': 'Thank you, {value}!',
          'type': 'composite'
        },
        {
          'field': 'fullAddress',
          'question':
              'Now, please tell me your complete address. You can say your house number, street, barangay, city or municipality, and province all together.',
          'followUp': 'Got it, thank you!',
          'type': 'composite'
        },
        {
          'field': 'birthdate',
          'question':
              'When were you born? Please tell me the month, day, and year.',
          'followUp': 'Thank you. So you were born on {value}.'
        },
        {
          'field': 'sex',
          'question': 'What is your sex? Please say male or female.',
          'followUp': 'Okay, {value}.'
        },
        {
          'field': 'placeOfBirth',
          'question': 'Where were you born? What municipality or city?',
          'followUp': 'Thank you.',
          'optional': true
        },
        {
          'field': 'civilStatus',
          'question':
              'What is your civil status? Single, married, separated, widowed, or solo parent?',
          'followUp': 'Understood.',
          'optional': true
        },
        {
          'field': 'religion',
          'question': 'What is your religion?',
          'followUp': 'Thank you.',
          'optional': true
        },
        {
          'field': 'ethnicGroup',
          'question':
              'Are you part of an indigenous people or ethnic group? If yes, which one? If no, say "none".',
          'followUp': 'Okay.',
          'optional': true
        },
        {
          'field': 'motherTongue',
          'question': 'What is your mother tongue or first language?',
          'followUp': 'Thank you.',
          'optional': true
        },
        {
          'field': 'contactNumber',
          'question': 'What\'s a good contact number where we can reach you?',
          'followUp': 'Thank you, {value}.'
        },
        {
          'field': 'isPWD',
          'question': 'Are you a person with disability? Please say yes or no.',
          'followUp': 'Understood.',
          'optional': true
        },
        {
          'field': 'fatherInfo',
          'question':
              'Now, let\'s get your father or guardian\'s information. You can tell me their full name and occupation all at once.',
          'followUp': 'Thank you for the information about your father.',
          'optional': true,
          'type': 'composite'
        },
        {
          'field': 'motherInfo',
          'question':
              'Now for your mother or guardian. Please tell me their full name and occupation all at once.',
          'followUp': 'Thank you for the information about your mother.',
          'optional': true,
          'type': 'composite'
        },
        {
          'field': 'lastSchoolAttended',
          'question': 'What was the last school you attended?',
          'followUp': 'Thank you.',
          'optional': true
        },
        {
          'field': 'lastGradeLevelCompleted',
          'question': 'What was the last grade level you completed?',
          'followUp': 'Okay.',
          'optional': true
        },
        {
          'field': 'reasonForIncompleteSchooling',
          'question': 'Why did you not complete or continue your schooling?',
          'followUp': 'I understand. Thank you for sharing.',
          'optional': true
        },
        {
          'field': 'hasAttendedALS',
          'question':
              'Have you attended ALS learning sessions before? Please say yes or no.',
          'followUp': 'Thank you.',
          'optional': true
        },
        {
          'field': 'complete',
          'question':
              'That\'s all the information I need! Let me save your enrollment. Thank you for your patience!',
          'type': 'complete'
        },
      ];
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initializeQuestions();
    _initializeAI();
    _initializeAll();
  }

  void _initializeAI() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print('GEMINI_API_KEY not found');
      return;
    }
    _aiModel = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );
  }

  Future<void> _initializeAll() async {
    // Initialize speech recognition first
    await _initSpeech();
    // Then initialize TTS
    await _initTts();
  }

  Future<void> _initSpeech() async {
    // Request microphone permission first
    if (!kIsWeb) {
      final status = await Permission.microphone.request();
      print('Microphone permission status: $status');

      if (!status.isGranted) {
        print('Microphone permission denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Microphone permission is required for voice enrollment'),
              backgroundColor: TulaiColors.error,
            ),
          );
        }
        return;
      }
    }

    _speechEnabled = await _speechToText.initialize(
      onError: (error) {
        print('Speech error: $error');
        // Update UI when error occurs
        if (mounted) {
          setState(() {
            _isListening = false;
          });
        }
      },
      onStatus: (status) {
        print('Speech status: $status');
        // Update UI based on speech status
        if (mounted) {
          if (status == 'done') {
            // When speech is done automatically, process the answer
            setState(() {
              _isListening = false;
            });
            // Wait for final result to arrive, then process if not already processing
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted && _lastWords.isNotEmpty && !_isProcessing) {
                print('Auto-processing final answer: $_lastWords');
                _isProcessing = true;
                final answer = _capitalizeAnswer(_lastWords);
                _lastWords = ''; // Clear for next question
                setState(() {});

                _conversation.add({
                  'type': 'user',
                  'message': answer,
                });
                setState(() {});
                _processAnswer(answer).then((_) {
                  _isProcessing = false;
                });
              }
            });
          } else if (status == 'notListening') {
            setState(() {
              _isListening = false;
            });
          } else if (status == 'listening') {
            setState(() {
              _isListening = true;
            });
          }
        }
      },
    );
    print('Speech recognition initialized: $_speechEnabled');
    setState(() {});
  }

  Future<void> _initTts() async {
    try {
      // Set up handlers first (works on all platforms)
      _flutterTts.setStartHandler(() {
        print('TTS Started');
        if (mounted) {
          setState(() {
            _isSpeaking = true;
          });
        }
      });

      _flutterTts.setCompletionHandler(() {
        print('TTS Completed');
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });

      _flutterTts.setErrorHandler((msg) {
        print('TTS Error: $msg');
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });

      // Try to configure TTS settings (may not be supported on all platforms)
      try {
        await _flutterTts.setLanguage(widget.isFilipino ? 'fil-PH' : 'en-US');
        await _flutterTts.setSpeechRate(0.5);
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setPitch(1.0);

        // Only await speak completion on mobile platforms (not web or desktop)
        if (!kIsWeb) {
          try {
            await _flutterTts.awaitSpeakCompletion(true);
            print('TTS await speak completion enabled');
          } catch (e) {
            print('TTS awaitSpeakCompletion not supported: $e');
          }
        }

        print('TTS configured successfully');
      } catch (e) {
        print('TTS configuration warning (non-critical): $e');
        // Continue anyway - basic TTS should still work
      }

      // Start the conversation
      print(
          'Attempting to start conversation, _speechEnabled: $_speechEnabled');
      if (_speechEnabled) {
        print('Starting conversation in 1 second...');
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            print('Calling _askQuestion()');
            _askQuestion();
          }
        });
      } else {
        print('Speech not enabled, cannot start conversation');
      }
    } catch (e) {
      print('Error initializing TTS: $e');
    }
  }

  void _askQuestion() async {
    print(
        '_askQuestion called, currentStep: $_currentStep, total questions: ${_questions.length}');
    if (_currentStep < _questions.length) {
      final question = _questions[_currentStep];
      final questionType = question['type'] as String?;

      final questionText = question['question'] as String;

      print('Adding question to conversation: $questionText');

      _conversation.add({
        'type': 'ai',
        'message': questionText,
      });

      setState(() {}); // Update UI with new conversation message

      // AI speaks the question
      await _speak(questionText);

      // If it's a greeting, automatically proceed to next question
      if (questionType == 'greeting') {
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          _processAnswer(''); // Empty answer to trigger progression
        }
      }
    }
  }

  Future<void> _speak(String text) async {
    print('TTS attempting to speak: $text');
    setState(() {
      _isSpeaking = true;
    });

    try {
      var result = await _flutterTts.speak(text);
      print('TTS speak result: $result');
    } catch (e) {
      print('TTS speak error: $e');
      setState(() {
        _isSpeaking = false;
      });
    }
  }

  Future<void> _startListening() async {
    print('_startListening called');
    print(
        '_speechEnabled: $_speechEnabled, _isSpeaking: $_isSpeaking, _isListening: $_isListening');

    if (!_speechEnabled) {
      print('Speech not enabled - cannot listen');
      // Try to reinitialize
      await _initSpeech();
      if (!_speechEnabled) {
        return;
      }
    }

    if (_isSpeaking) {
      print('AI is speaking - cannot listen');
      return;
    }

    if (_isListening) {
      print('Already listening');
      return;
    }

    // Check if speech recognition is available
    if (!await _speechToText.hasPermission) {
      print('No speech permission');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please grant microphone permission'),
            backgroundColor: TulaiColors.error,
          ),
        );
      }
      return;
    }

    setState(() {
      _lastWords = '';
      _isListening = true;
    });

    print('Starting speech recognition...');
    try {
      await _speechToText.listen(
        onResult: (result) {
          print(
              'Speech result: ${result.recognizedWords}, final: ${result.finalResult}');
          // Only update if not processing to prevent race conditions
          if (!_isProcessing) {
            setState(() {
              _lastWords = result.recognizedWords;
            });
          }
        },
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 5),
        cancelOnError: false,
        partialResults: true,
        listenMode: ListenMode.confirmation,
        onSoundLevelChange: (level) {
          if (level > 0) {
            print('Sound detected: $level');
          }
        },
      );
      print('Listen started successfully - speak now!');
    } catch (e) {
      print('Error starting listening: $e');
      setState(() {
        _isListening = false;
      });
    }
  }

  void _showTypeAnswerDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Type Your Answer'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Type your answer here',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              Navigator.of(context).pop();
              _conversation.add({
                'type': 'user',
                'message': value,
              });
              setState(() {});
              _processAnswer(value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.of(context).pop();
                _conversation.add({
                  'type': 'user',
                  'message': controller.text,
                });
                setState(() {});
                _processAnswer(controller.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TulaiColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  String _capitalizeAnswer(String text) {
    if (text.isEmpty) return text;

    // Capitalize first letter of the entire text
    String result = text[0].toUpperCase() + text.substring(1);

    // Capitalize after sentence endings (. ! ?)
    result = result.replaceAllMapped(
      RegExp(r'([.!?]\s+)([a-z])'),
      (match) => '${match.group(1)}${match.group(2)!.toUpperCase()}',
    );

    return result;
  }

  Future<void> _stopListening() async {
    print('_stopListening called with text: $_lastWords');

    // If already processing (from status callback), don't process again
    if (_isProcessing) {
      print('Already processing, ignoring manual stop');
      await _speechToText.stop();
      setState(() {
        _isListening = false;
      });
      return;
    }

    // Set processing flag to block onResult updates and status callback processing
    _isProcessing = true;

    // Capture answer before clearing and capitalize it
    final answerToProcess = _capitalizeAnswer(_lastWords);

    // Stop speech recognition
    await _speechToText.stop();

    // Clear UI immediately
    setState(() {
      _isListening = false;
      _lastWords = ''; // Clear from display
    });

    // Process the answer
    if (answerToProcess.isNotEmpty) {
      _conversation.add({
        'type': 'user',
        'message': answerToProcess,
      });
      setState(() {});

      await _processAnswer(answerToProcess);
    }

    // Reset processing flag
    _isProcessing = false;
  }

  Future<String> _extractInformationWithAI(
      String question, String field, String userAnswer) async {
    final prompt = '''
You are helping extract specific information from a user's response in a voice enrollment system for ALS (Alternative Learning System) students in the Philippines.

IMPORTANT CONTEXT:
- Users may have varying literacy levels
- Users may respond in Tagalog, English, or mixed (Taglish)
- Users may not understand the question or know the answer
- Speech recognition may produce misspelled or incorrect transcriptions
- Be very sensitive to expressions of uncertainty or lack of knowledge
- Users may ask questions back instead of answering

Question asked: "$question"
Field to extract: $field
User's answer: "$userAnswer"

CRITICAL VALIDATION RULES:

${field == 'fullName' ? '''
FOR FULL NAME (COMPOSITE FIELD):
IMPORTANT: Accept partial information! Extract whatever the user provides and leave empty "" for missing parts.

Extract and return in JSON format with these fields:
{
  "firstName": "first name here (or empty if not clear)",
  "middleName": "middle name (or empty if not provided)",
  "lastName": "last name here (or empty if not clear)",
  "nameExtension": "Jr/Sr/III/etc (or empty if not provided)",
  "missingFields": ["list", "of", "missing", "field", "names"]
}

Examples:
"Juan Dela Cruz" → {"firstName": "Juan", "middleName": "", "lastName": "Dela Cruz", "nameExtension": "", "missingFields": []}
"Maria Santos Reyes" → {"firstName": "Maria", "middleName": "Santos", "lastName": "Reyes", "nameExtension": "", "missingFields": []}
"Pedro" → {"firstName": "Pedro", "middleName": "", "lastName": "", "nameExtension": "", "missingFields": ["lastName"]}
"Garcia Junior" → {"firstName": "", "middleName": "", "lastName": "Garcia", "nameExtension": "Junior", "missingFields": ["firstName"]}

Filipino name patterns:
- Usually: FirstName MiddleName LastName
- Sometimes: FirstName LastName
- May include: Jr, Sr, II, III, IV at the end
- Extract what's available, leave empty "" for not mentioned
- Always include missingFields array listing which required fields (firstName, lastName) are empty

NEVER return UNCLEAR for partial name. Always extract what's provided.
''' : field == 'fatherInfo' ? '''
FOR FATHER INFO (COMPOSITE FIELD):
IMPORTANT: Accept partial information! Extract whatever the user provides and leave empty "" for missing parts.

Extract and return in JSON format with these fields:
{
  "fatherFirstName": "first name (or empty if not provided)",
  "fatherMiddleName": "middle name (or empty if not provided)",
  "fatherLastName": "last name (or empty if not provided)",
  "fatherOccupation": "occupation/job (or empty if not provided)",
  "missingFields": ["list", "of", "missing", "field", "names"]
}

Examples:
"Juan Dela Cruz, construction worker" → {"fatherFirstName": "Juan", "fatherMiddleName": "", "fatherLastName": "Dela Cruz", "fatherOccupation": "Construction Worker", "missingFields": []}
"Pedro Santos, farmer" → {"fatherFirstName": "Pedro", "fatherMiddleName": "", "fatherLastName": "Santos", "fatherOccupation": "Farmer", "missingFields": []}
"Jose Reyes Garcia" → {"fatherFirstName": "Jose", "fatherMiddleName": "Reyes", "fatherLastName": "Garcia", "fatherOccupation": "", "missingFields": ["fatherOccupation"]}
"driver" → {"fatherFirstName": "", "fatherMiddleName": "", "fatherLastName": "", "fatherOccupation": "Driver", "missingFields": ["fatherFirstName", "fatherLastName"]}
"wala" / "none" / "unknown" → {"fatherFirstName": "", "fatherMiddleName": "", "fatherLastName": "", "fatherOccupation": "", "missingFields": []}

NEVER return UNCLEAR for partial father info. Always extract what's provided.
''' : field == 'motherInfo' ? '''
FOR MOTHER INFO (COMPOSITE FIELD):
IMPORTANT: Accept partial information! Extract whatever the user provides and leave empty "" for missing parts.

Extract and return in JSON format with these fields:
{
  "motherFirstName": "first name (or empty if not provided)",
  "motherMiddleName": "middle name (or empty if not provided)",
  "motherLastName": "last name (or empty if not provided)",
  "motherOccupation": "occupation/job (or empty if not provided)",
  "missingFields": ["list", "of", "missing", "field", "names"]
}

Examples:
"Maria Santos Cruz, housewife" → {"motherFirstName": "Maria", "motherMiddleName": "Santos", "motherLastName": "Cruz", "motherOccupation": "Housewife", "missingFields": []}
"Ana Reyes, vendor" → {"motherFirstName": "Ana", "motherMiddleName": "", "motherLastName": "Reyes", "motherOccupation": "Vendor", "missingFields": []}
"Rosa Garcia" → {"motherFirstName": "Rosa", "motherMiddleName": "", "motherLastName": "Garcia", "motherOccupation": "", "missingFields": ["motherOccupation"]}
"teacher" → {"motherFirstName": "", "motherMiddleName": "", "motherLastName": "", "motherOccupation": "Teacher", "missingFields": ["motherFirstName", "motherLastName"]}
"wala" / "none" / "unknown" → {"motherFirstName": "", "motherMiddleName": "", "motherLastName": "", "motherOccupation": "", "missingFields": []}

NEVER return UNCLEAR for partial mother info. Always extract what's provided.
''' : field == 'fullAddress' ? '''
FOR FULL ADDRESS (COMPOSITE FIELD):
IMPORTANT: Accept partial information! Extract whatever the user provides and leave empty "" for missing parts.

ZAMBALES LOCATION CORRECTION:
This system is primarily used in Zambales province. Correct common speech-to-text transcription errors for local place names:

MUNICIPALITIES IN ZAMBALES:
- Olongapo City (common mishearings: "along gapo", "oh long ah po")
- Subic (common mishearings: "subik", "su bik")
- Castillejos (common mishearings: "kastillehos", "castilejos")
- San Antonio (common mishearings: "san antoni", "santonio")
- San Felipe (common mishearings: "san felip", "sanfelipe")
- San Marcelino (common mishearings: "san marselino", "sanmarcelino")
- San Narciso (common mishearings: "san narsiso", "sannarciso")
- Botolan (common mishearings: "botolon", "botolan")
- Cabangan (common mishearings: "kabangan", "cabanggan")
- Iba (common mishearings: "iba", "eeba", "ihba")
- Palauig (common mishearings: "palawig", "palawit")
- Masinloc (common mishearings: "masinlok", "masenloc")
- Candelaria (common mishearings: "kandelaria", "candeleria")
- Santa Cruz (common mishearings: "santacruz", "santa krus")

COMMON BARANGAYS IN ZAMBALES:
Olongapo City:
- Bajac-Bajac (common mishearings: "bahak bahak", "bajak bajak", "bajac bajak", "bahac bahac")
- Barretto (common mishearings: "baretto", "barrett", "bareto")
- East Bajac-Bajac (common mishearings: "east bahak bahak", "east bajak")
- West Bajac-Bajac (common mishearings: "west bahak bahak", "west bajak")
- New Cabalan (common mishearings: "new kabalan", "newcabalan")
- Old Cabalan (common mishearings: "old kabalan", "oldcabalan")
- Asinan Poblacion (common mishearings: "asinan poblasyon", "asinan")
- Kalaklan (common mishearings: "kalaklan", "kalaklan")
- Santa Rita (common mishearings: "santarita", "santa rita")
- Pag-asa (common mishearings: "pagasa", "pag asa")
- Gordon Heights (common mishearings: "gordon heights", "gordon")

Subic:
- Ilwas (common mishearings: "ilwas", "iluas")
- Wawandue (common mishearings: "wawandue", "wawandyu")
- Calapacuan (common mishearings: "kalapakuan", "calapakwan")
- Naugsol (common mishearings: "naugsol", "naogsol")

CORRECTION RULES:
1. When you see "bahak bahak" or similar mishearings → correct to "Bajac-Bajac"
2. When you see "east/west bahak bahak" → correct to "East/West Bajac-Bajac"
3. Always add "Zambales" as province if location is recognized as Zambales municipality/barangay
4. If only barangay mentioned without city, and it's a known Olongapo barangay → add "Olongapo City"

Extract and return in JSON format with these fields:
{
  "houseStreetSitio": "house number, street, or sitio (or empty if not mentioned)",
  "barangay": "barangay name CORRECTED for common mishearings (or empty if not mentioned)",
  "municipalityCity": "city or municipality CORRECTED for mishearings (or empty if not mentioned)",
  "province": "province name - default to Zambales if recognized location (or empty if not mentioned)",
  "missingFields": ["list", "of", "missing", "field", "names"]
}

Examples:
"123 Rizal Street, Bajac-Bajac, Olongapo City, Zambales" → {"houseStreetSitio": "123 Rizal Street", "barangay": "Bajac-Bajac", "municipalityCity": "Olongapo City", "province": "Zambales", "missingFields": []}
"26th street bahak bahak olongapo" → {"houseStreetSitio": "26th Street", "barangay": "Bajac-Bajac", "municipalityCity": "Olongapo City", "province": "Zambales", "missingFields": []}
"barretto subic" → {"houseStreetSitio": "", "barangay": "Barretto", "municipalityCity": "Subic", "province": "Zambales", "missingFields": ["houseStreetSitio"]}
"east bahak bahak" → {"houseStreetSitio": "", "barangay": "East Bajac-Bajac", "municipalityCity": "Olongapo City", "province": "Zambales", "missingFields": ["houseStreetSitio"]}
"gordon heights zambales" → {"houseStreetSitio": "", "barangay": "Gordon Heights", "municipalityCity": "Olongapo City", "province": "Zambales", "missingFields": ["houseStreetSitio"]}

Common patterns to recognize:
- Barangay names often start with: Barangay, Brgy, Brgy., or just the name (like Poblacion, Bajac-Bajac)
- Cities often end with: City, Municipality
- If recognized Zambales location, always set province to "Zambales"
- Street indicators: Street, St., Road, Rd., Avenue, Ave.
- Extract what's available, leave empty "" for not mentioned
- Always include missingFields array listing which fields are empty

NEVER return UNCLEAR for partial address. Always extract what's provided.
''' : '''
1. VERIFY ANSWER TYPE MATCHES FIELD:
   - For lastName/firstName/middleName: Must be a person's name (not a place, date, or number)
     Example MISMATCH: User says "Manila" when asked for last name → "UNCLEAR: I think you gave a place name, but I need your last name. For example, like 'Santos' or 'Reyes'. What is your last name?"
   
   - For barangay: Must be a barangay name (not municipality, province, or person name)
     EXCEPTION: Recognize known Zambales barangays even with transcription errors (e.g., "bahak bahak" = "Bajac-Bajac")
     Example MISMATCH: User says "Juan" when asked for barangay → "UNCLEAR: I think you gave a person's name, but I need your barangay. For example, like 'Poblacion' or 'San Jose'. What barangay do you live in?"
     Example MISMATCH: User says "Olongapo" when asked for barangay → "UNCLEAR: I think you gave a city name, but I need your barangay. For example, like 'Poblacion' or 'San Jose'. What barangay do you live in?"
   
   - For municipality: Must be a city/municipality (not barangay, province, or person name)
     EXCEPTION: Recognize known Zambales municipalities even with transcription errors
     Example MISMATCH: User says "Poblacion" when asked for city → "UNCLEAR: I think you gave a barangay name, but I need your city or municipality. For example, like 'Olongapo City' or 'Manila'. What is yours?"
   
   - For province: Must be a province name (not barangay, municipality, or person name)
     Example MISMATCH: User says "Quezon City" when asked for province → "UNCLEAR: I think you gave a city name, but I need your province. For example, like 'Metro Manila' or 'Cebu'. What province do you live in?"
   
   - For birthdate: Must be a date (not a name or place)
     Example MISMATCH: User says "Santos" when asked for birthdate → "UNCLEAR: I think you gave a name, but I need your birthdate. For example, 'January 1, 2000'. When were you born?"
   
   - For sex: Must be male/female related (not a name, place, or date)
   
   - For contactNumber: Must contain digits (not a name, place, or random words)
     Example MISMATCH: User says "Juan" when asked for phone → "UNCLEAR: I think you gave a name, but I need your phone number. For example, like '0917 123 4567'. What is your contact number?"
'''}

2. CORRECT ZAMBALES LOCATION TRANSCRIPTION ERRORS:
   BEFORE rejecting as unclear, check if the answer matches known Zambales locations with transcription errors:
   
   BARANGAYS (correct these even if they sound garbled):
   - "bahak bahak", "bajak bajak", "bahac bahac", "bajac bajak" → "Bajac-Bajac"
   - "east bahak bahak", "east bajak", "east bahac" → "East Bajac-Bajac"
   - "west bahak bahak", "west bajak", "west bahac" → "West Bajac-Bajac"
   - "barretto", "barrett", "bareto" → "Barretto"
   - "gordon heights", "gordon" → "Gordon Heights"
   - "new cabalan", "kabalan", "newcabalan" → "New Cabalan"
   - "old cabalan", "oldcabalan" → "Old Cabalan"
   - "kalaklan" → "Kalaklan"
   - "santarita", "santa rita" → "Santa Rita"
   - "pagasa", "pag asa" → "Pag-asa"
   
   MUNICIPALITIES:
   - "along gapo", "oh long ah po", "olongapu" → "Olongapo City"
   - "subik", "su bik" → "Subic"
   - "kastillehos", "castilejos" → "Castillejos"
   - "san antoni", "santonio" → "San Antonio"
   - "san felip", "sanfelipe" → "San Felipe"
   - "iba", "eeba", "ihba" → "Iba"
   
   If the answer matches any of these patterns, DO NOT return UNCLEAR. Extract and normalize the location.

3. CHECK FOR OTHER SPEECH RECOGNITION ERRORS:
   - Correct common misspellings and transcription errors for non-location fields
   - Handle Filipino spelling variations (e.g., "Marso" = "March")
   - For unclear/garbled text that doesn't match known patterns, ask for clarification

4. User is asking a question (NOT answering):
   - "what is that" / "ano yun" / "ano yan"
   - "what" / "ano"
   - "why" / "bakit"
   - "how" / "paano"
   - "huh" / "ha"
   - "what do you mean" / "ano ibig sabihin"
   → Provide field-specific explanation with examples

5. User expresses "I don't know" or uncertainty:
   - "hindi ko alam" / "di ko alam" / "I don't know"
   - "wala akong alam" / "hindi ko sure" / "di ko sigurado"
   - "wala" / "ayaw ko sabihin" / "secret"
   → Return: "UNCLEAR: That's okay! You can say 'skip' to move to the next question, or tell me if you remember."

6. User gives very short/vague responses:
   - Single words like "yes", "no", "okay", "oo", "hindi" when specific answer needed
   - Random words unrelated to the question
   → Return: "UNCLEAR: That's okay! You can say 'skip' to move to the next question, or tell me if you remember."

5. User gives very short/vague responses:
   - Single words like "yes", "no", "okay", "oo", "hindi" when specific answer needed
   - Random words unrelated to the question
   → Return: "UNCLEAR: I need a specific answer. Could you please tell me your \$field?"

Extract rules (ONLY if answer is valid and matches field type):
- For lastName/firstName/middleName: Extract just the name part, capitalize properly
- For birthdate: Convert to YYYY-MM-DD format, handle various date formats
- For sex: Return "Male" for (male/lalaki/boy) or "Female" for (female/babae/girl)
- For barangay: Extract barangay name, correct common misspellings
- For municipality: Extract city/municipality name, correct common misspellings
- For province: Extract province name, correct common misspellings
- For contactNumber: Extract digits only, format as 11-digit number

Respond with ONLY the extracted value, JSON for composite fields, or the UNCLEAR message.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _aiModel.generateContent(content);
      final extracted = response.text?.trim() ?? '';
      print('AI extracted: $extracted from "$userAnswer"');
      return extracted;
    } catch (e) {
      print('AI extraction failed: $e');
      return userAnswer; // Fallback to original
    }
  }

  Future<void> _processAnswer(String answer) async {
    final question = _questions[_currentStep];
    final field = question['field'] as String;
    final questionType = question['type'] as String?;
    final questionText = question['question'] as String;

    // Handle greeting - automatically proceed to first question
    if (questionType == 'greeting') {
      // Greeting was already spoken in _askQuestion, just move to next
      setState(() {
        _currentStep++;
        _lastWords = '';
      });

      await Future.delayed(const Duration(milliseconds: 1500));

      if (_currentStep < _questions.length - 1) {
        _askQuestion();
      }
      return;
    }

    // Check for skip BEFORE AI processing
    // But block skip for required fields (lastName and firstName)
    if (answer.toLowerCase().contains('skip') ||
        answer.toLowerCase().contains('laktawan') ||
        answer.toLowerCase().contains('i want to skip')) {
      // Check if this is a required field
      final isRequiredField = (field == 'lastName' || field == 'firstName');

      if (isRequiredField) {
        // Show error message for required fields
        final errorMsg = widget.isFilipino
            ? 'Hindi ka maaaring laktawan ang tanong na ito. Ang iyong ${field == 'lastName' ? 'apelyido' : 'pangalan'} ay kinakailangan. Mangyaring magbigay ng sagot.'
            : 'You cannot skip this question. Your ${field == 'lastName' ? 'last name' : 'first name'} is required. Please provide an answer.';

        _conversation.add({
          'type': 'ai',
          'message': errorMsg,
        });
        setState(() {});
        await _speak(errorMsg);
        return; // Don't proceed, stay on current question
      }

      // For optional fields, allow skip
      _enrollmentData[field] = '';

      String followUp = widget.isFilipino
          ? 'Sige, laktawan ang tanong na ito.'
          : 'Okay, skipping this question.';

      setState(() {
        _currentStep++;
        _lastWords = '';
      });

      _conversation.add({
        'type': 'ai',
        'message': followUp,
      });

      await _speak(followUp);
      await Future.delayed(const Duration(milliseconds: 800));

      if (_currentStep < _questions.length - 1) {
        _askQuestion();
      } else {
        final completeMsg = _questions.last['question'] as String;
        _conversation.add({
          'type': 'ai',
          'message': completeMsg,
        });
        await _speak(completeMsg);
        await Future.delayed(const Duration(seconds: 2));
        _submitEnrollment();
      }
      return;
    }

    // Use AI to extract and validate the answer
    String extractedValue = answer;
    bool needsClarification = false;
    String clarificationMessage = '';

    try {
      extractedValue =
          await _extractInformationWithAI(questionText, field, answer);

      // Check if extraction failed or needs clarification
      if (extractedValue.startsWith('UNCLEAR:')) {
        needsClarification = true;
        clarificationMessage = extractedValue.substring(8);
      } else if (questionType == 'composite') {
        // Handle composite fields (fullName, fullAddress)
        try {
          // Strip markdown code blocks if present
          String cleanedJson = extractedValue;
          if (cleanedJson.contains('```json')) {
            cleanedJson = cleanedJson
                .replaceAll('```json', '')
                .replaceAll('```', '')
                .trim();
          } else if (cleanedJson.contains('```')) {
            cleanedJson = cleanedJson.replaceAll('```', '').trim();
          }

          final jsonData = jsonDecode(cleanedJson);

          if (field == 'fullName') {
            _enrollmentData['firstName'] = jsonData['firstName'] ?? '';
            _enrollmentData['middleName'] = jsonData['middleName'] ?? '';
            _enrollmentData['lastName'] = jsonData['lastName'] ?? '';
            _enrollmentData['nameExtension'] = jsonData['nameExtension'] ?? '';

            // Check for missing required fields
            List<dynamic> missingFields = jsonData['missingFields'] ?? [];

            if (missingFields.isNotEmpty) {
              // Ask for missing fields
              String missingFieldsMsg = '';
              if (missingFields.contains('firstName') &&
                  missingFields.contains('lastName')) {
                missingFieldsMsg = widget.isFilipino
                    ? 'Kailangan ko ng iyong pangalan at apelyido. Ano ang iyong pangalan at apelyido?'
                    : 'I need your first name and last name. What is your first and last name?';
              } else if (missingFields.contains('firstName')) {
                missingFieldsMsg = widget.isFilipino
                    ? 'Salamat! Ano ang iyong pangalan (first name)?'
                    : 'Thank you! What is your first name?';
              } else if (missingFields.contains('lastName')) {
                missingFieldsMsg = widget.isFilipino
                    ? 'Salamat! Ano ang iyong apelyido (last name)?'
                    : 'Thank you! What is your last name?';
              }

              needsClarification = true;
              clarificationMessage = missingFieldsMsg;
            } else {
              // Build display name
              String displayName =
                  '${jsonData['firstName']} ${jsonData['lastName']}';
              if (jsonData['middleName']?.isNotEmpty == true) {
                displayName =
                    '${jsonData['firstName']} ${jsonData['middleName']} ${jsonData['lastName']}';
              }
              if (jsonData['nameExtension']?.isNotEmpty == true) {
                displayName += ' ${jsonData['nameExtension']}';
              }
              extractedValue = displayName;
            }
          } else if (field == 'fullAddress') {
            _enrollmentData['houseStreetSitio'] =
                jsonData['houseStreetSitio'] ?? '';
            _enrollmentData['barangay'] = jsonData['barangay'] ?? '';
            _enrollmentData['municipalityCity'] =
                jsonData['municipalityCity'] ?? '';
            _enrollmentData['province'] = jsonData['province'] ?? '';

            // Check for missing fields
            List<dynamic> missingFields = jsonData['missingFields'] ?? [];

            if (missingFields.isNotEmpty) {
              // Ask for the first missing field
              String missingFieldMsg = '';
              if (missingFields.contains('barangay')) {
                missingFieldMsg = widget.isFilipino
                    ? 'Salamat! Ano ang barangay mo?'
                    : 'Thank you! What barangay do you live in?';
              } else if (missingFields.contains('municipalityCity')) {
                missingFieldMsg = widget.isFilipino
                    ? 'Salamat! Sa anong lungsod o bayan ka nakatira?'
                    : 'Thank you! What city or municipality do you live in?';
              } else if (missingFields.contains('province')) {
                missingFieldMsg = widget.isFilipino
                    ? 'Salamat! Anong lalawigan?'
                    : 'Thank you! What province?';
              } else if (missingFields.contains('houseStreetSitio')) {
                missingFieldMsg = widget.isFilipino
                    ? 'Salamat! Ano ang numero ng bahay o kalye mo?'
                    : 'Thank you! What is your house number or street?';
              }

              needsClarification = true;
              clarificationMessage = missingFieldMsg;
            } else {
              // Build display address
              List<String> addressParts = [];
              if (jsonData['houseStreetSitio']?.isNotEmpty == true)
                addressParts.add(jsonData['houseStreetSitio']);
              if (jsonData['barangay']?.isNotEmpty == true)
                addressParts.add(jsonData['barangay']);
              if (jsonData['municipalityCity']?.isNotEmpty == true)
                addressParts.add(jsonData['municipalityCity']);
              if (jsonData['province']?.isNotEmpty == true)
                addressParts.add(jsonData['province']);
              extractedValue = addressParts.join(', ');
            }
          } else if (field == 'fatherInfo') {
            _enrollmentData['fatherFirstName'] =
                jsonData['fatherFirstName'] ?? '';
            _enrollmentData['fatherMiddleName'] =
                jsonData['fatherMiddleName'] ?? '';
            _enrollmentData['fatherLastName'] =
                jsonData['fatherLastName'] ?? '';
            _enrollmentData['fatherOccupation'] =
                jsonData['fatherOccupation'] ?? '';

            List<dynamic> missingFields = jsonData['missingFields'] ?? [];

            // For optional parent fields, don't ask follow-ups if user said "wala"/"none"
            bool hasAnyData =
                (jsonData['fatherFirstName']?.isNotEmpty == true ||
                    jsonData['fatherLastName']?.isNotEmpty == true ||
                    jsonData['fatherOccupation']?.isNotEmpty == true);

            if (missingFields.isNotEmpty && hasAnyData) {
              String missingFieldMsg = '';
              if (missingFields.contains('fatherFirstName')) {
                missingFieldMsg = widget.isFilipino
                    ? 'Salamat! Ano ang pangalan ng iyong ama?'
                    : 'Thank you! What is your father\'s first name?';
              } else if (missingFields.contains('fatherLastName')) {
                missingFieldMsg = widget.isFilipino
                    ? 'Salamat! Ano ang apelyido ng iyong ama?'
                    : 'Thank you! What is your father\'s last name?';
              } else if (missingFields.contains('fatherOccupation')) {
                missingFieldMsg = widget.isFilipino
                    ? 'Salamat! Ano ang trabaho ng iyong ama?'
                    : 'Thank you! What is your father\'s occupation?';
              }

              needsClarification = true;
              clarificationMessage = missingFieldMsg;
            } else {
              // Build display text
              List<String> infoParts = [];
              if (jsonData['fatherFirstName']?.isNotEmpty == true)
                infoParts.add(jsonData['fatherFirstName']);
              if (jsonData['fatherMiddleName']?.isNotEmpty == true)
                infoParts.add(jsonData['fatherMiddleName']);
              if (jsonData['fatherLastName']?.isNotEmpty == true)
                infoParts.add(jsonData['fatherLastName']);
              if (jsonData['fatherOccupation']?.isNotEmpty == true)
                infoParts.add('(${jsonData['fatherOccupation']})');
              extractedValue =
                  infoParts.isNotEmpty ? infoParts.join(' ') : 'Not provided';
            }
          } else if (field == 'motherInfo') {
            _enrollmentData['motherFirstName'] =
                jsonData['motherFirstName'] ?? '';
            _enrollmentData['motherMiddleName'] =
                jsonData['motherMiddleName'] ?? '';
            _enrollmentData['motherLastName'] =
                jsonData['motherLastName'] ?? '';
            _enrollmentData['motherOccupation'] =
                jsonData['motherOccupation'] ?? '';

            List<dynamic> missingFields = jsonData['missingFields'] ?? [];

            // For optional parent fields, don't ask follow-ups if user said "wala"/"none"
            bool hasAnyData =
                (jsonData['motherFirstName']?.isNotEmpty == true ||
                    jsonData['motherLastName']?.isNotEmpty == true ||
                    jsonData['motherOccupation']?.isNotEmpty == true);

            if (missingFields.isNotEmpty && hasAnyData) {
              String missingFieldMsg = '';
              if (missingFields.contains('motherFirstName')) {
                missingFieldMsg = widget.isFilipino
                    ? 'Salamat! Ano ang pangalan ng iyong ina?'
                    : 'Thank you! What is your mother\'s first name?';
              } else if (missingFields.contains('motherLastName')) {
                missingFieldMsg = widget.isFilipino
                    ? 'Salamat! Ano ang apelyido ng iyong ina?'
                    : 'Thank you! What is your mother\'s last name?';
              } else if (missingFields.contains('motherOccupation')) {
                missingFieldMsg = widget.isFilipino
                    ? 'Salamat! Ano ang trabaho ng iyong ina?'
                    : 'Thank you! What is your mother\'s occupation?';
              }

              needsClarification = true;
              clarificationMessage = missingFieldMsg;
            } else {
              // Build display text
              List<String> infoParts = [];
              if (jsonData['motherFirstName']?.isNotEmpty == true)
                infoParts.add(jsonData['motherFirstName']);
              if (jsonData['motherMiddleName']?.isNotEmpty == true)
                infoParts.add(jsonData['motherMiddleName']);
              if (jsonData['motherLastName']?.isNotEmpty == true)
                infoParts.add(jsonData['motherLastName']);
              if (jsonData['motherOccupation']?.isNotEmpty == true)
                infoParts.add('(${jsonData['motherOccupation']})');
              extractedValue =
                  infoParts.isNotEmpty ? infoParts.join(' ') : 'Not provided';
            }
          }
        } catch (e) {
          print('Failed to parse composite field JSON: $e');
          needsClarification = true;
          clarificationMessage = widget.isFilipino
              ? 'Hindi ko lubos na naintindihan ang iyong sagot. Pwede mo bang ulitin?'
              : 'I didn\'t fully understand your answer. Could you please repeat that?';
        }
      }
    } catch (e) {
      print('AI extraction error: $e');
      // Fallback to original answer if AI fails
      extractedValue = answer;
    }

    // If answer is unclear, ask for clarification
    if (needsClarification) {
      _conversation.add({
        'type': 'ai',
        'message': clarificationMessage,
      });
      setState(() {});
      await _speak(clarificationMessage);
      return; // Don't advance, wait for better answer
    }

    // Handle skip/none for optional questions
    if (question['optional'] == true &&
        (answer.toLowerCase().contains('skip') ||
            answer.toLowerCase().contains('none') ||
            answer.toLowerCase().contains('no') ||
            extractedValue.toLowerCase() == 'skip')) {
      _enrollmentData[field] = '';
      extractedValue = 'skipped';
    } else if (questionType != 'composite') {
      // Only store for non-composite fields (composite already stored above)
      _enrollmentData[field] = extractedValue;
    }

    // Give contextual feedback
    String followUp = question['followUp'] as String? ?? 'Thank you.';
    followUp = followUp.replaceAll('{value}', extractedValue);

    setState(() {
      _currentStep++;
      _lastWords = '';
    });

    _conversation.add({
      'type': 'ai',
      'message': followUp,
    });

    await _speak(followUp);

    // Small delay before next question
    await Future.delayed(const Duration(milliseconds: 800));

    if (_currentStep < _questions.length - 1) {
      _askQuestion();
    } else {
      // Final completion message
      final completeMsg = _questions.last['question'] as String;
      _conversation.add({
        'type': 'ai',
        'message': completeMsg,
      });
      await _speak(completeMsg);
      await Future.delayed(const Duration(seconds: 2));
      _submitEnrollment();
    }
  }

  Future<void> _submitEnrollment() async {
    try {
      final supabase = Supabase.instance.client;

      // Fetch active batch
      final batchResponse = await supabase
          .from('batches')
          .select('id')
          .eq('is_active', true)
          .single();
      final batchId = batchResponse['id'];

      // Prepare submission data for pending_submissions table
      final submissionData = {
        'last_name': _enrollmentData['lastName'],
        'first_name': _enrollmentData['firstName'],
        'middle_name': _enrollmentData['middleName'],
        'name_extension': _enrollmentData['nameExtension'],
        'house_street_sitio': _enrollmentData['houseStreetSitio'],
        'barangay': _enrollmentData['barangay'],
        'municipality_city': _enrollmentData['municipalityCity'],
        'province': _enrollmentData['province'],
        'birthdate': _enrollmentData['birthdate'],
        'sex': _enrollmentData['sex'],
        'place_of_birth': _enrollmentData['placeOfBirth'],
        'civil_status': _enrollmentData['civilStatus'],
        'religion': _enrollmentData['religion'],
        'ethnic_group': _enrollmentData['ethnicGroup'],
        'mother_tongue': _enrollmentData['motherTongue'],
        'contact_number': _enrollmentData['contactNumber'],
        'is_pwd': _enrollmentData['isPWD']?.toLowerCase() == 'yes' ||
            _enrollmentData['isPWD']?.toLowerCase() == 'oo',
        'father_last_name': _enrollmentData['fatherLastName'],
        'father_first_name': _enrollmentData['fatherFirstName'],
        'father_middle_name': _enrollmentData['fatherMiddleName'],
        'father_occupation': _enrollmentData['fatherOccupation'],
        'mother_last_name': _enrollmentData['motherLastName'],
        'mother_first_name': _enrollmentData['motherFirstName'],
        'mother_middle_name': _enrollmentData['motherMiddleName'],
        'mother_occupation': _enrollmentData['motherOccupation'],
        'last_school_attended': _enrollmentData['lastSchoolAttended'],
        'last_grade_level_completed':
            _enrollmentData['lastGradeLevelCompleted'],
        'reason_for_incomplete_schooling':
            _enrollmentData['reasonForIncompleteSchooling'],
        'has_attended_als':
            _enrollmentData['hasAttendedALS']?.toLowerCase() == 'yes' ||
                _enrollmentData['hasAttendedALS']?.toLowerCase() == 'oo',
        'submitted_at': DateTime.now().toIso8601String(),
        'batch_id': batchId,
      };

      // Insert into pending_submissions
      await supabase.from('pending_submissions').insert(submissionData);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const EnrollmentWaiting(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: TulaiColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TulaiColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: TulaiColors.primary,
        elevation: 0,
        title: Text(
          'Voice Enrollment',
          style: TulaiTextStyles.heading3.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TulaiSpacing.lg),
          child: Column(
            children: [
              // Progress indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TulaiSpacing.md,
                  vertical: TulaiSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: TulaiColors.backgroundPrimary,
                  borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
                  boxShadow: TulaiShadows.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: _currentStep / _questions.length,
                        backgroundColor: TulaiColors.borderLight,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(TulaiColors.primary),
                      ),
                    ),
                    const SizedBox(width: TulaiSpacing.md),
                    Text(
                      'Step ${_currentStep + 1}/${_questions.length}',
                      style: TulaiTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TulaiSpacing.lg),

              // Conversation history
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: TulaiColors.backgroundPrimary,
                    borderRadius: BorderRadius.circular(TulaiBorderRadius.lg),
                    boxShadow: TulaiShadows.md,
                  ),
                  child: Column(
                    children: [
                      // AI Avatar/Status Header
                      Container(
                        padding: const EdgeInsets.all(TulaiSpacing.md),
                        decoration: BoxDecoration(
                          color: TulaiColors.primary.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(TulaiBorderRadius.lg),
                            topRight: Radius.circular(TulaiBorderRadius.lg),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Animated Tulai Avatar with pulsing effect when speaking
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer pulsing ring when speaking
                                if (_isSpeaking)
                                  AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (context, child) {
                                      return Container(
                                        width: 70 * _pulseAnimation.value,
                                        height: 70 * _pulseAnimation.value,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: TulaiColors.primary
                                                .withValues(alpha: 0.3),
                                            width: 2,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                // Avatar circle
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 60,
                                  height: 60,
                                  padding:
                                      const EdgeInsets.all(TulaiSpacing.sm),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: _isSpeaking
                                          ? [
                                              TulaiColors.primary,
                                              TulaiColors.secondary
                                            ]
                                          : [
                                              TulaiColors.backgroundPrimary,
                                              TulaiColors.backgroundPrimary
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: TulaiColors.primary,
                                      width: 3,
                                    ),
                                    boxShadow: _isSpeaking
                                        ? [
                                            BoxShadow(
                                              color: TulaiColors.primary
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 12,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Icon(
                                    _isSpeaking
                                        ? Icons.face_retouching_natural
                                        : Icons.face,
                                    size: 32,
                                    color: _isSpeaking
                                        ? Colors.white
                                        : TulaiColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: TulaiSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tulai',
                                    style: TulaiTextStyles.heading3.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: TulaiColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Your AI Enrollment Assistant',
                                    style: TulaiTextStyles.bodySmall.copyWith(
                                      color: TulaiColors.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: _isSpeaking
                                              ? TulaiColors.success
                                              : _isListening
                                                  ? TulaiColors.warning
                                                  : TulaiColors.textMuted,
                                          shape: BoxShape.circle,
                                          boxShadow: _isSpeaking || _isListening
                                              ? [
                                                  BoxShadow(
                                                    color: (_isSpeaking
                                                            ? TulaiColors
                                                                .success
                                                            : TulaiColors
                                                                .warning)
                                                        .withValues(alpha: 0.5),
                                                    blurRadius: 8,
                                                    spreadRadius: 1,
                                                  ),
                                                ]
                                              : [],
                                        ),
                                      ),
                                      const SizedBox(width: TulaiSpacing.xs),
                                      Text(
                                        _isSpeaking
                                            ? 'Speaking...'
                                            : _isListening
                                                ? 'Listening...'
                                                : 'Ready',
                                        style:
                                            TulaiTextStyles.bodyMedium.copyWith(
                                          color: _isSpeaking
                                              ? TulaiColors.success
                                              : _isListening
                                                  ? TulaiColors.warning
                                                  : TulaiColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Conversation messages
                      Expanded(
                        child: _conversation.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.mic_none,
                                      size: 64,
                                      color: TulaiColors.textSecondary
                                          .withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: TulaiSpacing.md),
                                    Text(
                                      'Initializing...',
                                      style: TulaiTextStyles.bodyLarge.copyWith(
                                        color: TulaiColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(TulaiSpacing.md),
                                itemCount: _conversation.length,
                                itemBuilder: (context, index) {
                                  final message = _conversation[index];
                                  final isAI = message['type'] == 'ai';

                                  return Align(
                                    alignment: isAI
                                        ? Alignment.centerLeft
                                        : Alignment.centerRight,
                                    child: Container(
                                      margin: const EdgeInsets.only(
                                        bottom: TulaiSpacing.md,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: TulaiSpacing.md,
                                        vertical: TulaiSpacing.sm,
                                      ),
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                0.7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isAI
                                            ? TulaiColors.primary
                                                .withValues(alpha: 0.1)
                                            : TulaiColors.primary,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(
                                              TulaiBorderRadius.md),
                                          topRight: const Radius.circular(
                                              TulaiBorderRadius.md),
                                          bottomLeft: Radius.circular(
                                            isAI ? 0 : TulaiBorderRadius.md,
                                          ),
                                          bottomRight: Radius.circular(
                                            isAI ? TulaiBorderRadius.md : 0,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        message['message']!,
                                        style:
                                            TulaiTextStyles.bodyMedium.copyWith(
                                          color: isAI
                                              ? TulaiColors.textPrimary
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),

                      // Current user input (while listening)
                      if (_isListening && _lastWords.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(TulaiSpacing.md),
                          decoration: BoxDecoration(
                            color: TulaiColors.backgroundSecondary,
                            border: Border(
                              top: BorderSide(
                                color: TulaiColors.borderLight,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.mic,
                                color: TulaiColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: TulaiSpacing.sm),
                              Expanded(
                                child: Text(
                                  _lastWords,
                                  style: TulaiTextStyles.bodyMedium.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: TulaiColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: TulaiSpacing.lg),

              // Control buttons
              if (!_isSpeaking)
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_isListening)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _startListening,
                              icon: const Icon(Icons.mic),
                              label: const Text('Tap to Speak'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TulaiColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: TulaiSpacing.md,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      TulaiBorderRadius.md),
                                ),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _stopListening,
                              icon: const Icon(Icons.stop_circle),
                              label: const Text('Stop & Confirm'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TulaiColors.error,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: TulaiSpacing.md,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      TulaiBorderRadius.md),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: TulaiSpacing.sm),
                    TextButton.icon(
                      onPressed: _showTypeAnswerDialog,
                      icon: const Icon(Icons.keyboard),
                      label: const Text('Type Instead'),
                      style: TextButton.styleFrom(
                        foregroundColor: TulaiColors.primary,
                      ),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: TulaiSpacing.md,
                    horizontal: TulaiSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    color: TulaiColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            TulaiColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: TulaiSpacing.md),
                      Text(
                        'AI is speaking...',
                        style: TulaiTextStyles.bodyMedium.copyWith(
                          color: TulaiColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speechToText.stop();
    _flutterTts.stop();
    super.dispose();
  }
}

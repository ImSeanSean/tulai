import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:tulai/services/gemini.dart';

class AiAssistantService {
  final SpeechToText _speechToText = SpeechToText();
  final List<Map<String, String>> _chatHistory = [];

  // Context for the AI assistant
  static const String _contextPrompt = '''
You are Tulai, an AI-powered assistant for the ALS Enrollment System. This app helps users enroll in the Alternative Learning System (ALS) by guiding them through the enrollment process step-by-step. Many users may not be digitally literate, so always provide clear, simple, and friendly instructions.

When a user asks how to use the app, explain that:
- The app will ask for their information step-by-step.
- They can answer by typing or by speaking using the microphone.
- Tulai will help them understand each question and what to do next.
- If they need help at any time, they can ask Tulai for assistance.

Always use speech-to-text and AI to provide concise, easy-to-understand answers about the enrollment process. Be friendly, helpful, and patient.
''';

  // Get chat history
  List<Map<String, String>> get chatHistory => List.unmodifiable(_chatHistory);

  // Add a message to chat history
  void addMessage(String role, String message) {
    _chatHistory.add({'role': role, 'message': message});
  }

  // Get AI response using Gemini, always prepending the context to the first message
  Future<String> getAiResponse(String prompt) async {
    String fullPrompt = prompt;
    if (_chatHistory.where((m) => m['role'] == 'user').length <= 1) {
      fullPrompt = '$_contextPrompt\n$prompt';
    }
    final response = await model.generateContent([
      Content.text(fullPrompt),
    ]);
    final aiText = response.text ?? '';
    addMessage('assistant', aiText);
    return aiText;
  }

  // --- Speech to Text Methods ---

  Future<bool> initSpeech() async {
    return await _speechToText.initialize();
  }

  Future<void> startListening(Function(String) onResult) async {
    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
        }
      },
    );
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  bool get isListening => _speechToText.isListening;

  Future<String> sendMessage(String message) async {
    addMessage('user', message);
    final response = await getAiResponse(message);
    return response;
  }
}

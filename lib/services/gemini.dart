// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final model = GenerativeModel(
    model: "gemma-3-12b-it", apiKey: dotenv.env['GEMINI_API_KEY']!);

class NameFieldResult {
  final List<String>? suggestions;
  final String? error;

  NameFieldResult({this.suggestions, this.error});

  bool get hasError => error != null;
}

Future<NameFieldResult> handleNameField(
    String question, String userAnswer) async {
  const instruction = '''
You are processing a name field in a speech-to-text enrollment form. Your task:

1. If the user’s answer is ambiguous or may contain transcription errors, generate 3–5 distinct corrected versions of the name, accounting for common errors like reversed order or misunderstood pronunciation.

2. If the user’s answer is already clear and unambiguous, return only one properly capitalized corrected version.

3. Capitalize names properly (first letters uppercase, others lowercase).

4. If the response appears unrelated (address, date, school name), return an error JSON:
{"error": {"message": "That seems like a [type], but we’re asking for a name."}}
''';

  final expectedComponent = () {
    final lower = question.toLowerCase();
    if (lower.contains("first")) return "first name";
    if (lower.contains("last")) return "last name";
    if (lower.contains("middle")) return "middle name";
    if (lower.contains("extension")) return "name extension";
    return "name";
  }();

  final prompt = '''
Form field: "$question"
Expected component: $expectedComponent
Transcribed user answer: "$userAnswer"
''';

  final content = [
    Content.text(instruction),
    Content.text(prompt),
  ];

  print(prompt);

  final response = await model.generateContent(content);
  String? rawText = response.text;

  // Strip code block markers
  if (rawText != null && rawText.startsWith("```")) {
    final codeBlockRegex = RegExp(r"```(?:json)?\s*([\s\S]*?)\s*```");
    final match = codeBlockRegex.firstMatch(rawText);
    if (match != null) {
      rawText = match.group(1);
    }
  }

  try {
    final dynamic jsonResponse = jsonDecode(rawText!);

    if (jsonResponse is List) {
      return NameFieldResult(suggestions: jsonResponse.cast<String>());
    } else if (jsonResponse is Map && jsonResponse.containsKey("error")) {
      final errorMessage = jsonResponse["error"]["message"] ?? "Unknown error";
      print("Model returned an error: $errorMessage");
      return NameFieldResult(error: errorMessage);
    } else {
      print("Unexpected JSON response format: $rawText");
      return NameFieldResult(error: "Unexpected response format.");
    }
  } catch (e) {
    print("Failed to parse response: $rawText");
    return NameFieldResult(error: "Failed to process model response.");
  }
}

Future<List<String>> handleAddressField(
    String question, String userAnswer) async {
  const instruction = '''
You are processing a Philippine address field in an enrollment form. The form may ask for a specific component like:

- **Barangay** (e.g., "Barangay San Juan")
- **Municipality/City** (e.g., "Olongapo City", "San Fernando")
- **Province** (e.g., "Zambales", "Pampanga")
- **Street or Sitio** (e.g., "Sitio Tagpos", "Purok 3, Mabini Street")

Your task:
1. Generate 3–5 possible corrected transcriptions for the input.
2. Identify if the response mismatches the expected address level. For example:
   - User gave a **barangay**, but the question is asking for **municipality**
   - User gave a **province**, but the question is asking for **street**

If mismatched, respond with:
{"error": {"message": "It seems you gave a [actual component], but we’re asking for your [expected component]."}}

Otherwise, return an array like:
["Barangay San Juan", "Brgy. San Juan", "San Juan Barangay", ...]

Assume common speech-to-text errors, such as:
- "Brgy" vs "Barangay"
- Wrong word order
- Misheard local place names
''';

  final expectedComponent = () {
    final q = question.toLowerCase();
    if (q.contains("barangay")) return "barangay";
    if (q.contains("municipality") || q.contains("city")) {
      return "municipality or city";
    }
    if (q.contains("province")) return "province";
    if (q.contains("street") || q.contains("sitio") || q.contains("house")) {
      return "street or sitio";
    }
    return "address component";
  }();

  final prompt = '''
Current form field: "$question"
Expected address component: $expectedComponent
Transcribed user answer: "$userAnswer"
''';

  final content = [
    Content.text(instruction),
    Content.text(prompt),
  ];

  print(prompt);

  final response = await model.generateContent(content);
  String? rawText = response.text;

  // Strip code block markers
  if (rawText != null && rawText.startsWith("```")) {
    final codeBlockRegex = RegExp(r"```(?:json)?\s*([\s\S]*?)\s*```");
    final match = codeBlockRegex.firstMatch(rawText);
    if (match != null) {
      rawText = match.group(1);
    }
  }

  try {
    final dynamic jsonResponse = jsonDecode(rawText!);
    if (jsonResponse is List) {
      return (jsonResponse).cast<String>();
    } else if (jsonResponse is Map && jsonResponse.containsKey("error")) {
      print("Model returned an error: ${jsonResponse["error"]}");
      return [];
    } else {
      print("Unexpected JSON response format: $rawText");
      return [];
    }
  } catch (e) {
    print("Failed to parse response: $rawText");
    return [];
  }
}

Future<List<String>> handleEducationalInformationField(
    String question, String userAnswer) async {
  const instruction = '''
You are processing a Philippine enrollment form that asks for educational background. The form field may be one of the following:

- **Last School Attended** (e.g., "Gordon College", "San Juan High School")
- **Last grade level completed** (e.g., "Grade 10", "Senior High", "First Year College")
- **Reason for not completing school** (e.g., "financial problems", "family matters")
- **Attendance in ALS learning sessions** (e.g., "Yes", "No")

Your task:
1. Based on the current field, generate 3–5 likely corrected versions of the user's answer. Account for speech-to-text errors.
2. If the answer clearly belongs to another field (e.g., says "Grade 12" when the question is about school name), return:

{"error": {"message": "It seems you gave a [actual component], but we’re asking for your [expected component]."}}

Typical speech-to-text mistakes:
- Misheard school names (e.g., “San Juan” → “Saint John”)
- Answers being too short or generic
- Transcribing "yes" as "guess", or "no" as "know"

Only return corrected interpretations if the answer reasonably fits the current question.
''';

  final prompt =
      "Current form field: '$question'. Transcribed answer: '$userAnswer'.";

  final content = [
    Content.text(instruction),
    Content.text(prompt),
  ];

  print(prompt);

  final response = await model.generateContent(content);
  String? rawText = response.text;

  // Remove markdown/code block formatting if present
  if (rawText != null && rawText.startsWith("```")) {
    final codeBlockRegex = RegExp(r"```(?:json)?\s*([\s\S]*?)\s*```");
    final match = codeBlockRegex.firstMatch(rawText);
    if (match != null) {
      rawText = match.group(1);
    }
  }

  try {
    final dynamic jsonResponse = jsonDecode(rawText!);
    if (jsonResponse is List) {
      return (jsonResponse).cast<String>();
    } else if (jsonResponse is Map && jsonResponse.containsKey("error")) {
      print("Model returned an error: ${jsonResponse["error"]}");
      return [];
    } else {
      print("Unexpected JSON response format: $rawText");
      return [];
    }
  } catch (e) {
    print("Failed to parse response: $rawText");
    return [];
  }
}

Future<List<String>> handleOtherField(
    String question, String userAnswer) async {
  const instruction = '''
You are processing one of several common personal information fields in a Philippine enrollment form. The form may ask for one of the following:

- **Birthdate** (e.g., "05/23/2001", "May 23, 2001")
- **Sex** (e.g., "Male", "Female")
- **Place of Birth** (e.g., "Olongapo City", "Quezon City")
- **Civil Status** (e.g., "Single", "Married", "Widow")
- **Religion** (e.g., "Catholic", "Iglesia ni Cristo", "None")
- **Indigenous group (IP)** (e.g., "Aeta", "Tagbanwa", or "None")
- **Mother Tongue** (e.g., "Tagalog", "Kapampangan", "Ilocano")
- **Contact Number/s** (e.g., "09123456789", "09561234567")
- **PWD status** (Yes or No)

Your job is to:
1. Detect if the user's answer fits the expected type for that field.
2. Return 3–5 plausible corrected versions of the answer, accounting for speech-to-text errors, formatting issues, or capitalization.
3. If the user’s answer clearly belongs to a different type (e.g., says “Catholic” when the form asks for a contact number), respond with:

{"error": {"message": "It seems you gave a [actual type], but we’re asking for your [expected type]."}}

Typical mistakes:
- Saying “May twenty three two thousand one” → should be "05/23/2001"
- Saying a phone number but it’s misheard
- Saying a name instead of a location

Be strict but helpful. All answers should be plausible transcriptions or valid corrections.
''';

  final prompt =
      "Current form field: '$question'. Transcribed answer: '$userAnswer'.";

  final content = [
    Content.text(instruction),
    Content.text(prompt),
  ];

  print(prompt);

  final response = await model.generateContent(content);
  String? rawText = response.text;

  // Remove markdown/code block formatting if present
  if (rawText != null && rawText.startsWith("```")) {
    final codeBlockRegex = RegExp(r"```(?:json)?\s*([\s\S]*?)\s*```");
    final match = codeBlockRegex.firstMatch(rawText);
    if (match != null) {
      rawText = match.group(1);
    }
  }

  try {
    final dynamic jsonResponse = jsonDecode(rawText!);
    if (jsonResponse is List) {
      return (jsonResponse).cast<String>();
    } else if (jsonResponse is Map && jsonResponse.containsKey("error")) {
      print("Model returned an error: ${jsonResponse["error"]}");
      return [];
    } else {
      print("Unexpected JSON response format: $rawText");
      return [];
    }
  } catch (e) {
    print("Failed to parse response: $rawText");
    return [];
  }
}

//Response for Inquiries

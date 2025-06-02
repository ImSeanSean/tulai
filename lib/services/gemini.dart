import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final model = GenerativeModel(
    model: "gemini-2.0-flash", apiKey: dotenv.env['GEMINI_API_KEY']!);

//Response for Form Inputs
Future<List<String>> handleNameField(String question, String userAnswer) async {
  const instruction = '''
You are processing a name field in a speech-to-text enrollment form.

Return a JSON array (3–5 items) of likely corrected versions of the user's spoken name. Consider:
- common transcription issues (e.g., "Alberto" → "Albert"),
- misunderstood pronunciation or missing parts.

⚠️ Strict format:
- Do NOT include explanations or extra text.
- Respond only with a valid JSON array of strings.

If the input is clearly unrelated (like an address, date, or school name), respond with:

{
  "error": {
    "message": "That seems like a [type], but we’re asking for a name."
  }
}
''';

  final prompt = "Form field: '$question'. Transcribed answer: '$userAnswer'.";

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

  final prompt =
      "Current form field: '$question'. Transcribed answer: '$userAnswer'.";

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
You are processing an educational background field in a Philippine enrollment form. The form may ask for components like:

- **School name** (e.g., "Gordon College", "San Juan National High School")
- **Educational level** (e.g., "Senior High", "College", "Vocational")
- **Course or strand** (e.g., "BSIT", "STEM", "HUMSS")
- **Year graduated** (e.g., "2020", "2023")

Your task:
1. Generate 3–5 likely corrected transcriptions of the user's answer.
2. If the user gave an answer that clearly matches a *different* field (e.g., "2022" when the question asks for a school name), return:

{"error": {"message": "It seems you gave a [actual component], but we’re asking for your [expected component]."}}

Common speech-to-text mistakes:
- Misheard acronyms ("BSIT" as "B S I T" or "Business IT")
- Dates being transcribed as words
- Swapped order of words (e.g., "High School San Juan" instead of "San Juan High School")
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

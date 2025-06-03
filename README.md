# Tulai – ALS Enrollment System

Tulai is a Flutter-based enrollment system for the Philippine Alternative Learning System (ALS).  
It features an AI-powered assistant named **Tulai** that helps users—especially those who are not digitally literate—navigate and complete the enrollment process with ease.

## Features

- **AI Assistant (Tulai):**  
  Provides clear, concise, and friendly answers to user questions about the enrollment process.
- **Speech-to-Text:**  
  Users can answer questions or interact with the app using their voice, making it accessible for those with limited typing skills.
- **Step-by-Step Guidance:**  
  The app guides users through each section of the enrollment form, including personal information, address, guardian details, and educational background.
- **Multi-language Support:**  
  Supports both English and Filipino for questions and section titles.
- **Secure Data Handling:**  
  Sensitive information is kept out of version control via `.env` and best practices.

## Getting Started

1. **Clone the repository:**

   ```sh
   git clone https://github.com/ImSeanSean/tulai.git
   cd tulai
   ```

2. **Install dependencies:**

   ```sh
   flutter pub get
   ```

3. **Set up your environment variables:**  
   Create a `.env` file in the project root with your Supabase and Gemini API keys:

   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   GEMINI_API_KEY=your_gemini_api_key
   ```

4. **Run the app:**
   ```sh
   flutter run
   ```

## Project Structure

- `lib/`
  - `components/` – UI components (including the AI assistant modal)
  - `core/` – App configuration and constants
  - `screens/` – Main app screens (enrollment, review, success, etc.)
  - `services/` – API, AI, and database service classes

## Technologies Used

- [Flutter](https://flutter.dev/)
- [Supabase](https://supabase.com/) (for backend/database)
- [Google Gemini](https://ai.google.dev/) (for AI assistant)
- [speech_to_text](https://pub.dev/packages/speech_to_text) (for voice input)

**Tulai** makes ALS enrollment accessible for everyone, with the power of AI and voice technology.

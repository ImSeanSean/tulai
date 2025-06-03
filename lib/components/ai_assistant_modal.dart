import 'package:flutter/material.dart';
import 'package:tulai/core/app_config.dart';
import 'package:tulai/services/ai_asssistance_service.dart';

class AiAssistantModal extends StatefulWidget {
  const AiAssistantModal({super.key});

  @override
  State<AiAssistantModal> createState() => _AiAssistantModalState();
}

class _AiAssistantModalState extends State<AiAssistantModal> {
  final TextEditingController _controller = TextEditingController();
  final AiAssistantService _aiService = AiAssistantService();
  final ScrollController _scrollController = ScrollController();
  bool _isListening = false;

  @override
  void dispose() {
    _aiService.stopListening();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _handleMic() async {
    if (_isListening) {
      await _aiService.stopListening();
      setState(() => _isListening = false);
    } else {
      await _aiService.initSpeech();
      await _aiService.startListening((text) async {
        setState(() {
          _isListening = false;
        });
        await _aiService.sendMessage(text);
        setState(() {});
        _scrollToBottom();
        await Future.delayed(const Duration(milliseconds: 100));
        _scrollToBottom();
      });
      setState(() => _isListening = true);
    }
  }

  // Add this to your send button if you have one:
  void _handleSend() async {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      _controller.clear();
      await _aiService.sendMessage(text);
      setState(() {});
      _scrollToBottom();
      // Wait a short moment to ensure the AI response is added, then scroll again
      await Future.delayed(const Duration(milliseconds: 100));
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive sizing
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double modalWidth = screenWidth * 0.6;
    final double modalMaxHeight = screenHeight * 0.7;

    // Determine the introduction message based on the selected language
    final FormLanguage? lang = AppConfig().formLanguage;
    final String intro = (lang == FormLanguage.filipino)
        ? 'Hello, ako si Tulai. Tutulungan kita sa iyong pagsagot. Maaari mong gamitin ang keyboard upang i-type ang iyong mensahe o magsalita sa pamamagitan ng mikropono.'
        : 'Hello, I am Tulai. I will help you answer. You can use the keyboard to type your message or speak using the microphone.';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: modalWidth,
        constraints: BoxConstraints(
          maxHeight: modalMaxHeight,
        ),
        padding: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF3C5C3B),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: modalWidth * 0.05,
                vertical: 16,
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/tulai-logo.png',
                    width: modalWidth * 0.08,
                    height: modalWidth * 0.08,
                  ),
                  SizedBox(width: modalWidth * 0.03),
                  const Text(
                    'Tulai – AI Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            // Chat bubble (scrollable if needed)
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController, // <-- Attach controller here
                padding: EdgeInsets.all(modalWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Intro message
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF3C5C3B),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: EdgeInsets.all(modalWidth * 0.04),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        intro,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize:
                              modalWidth * 0.04 > 18 ? 18 : modalWidth * 0.04,
                        ),
                      ),
                    ),
                    // Chat history
                    ..._aiService.chatHistory.map((msg) {
                      final isUser = msg['role'] == 'user';
                      return Container(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        margin: EdgeInsets.only(
                          top: 4,
                          bottom: 4,
                          left: isUser ? modalWidth * 0.15 : 0,
                          right: isUser ? 0 : modalWidth * 0.15,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isUser
                                ? const Color.fromARGB(255, 179, 137, 48)
                                : const Color(0xFF3C5C3B),
                            borderRadius: isUser
                                ? const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(0),
                                  )
                                : const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                    bottomLeft: Radius.circular(0),
                                    bottomRight: Radius.circular(16),
                                  ),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: modalWidth * 0.03,
                          ),
                          child: Text(
                            msg['message'] ?? '',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: modalWidth * 0.035 > 16
                                  ? 16
                                  : modalWidth * 0.035,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            // Input field and mic button
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF9CA69C),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: modalWidth * 0.03,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: 'Type your message...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.white70),
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: Colors.white,
                            size:
                                modalWidth * 0.06 > 32 ? 32 : modalWidth * 0.06,
                          ),
                          onPressed: _handleMic,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.send,
                            color: Colors.white,
                            size:
                                modalWidth * 0.06 > 32 ? 32 : modalWidth * 0.06,
                          ),
                          onPressed: _handleSend,
                          tooltip: 'Send',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

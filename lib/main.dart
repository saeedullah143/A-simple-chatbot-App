import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class Chatbot extends ChangeNotifier {
  String spokenText = "";
  bool isListening = false;
  final stt.SpeechToText speech = stt.SpeechToText();
  final FlutterTts flutterTts = FlutterTts();
  TextEditingController messageController = TextEditingController();
  List<String> messages = [];
  ScrollController _scrollController = ScrollController();

  Chatbot() {
    initSpeechRecognition();
  }

  Future<void> initSpeechRecognition() async {
    bool available = await speech.initialize(
      onError: (errorNotification) {
        print('Speech recognition error: $errorNotification');
      },
      onStatus: (status) {
        print('Speech recognition status: $status');
      },
    );

    if (available) {
      print('Speech recognition initialized successfully.');
    } else {
      print('Speech recognition not available.');
    }
  }

  void listenForVoice() async {
    if (!speech.isListening) {
      try {
        speech.listen(
          onResult: (result) {
            final userVoiceInput = result.recognizedWords;
            spokenText = userVoiceInput; // Update spoken text immediately
            if (result.finalResult) {
              addMessage("User (Voice): $userVoiceInput", true);
              generateResponse(userVoiceInput).then((response) {
                addMessage("Chatbot: $response", false);
                speakResponse(response);
              });
            }
            notifyListeners(); // Notify listeners when spoken text updates
          },
        );
        isListening = true; // Voice recognition is active
        notifyListeners(); // Notify listeners when listening starts
      } catch (e) {
        print('Error during voice recognition: $e');
      }
    } else {
      await speech.stop();
      isListening = false; // Voice recognition is not active
      notifyListeners(); // Notify listeners when listening stops
    }
  }

  Future<void> speakResponse(String text) async {
    await flutterTts.stop();
    await flutterTts.speak(text);
  }

  Future<String> generateResponse(String userInput) async {
    userInput = userInput.toLowerCase();
    if (userInput.contains('hello')) {
      return "Hi there! How can I help you?";
    } else if (userInput.contains('name')) {
      return "Nice to meet you. What's your date of birth?";
    } else if (userInput.contains('date of birth')) {
      return "Thank you for providing your date of birth. What's the reason for your appointment?";
    } else if (userInput.contains('appointment')) {
      return "I'm here to help. Please let me know your preferred date and time.";
    } else {
      return "I'm sorry, I may not have the information you need. Can you please clarify?";
    }
  }


  void addMessage(String message, bool isUser) {
    messages.add(message);

    // Notify listeners to update the UI
    notifyListeners();

    // Scroll to the latest message
    _scrollToBottom();

    // Clear the spoken text after a delay
    Future.delayed(Duration(seconds: 1), () {
      spokenText = "";
      notifyListeners();
    });
  }

  void _scrollToBottom() {
    // Scroll to the bottom with animation
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
}
class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chatbot = Provider.of<Chatbot>(context);

    return Scaffold(
      appBar: AppBar( title: Text('SpeakLE.Ai'),backgroundColor: Colors.indigo,leading: CircleAvatar(
        radius: 5,
        backgroundColor: Colors.indigo,
        child:  Image.asset('assets/user_avatar.png')),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              reverse: true, // Set reverse to true to scroll from top to bottom
              child: Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: chatbot.messages.length,
                    controller: chatbot._scrollController,
                    reverse: false,
                    // Set reverse to false to scroll from top to bottom
                    itemBuilder: (context, index) {
                      final message = chatbot.messages[index];
                      return buildMessageBubble(message);
                    },
                  ),
                ],
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: chatbot.isListening ? 1.0 : 0.0,
            duration: Duration(milliseconds: 500),
            child: Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                chatbot.spokenText,
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: chatbot.messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    final userInput = chatbot.messageController.text;
                    if (userInput.isNotEmpty) {
                      chatbot.addMessage("User (Text): $userInput", true);
                      chatbot.generateResponse(userInput).then((response) {
                        chatbot.addMessage("Chatbot: $response", false);
                        chatbot.speakResponse(response);
                      });
                      chatbot.messageController.clear();
                    }
                  },
                ),
                IconButton(
                  icon: Icon(
                    chatbot.isListening ? Icons.mic : Icons.mic_off,
                    color: chatbot.isListening ? Colors.blue : Colors.red,
                  ),
                  onPressed: () {
                    chatbot.listenForVoice();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMessageBubble(String message) {
    final isUserMessage = message.startsWith("User");

    // Define avatar images for the user and chatbot
    final userAvatar = AssetImage("assets/user_avatar.png"); // Replace with your user avatar image
    final chatbotAvatar = AssetImage("assets/chatbot_avatar.png"); // Replace with your chatbot avatar image

    // Define avatar colors
    final userAvatarColor = Colors.indigo; // Replace with your desired color
    final chatbotAvatarColor = Colors.teal; // Replace with your desired color

    // Calculate the maximum width for the message container
    final maxWidth = 240.0; // You can adjust this value as needed

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: isUserMessage
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if (!isUserMessage)
          CircleAvatar(
            radius: 20,
            backgroundColor: chatbotAvatarColor,
            child: CircleAvatar(
              radius: 18,
              backgroundImage: userAvatar,
              backgroundColor: Colors.transparent,
            ),
          ),
        Padding(
          padding:isUserMessage? const EdgeInsets.fromLTRB(2,5,5,10):const EdgeInsets.fromLTRB(2,5,5,10),
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            decoration: BoxDecoration(
              color: isUserMessage ? userAvatarColor : chatbotAvatarColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        if (isUserMessage)
          CircleAvatar(
            radius: 20,
            backgroundColor: userAvatarColor,
            child: CircleAvatar(
              radius: 18,
              backgroundImage: chatbotAvatar,
              backgroundColor: Colors.transparent,
            ),
          ),
      ],
    );
  }



}

  void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => Chatbot(),
      child: MaterialApp(
        home: ChatScreen(),
      ),
    ),
  );
}
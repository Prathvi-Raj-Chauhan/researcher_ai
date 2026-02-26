import 'package:research_helper/MODELS/message.dart';

class CreatingMessage {
  Message createUserMessage(String content) {
    final mess = Message(
      role: 'user',
      content: content,
      timestamp: DateTime.now(),
    );
    return mess;
  }

  Message createAiMessage(String content) {
    final mess = Message(
      role: 'ai',
      content: content,
      timestamp: DateTime.now(),
    );
    return mess;
  }
}

import 'package:chat_bubbles/bubbles/bubble_normal.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:research_helper/MODELS/message.dart';
import 'package:research_helper/PROVIDER/project_provider.dart';
import 'package:research_helper/SERVICES/apiServices.dart';
import 'package:research_helper/SERVICES/creatingMessage.dart';
import 'package:research_helper/SERVICES/storage_services.dart';

class ChatPage extends StatefulWidget {
  String projectId;
  ChatPage({required this.projectId, super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController _messageController = TextEditingController();

  bool userMessageSent = false;
  bool aiMessageLoading = false;
  bool _isTextEmpty = true;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _messageController.addListener(() {
      setState(() {
        _isTextEmpty = _messageController.text.trim().isEmpty;
      });
    });
    context.read<ProjectProvider>().fetchAllMessages(widget.projectId);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            const Text(
              'Ask Questions',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Consumer<ProjectProvider>(
                  builder: (context, projectProvider, _) {
                    if (projectProvider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }
                    if (projectProvider.messages.isEmpty) {
                      return Center(
                        child: Text(
                          'No messages yet.\nAsk something!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount:
                          projectProvider.messages.length +
                          // add extra items at end for loading bubbles if needed
                          (userMessageSent ? 1 : 0) +
                          (aiMessageLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        // show user loading bubble after all messages
                        if (userMessageSent &&
                            index == projectProvider.messages.length) {
                          return BubbleNormal(
                            text: "Sending...",
                            isSender: true,
                            color: Color(0xFF1B97F3),
                            tail: true,
                            textStyle: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          );
                        }
                        // show ai loading bubble after all messages (and after user bubble if both somehow true)
                        if (aiMessageLoading &&
                            index ==
                                projectProvider.messages.length +
                                    (userMessageSent ? 1 : 0)) {
                          // return BubbleNormal(
                          //   text: "...",
                          //   isSender: false,
                          //   color: Colors.grey[800]!,
                          //   tail: true,
                          //   textStyle: TextStyle(
                          //     fontSize: 20,
                          //     color: Colors.white,
                          //   ),
                          // );
                          return Padding(
                            padding: const EdgeInsets.all(6.5),
                            child: TypingIndicatorWave(
                              showIndicator: true,
                              bubbleColor: Color(0xFFE8E8EE),
                              dotColor: Colors.black54,
                            ),
                          );
                        }
                        final message = projectProvider.messages[index];
                        bool isSender = message.role == 'user';
                        return Padding(
                          padding: const EdgeInsets.all(6.5),
                          child: BubbleNormal(
                            text: message.content,
                            isSender: isSender,
                            color: isSender
                                ? Colors.blueAccent
                                : Colors.blueGrey,
                            tail: true,
                            textStyle: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(color: Colors.black),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.add, color: Colors.white),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        onSubmitted: (_) async => await handleSend(),
                        controller: _messageController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintStyle: TextStyle(color: Colors.white),
                          hintText: "Ask Question Here...",
                          filled: true,
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          fillColor: const Color.fromARGB(255, 62, 60, 60),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isTextEmpty ? null : handleSend,
                    icon: Icon(Icons.send_rounded, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> handleSend() async {
    if (!mounted) return;
    setState(() {
      // now start to show loading becuase only userMessageSent is true
      userMessageSent = true;
    });
    Message userMessage = CreatingMessage().createUserMessage(
      _messageController.text,
    );
    _messageController.clear();
    await StorageServices.addMessage(
      widget.projectId,
      userMessage,
    ); //user's message is added from here only and the response we get from backend is ai's message and will be added to storage from the api call

    context.read<ProjectProvider>().addNewMessage(
      widget.projectId,
      userMessage,
    ); // now user's added message will be shown in the list
    if (!mounted) return;
    setState(() {
      userMessageSent = false;
      aiMessageLoading = true;
    });
    //until here user side message sent request loading must be shown

    Message? aiMessage = await Apiservices.query(
      // on this part ai's side message loading bubble must be shown
      // do query in backend with user's message content and if success message will be added in the list from that Apiservice query function if false we add error message from here
      userMessage.content,
      widget.projectId,
    );
    if (aiMessage == null) {
      Message error = Message(
        role: 'ai',
        content:
            "There was an error in sending your message to backend for querying",
        timestamp: DateTime.now(),
      );
      await StorageServices.addMessage(widget.projectId, error);
      context.read<ProjectProvider>().addNewMessage(widget.projectId, error);
    } else {
      context.read<ProjectProvider>().addNewMessage(
        widget.projectId,
        aiMessage,
      );
    }
    if (!mounted) return;
    setState(() {
      aiMessageLoading = false;
    });
  }
}

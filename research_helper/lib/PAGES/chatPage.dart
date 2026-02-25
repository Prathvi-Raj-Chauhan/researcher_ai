import 'package:chat_bubbles/bubbles/bubble_normal.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:research_helper/PROVIDER/project_provider.dart';

class ChatPage extends StatefulWidget {
  String projectId;
  ChatPage({required this.projectId, super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController _messageController = new TextEditingController();
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
                    itemCount: projectProvider.messages.length,
                    itemBuilder: (context, index) {
                      final message = projectProvider.messages[index];
                      return BubbleNormal(
                        text: message.content,
                        isSender: false,
                        color: Color(0xFF1B97F3),
                        tail: true,
                        textStyle: TextStyle(fontSize: 20, color: Colors.white),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(color: Colors.black),
              child: Row(
                children: [
                  IconButton(onPressed: () {}, icon: Icon(Icons.add, color: Colors.white,)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintStyle: TextStyle(color: Colors.white),
                        hintText: "Ask Question Here...",
                        filled: true,
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: Colors.grey
                          )
                        ),
                        fillColor: const Color.fromARGB(255, 62, 60, 60),
                        border: OutlineInputBorder(
                          
                          borderRadius: BorderRadius.circular(20)
                        )
                      ),
                      
                    ),
                  ),
                  IconButton(onPressed: (){}, icon: Icon(Icons.send_rounded, color: Colors.blue,))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

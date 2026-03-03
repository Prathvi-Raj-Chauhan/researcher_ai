import 'dart:io';

import 'package:chat_bubbles/bubbles/bubble_normal.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:research_helper/COMPONENTS/progressAddIndicator.dart';
import 'package:research_helper/COMPONENTS/progressIndicator.dart';
import 'package:research_helper/COMPONENTS/suggestionCard.dart';
import 'package:research_helper/MODELS/message.dart';
import 'package:research_helper/MODELS/project.dart';
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
  File? chosenPdf;
  File? chosenText;
  String? chosenUrl;
  String sourceType = "";

  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  void choosePdfFile(StateSetter setDialogState) async {
    FilePickerResult? res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (res != null) {
      setDialogState(() {
        chosenPdf = File(res.files.single.path!);
        chosenText = null;
        chosenUrl = null;
        sourceType = "pdf";
      });
    }
  }

  void chooseTextFile(StateSetter setDialogState) async {
    FilePickerResult? res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );
    if (res != null) {
      setDialogState(() {
        chosenText = File(res.files.single.path!); // fixed bug
        chosenPdf = null;
        chosenUrl = null;
        sourceType = "txt";
      });
    }
  }

  bool _canSubmit() {
    return (chosenPdf != null || chosenText != null || chosenUrl != null);
  }

  TextEditingController _messageController = TextEditingController();

  bool userMessageSent = false;
  bool aiMessageLoading = false;
  bool _isTextEmpty = true;
  @override
  void initState() {
    super.initState();

    _messageController.addListener(() {
      setState(() {
        _isTextEmpty = _messageController.text.trim().isEmpty;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().fetchAllMessages(widget.projectId);
    });
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
            SuggestionCart(projectId: widget.projectId),
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
                    onPressed: () {
                      _nameController.clear();
                      _urlController.clear();
                      setState(() {
                        chosenPdf = null;
                        chosenText = null;
                        chosenUrl = null;
                        sourceType = "";
                      });

                      showDialog(
                        context: context,
                        builder: (context) {
                          return StatefulBuilder(
                            // let dialog rebuild itself
                            builder: (context, setDialogState) {
                              return Dialog(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  35,
                                  35,
                                  35,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Add Source',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Choose Source',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          sourceButton(
                                            "PDF",
                                            Icons.picture_as_pdf_rounded,
                                            Colors.red,
                                            () {
                                              choosePdfFile(setDialogState);
                                            },
                                          ),
                                          sourceButton(
                                            "URL",
                                            Icons.link,
                                            Colors.blueAccent,
                                            () {
                                              _showUrlDialog(
                                                context,
                                                setDialogState,
                                              );
                                            },
                                          ),
                                          sourceButton(
                                            "TXT",
                                            Icons.text_fields_rounded,
                                            Colors.grey,
                                            () {
                                              chooseTextFile(setDialogState);
                                            },
                                          ),
                                        ],
                                      ),

                                      // show selected source
                                      if (chosenPdf != null ||
                                          chosenText != null ||
                                          chosenUrl != null) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.green.withOpacity(
                                                0.4,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.check_circle,
                                                color: Colors.green,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  chosenPdf?.path
                                                          .split('\\')
                                                          .last ??
                                                      chosenText?.path
                                                          .split('\\')
                                                          .last ??
                                                      chosenUrl ??
                                                      "",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],

                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.black,
                                            foregroundColor: Colors.white,
                                            disabledBackgroundColor:
                                                Colors.grey[300],
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: _canSubmit()
                                              ? _addDoc
                                              : null,
                                          child: const Text('Add Document'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
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
    // await StorageServices.addMessage(
    //   widget.projectId,
    //   userMessage,
    // );

    //user's message is added from here only and the response we get from backend is ai's message and will be added to storage from the api call
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
      // await StorageServices.addMessage(widget.projectId, error);
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

  void _showUrlDialog(BuildContext context, StateSetter setDialogState) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Enter URL",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  hintText: 'https://...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (_urlController.text.trim().isNotEmpty) {
                      setDialogState(() {
                        chosenUrl = _urlController.text.trim();
                        chosenPdf = null;
                        chosenText = null;
                        sourceType = "url";
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Confirm'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget sourceButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color.fromARGB(255, 171, 171, 171),
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Icon(icon, color: color),
          ],
        ),
      ),
    );
  }

  // void _addDoc() async {
  //   try {
  //     // 1. get current project

  //     Project currProj = await StorageServices.getSpecificProject(widget.projectId)!;

  //     // 2. saving ingesting the document in chroma db
  //     String projId = currProj.id;
  //     String sourceType = "";

  //     if (chosenUrl != null) {
  //       sourceType = "url";
  //       // var res = await Apiservices.ingestUrl(chosenUrl!, projId);
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (_) => IngestionAddScreen(
  //             project: currProj,
  //             sourceType: sourceType,
  //             url: chosenUrl!,
  //           ),
  //         ),
  //       );
  //     } else {
  //       sourceType = "file";
  //       var res = await Apiservices.ingestFile(chosenPdf!, projId);
  //     }
  //     // SharedPreferences pref = await SharedPreferences.getInstance();
  //     // String userId = pref.getString('userId')!;
  //     // context.read<ProjectListProvider>().addNewProject(userId, newProj);
  //     Navigator.pop(context);

  //     // Navigator.push(
  //     //   context,
  //     //   MaterialPageRoute(builder: (_) => ChatPage(projectId: projId)),
  //     // );
  //   } catch (e) {
  //     debugPrint(e.toString());
  //   }
  // }
  void _addDoc() async {
  try {
    Project? currProj = StorageServices.getSpecificProject(widget.projectId);
    if (currProj == null) return;

    Navigator.pop(context); // close dialog first

    if (chosenUrl != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IngestionAddScreen(
            project: currProj,
            sourceType: "url",
            url: chosenUrl,
          ),
        ),
      );
    } else if (chosenPdf != null || chosenText != null) {
      File file = chosenPdf ?? chosenText!;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IngestionScreen(
            project: currProj,
            sourceType: "file",
            file: file,
          ),
        ),
      );
    }
    
      
    
  } catch (e) {
    debugPrint(e.toString());
  }
}
}

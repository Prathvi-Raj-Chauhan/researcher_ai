import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:research_helper/MODELS/project.dart';
import 'package:research_helper/PAGES/chatPage.dart';
import 'package:research_helper/PROVIDER/progress_provider.dart';
import 'package:research_helper/PROVIDER/project_list_provider.dart';
import 'package:research_helper/SERVICES/apiServices.dart';
import 'package:research_helper/SERVICES/storage_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IngestionAddScreen extends StatefulWidget {
  final Project project;
  final File? file;
  final String? url;
  final String sourceType;

  const IngestionAddScreen({
    this.file,
    required this.project,
    this.url,
    required this.sourceType,
    super.key,
  });

  @override
  State<IngestionAddScreen> createState() => _IngestionAddScreenState();
}

class _IngestionAddScreenState extends State<IngestionAddScreen> {
  final List<Map<String, dynamic>> steps = [
    {"label": "Reading document",      "icon": Icons.description_outlined},
    {"label": "Chunking content",      "icon": Icons.cut_outlined},
    {"label": "Generating embeddings", "icon": Icons.psychology_outlined},
    {"label": "Done",    "icon": Icons.summarize_outlined},
  ];

  int currentStep = 0;
  bool hasError = false;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => startIngestion());
  }

  Future<void> startIngestion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId')!;

      final stream = widget.sourceType == 'url'
          ? Apiservices.ingestUrlAddStream(widget.url!, widget.project.id)
          :Apiservices.ingestUrlAddStream(widget.url!, widget.project.id);

      await for (final event in stream) {
        if (!mounted) break;

        final step = event['step'] as int;

        if (step == -1) {
          setState(() {
            hasError = true;
            errorMessage = event['message'] ?? 'Something went wrong';
          });
          break;
        }

        context.read<ProgressProvider>().update(step / 3);
        setState(() => currentStep = step);

        if (step == 3) {
          await Future.delayed(const Duration(milliseconds: 700));
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ChatPage(projectId: widget.project.id),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          hasError = true;
          errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Consumer<ProgressProvider>(
              builder: (context, pp, _) {
                return SizedBox(
                  height: 150,
                  width: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 150,
                        width: 150,
                        child: CircularProgressIndicator(
                          backgroundColor: Colors.grey.withOpacity(0.4),
                          color: Colors.deepPurpleAccent,
                          strokeCap: StrokeCap.round,
                          strokeWidth: 12,
                          value: pp.progress, // 0.0 to 1.0
                        ),
                      ),
                      Text(
                        '${(pp.progress * 100).toInt()}%', // fixed: was missing * 100
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            Text(
              'Status: ${steps[currentStep]['label']}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),

            if (hasError) ...[
              const SizedBox(height: 20),
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
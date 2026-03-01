import 'package:flutter/material.dart';
import 'package:research_helper/SERVICES/storage_services.dart';

class SuggestionCart extends StatefulWidget {
  final String projectId;
  const SuggestionCart({required this.projectId, super.key});

  @override
  State<SuggestionCart> createState() => _SuggestionCartState();
}

class _SuggestionCartState extends State<SuggestionCart> {


  String? summary;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    summary = StorageServices.getProjectSummary(widget.projectId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 30, 30, 30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Brief : ', style: TextStyle(color: Colors.white)),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
                icon: Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey,
                  size: 20,
                ),
              ),
            ],
          ),

          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(
                summary == null ? "cannot summarize" : summary!,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

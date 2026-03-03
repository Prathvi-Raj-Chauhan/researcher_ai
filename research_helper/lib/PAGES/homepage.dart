import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:research_helper/COMPONENTS/progressIndicator.dart';
import 'package:research_helper/COMPONENTS/projectTile.dart';
import 'package:research_helper/MODELS/project.dart';
import 'package:research_helper/PAGES/chatPage.dart';
import 'package:research_helper/PROVIDER/connectivity_provider.dart';
import 'package:research_helper/PROVIDER/project_list_provider.dart';
import 'package:research_helper/SERVICES/apiServices.dart';
import 'package:research_helper/SERVICES/storage_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? chosenPdf;
  File? chosenText;
  String? chosenUrl;
  String sourceType = "";
  TextEditingController _rename = TextEditingController();

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
    return _nameController.text.trim().isNotEmpty &&
        (chosenPdf != null || chosenText != null || chosenUrl != null);
  }

  void _submitResearch() async {
  try {
    Project newProj = await StorageServices.createNewProject(
      _nameController.text,
    );

    String projId = newProj.id;

    Navigator.pop(context); // close dialog first

    if (chosenUrl != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IngestionScreen(
            project: newProj,
            sourceType: "url",
            url: chosenUrl!,
          ),
        ),
      ).then((_) => loadUserAndFetchProject()); // refresh after returning
    } else {
      File file = chosenPdf ?? chosenText!;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IngestionScreen(
            project: newProj,
            sourceType: "file",
            file: file,
          ),
        ),
      ).then((_) => loadUserAndFetchProject()); // refresh after returning
    }
  } catch (e) {
    debugPrint(e.toString());
  }
}

  Future<String> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userId')!;
    return userId;
  }

  @override
  void initState() {
    super.initState();
    loadUserAndFetchProject();
  }

  Future<void> loadUserAndFetchProject() async {
    String userId = await getUserId();
    context.read<ProjectListProvider>().fetchAllProjects(userId);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<ConnectivityProvider>(
        builder: (context, connectivity, child) {
          if (connectivity.isOffline) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.wifi_off, size: 80, color: Colors.red),
                    SizedBox(height: 20),
                    Text(
                      "No Internet Connection",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Please check your connection.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return Scaffold(
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: Colors.white,
              tooltip: "New Project",
              label: const Text('New Project'),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'New Research',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  style: TextStyle(color: Colors.white),
                                  controller: _nameController,

                                  onChanged: (_) => setDialogState(
                                    () {},
                                  ), // rebuild to enable button
                                  decoration: InputDecoration(
                                    hintText: 'Research name...',

                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
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
                                        _showUrlDialog(context, setDialogState);
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
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.green.withOpacity(0.4),
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
                                            chosenPdf?.path.split('\\').last ??
                                                chosenText?.path
                                                    .split('\\')
                                                    .last ??
                                                chosenUrl ??
                                                "",
                                            overflow: TextOverflow.ellipsis,
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
                                      disabledBackgroundColor: Colors.grey[300],
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: _canSubmit()
                                        ? _submitResearch
                                        : null,
                                    child: const Text('Start Research'),
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
              icon: const Icon(Icons.add),
            ),
            backgroundColor: Colors.black,
            body: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Researcher',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Consumer<ProjectListProvider>(
                    builder: (context, plp, _) {
                      if (plp.isLoading) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (plp.projectList.length == 0) {
                        return Center(
                          child: Text(
                            'No research yet\n Tap + to start',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: plp.projectList.length,
                        itemBuilder: (context, index) {
                          Project currProj = plp.projectList[index];
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            // child: Container(
                            //   height: 80,
                            //   decoration: BoxDecoration(
                            //     boxShadow: [
                            //       BoxShadow(
                            //         color: Colors.black.withOpacity(0.6),
                            //         offset: Offset(4, 4),
                            //         blurRadius: 8,
                            //         spreadRadius: 1,
                            //       ),
                            //       BoxShadow(
                            //         color: Colors.white.withOpacity(0.05),
                            //         offset: Offset(-2, -2),
                            //         blurRadius: 6,
                            //         spreadRadius: 0,
                            //       ),
                            //     ],
                            //     color: const Color.fromARGB(255, 47, 46, 46),
                            //     border: BoxBorder.all(color: Colors.grey),
                            //     borderRadius: BorderRadius.circular(15),
                            //   ),
                            //   padding: EdgeInsets.all(12),
                            //   child: Center(
                            //     child: ListTile(
                            //       onTap: () => Navigator.push(
                            //         context,
                            //         MaterialPageRoute(
                            //           builder: (BuildContext context) =>
                            //               ChatPage(projectId: currProj.id),
                            //         ),
                            //       ).then((_) => loadUserAndFetchProject()),
                            //       leading: Text(
                            //         currProj.name,
                            //         style: TextStyle(
                            //           fontWeight: FontWeight.bold,
                            //           color: Colors.white,
                            //           fontSize: 16,
                            //         ),
                            //       ),
                            //       trailing: Text(currProj.createdAt.toString()),
                            //     ),
                            //   ),
                            // ),
                            child: ProjectTile(
                              currProj: currProj,
                              onRename: (currProj) =>
                                  openRenameDialog(currProj),
                              onDelete: (currProj) =>
                                  openDeleteDialog(currProj),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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

  void onDelete(String id) {
    StorageServices.deleteProject(id);
    context.read<ProjectListProvider>().deleteProject(id);
  }

 void openDeleteDialog(Project currProj) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color.fromARGB(255, 49, 49, 49),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          "Delete Project",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete this project?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              onDelete(currProj.id);
              Navigator.pop(context);
            },
            child: Text('Delete'),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.purpleAccent,
              side: BorderSide(color: Colors.purpleAccent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
        ],
      );
    },
  );
}

  void onRename(String id, String newName) {
    StorageServices.renameProject(id, newName);
    Provider.of<ProjectListProvider>(
      context,
      listen: false,
    ).renameProject(id, newName);
  }

  void openRenameDialog(Project proj) {
    showDialog(context: context, builder: (context) => renameProject(proj));
  }

  Widget renameProject(Project currProj) {
  _rename.text = currProj.name;

  return AlertDialog(
    backgroundColor: const Color.fromARGB(255, 54, 54, 54),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    title: Text(
      "Rename Your Project",
      style: TextStyle(color: Colors.white),
    ),
    content: TextField(
      controller: _rename,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Enter new name',
        hintStyle: TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.grey.shade900,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey, width: 2),
        ),
      ),
    ),
    actions: [
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onPressed: () {
          if (_rename.text != currProj.name)
            onRename(currProj.id, _rename.text);
          Navigator.pop(context);
        },
        child: Text('Save'),
      ),
      OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white70,
          side: BorderSide(color: Colors.white30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () {
          Navigator.pop(context);
        },
        child: Text('Cancel'),
      ),
    ],
  );
}
}

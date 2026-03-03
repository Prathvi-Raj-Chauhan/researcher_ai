import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:research_helper/MODELS/project.dart';
import 'package:research_helper/PAGES/chatPage.dart';
import 'package:research_helper/PROVIDER/project_list_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProjectTile extends StatefulWidget {
  final Project currProj;
  final void Function(Project) onRename;
  final void Function(Project) onDelete;
  const ProjectTile({
    required this.onRename,
    required this.currProj,
    required this.onDelete,
    super.key,
  });

  @override
  State<ProjectTile> createState() => _ProjectTileState();
}

class _ProjectTileState extends State<ProjectTile> {
  TextEditingController _rename = TextEditingController();

  

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _rename.text = widget.currProj.name;
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(widget.currProj.name),
      startActionPane: ActionPane(
        motion: const StretchMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => widget.onRename(widget.currProj),
            borderRadius: BorderRadius.circular(12),
            autoClose: true,
            backgroundColor: Colors.blue,
            icon: Icons.edit,
            label: 'Rename',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => widget.onDelete(widget.currProj),
            borderRadius: BorderRadius.circular(12),
            autoClose: true,
            backgroundColor: Colors.redAccent,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              offset: Offset(4, 4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.05),
              offset: Offset(-2, -2),
              blurRadius: 6,
              spreadRadius: 0,
            ),
          ],
          color: const Color.fromARGB(255, 47, 46, 46),
          border: BoxBorder.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: EdgeInsets.all(12),
        child: Center(
          child: ListTile(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) =>
                    ChatPage(projectId: widget.currProj.id),
              ),
            ).then((_) => loadUserAndFetchProject()),
            leading: Text(
              widget.currProj.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            trailing: Text(widget.currProj.createdAt.toString()),
          ),
        ),
      ),
    );
  }

  Future<void> loadUserAndFetchProject() async {
    String userId = await getUserId();
    context.read<ProjectListProvider>().fetchAllProjects(userId);
  }

  Future<String> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userId')!;
    return userId;
  }
}

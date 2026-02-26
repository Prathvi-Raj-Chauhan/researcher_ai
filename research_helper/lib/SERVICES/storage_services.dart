import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:research_helper/MODELS/message.dart';
import 'package:research_helper/MODELS/project.dart';
import 'package:research_helper/PROVIDER/project_list_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class StorageServices {
  static final _box = Hive.box<Project>('projects');
  static final _uuid = Uuid();

  //project functions
  static List<Project> getAllProjects(String userId) {
    print('running fetch all projects');
    List<Project> lis =
        _box.values.where((project) => project.userId == userId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    print('GOT all projects in storage service: ${lis.length}');
    return lis;
  }

  static Project? getSpecificProject(String id) {
    return _box.get(id);
  }

  static Future<Project> createNewProject(String name) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String userId = pref.getString('userId')!;
    final proj = Project(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
      userId: userId,
    );
    ProjectListProvider().addNewProject(name, userId, proj);
    await _box.put(proj.id, proj);

    

    return proj;
  }

  static Future<bool> renameProject(String id, String newName) async {
    final project = _box.get(id);
    if (project != null) {
      project.name = newName;
      await project.save();
      return true;
    }
    return false;
  }

  static Future<void> deleteProject(String id) async {
    await _box.delete(id);
  }

  static Future<void> addSource(String id, String source) async {
    final project = _box.get(id);
    if (project != null) {
      project.sources = [...project.sources, source];
      await project.save();
    }
  }

  //messages functions
  static Future<void> addMessage(String id, Message message) async {
    final project = _box.get(id);
    if (project != null) {
      project.messages = [...project.messages, message];
      await project.save();
    }
  }

  static List<Message> getAllMessages(String id) {
    return _box.get(id)?.messages ?? [];
  }

  static List<Message> getLastNMessages(String id, int n) {
    final messages = getAllMessages(id);
    if (messages.length <= n) return messages;
    return messages.sublist(messages.length - n);
  }

  static List<Map<String, dynamic>> getLastNMessagesJson(String id, int n) {
    final messages = getLastNMessages(id, n);
    if (messages.length <= n) {
      return messages.map((m) => toJson(m)).toList();
    }

    final lastMessages = messages.sublist(messages.length - n);
    return lastMessages.map((m) => toJson(m)).toList();
  }
 
  static Map<String, dynamic> toJson(Message message) {
    return {
      "role": message.role,
      "content": message.content,
    };
  }
  //search project
  static List<Project> searchProjects(String query) {
    return _box.values
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}

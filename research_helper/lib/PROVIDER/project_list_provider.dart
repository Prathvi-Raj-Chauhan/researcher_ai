import 'package:flutter/material.dart';
import 'package:research_helper/MODELS/project.dart';
import 'package:research_helper/SERVICES/storage_services.dart';

class ProjectListProvider extends ChangeNotifier {
  List<Project> _projectList = [];
  bool _isLoading = false;

  List<Project> get projectList => _projectList;
  bool get isLoading => _isLoading;

  Future<void> fetchAllProjects(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _projectList = StorageServices.getAllProjects(userId);
    } catch (e) {
      print("Caught error in fetching all projects ${e}");
    }
    _isLoading = false;
    print('GOT all projects _${_projectList.length}\n');
    notifyListeners();
  }

  Future addNewProject(String name, String userId, Project proj) async {
    _isLoading = true;
    notifyListeners();
    try {
      _projectList.add(proj);

      return proj;
    } catch (e) {
      print("Caught error in fetching all projects ${e}");
    }
    _isLoading = false;
    notifyListeners();
  }
}

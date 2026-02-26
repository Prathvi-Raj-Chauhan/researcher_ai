import 'package:flutter/material.dart';
import 'package:research_helper/MODELS/message.dart';
import 'package:research_helper/SERVICES/storage_services.dart';

class ProjectProvider extends ChangeNotifier {
  List<Message> _messages = [];
  bool _isLoading = false;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;

  bool _currMessageIsLoading = false;
  bool get currMessageIsLoadinge => _currMessageIsLoading;

  Future<void> addNewMessage(String projId, Message message) async {
    notifyListeners();
    _currMessageIsLoading = true;
    try {
      _messages.add(message);
      await StorageServices.addMessage(projId, message);
    } catch (e) {
      print("Got in catch while adding new messages");
    }
    _currMessageIsLoading = false;
    notifyListeners();
  }

  Future<void> fetchAllMessages(String projId) async {
    notifyListeners();
    _isLoading = true;
    try {
      _messages
          .clear(); // fetch messages will only be called when user enters new project so we have to fetch messages of that project only so first we clear it and then add all messages
      List<Message> allMess = await StorageServices.getAllMessages(projId);
      _messages.addAll(allMess);
    } catch (e) {
      print("Got in catch while fetching all messages");
    }
    _isLoading = false;
    notifyListeners();
  }
}

import 'package:flutter/material.dart';

class ProgressProvider extends ChangeNotifier {
  double _progress = 0;

  double get progress => _progress;

  void update(double amount){
    _progress = amount;
    notifyListeners();
  }
}

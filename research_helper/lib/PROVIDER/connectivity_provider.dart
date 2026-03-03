import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool _isOffline = false;
  bool get isOffline => _isOffline;

  ConnectivityProvider() {
    Connectivity().onConnectivityChanged.listen((result) {
      final offline = result == ConnectivityResult.none;

      if (offline != _isOffline) {
        _isOffline = offline;
        notifyListeners();
      }
    });
  }
}
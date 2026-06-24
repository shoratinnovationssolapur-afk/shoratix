import 'package:flutter/material.dart';

class BranchProvider extends ChangeNotifier {
  String _branch = 'all';
  String get branch => _branch;

  void setBranch(String b) {
    if (b != _branch) {
      _branch = b;
      notifyListeners();
    }
  }
}

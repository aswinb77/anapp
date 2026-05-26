import 'package:flutter/material.dart';

class RegionProvider extends ChangeNotifier {
  String _region = 'IN';

  String get region => _region;

  void setRegion(String newRegion) {
    _region = newRegion;
    notifyListeners();
  }
}

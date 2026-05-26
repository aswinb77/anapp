import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  late final StreamSubscription<ConnectivityResult> _subscription;
  ConnectivityResult _status = ConnectivityResult.none;

  ConnectivityResult get status => _status;
  bool get isOffline => _status == ConnectivityResult.none;

  ConnectivityProvider() {
    _init();
  }

  Future<void> _init() async {
    _status = await _connectivity.checkConnectivity();
    notifyListeners();
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      if (result != _status) {
        _status = result;
        notifyListeners();
      }
    });
  }

  Future<bool> refresh() async {
    final result = await _connectivity.checkConnectivity();
    if (result != _status) {
      _status = result;
      notifyListeners();
    }
    return result != ConnectivityResult.none;
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

import 'package:flutter/material.dart';

/// Coordinates transient overlays that should be dismissed when a new workflow
/// starts, such as searching for a location or opening route results.
class TransientUiProvider extends ChangeNotifier {
  VoidCallback? _closeBottomSheet;
  int _registrationId = 0;

  int registerBottomSheet(VoidCallback close) {
    final registrationId = ++_registrationId;
    _closeBottomSheet = close;
    return registrationId;
  }

  void unregisterBottomSheet(int registrationId) {
    if (registrationId != _registrationId) return;
    _closeBottomSheet = null;
  }

  void dismissBottomSheet() {
    final close = _closeBottomSheet;
    _closeBottomSheet = null;
    close?.call();
  }
}

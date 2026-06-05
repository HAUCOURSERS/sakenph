import 'package:flutter/material.dart';

/// This context provider is mainly used to be shared across the entire app.
/// For example, you want to create a variable and have it accessible in parts
/// of the code that are distant to each other, put it here.
class SystemVariablesProvider with ChangeNotifier {
  /// Note to developers:
  /// - Separate the encapsulated variables, their get and set methods for
  /// code cleanliness
  ///
  /// - Josef Miko

  // =======================================================================================
  // =======================================================================================
  // =======================================================================================

  String _originName = '';
  String _destName = '';
  bool _backgroundWidgetVisibility = false;
  String _backWidgetCurrentState = "GATHERING_FROMLOC";

  // =======================================================================================
  // =======================================================================================
  // =======================================================================================

  String get originName => _originName;
  String get destName => _destName;
  bool get backgroundWidgetVisibility => _backgroundWidgetVisibility;

  /// Used to tell the BackWidget what to show
  /// - "GATHERING_FROMLOC" : show widgets relevant for gathering
  ///
  String get backWidgetCurrentState => _backWidgetCurrentState;

  // =======================================================================================
  // =======================================================================================
  // =======================================================================================

  void setOriginName(String val) {
    _originName = val;
    notifyListeners();
  }

  void setDestName(String val) {
    _destName = val;
    notifyListeners();
  }

  void setBackgroundWidgetVisibility(bool val) {
    _backgroundWidgetVisibility = val;

    // It's better to put the unfocus method here since any occurence in the
    // code that requests for removing the background widget's visibility is
    // likely when the user isn't actively using the textfield.
    if (!val) FocusManager.instance.primaryFocus?.unfocus();

    notifyListeners();
  }

  void setBackWidgetCurrentState(String val) {
    _backWidgetCurrentState = val;
    notifyListeners();
  }
}

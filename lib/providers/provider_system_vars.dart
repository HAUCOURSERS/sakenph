import 'package:flutter/material.dart';
import 'package:sakenph/globals/enums.dart';

/// This context provider is mainly used to be shared across the entire app.
/// For example, you want to create a variable and have it accessible in parts
/// of the code that are distant to each other, put it here.
class SystemVariablesProvider with ChangeNotifier {
  /// Note to developers:
  /// - Separate the encapsulated variables, their get and set methods for
  /// code cleanliness
  ///
  /// - Josef Miko

  bool _backgroundWidgetVisibility = false;

  /// Changes depending on app logic. The value of this variable decides what the widgets
  /// such as the Foreground and the Background widgets display
  SystemState _appCurrentState = SystemState.gatheringFromLoc;
  Color _backgroundWidgetColor =
      Colors.white; // Default. May be changed by app logic

  // /////////////////////////////////////////////////////////////////////////////////////////////////////////
  // Getters
  // /////////////////////////////////////////////////////////////////////////////////////////////////////////

  /// If the value of this variable is false, the Background Widget will bee unrendered
  bool get backgroundWidgetVisibility => _backgroundWidgetVisibility;
  SystemState get backWidgetCurrentState => _appCurrentState;
  Color get backgroundWidgetColor => _backgroundWidgetColor;

  // /////////////////////////////////////////////////////////////////////////////////////////////////////////
  // Functions
  // /////////////////////////////////////////////////////////////////////////////////////////////////////////

  void setBackgroundWidgetVisibility(bool val) {
    _backgroundWidgetVisibility = val;

    // It's better to put the unfocus method here since any occurence in the
    // code that requests for removing the background widget's visibility is
    // likely when the user isn't actively using the textfield.
    if (!val) FocusManager.instance.primaryFocus?.unfocus();

    notifyListeners();
  }

  void setAppCurrentState(SystemState val) {
    _appCurrentState = val;
    notifyListeners();
  }

  void setBackgroundWidgetColor(Color color) {
    _backgroundWidgetColor = color;
    notifyListeners();
  }
}

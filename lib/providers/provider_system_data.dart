import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SystemDataProvider extends ChangeNotifier {
  bool isTutorialOngoing = false;

  SystemDataProvider() {
    _init();
  }

  /// observe later whether to keep or not. idk if sharedprefs would share the info and cause re-renders immediately.
  Future<void> _init() async {
    isTutorialOngoing = await getIsTutorialOngoing();
    notifyListeners();
  }

  /// Disables the landing message upon app startup
  void setPrototypeMessageIsNowRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('prototypeInfoDisplayed', true);
  }

  /// Clears SharedPreferences app data
  void clearSharedPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print(
      "[CONSOLE] SharedPreferences data cleared. Feel free to hot restart the app.",
    );
  }

  Future<bool> getIsTutorialOngoing() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? returnVal = prefs.getBool('isTutorialOngoing');
    return returnVal ?? false;
  }

  void startTutorial() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    isTutorialOngoing = true;
    await prefs.setBool('isTutorialOngoing', true);
    notifyListeners();
  }

  void stopTutorial() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    isTutorialOngoing = false;
    await prefs.setBool('isTutorialOngoing', false);
    notifyListeners();
  }
}

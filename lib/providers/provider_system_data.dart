import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SystemDataProvider extends ChangeNotifier {
  /**
   * Disables the landing message upon app startup
   */
  void setPrototypeMessageIsNowRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('prototypeInfoDisplayed', true);
  }

  /**
   * Clears SharedPreferences app data
   */
  void clearSharedPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

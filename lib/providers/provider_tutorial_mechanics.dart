import 'package:flutter/material.dart';
import 'package:sakenph/globals/enums.dart';
/**
(exiting the app resets the tutorial)

stage 1 - press the fromloc textfield
stage 2 - press a location
stage 3 - manual click to move to stage 4 : toloc 
stage 4 - search for a location
stage 5 - wait for backend
stage 6 - select a route (if backed somehow, consider this as stage 6.1 and tell them to press the view suggested routes)
stage 7 - tell them to press start traveling
stage 8 - press stop travelling (app must wipe from and to loc details as well as the variable that keeps the destination textfield present)
stage 9 - tell them to visit settings
stage 10 - tell them to toggle traffic data
stage 11 - tell them to hold the map
stage 12 - press select as origin
stage 13 - hold map in a different spot
stage 14 - press select as destination
stage 15 - popup that will tell the user to read, close and that's the end of the tutorial
 */

/// This provider is used by the tutorial components to manage the flow of the tutorial. Each step may face complications
/// so the progression of each step is very rigid logic-wise.
class TutorialMechanicsProvider extends ChangeNotifier {
  /// Represents the current stage of the tutorial.
  TutorialStage _currentTutorialStage = TutorialStage.stage01;
  TutorialStage get getCurrentTutorialStage => _currentTutorialStage;

  void moveToStage02() {
    if (_currentTutorialStage == TutorialStage.stage01) {
      _currentTutorialStage = TutorialStage.stage02;
      notifyListeners();
    }
  }

  void moveToStage03() {
    if (_currentTutorialStage == TutorialStage.stage02) {
      _currentTutorialStage = TutorialStage.stage03;
      notifyListeners();
    }
  }

  void moveToStage04() {
    if (_currentTutorialStage == TutorialStage.stage03) {
      _currentTutorialStage = TutorialStage.stage04;
      notifyListeners();
    }
  }

  void moveToStage05() {
    if (_currentTutorialStage == TutorialStage.stage04) {
      _currentTutorialStage = TutorialStage.stage05;
      notifyListeners();
    }
  }

  void moveToStage06() {
    if (_currentTutorialStage == TutorialStage.stage05) {
      _currentTutorialStage = TutorialStage.stage06;
      notifyListeners();
    }
  }

  void moveToStage07() {
    if (_currentTutorialStage == TutorialStage.stage06) {
      _currentTutorialStage = TutorialStage.stage07;
      notifyListeners();
    }
  }

  void moveToStage08() {
    if (_currentTutorialStage == TutorialStage.stage07) {
      _currentTutorialStage = TutorialStage.stage08;
      notifyListeners();
    }
  }

  void moveToStage09() {
    if (_currentTutorialStage == TutorialStage.stage08) {
      _currentTutorialStage = TutorialStage.stage09;
      notifyListeners();
    }
  }

  void moveToStage10() {
    if (_currentTutorialStage == TutorialStage.stage09) {
      _currentTutorialStage = TutorialStage.stage10;
      notifyListeners();
    }
  }

  void moveToStage11() {
    if (_currentTutorialStage == TutorialStage.stage10) {
      _currentTutorialStage = TutorialStage.stage11;
      notifyListeners();
    }
  }

  void moveToStage12() {
    if (_currentTutorialStage == TutorialStage.stage11) {
      _currentTutorialStage = TutorialStage.stage12;
      notifyListeners();
    }
  }

  void moveToStage13() {
    if (_currentTutorialStage == TutorialStage.stage12) {
      _currentTutorialStage = TutorialStage.stage13;
      notifyListeners();
    }
  }

  void moveToStage14() {
    if (_currentTutorialStage == TutorialStage.stage13) {
      _currentTutorialStage = TutorialStage.stage14;
      notifyListeners();
    }
  }

  void moveToStage15() {
    if (_currentTutorialStage == TutorialStage.stage14) {
      _currentTutorialStage = TutorialStage.stage15;
      notifyListeners();
    }
  }
}

import 'package:flutter/material.dart';
import 'package:sakenph/globals/enums.dart';

/// This provider is used by the tutorial components to manage the flow of the tutorial. Each step may face complications
/// so the progression of each step is very rigid logic-wise.
class TutorialMechanicsProvider extends ChangeNotifier {
  /// Represents the current state of the tutorial. If true, the widgets meant for tutorial will show up.
  bool _currentTutorialState = false;
  bool get getCurrentTutorialState => _currentTutorialState;

  /// Represents the current stage of the tutorial.
  TutorialStage _currentTutorialStage = TutorialStage.stage1;
  TutorialStage get getCurrentTutorialStage => _currentTutorialStage;
}

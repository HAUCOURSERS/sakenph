import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/features/tutorial_widget/stage01.dart';
import 'package:sakenph/features/tutorial_widget/stage02.dart';
import 'package:sakenph/features/tutorial_widget/stage03.dart';
import 'package:sakenph/features/tutorial_widget/stage04.dart';
import 'package:sakenph/features/tutorial_widget/stage05.dart';
import 'package:sakenph/features/tutorial_widget/stage06.dart';
import 'package:sakenph/globals/enums.dart';
import 'package:sakenph/providers/provider_system_data.dart';
import 'package:sakenph/providers/provider_tutorial_mechanics.dart';

/// Handles the rendering of tutorial widgets
class TutorialWidgetManager extends StatefulWidget {
  const TutorialWidgetManager({super.key});

  @override
  State<TutorialWidgetManager> createState() => _TutorialWidgetManagerState();
}

class _TutorialWidgetManagerState extends State<TutorialWidgetManager> {
  @override
  Widget build(BuildContext context) {
    bool isTutorialOngoing = context.select<SystemDataProvider, bool>(
      (val) => val.isTutorialOngoing,
    );
    TutorialMechanicsProvider tutorialMechanicsProvider = context
        .watch<TutorialMechanicsProvider>();

    // tutorial widgets will only render if the tutorial is ongoing
    if (!isTutorialOngoing) return SizedBox.shrink();

    switch (tutorialMechanicsProvider.getCurrentTutorialStage) {
      case TutorialStage.stage01:
        return Stage01();
      case TutorialStage.stage02:
        return Stage02();
      case TutorialStage.stage03:
        return Stage03();
      case TutorialStage.stage04:
        return Stage04();
      case TutorialStage.stage05:
        return Stage05();
      case TutorialStage.stage06:
        return Stage06();
      case TutorialStage.stage07:
        // TODO: Handle this case.
        return SizedBox.shrink();
      case TutorialStage.stage08:
        // TODO: Handle this case.
        return SizedBox.shrink();
      case TutorialStage.stage09:
        // TODO: Handle this case.
        return SizedBox.shrink();
      case TutorialStage.stage10:
        // TODO: Handle this case.
        return SizedBox.shrink();
      case TutorialStage.stage11:
        // TODO: Handle this case.
        return SizedBox.shrink();
      case TutorialStage.stage12:
        // TODO: Handle this case.
        return SizedBox.shrink();
      case TutorialStage.stage13:
        // TODO: Handle this case.
        return SizedBox.shrink();
      case TutorialStage.stage14:
        // TODO: Handle this case.
        return SizedBox.shrink();
      case TutorialStage.stage15:
        // TODO: Handle this case.
        return SizedBox.shrink();
    }
  }
}

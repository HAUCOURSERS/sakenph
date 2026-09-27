import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/features/tutorial_widget/stage01.dart';
import 'package:sakenph/features/tutorial_widget/stage02.dart';
import 'package:sakenph/features/tutorial_widget/stage03.dart';
import 'package:sakenph/features/tutorial_widget/stage04.dart';
import 'package:sakenph/features/tutorial_widget/stage05.dart';
import 'package:sakenph/features/tutorial_widget/stage06.dart';
import 'package:sakenph/features/tutorial_widget/stage07.dart';
import 'package:sakenph/features/tutorial_widget/stage08.dart';
import 'package:sakenph/features/tutorial_widget/stage09.dart';
import 'package:sakenph/features/tutorial_widget/stage10.dart';
import 'package:sakenph/features/tutorial_widget/stage11.dart';
import 'package:sakenph/features/tutorial_widget/stage12.dart';
import 'package:sakenph/features/tutorial_widget/stage13.dart';
import 'package:sakenph/features/tutorial_widget/stage14.dart';
import 'package:sakenph/features/tutorial_widget/stage15.dart';
import 'package:sakenph/features/tutorial_widget/stage16.dart';
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
        return Stage07();
      case TutorialStage.stage08:
        return Stage08();
      case TutorialStage.stage09:
        return Stage09();
      case TutorialStage.stage10:
        return Stage10();
      case TutorialStage.stage11:
        return Stage11();
      case TutorialStage.stage12:
        return Stage12();
      case TutorialStage.stage13:
        return Stage13();
      case TutorialStage.stage14:
        return Stage14();
      case TutorialStage.stage15:
        return Stage15();
      case TutorialStage.stage16:
        return Stage16();
      default:
        return SizedBox.shrink();
    }
  }
}

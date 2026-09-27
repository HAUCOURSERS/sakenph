import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/providers/provider_system_data.dart';
import 'package:sakenph/providers/provider_tutorial_mechanics.dart';

class Stage16 extends StatefulWidget {
  const Stage16({super.key});

  @override
  State<Stage16> createState() => _Stage16State();
}

class _Stage16State extends State<Stage16> {
  bool hideWidget = false;

  @override
  Widget build(BuildContext context) {
    SystemDataProvider systemDataProvider = context.read<SystemDataProvider>();
    TutorialMechanicsProvider tutorialMechanicsProvider = context
        .read<TutorialMechanicsProvider>();
    if (hideWidget) return SizedBox.shrink();
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Align(
          alignment: Alignment(0, 0.3),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Color.fromARGB(255, 33, 87, 204),
              border: Border.all(color: Colors.black, width: 1),
            ),

            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                    padding: EdgeInsets.only(
                      bottom: 2,
                      top: 2,
                      left: 10,
                      right: 10,
                    ),
                    child: Text(
                      "16/16",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 5),

                  Text(
                    "Congratulations! You have finished the tutorial. Now you should be able to use the app properly.",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        hideWidget = true;
                      });
                      systemDataProvider.stopTutorial();
                    },
                    child: Text("Finish", style: TextStyle(fontSize: 20)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

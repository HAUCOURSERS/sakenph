import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/providers/provider_system_data.dart';
import 'package:sakenph/providers/provider_tutorial_mechanics.dart';

class Stage03 extends StatefulWidget {
  const Stage03({super.key});

  @override
  State<Stage03> createState() => _Stage03State();
}

class _Stage03State extends State<Stage03> {
  bool hideWidget = false;

  @override
  Widget build(BuildContext context) {
    if (hideWidget) return SizedBox.shrink();
    return Align(
      alignment: Alignment(0, -0.3),
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
                  "3/15",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 5),
              _othercomponents(),
            ],
          ),
        ),
      ),
    );
  }

  Column _othercomponents() {
    return Column(
      children: [
        Text(
          "Since you supplied the app with a \"From\" location, the",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        Text(
          "option to give the app a \"To\" location is now available.",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        Text(
          "The red highlighted choices are not recommended due to those",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        Text(
          "locations being outside of the app's scope.",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        SizedBox(height: 5),
        ElevatedButton(
          onPressed: () {
            TutorialMechanicsProvider tutorialMechanicsProvider = context
                .read<TutorialMechanicsProvider>();
            tutorialMechanicsProvider.moveToStage04();
          },
          child: Text("Next", style: TextStyle(fontSize: 20)),
        ),
      ],
    );
  }
}

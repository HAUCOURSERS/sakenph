import 'package:flutter/material.dart';

class Stage09 extends StatefulWidget {
  const Stage09({super.key});

  @override
  State<Stage09> createState() => _Stage09State();
}

class _Stage09State extends State<Stage09> {
  bool hideWidget = false;

  @override
  Widget build(BuildContext context) {
    if (hideWidget) return SizedBox.shrink();
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Align(
          alignment: Alignment(0, 0.5),
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
                      "9/16",
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
        ),
      ),
    );
  }

  Column _othercomponents() {
    return Column(
      children: [
        Text(
          "Now you're done with the basics of the app. The currently selected locations will be wiped to learn the other features of the app.",
          style: TextStyle(fontSize: 18, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 15),
        Text(
          "See the button with the jeep/tricycle icons? Press that.",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class Stage15 extends StatefulWidget {
  const Stage15({super.key});

  @override
  State<Stage15> createState() => _Stage15State();
}

class _Stage15State extends State<Stage15> {
  bool hideWidget = false;

  @override
  Widget build(BuildContext context) {
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
                      "15/16",
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
          "Press \"Use this as your Destination Location\" to set the selected location as your source location.",
          style: TextStyle(fontSize: 18, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class Stage07 extends StatefulWidget {
  const Stage07({super.key});

  @override
  State<Stage07> createState() => _Stage07State();
}

class _Stage07State extends State<Stage07> {
  bool hideWidget = false;

  @override
  Widget build(BuildContext context) {
    if (hideWidget) return SizedBox.shrink();
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Align(
          alignment: Alignment(0, -0.8),
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
                      "7/16",
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
          "You can drag the route detail's display to expand or hide the details. You can also scroll through the details to analyze the travel duration of each transport mode.",
          style: TextStyle(fontSize: 15, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 7),
        Text(
          "You can press \"Go Back\" if you don't like this route to view other routes too.",
          style: TextStyle(fontSize: 15, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 7),
        Text(
          "Once you're done, you can start travelling by pressing \"Select This Route\"",
          style: TextStyle(fontSize: 15, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 5),
        ElevatedButton(
          onPressed: () {
            setState(() {
              hideWidget = true;
            });
          },
          child: Text("Close", style: TextStyle(fontSize: 20)),
        ),
      ],
    );
  }
}

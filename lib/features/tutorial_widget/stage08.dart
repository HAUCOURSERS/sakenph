import 'package:flutter/material.dart';

class Stage08 extends StatefulWidget {
  const Stage08({super.key});

  @override
  State<Stage08> createState() => _Stage08State();
}

class _Stage08State extends State<Stage08> {
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
                      "8/16",
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
          "Upon travelling, it will move the map towards your current geolocation. The icon's rotation relies on your geolocation history. The green marker represents the selected from location and the red marker is for your destination.",
          style: TextStyle(fontSize: 18, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        Text(
          "Press \"Stop Travelling\" once you're done.",
          style: TextStyle(fontSize: 18, color: Colors.white),
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

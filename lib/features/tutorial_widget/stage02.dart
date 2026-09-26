import 'package:flutter/material.dart';

class Stage02 extends StatefulWidget {
  const Stage02({super.key});

  @override
  State<Stage02> createState() => _Stage01State();
}

class _Stage01State extends State<Stage02> {
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
                  "2/15",
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
          "After pressing the textfield, type the name of the",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        Text(
          "place you want to be at, and wait for search results",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        Text(
          "to show up (Search results may not be accurate).",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        Text(
          "You can also use your geolocation as your source instead.",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        SizedBox(height: 15),
        Text(
          "Sometimes it may take a while for the search results.",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        Text(
          "to show up.",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        SizedBox(height: 15),
        Text(
          "It's not recommended to select the red-highlighted choices.",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              hideWidget = true;
            });
          },
          child: Text("Close for now", style: TextStyle(fontSize: 20)),
        ),
      ],
    );
  }
}

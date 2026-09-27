import 'package:flutter/material.dart';

class Stage04 extends StatefulWidget {
  const Stage04({super.key});

  @override
  State<Stage04> createState() => _Stage04State();
}

class _Stage04State extends State<Stage04> {
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
                  "4/16",
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
          "Press the second textfield and type the name",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        Text(
          "of the place you want to go to. Afterwards,",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        Text(
          "press the search result of your choice.",
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

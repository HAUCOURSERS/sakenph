import 'package:flutter/material.dart';

class Stage05 extends StatefulWidget {
  const Stage05({super.key});

  @override
  State<Stage05> createState() => _Stage05State();
}

class _Stage05State extends State<Stage05> {
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
                  "5/16",
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
          "Wait for the app to finish computing",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        Text(
          "for routes...",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        SizedBox(height: 5),
      ],
    );
  }
}

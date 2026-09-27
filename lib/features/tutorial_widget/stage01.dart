import 'package:flutter/material.dart';

class Stage01 extends StatefulWidget {
  const Stage01({super.key});

  @override
  State<Stage01> createState() => _Stage01State();
}

class _Stage01State extends State<Stage01> {
  bool hideWidget = false;

  @override
  Widget build(BuildContext context) {
    if (hideWidget) return SizedBox.shrink();
    return Container(
      child: Align(
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
                    "1/16",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 5),
                part1(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Column part1() {
    return Column(
      children: [
        Text(
          "Hello. Welcome to the tutorial. Follow the instructions",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        Text(
          "to learn how to use the app. First, press the textfield",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        Text(
          "to start typing.",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        SizedBox(height: 5),
      ],
    );
  }
}

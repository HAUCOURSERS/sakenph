import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/providers/provider_system_data.dart';
import 'package:sakenph/providers/provider_tutorial_mechanics.dart';

class Stage06 extends StatefulWidget {
  const Stage06({super.key});

  @override
  State<Stage06> createState() => _Stage06State();
}

class _Stage06State extends State<Stage06> {
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
                  "6/15",
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
          "Select a route from the given route choices.",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        Text(
          "If you pressed back, you can press \"View Searched",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        Text(
          "Routes\" to open the menu once more.",
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

import 'package:flutter/material.dart';

class PrototypeInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
  
  return AlertDialog(
      title: const Text('Welcome!'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'This is the prototype app for the "Commuter Guide Application with Multimodal Transport using A* and Yen\'s" capstone project.',
              textAlign: TextAlign.justify
            ),
            SizedBox(height: 12),
            Text(
              'You may test features such as inputting your origin and your destination point using the search bar, or by long pressing a point on the map.',
              textAlign: TextAlign.justify
            ),
            SizedBox(height: 12),
            Text(
              'You can also enable traffic data by clicking the (⚙) Gear icon on the search bar and toggle "Include Traffic" on.',
              textAlign: TextAlign.justify
            ),
            SizedBox(height: 12),
            Text(
              'After you are done testing the app within a set period of time, please answer the Post-Survey form given to you in your inbox.',
              textAlign: TextAlign.justify
            ),
            SizedBox(height: 12),
            Text(
              'You may also delete the app from your phone after you have finished testing the app. If you decide to keep it after the survey, please keep in mind'
              ' that the app may be non-functional after the group\'s thesis ended due to cloud hosting limitations.',
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 12),
            Text(
              'Thank you for your participation in the survey.',
              textAlign: TextAlign.justify
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
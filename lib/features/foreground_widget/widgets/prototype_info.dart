import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/providers/provider_system_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrototypeInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemDataProvider systemDataProvider = context.read<SystemDataProvider>();
    return AlertDialog(
      title: const Text('Welcome!'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'This is the prototype app for the "Commuter Guide Application with Multimodal Transport using A* and Yen\'s" capstone project.',
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 18),
            Text(
              'The scope of the app is within Angeles and Mabalacat City only, excluding Clark Freeport Zone.',
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 18),
            Text(
              'You may test features such as inputting your origin and your destination point using the search bar, or by long pressing a point on the map.',
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 18),
            Text(
              'You can also enable traffic data by clicking the (⚙) Gear icon on the search bar and toggle "Include Traffic" on.',
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 18),
            Text(
              'After you are done testing the app within a set period of time, please answer the Post-Survey form given to you in your inbox.',
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 18),
            Text(
              'You may also delete the app from your phone after you have finished testing the app. If you decide to keep it after the survey, please keep in mind'
              ' that the app may be non-functional after the end of the group\'s thesis due to cloud hosting limitations.',
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 18),
            Text(
              'Thank you for your participation in the survey.',
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: () {
                print("[TEMP] Tutorial Started!");
                _stopPrototypeMessageAppearance();
                systemDataProvider.startTutorial();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 43, 138, 216),
                foregroundColor: Colors.white,
              ),
              child: const Text('Start Tutorial'),
            ),
            ElevatedButton(
              onPressed: () {
                _stopPrototypeMessageAppearance();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 216, 43, 43),
                foregroundColor: Colors.white,
              ),
              child: const Text('Skip Tutorial'),
            ),
          ],
        ),
      ],
    );
  }

  /// By using SharedPreferences to store variable value device-wise, this setting will persist through app restarts
  void _stopPrototypeMessageAppearance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('prototypeInfoDisplayed', true);
  }
}

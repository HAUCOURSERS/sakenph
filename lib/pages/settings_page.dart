import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/providers/provider_system_data.dart';
import 'package:sakenph/providers/provider_system_vars.dart';
import 'package:sakenph/providers/provider_tutorial_mechanics.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPage();
}

class _SettingsPage extends State<SettingsPage> {
  bool hasPressedTheResetButton = false;
  @override
  Widget build(BuildContext context) {
    SystemVariablesProvider systemVariablesProvider = context
        .read<SystemVariablesProvider>();
    SystemDataProvider systemDataProvider = context.read<SystemDataProvider>();
    TutorialMechanicsProvider tutorialMechanicsProvider = context
        .read<TutorialMechanicsProvider>();
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.black,
        ),
        backgroundColor: Colors.blue,
        title: Text('Navigation Settings'),
      ),
      body: Column(
        children: [
          ListTile(
            title: Text('Include Traffic'),
            trailing: Switch(
              value: context.watch<SystemVariablesProvider>().includeTraffic,
              onChanged: (value) {
                if (systemDataProvider.isTutorialOngoing) {
                  tutorialMechanicsProvider.moveToStage12();
                }
                systemVariablesProvider.setIncludeTraffic = value;
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 0, bottom: 5),
            child: Text(
              'Traffic data utilized by the app may not be accurate.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 0, bottom: 5),
            child: Text(
              'Traffic data is provided by the TomTom Traffic API.',
              style: TextStyle(
                fontSize: 13,
                color: const Color.fromARGB(255, 53, 53, 53),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          ListTile(
            title: Text('Reset App Internal Data'),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // button fill color
                foregroundColor: Colors.white, // text/icon color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                systemDataProvider.clearSharedPreferences();
                setState(() {
                  hasPressedTheResetButton = true;
                });
              },
              child: Text("Reset"),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 0, bottom: 5),
            child: Text(
              (!hasPressedTheResetButton
                  ? 'Makes the landing message appear again'
                  : 'The landing message will appear again the next time the app loads.'),
              style: TextStyle(
                fontSize: 13,
                color: const Color.fromARGB(255, 27, 14, 14),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

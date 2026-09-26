import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/providers/provider_system_data.dart';
import 'package:sakenph/providers/provider_system_vars.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPage();
}

class _SettingsPage extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    SystemVariablesProvider systemVariablesProvider = context
        .read<SystemVariablesProvider>();
    SystemDataProvider systemDataProvider = context.read<SystemDataProvider>();
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
            title: Text('DEBUG: Clear SharedPreferences'),
            trailing: GestureDetector(
              onTap: () async {
                systemDataProvider.clearSharedPreferences();
              },
              child: Container(
                height: 20,
                width: 40,
                decoration: BoxDecoration(color: Colors.redAccent),
                child: Center(
                  child: Text("Reset", style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

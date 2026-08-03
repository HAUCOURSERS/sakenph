import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPage();
}

class _SettingsPage extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
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
              value: context
                  .watch<SystemVariablesProvider>()
                  .includeTraffic,
              onChanged: (value) {
                context.read<SystemVariablesProvider>().setIncludeTraffic = value;
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Traffic data is provided by the TomTom Traffic API.',
              style: TextStyle(fontSize: 13, color: const Color.fromARGB(255, 53, 53, 53)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

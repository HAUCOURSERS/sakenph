import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPage();
}

class _SettingsPage extends State<SettingsPage> {
  bool toggleToda = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text('Navigation Settings'),
      ),
      body: Column(
        children: [
          ListTile(
            title: Text('Tricycles'),
            trailing: Switch(
              value: toggleToda,
              onChanged: (value) {
                setState(() {
                  toggleToda = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

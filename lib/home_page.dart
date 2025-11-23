import 'package:flutter/material.dart';
import 'package:sakenph/auth_service.dart';
import 'package:sakenph/map_widget.dart';
import 'package:sakenph/ors_api.dart';
import 'package:sakenph/settings_page.dart';
import 'package:http/http.dart' as http;
import 'dart:developer';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
    
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue,
        title: ListTile(
          title: Text("Test"),
          trailing: PopupMenuButton(
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'Settings', child: Text('Settings')),
              PopupMenuItem<String>(value: 'Log out', child: Text('Log out')),
            ],
            onSelected: (value) async {
              if (value=='Log out') {
                try {
                  await AuthService().signOut();
                } catch (e) {
                  return;
                }
              } else if (value=='Settings') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              }
            }
          )
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () async {

        var response = await http.get(OpenRouteService().getRoute('120.59007831390122,15.182698929441157', '120.57995791303243,15.166703930958025'));

        log(response.body);
      }),
      body: MapWidget()
    );
  }
}
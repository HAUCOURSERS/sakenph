import 'package:flutter/material.dart';
import 'package:sakenph/auth_service.dart';
import 'package:sakenph/map_widget.dart';

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
              PopupMenuItem<String>(value: 'Log out', child: Text('Log out')),
            ],
            onSelected: (value) async {
              if (value=='Log out') {
                try {
                  await AuthService().signOut();
                } catch (e) {
                  return;
                }
              }
            }
          )
        ),
      ),
      body: MapWidget()
    );
  }
}
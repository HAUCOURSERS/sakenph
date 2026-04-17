import 'package:flutter/material.dart';
import 'package:sakenph/map_widget.dart';
import 'package:sakenph/settings_page.dart';
import 'package:http/http.dart' as http;
import 'dart:developer';
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  late Future<Map<dynamic, dynamic>> json;
  String originName = '';
  String destName = '';

  @override
  void initState() {
    super.initState();
    json = fetchData();

  }

  Future<String> reverseGeocode({required double longitude, required double latitude}) async {
    final response = await http.get(Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=jsonv2'));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonObject = jsonDecode(response.body);

      return jsonObject['display_name'];
    } else {
      throw Exception('Failed to load JSON');
    }
  }


  Future<Map<String, dynamic>> fetchData() async {
    String localIp = "192.168.100.7";
    final response = await http.get(Uri.parse('http://${localIp}:8000/flutterTest'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load JSON');
    }
  }
    
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
            ],
            onSelected: (value) async {
              if (value=='Settings') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              }
            }
          )
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () async {
      }),
      body: Stack(
        children: [
          
          MapWidget(),
          Center(
            child: Column(
              children: [
                Container(
                  width: 320, height: 40,
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width:1),
                    color: const Color.fromARGB(255, 227, 241, 255),
                    borderRadius: BorderRadius.circular(32)
                  ),
                  child: Center(
                    child: Text("From:"),
                  )
                ),
                Container(
                  width: 320, height: 40,
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width:1),
                    color: const Color.fromARGB(255, 227, 241, 255),
                    borderRadius: BorderRadius.circular(32)
                  ),
                  child: Center(
                    child: Text("To:"),
                  )
                ),

                Container(
                  width: 320, height: 40,
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width:1),
                    color: const Color.fromARGB(255, 227, 241, 255),
                    borderRadius: BorderRadius.circular(32)
                  ),
                  child: Center(
                    child: FutureBuilder(
                      future: json, 
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text(snapshot.data!['key']);
                        } else {
                          return Text('${snapshot.error}');
                        }
                      }
                      ),
                  )
                ),
              ],
            ),
          )
        ],
      )
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChrome, SystemUiOverlayStyle;
// import 'package:sakenph/auth_gate.dart';
// import 'package:sakenph/login_register.dart';
import 'package:sakenph/home_page.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/providers/provider_search_results.dart';
import 'package:sakenph/providers/provider_selected_loc.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

void main() async {
  // WidgetsFlutterBinding.ensureInitialized();

  // await Supabase.initialize(
  //   url: 'https://tfycptprhagrgpxccjiy.supabase.co',
  //   anonKey: 'sb_publishable_M6rcjMdAMWceiBpMkQQOVg_ejVFeKK7'
  // );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LatLongProvider()),
        ChangeNotifierProvider(create: (_) => SystemVariablesProvider()),
        ChangeNotifierProvider(create: (_) => SearchResultsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'saken.ph',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      home: const HomePage(),
    );
  }
}

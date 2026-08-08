import 'package:flutter/material.dart';
import 'package:sakenph/globals/functions/system/on_app_start.dart';

// import 'package:sakenph/auth_gate.dart';
// import 'package:sakenph/login_register.dart';
import 'package:sakenph/home_page.dart';

// import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sakenph/providers/provider_map_helper.dart';
import 'package:sakenph/providers/provider_search_details.dart';
import 'package:sakenph/providers/provider_system_tasks.dart';
import 'package:sakenph/providers/provider_system_vars.dart';

void main() async {
  runAtMain();

  FlutterError.onError = (FlutterErrorDetails details) {
    // Define the error or text you want to block
    final errorMessage = details.exception.toString();

    // keeps spamming while using chrome debugger.
    if (errorMessage.contains(
      'Another exception was thrown: Assertion failed:',
    )) {
      // Suppress/skip printing this specific error
      return;
    }

    // Fallback to default behavior for all other errors
    FlutterError.dumpErrorToConsole(details);
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MapHelperProvider()),
        ChangeNotifierProvider(create: (_) => SystemVariablesProvider()),
        ChangeNotifierProvider(create: (_) => SearchDetailsProvider()),
        ChangeNotifierProvider(create: (_) => SystemTasksProvder()),
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

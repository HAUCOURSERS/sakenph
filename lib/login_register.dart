import 'package:flutter/material.dart';
import 'package:sakenph/login_page.dart';
import 'package:sakenph/register_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginRegister extends StatefulWidget {
  const LoginRegister({super.key});

  @override
  State<LoginRegister> createState() => _LoginRegister();
}

class _LoginRegister extends State<LoginRegister> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(backgroundColor: colorScheme.primary),
      body: Center(
        child: Column(
        children: [
          Container(
            height: 520,
            child: Text("saken.ph"),
          ),

          TextButton(
            onPressed: () {
               Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            }, 
            child: Container(
              width: 320,
              decoration: BoxDecoration(
                color: colorScheme.secondary, 
                borderRadius: BorderRadius.circular(32)
              ),
              padding: EdgeInsets.all(10),
              child: Text(
                "Login",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.surface,
                  fontSize: 24,
                ),
              )
            )
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => RegisterPage()),
              );
            }, 
            child: Container(
              width: 320,
              decoration: BoxDecoration(
                color: colorScheme.secondary, 
                borderRadius: BorderRadius.circular(32)
              ),
              padding: EdgeInsets.all(10),
              child: Text(
                "Register",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.surface,
                  fontSize: 24,
                ),
              )
            )
          )
        ],
      ),
      )
    );
  }
}
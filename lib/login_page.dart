

import 'package:flutter/material.dart';
import 'package:sakenph/auth_gate.dart';
import 'package:sakenph/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPage();
}

class _LoginPage extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? emailErrorMessage;
  String? passwordErrorMessage;
  String generalErrorMessage = "";

  bool checkCredentials() {
    if (_emailController.text != "") {
      if (RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(_emailController.text)) {
        emailErrorMessage = null;
      } else {
        emailErrorMessage = "Please input a valid email address";
      }
    } else {
      emailErrorMessage = "Please input an email";
    }

    if (_passwordController.text == "") {
      passwordErrorMessage = "Please input a password";
    } else {
      passwordErrorMessage = null;
    }

    setState((){});
    if (emailErrorMessage == null && passwordErrorMessage == null) {
      return true;
    } else {
      return false;
    }
  }

  void clickedLogin() async {
    try {
      if (checkCredentials()) {
        await AuthService().logInWithCredentials(email: _emailController.text, password: _passwordController.text);

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => AuthGate()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (e is AuthApiException) {
        if (e.code == "email_not_confirmed") {
          emailErrorMessage = ""; passwordErrorMessage = "";
          generalErrorMessage = "Please confirm email.";

        } else if (e.code == "invalid_credentials") {
          emailErrorMessage = ""; passwordErrorMessage = "";
          generalErrorMessage = "Credentials are invalid.";

        } else {
          emailErrorMessage = ""; passwordErrorMessage = "";
          generalErrorMessage = "Error: ${e.message}";
        }
        
      } else {
        emailErrorMessage = ""; passwordErrorMessage = "";
        generalErrorMessage = "Error: $e";
      }

      setState((){});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 220,
              child: Text("saken.ph"),
            ),

            Text("Email", 
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold
              )
            ),
            Container(
              margin: EdgeInsets.only(top: 8, bottom: 8),
              width: 320,
              child: Column(
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      errorText: emailErrorMessage,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Text("Password", 
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold
              )
            ),
            Container(
              margin: EdgeInsets.only(top: 8, bottom: 8),
              width: 320,
              child: Column(
                children: [
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      errorText: passwordErrorMessage,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Text(
              generalErrorMessage,
              style: TextStyle(
                color: Colors.red
              ),
            ),

            TextButton(
              onPressed: clickedLogin,
              child: Container(
                width: 320,
                decoration: BoxDecoration(
                  color: Colors.blueAccent, 
                  borderRadius: BorderRadius.circular(32)
                ),
                padding: EdgeInsets.all(10),
                child: Text(
                  "Login",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                )
              )
            )
          ]
        )
      )
    );
  }
}
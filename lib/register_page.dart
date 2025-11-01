

import 'package:flutter/material.dart';
import 'package:sakenph/email_sent_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sakenph/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPage();
}

class _RegisterPage extends State<RegisterPage> {
  TextEditingController emailController = TextEditingController();
  // TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController rePasswordController = TextEditingController();

  String? emailErrorMessage;
  String? passwordErrorMessage;
  String? rePasswordErrorMessage;

  bool validCredentialInput() {
    if (emailController.text != "") {
      if (RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(emailController.text)) {
        emailErrorMessage = null;
      } else {
        emailErrorMessage = "Please input a valid email address";
      }
    } else {
      emailErrorMessage = "Please input an email";
    }

    if (passwordController.text != "") {
      if (RegExp(r"^.{6,32}$").hasMatch(passwordController.text)) {
        passwordErrorMessage = null;
      } else {
        passwordErrorMessage = "Password should have 6-32 characters";
      }
    } else {
      emailErrorMessage = "Please input a password";
    }
    // if (usernameController.text != "") {
    //   if (RegExp(r"^[a-zA-Z0-9_-]{3,16}$").hasMatch(usernameController.text)) {
    //     usernameErrorMessage = null;
    //   } else {
    //     usernameErrorMessage = "Username should only contain 3-16 characters, and alphanumeric characters, underscore, and period.";
    //   }
    // } else {
    //   usernameErrorMessage = "Please input a username";
    // }

    setState((){});
    if (emailErrorMessage == null && passwordErrorMessage == null && rePasswordErrorMessage == null) {
      return true;
    } else {
      return false;
    }
  }

  void registerAccount() async {
    final authService = AuthService();
    try {
      if (validCredentialInput()) {
        await authService.registerAccount(email: emailController.text, password: passwordController.text);

        // Please fix this
        print(emailController.text);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => EmailSentPage(email: emailController.text)),
        );
      }
    } catch (e) {
      print(e);
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
              child: Text(
                "Register Account",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold
                )
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Email Address", style: Theme.of(context).textTheme.labelLarge),
                Container(
                  margin: EdgeInsets.only(top: 8, bottom: 8),
                  width: 320,
                  child: Column(
                    children: [
                      TextField(
                        controller: emailController,
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
              ],
            ),
            

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Password", style: Theme.of(context).textTheme.labelLarge),
                Container(
                  margin: EdgeInsets.only(top: 8, bottom: 8),
                  width: 320,
                  child: Column(
                    children: [
                      TextField(
                        controller: passwordController,
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
              ],
            ),

            TextButton(
              onPressed: registerAccount, 
              child: Container(
                width: 320,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary, 
                  borderRadius: BorderRadius.circular(32)
                ),
                padding: EdgeInsets.all(10),
                child: Text(
                  "Submit",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.surface,
                    fontSize: 24,
                  ),
                )
              )
            ),
          ]
        )
      )
    );
  }
}
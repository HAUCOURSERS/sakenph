

import 'package:flutter/material.dart';
import 'package:sakenph/login_page.dart';
import 'package:sakenph/login_register.dart';

class EmailSentPage extends StatelessWidget {
  final String email;

  const EmailSentPage({super.key, required this.email});

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SizedBox(
        child: Column(
          children: [
            Text(
              "Email Sent!",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold
              )
            ),

            Text(
              "Please check email sent to '$email' to verify your account.",
              style: TextStyle(
                fontSize: 16,
              )
            ),

            TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginRegister()),
                  (route) => false,
                );
              },
              child: Container(
                width: 320,
                decoration: BoxDecoration(
                  color: Colors.blueAccent, 
                  borderRadius: BorderRadius.circular(32)
                ),
                padding: EdgeInsets.all(10),
                child: Text(
                  "Go to Login",
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

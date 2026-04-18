import 'package:flutter/material.dart';

class AppName extends StatelessWidget {
  const AppName({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(

        body: Center(
          child: Text(
            'Campus Crush',
            style: const TextStyle(
              fontFamily: 'DancingScript',
              fontSize: 48,
              fontWeight: FontWeight.bold,
              //color: Colors.pinkAccent,
              letterSpacing: 1.2,
            ),
          )

        ),
      ),
    );
  }
}

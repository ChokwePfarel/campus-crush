
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PrivateProfilePage extends StatelessWidget {

  const PrivateProfilePage({super.key,});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // white background
      appBar: AppBar(
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [


            Icon(Icons.lock,
            color: Colors.grey,
              size: 50,
            ),

            const SizedBox(height: 10),


            const Text(
              "This account is private",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.systemGrey,
              ),
            ),

          ],
        ),
      ),
    );
  }
}


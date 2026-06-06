import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SuspendedPage extends StatefulWidget {
  const SuspendedPage({super.key});

  @override
  State<SuspendedPage> createState() => _SuspendedPageState();
}

class _SuspendedPageState extends State<SuspendedPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Suspended icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.block,
                size: 80,
                color: Colors.red.shade700,
              ),
            ),

            const SizedBox(height: 32),

            // Suspended title
            const Text(
              'ACCOUNT',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),

            const Text(
              'SUSPENDED',
              style: TextStyle(
                color: Colors.red,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 24),

            // Message box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 40,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Your account has been suspended due to multiple violations of our community guidelines.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                ],
              ),
            ),


          ],
        ),
      ),
    );
  }
}
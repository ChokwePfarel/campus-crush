import 'package:dating_app/core/utils/auth_gate.dart';
import 'package:dating_app/presentation/pages/boarding_pages.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RootDecider extends StatefulWidget {
  const RootDecider({super.key});

  @override
  State<RootDecider> createState() => _RootDeciderState();
}

class _RootDeciderState extends State<RootDecider> {
  bool? seenOnboarding;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('seenOnboarding') ?? false;

    setState(() {
      seenOnboarding = seen;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (seenOnboarding == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // FIRST TIME  onboarding
    if (seenOnboarding == false) {
      return const BoardingPage();
    }
    //AFTER onboarding auth flow
    return const AuthGate();
  }
}
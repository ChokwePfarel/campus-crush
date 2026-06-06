import 'package:dating_app/presentation/pages/Warning_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WarningBar extends StatefulWidget {
  const WarningBar({super.key});

  @override
  State<WarningBar> createState() => _WarningBarState();
}

class _WarningBarState extends State<WarningBar> {
  bool _showContainer = true;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showContainer = prefs.getBool('showContainer') ?? true;
    });
  }

  Future<void> _dismissContainer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showContainer', false);
    setState(() {
      _showContainer = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showContainer) {
      return SizedBox.shrink();
    }

    return GestureDetector(
      onTap: (){
        Navigator.push(
          context, MaterialPageRoute(
            builder: (context) => const WarningPage()
        )
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.amber),
            Text(
              'Tap to view warning',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

          ],
        ),
      ),
    );
  }
}

import 'package:dating_app/core/utils/theme.dart';
import 'package:dating_app/presentation/pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class BoardingPage extends StatefulWidget {
  const BoardingPage({super.key});

  @override
  State<BoardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<BoardingPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> pages = [
    {
      "title": "Campus Crush",
      "desc":
          "A dating app exclusively for university students. Connect, vibe, and find your crush on campus.",
    },
    {
      "title": "Post Your Feelings",
      "desc":
          "Send posts directly to your crush or share with everyone. Confessions, questions, or crush posts, anonymously or not.",
    },
    {
      "title": "Spotted on Campus",
      "desc":
          "Describe what you're wearing and your location. Others nearby can find you in real time on the radar.",
    },
  ];

  void _nextPage() {
    if (_currentPage < pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _getStarted() async {

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: pages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (index == 2)
                        Image.asset("assets/onboarding3.png",
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      else
                        Image.asset(
                          index == 0
                              ? "assets/onboarding2.png"
                              : "assets/onboarding1.png",
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),

                      const SizedBox(height: 40),

                      Text(
                        pages[index]["title"]!,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        pages[index]["desc"]!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // DOTS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pages.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: _currentPage == index ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? AppStylee.primaryColor
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }),
          ),

          const SizedBox(height: 30),

          // BUTTONS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // PREVIOUS
                if (_currentPage > 0)
                  TextButton(
                    onPressed: _prevPage,
                    child: const Text("Previous"),
                  ),

                const Spacer(),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppStylee.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppStylee.connerRadius),
                    ),
                  ),
                  onPressed: _currentPage == pages.length - 1
                      ? _getStarted
                      : _nextPage,
                  child: Text(
                    _currentPage == pages.length - 1 ? "Get Started" : "Next",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int currentIndex = 0;

  final List<Map<String, String>> onboardingData = [
    {
      'image': 'assets/onboarding1.png',
      'title': 'Discover Services Nearby',
      'subtitle': 'Locate the nearest fuel, EV, or mechanic services—anytime, anywhere.',
    },
    {
      'image': 'assets/onboarding2.png',
      'title': 'Smart Assistance in Emergencies',
      'subtitle': 'Stranded? Tap once for towing, fuel delivery, or SOS support.',
    },
    {
      'image': 'assets/onboarding3.png',
      'title': 'Empower Your Driving Experience',
      'subtitle': 'Reviews, ratings, real-time maps, and smart tools—all in one app.',
    },
  ];

  void nextPage() async {
    if (currentIndex < onboardingData.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenOnboarding', true);
      Navigator.pushReplacementNamed(context, '/login'); // login screen is next
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _controller,
        onPageChanged: (index) {
          setState(() => currentIndex = index);
        },
        itemCount: onboardingData.length,
        itemBuilder: (context, index) {
          final item = onboardingData[index];
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(item['image']!, height: 300),
                const SizedBox(height: 40),
                Text(
                  item['title']!,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  item['subtitle']!,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                ElevatedButton(
                  onPressed: nextPage,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(currentIndex == onboardingData.length - 1 ? 'Get Started' : 'Next'),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

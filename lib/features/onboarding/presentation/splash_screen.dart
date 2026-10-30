import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Show the splash branding for a few seconds first.
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return; // widget may have been removed during the delay

    // Read the onboarding flag (SharedPreferences itself is an async gap).
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return; // guard AGAIN: every await can outlive the widget

    final isFirstLaunch = prefs.getBool('first_launch') ?? true;

    // Persist the flag before navigating; writing prefs is also async.
    if (isFirstLaunch) {
      await prefs.setBool('first_launch', false);
      if (!mounted) return; // guard before touching `context`
    }

    // Only use `context` once we're certain the State is still mounted.
    if (isFirstLaunch) {
      context.go('/landing');
    } else {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(height: 16),
            Text(
              'Wordsy',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

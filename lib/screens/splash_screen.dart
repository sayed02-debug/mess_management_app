import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller!);
    _controller!.forward();

    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    await Future.delayed(const Duration(seconds: 3)); // 3 seconds delay
    if (mounted) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Navigator.pushReplacementNamed(context, '/home'); // Logged in user goes to Home
      } else {
        Navigator.pushReplacementNamed(context, '/auth'); // Not logged in user goes to Login
      }
    }
  }

  @override
  void dispose() {
    _controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2D3748), // Dark grey
              Color(0xFF4B5563), // Lighter grey
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _animation!,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3), // Glow effect (blue)
                    blurRadius: 20,
                    spreadRadius: 10,
                  ),
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.3), // Glow effect (pink)
                    blurRadius: 20,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/splash_logo.png',
                width: 300, // Adjust size as needed
                height: 300,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
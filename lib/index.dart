import 'package:flutter/material.dart';
import 'email_signin_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Keep this route as a compatibility target (logout, old links),
    // but the desired flow is Splash → Email sign-in.
    return const EmailLoginScreen();
  }
}
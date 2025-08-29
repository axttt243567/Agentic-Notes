import 'package:flutter/material.dart';

class PexelsBannerNote extends StatelessWidget {
  const PexelsBannerNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2F3336)),
      ),
      child: const Text(
        'Tip: Add your Pexels API key in Profile to load banner images.',
        style: TextStyle(color: Color(0xFF71767B)),
      ),
    );
  }
}

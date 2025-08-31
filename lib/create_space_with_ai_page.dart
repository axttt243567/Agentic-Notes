import 'package:flutter/material.dart';

class CreateSpaceWithAiPage extends StatelessWidget {
  const CreateSpaceWithAiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create space with AI')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.auto_awesome, size: 42, color: Color(0xFF71767B)),
            SizedBox(height: 8),
            Text(
              'This page is intentionally blank for now',
              style: TextStyle(color: Color(0xFF71767B)),
            ),
          ],
        ),
      ),
    );
  }
}

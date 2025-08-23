import 'package:flutter/material.dart';

/// A blank placeholder home page.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: null,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(
              child: InputChip(
                label: Text('me', style: TextStyle(color: Colors.white70)),
                shape: StadiumBorder(),
                backgroundColor: Colors.white10,
                side: BorderSide(color: Colors.white12),
                onPressed: null,
              ),
            ),
          ),
        ],
      ),
      // Keep intentionally simple body for now.
      body: const SafeArea(child: SizedBox.shrink()),
    );
  }
}

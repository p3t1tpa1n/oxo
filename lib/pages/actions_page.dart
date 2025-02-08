// lib/pages/actions_page.dart
import 'package:flutter/material.dart';

class ActionsPage extends StatelessWidget {
  const ActionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actions Page'),
      ),
      body: Center(
        child: Text('Actions Page'),
      ),
    );
  }
}
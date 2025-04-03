// lib/pages/shared/messaging_page.dart
import 'package:flutter/material.dart';

class MessagingPage extends StatelessWidget {
  const MessagingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messaging Page'),
      ),
      body: const Center(
        child: Text('Messaging Page'),
      ),
    );
  }
}
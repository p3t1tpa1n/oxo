// lib/pages/shared/messaging_page.dart
import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/chat_widget.dart';

class MessagingPage extends StatelessWidget {
  const MessagingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messaging Page'),
      ),
      body: Center(
        child: Text('Messaging Page'),
      ),
    );
  }
}
// lib/pages/partner/actions_page.dart
import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_drawer.dart';

class ActionsPage extends StatelessWidget {
  const ActionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(
        title: 'Actions',
        showBackButton: true,
      ),
      drawer: AppDrawer(),
      body: Center(
        child: Text('Actions Page'),
      ),
    );
  }
}
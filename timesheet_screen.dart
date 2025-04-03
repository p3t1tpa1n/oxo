import 'package:flutter/material.dart';

class TimesheetScreen extends StatelessWidget {
  const TimesheetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Timesheets")),
      body: const Center(
        child: Text("Suivi des heures de travail", style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
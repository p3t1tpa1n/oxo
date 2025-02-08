import 'package:flutter/material.dart';

class TimesheetScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Timesheets")),
      body: Center(
        child: Text("Suivi des heures de travail", style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
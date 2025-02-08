// lib/models/day_data.dart
import 'package:flutter/material.dart';

class DayData {
  final int day;
  final Color color;

  DayData({
    required this.day,
    required this.color,
  });

  // Simule une récupération depuis une base de données (à remplacer plus tard)
  static Future<List<DayData>> fetchDayData() async {
    await Future.delayed(const Duration(seconds: 1)); // Simule un délai réseau
    return [
      DayData(day: 11, color: Colors.green),
      DayData(day: 6, color: Colors.green),
      DayData(day: 8, color: Colors.green),
      DayData(day: 14, color: Colors.green),
      DayData(day: 16, color: Colors.orange),
      DayData(day: 20, color: Colors.green),
      DayData(day: 25, color: Colors.black),
    ];
  }
}
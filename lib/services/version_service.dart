import 'package:package_info_plus/package_info_plus.dart';
import 'package:version/version.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../config/github_config.dart';
import 'supabase_service.dart';
import 'package:flutter/material.dart';

class VersionService {
  static const String currentVersion = '1.0.0';
  
  // Vérifie si une mise à jour est disponible
  static Future<Map<String, dynamic>?> checkForUpdates() async {
    try {
      final response = await SupabaseService.client
          .from('app_versions')
          .select()
          .order('version', ascending: false)
          .limit(1)
          .single();
      
      final latestVersion = response['version'] as String;
      final minVersion = response['min_version'] as String;
      final downloadUrl = response['download_url'] as String;
      final releaseNotes = response['release_notes'] as String;
      final isMandatory = response['is_mandatory'] as bool;
      
      // Si la version actuelle est inférieure à la version minimale, mise à jour obligatoire
      if (_compareVersions(currentVersion, minVersion) < 0) {
        return {
          'updateAvailable': true,
          'isMandatory': true,
          'latestVersion': latestVersion,
          'downloadUrl': downloadUrl,
          'releaseNotes': releaseNotes,
        };
      }
      
      // Si la version actuelle est inférieure à la dernière version, mise à jour optionnelle
      if (_compareVersions(currentVersion, latestVersion) < 0) {
        return {
          'updateAvailable': true,
          'isMandatory': isMandatory,
          'latestVersion': latestVersion,
          'downloadUrl': downloadUrl,
          'releaseNotes': releaseNotes,
        };
      }
      
      // Pas de mise à jour nécessaire
      return {
        'updateAvailable': false,
      };
    } catch (e) {
      debugPrint('Erreur lors de la vérification des mises à jour : $e');
      return null;
    }
  }
  
  // Compare deux versions sémantiques (format: x.y.z)
  // Retourne:
  // -1 si version1 < version2
  //  0 si version1 = version2
  //  1 si version1 > version2
  static int _compareVersions(String version1, String version2) {
    final List<int> v1Parts = version1.split('.').map(int.parse).toList();
    final List<int> v2Parts = version2.split('.').map(int.parse).toList();
    
    for (int i = 0; i < 3; i++) {
      if (v1Parts[i] < v2Parts[i]) return -1;
      if (v1Parts[i] > v2Parts[i]) return 1;
    }
    
    return 0;
  }
} 
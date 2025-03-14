import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

class UpdateService {
  // TODO: Remplacez 'VOTRE_USERNAME' par votre nom d'utilisateur GitHub
  // et 'VOTRE_REPO' par le nom de votre repository
  // Exemple: 'https://api.github.com/repos/paul-username/oxo/releases/latest'
  static const String githubApiUrl = 'https://api.github.com/repos/p3t1tpa1n/oxo/releases/latest';
  static const String appName = 'oxo';

  static Future<Map<String, dynamic>?> checkForUpdates() async {
    try {
      // Récupérer la version actuelle de l'application
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Récupérer la dernière version depuis GitHub
      final response = await http.get(
        Uri.parse(githubApiUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['tag_name'].toString().replaceAll('v', '');

        // Comparer les versions
        if (_isNewerVersion(currentVersion, latestVersion)) {
          return {
            'version': latestVersion,
            'description': data['body'],
            'downloadUrl': _getAssetDownloadUrl(data['assets'], Platform.operatingSystem),
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la vérification des mises à jour: $e');
      return null;
    }
  }

  static bool _isNewerVersion(String currentVersion, String latestVersion) {
    List<int> current = currentVersion.split('.').map(int.parse).toList();
    List<int> latest = latestVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (latest[i] > current[i]) return true;
      if (latest[i] < current[i]) return false;
    }
    return false;
  }

  static String? _getAssetDownloadUrl(List<dynamic> assets, String platform) {
    String extension = '';
    switch (platform) {
      case 'macos':
        extension = '.dmg';
        break;
      case 'windows':
        extension = '.exe';
        break;
      case 'linux':
        extension = '.AppImage';
        break;
      default:
        return null;
    }

    final asset = assets.firstWhere(
      (asset) => asset['name'].toString().endsWith(extension),
      orElse: () => null,
    );

    return asset?['browser_download_url'];
  }

  static Future<void> downloadAndInstallUpdate(String downloadUrl) async {
    try {
      // Créer un dossier temporaire pour le téléchargement
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${appName}_update${_getFileExtension()}');

      // Télécharger le fichier
      final response = await http.get(Uri.parse(downloadUrl));
      await file.writeAsBytes(response.bodyBytes);

      // Lancer l'installation
      if (Platform.isMacOS) {
        await Process.run('open', [file.path]);
      } else if (Platform.isWindows) {
        await Process.run(file.path, []);
      } else if (Platform.isLinux) {
        await Process.run('chmod', ['+x', file.path]);
        await Process.run(file.path, []);
      }
    } catch (e) {
      debugPrint('Erreur lors du téléchargement/installation de la mise à jour: $e');
      rethrow;
    }
  }

  static String _getFileExtension() {
    if (Platform.isMacOS) return '.dmg';
    if (Platform.isWindows) return '.exe';
    if (Platform.isLinux) return '.AppImage';
    return '';
  }
} 
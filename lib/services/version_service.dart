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
  static const String currentVersion = '1.1.1';  // À mettre à jour à chaque release
  static const String githubOwner = 'p3t1tpa1n';  // À remplacer par votre nom d'utilisateur GitHub
  static const String githubRepo = 'oxo';  // À remplacer par le nom de votre repo
  static const String githubToken = GitHubConfig.token;

  // Pour les tests
  static String? _mockVersion;
  
  static void setMockVersion(String version) {
    _mockVersion = version;
  }

  static String? getCurrentMockVersion() {
    return _mockVersion;
  }

  // Méthode pour télécharger et installer automatiquement la mise à jour
  static Future<bool> downloadAndInstallUpdate(String downloadUrl) async {
    try {
      debugPrint('VersionService: Téléchargement de la nouvelle version...');
      
      // Télécharger le fichier de la mise à jour
      final response = await http.get(Uri.parse(downloadUrl));
      
      if (response.statusCode != 200) {
        debugPrint('VersionService: Erreur lors du téléchargement: ${response.statusCode}');
        return false;
      }
      
      // Créer un dossier temporaire pour stocker la mise à jour
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/oxo_update${_getFileExtension()}');
      
      // Écrire le contenu téléchargé dans le fichier
      await file.writeAsBytes(response.bodyBytes);
      debugPrint('VersionService: Mise à jour téléchargée: ${file.path}');
      
      // Installer la mise à jour
      return await _installUpdate(file.path);
    } catch (e, stackTrace) {
      debugPrint('VersionService: Erreur lors du téléchargement/installation: $e');
      debugPrint('VersionService: Stack trace: $stackTrace');
      return false;
    }
  }
  
  // Méthode privée pour installer la mise à jour selon la plateforme
  static Future<bool> _installUpdate(String filePath) async {
    try {
      debugPrint('VersionService: Installation de la mise à jour...');
      if (Platform.isMacOS) {
        // Sur macOS, ouvrir le fichier DMG
        final result = await Process.run('open', [filePath]);
        debugPrint('VersionService: Résultat de l\'ouverture: ${result.stdout}');
        if (result.exitCode != 0) {
          debugPrint('VersionService: Erreur lors de l\'ouverture: ${result.stderr}');
          return false;
        }
      } else if (Platform.isWindows) {
        // Sur Windows, exécuter le fichier EXE
        final result = await Process.run(filePath, []);
        if (result.exitCode != 0) {
          debugPrint('VersionService: Erreur lors de l\'exécution: ${result.stderr}');
          return false;
        }
      } else if (Platform.isLinux) {
        // Sur Linux, rendre le fichier exécutable puis l'exécuter
        await Process.run('chmod', ['+x', filePath]);
        final result = await Process.run(filePath, []);
        if (result.exitCode != 0) {
          debugPrint('VersionService: Erreur lors de l\'exécution: ${result.stderr}');
          return false;
        }
      } else {
        debugPrint('VersionService: Plateforme non supportée: ${Platform.operatingSystem}');
        return false;
      }
      
      debugPrint('VersionService: Mise à jour installée avec succès');
      return true;
    } catch (e, stackTrace) {
      debugPrint('VersionService: Erreur lors de l\'installation: $e');
      debugPrint('VersionService: Stack trace: $stackTrace');
      return false;
    }
  }
  
  // Méthode pour obtenir l'extension de fichier appropriée selon la plateforme
  static String _getFileExtension() {
    if (Platform.isMacOS) return '.dmg';
    if (Platform.isWindows) return '.exe';
    if (Platform.isLinux) return '.AppImage';
    return '';
  }

  static Future<Map<String, dynamic>?> checkForUpdates() async {
    try {
      debugPrint('VersionService: Vérification des mises à jour...');
      debugPrint('VersionService: Version actuelle = $currentVersion');
      debugPrint('VersionService: Mock version = $_mockVersion');
      
      if (_mockVersion != null) {
        debugPrint('VersionService: Utilisation de la version mockée = $_mockVersion');
        final currentAppVersion = Version.parse(currentVersion);
        final mockLatestVersion = Version.parse(_mockVersion!);
        
        final needsUpdate = currentAppVersion < mockLatestVersion;
        debugPrint('VersionService: needsUpdate = $needsUpdate');
        
        if (needsUpdate) {
          debugPrint('VersionService: Mise à jour nécessaire');
          return {
            'needs_update': true,
            'is_mandatory': true,
            'latest_version': _mockVersion,
            'changelog': 'Version de test pour vérifier le système de mise à jour',
            'download_url': 'https://example.com/download',
          };
        }
        debugPrint('VersionService: Pas de mise à jour nécessaire');
        return null;
      }

      debugPrint('VersionService: Requête API GitHub: $githubOwner/$githubRepo');
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'Authorization': 'token $githubToken',
        },
      );

      debugPrint('VersionService: Statut réponse API = ${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrint('VersionService: Erreur lors de la vérification des mises à jour: ${response.statusCode}');
        debugPrint('VersionService: Réponse: ${response.body}');
        return null;
      }

      final releaseData = json.decode(response.body);
      debugPrint('VersionService: Dernière version sur GitHub = ${releaseData['tag_name']}');
      
      final latestVersion = Version.parse(releaseData['tag_name'].replaceAll('v', ''));
      final currentAppVersion = Version.parse(currentVersion);

      final needsUpdate = currentAppVersion < latestVersion;
      debugPrint('VersionService: needsUpdate = $needsUpdate');
      
      if (needsUpdate) {
        debugPrint('VersionService: Mise à jour nécessaire');
        
        // Extraire l'URL de téléchargement directe du fichier d'installation
        String downloadUrl = '';
        if (releaseData['assets'] != null && (releaseData['assets'] as List).isNotEmpty) {
          final assets = releaseData['assets'] as List;
          final platformExtension = _getFileExtension();
          
          // Trouver l'asset correspondant à notre plateforme
          for (var asset in assets) {
            if (asset['name'].toString().endsWith(platformExtension)) {
              downloadUrl = asset['browser_download_url'];
              debugPrint('VersionService: URL de téléchargement trouvée: $downloadUrl');
              break;
            }
          }
        }
        
        // Si aucun asset spécifique n'a été trouvé, utiliser l'URL de la release
        if (downloadUrl.isEmpty) {
          downloadUrl = releaseData['html_url'];
          debugPrint('VersionService: Aucun asset trouvé, utilisation de l\'URL de la release: $downloadUrl');
        }
        
        return {
          'needs_update': true,
          'is_mandatory': true, // Vous pouvez ajouter une logique pour déterminer si la mise à jour est obligatoire
          'latest_version': releaseData['tag_name'].replaceAll('v', ''),
          'changelog': releaseData['body'],
          'download_url': downloadUrl,
        };
      }

      debugPrint('VersionService: Pas de mise à jour nécessaire');
      return null;
    } catch (e, stackTrace) {
      debugPrint('VersionService: Erreur lors de la vérification des mises à jour: $e');
      debugPrint('VersionService: Stack trace: $stackTrace');
      return null;
    }
  }

  // Méthode pour tester différents scénarios
  static Future<bool> testUpdateScenarios() async {
    try {
      // Test 1: Version égale (pas de mise à jour)
      setMockVersion('1.0.0');
      var result = await checkForUpdates();
      if (result != null) {
        print('❌ Test 1 échoué: Une mise à jour a été détectée alors que les versions sont identiques');
        return false;
      }
      print('✅ Test 1 réussi: Pas de mise à jour détectée pour la même version');

      // Test 2: Version supérieure (mise à jour nécessaire)
      setMockVersion('2.0.0');
      result = await checkForUpdates();
      if (result == null || !result['needs_update']) {
        print('❌ Test 2 échoué: Aucune mise à jour détectée alors qu\'une version supérieure existe');
        return false;
      }
      print('✅ Test 2 réussi: Mise à jour détectée pour une version supérieure');

      // Test 3: Version inférieure (pas de mise à jour)
      setMockVersion('0.9.0');
      result = await checkForUpdates();
      if (result != null) {
        print('❌ Test 3 échoué: Une mise à jour a été détectée pour une version inférieure');
        return false;
      }
      print('✅ Test 3 réussi: Pas de mise à jour détectée pour une version inférieure');

      // Réinitialiser le mock
      _mockVersion = null;
      print('✅ Tous les tests de version ont réussi');
      return true;
    } catch (e) {
      print('❌ Erreur lors des tests: $e');
      return false;
    }
  }
} 
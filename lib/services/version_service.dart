import 'package:package_info_plus/package_info_plus.dart';
import 'package:version/version.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/github_config.dart';
import 'supabase_service.dart';

class VersionService {
  static const String currentVersion = '1.1.0';  // À mettre à jour à chaque release
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

  static Future<Map<String, dynamic>?> checkForUpdates() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'Authorization': 'token $githubToken',
        },
      );

      if (response.statusCode != 200) {
        print('Erreur lors de la vérification des mises à jour: ${response.statusCode}');
        return null;
      }

      final releaseData = json.decode(response.body);
      final latestVersion = Version.parse(releaseData['tag_name'].replaceAll('v', ''));
      final currentAppVersion = Version.parse(currentVersion);

      final needsUpdate = currentAppVersion < latestVersion;

      if (needsUpdate) {
        return {
          'needs_update': true,
          'is_mandatory': true, // Vous pouvez ajouter une logique pour déterminer si la mise à jour est obligatoire
          'latest_version': releaseData['tag_name'].replaceAll('v', ''),
          'changelog': releaseData['body'],
          'download_url': releaseData['html_url'],
        };
      }

      return null;
    } catch (e) {
      print('Erreur lors de la vérification des mises à jour: $e');
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
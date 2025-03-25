// lib/pages/login_page.dart
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/version_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;
  bool _isCheckingForUpdates = true;

  @override
  void initState() {
    super.initState();
    // Vérifier les mises à jour au chargement de la page de connexion
    _checkForUpdates();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingForUpdates = true;
    });

    try {
      debugPrint('LoginPage: Vérification des mises à jour...');
      final updateInfo = await VersionService.checkForUpdates();
      
      if (updateInfo != null && mounted) {
        debugPrint('LoginPage: Mise à jour trouvée: ${updateInfo['latest_version']}');
        _showUpdateDialog(
          updateInfo['latest_version'],
          updateInfo['changelog'],
          updateInfo['download_url'],
          updateInfo['is_mandatory'],
        );
      } else {
        debugPrint('LoginPage: Aucune mise à jour disponible');
      }
    } catch (e) {
      debugPrint('LoginPage: Erreur lors de la vérification des mises à jour: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingForUpdates = false;
        });
      }
    }
  }

  void _showUpdateDialog(String version, String? changelog, String downloadUrl, bool isMandatory) {
    showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (context) => AlertDialog(
        title: Text('Nouvelle version disponible (v$version)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMandatory 
                  ? 'Une mise à jour obligatoire est disponible.'
                  : 'Une nouvelle version de l\'application est disponible.',
              ),
              if (changelog != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Nouveautés :',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(changelog),
              ],
            ],
          ),
        ),
        actions: [
          if (!isMandatory)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Plus tard'),
            ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              Navigator.of(context).pop(); // Fermer la boîte de dialogue
              
              // Afficher un dialogue de progression avec option d'annulation
              final completer = _showProgressDialogWithCancel('Téléchargement et installation en cours...');
              
              // Télécharger et installer la mise à jour avec un délai maximum
              bool success = false;
              try {
                success = await VersionService.downloadAndInstallUpdate(downloadUrl)
                    .timeout(const Duration(minutes: 2));
              } catch (e) {
                debugPrint('Erreur lors du téléchargement: $e');
                success = false;
              }
              
              // Fermer le dialogue de progression si toujours affiché
              if (!completer.isCompleted && mounted) {
                completer.complete();
                Navigator.of(context).pop();
              }
              
              if (success) {
                if (mounted) {
                  // Montrer un message de succès
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mise à jour installée. Veuillez redémarrer l\'application.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Si la mise à jour est obligatoire, quitter l'application
                  if (isMandatory) {
                    // Attendre un peu pour que l'utilisateur voie le message
                    await Future.delayed(const Duration(seconds: 3));
                    // Quitter l'application
                    SupabaseService.signOut();
                  }
                }
              } else {
                if (mounted) {
                  // Proposer d'ouvrir le lien de téléchargement dans le navigateur
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Échec de la mise à jour automatique'),
                      content: const Text(
                        'Le téléchargement ou l\'installation automatique a échoué. '
                        'Voulez-vous télécharger manuellement la mise à jour dans votre navigateur ?'
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            setState(() {
                              _isLoading = false;
                            });
                          },
                          child: const Text('Annuler'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            final url = Uri.parse(downloadUrl);
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                            setState(() {
                              _isLoading = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3D54),
                          ),
                          child: const Text('Télécharger manuellement'),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3D54),
            ),
            child: const Text('Mettre à jour maintenant'),
          ),
        ],
      ),
    );
  }
  
  // Affiche un dialogue de progression avec un bouton d'annulation
  Completer _showProgressDialogWithCancel(String message) {
    final completer = Completer();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  if (!completer.isCompleted) {
                    completer.complete();
                    Navigator.of(context).pop();
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
                child: const Text('Annuler'),
              ),
            ],
          ),
        ),
      ),
    );
    
    return completer;
  }

  Future<void> _login() async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      debugPrint('Tentative de connexion avec: $email');

      final response = await SupabaseService.signIn(
        email: email,
        password: password,
      );

      debugPrint('Réponse de Supabase: ${response.user}');

      if (response.user != null) {
        if (mounted) {
          final userRole = await SupabaseService.getCurrentUserRole();
          
          if (userRole == null) {
            setState(() {
              _errorMessage = 'Erreur: Rôle utilisateur non défini';
              _isLoading = false;
            });
            return;
          }

          debugPrint('Rôle utilisateur: $userRole');
          switch (userRole) {
            case UserRole.associe:
              Navigator.pushReplacementNamed(context, '/');
              break;
            case UserRole.partenaire:
              Navigator.pushReplacementNamed(context, '/dashboard');
              break;
          }
        }
      } else {
        setState(() {
          _errorMessage = 'Erreur de connexion: Utilisateur non trouvé';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur de connexion: $e');
      setState(() {
        _errorMessage = 'Erreur de connexion: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isCheckingForUpdates
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Vérification des mises à jour...'),
                  ],
                ),
              )
            : Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/oxo_logo.png',
                              height: 80,
                              errorBuilder: (context, error, stackTrace) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.business,
                                      size: 80,
                                      color: Color(0xFF122b35),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'OXO',
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF122b35),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),
                        const Text(
                          'Bienvenue',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF122b35),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Veuillez entrer vos identifiants',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        // Champ Email
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: Icon(
                                  Icons.email_outlined,
                                  color: Colors.grey,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    hintText: 'Email',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Champ Password
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: Icon(
                                  Icons.lock_outline,
                                  color: Colors.grey,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    hintText: 'Mot de passe',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _errorMessage,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 24),
                        // Bouton Connexion
                        ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1784af),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Se connecter',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
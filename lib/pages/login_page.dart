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
          updateInfo['isMandatory'],
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

  void _showUpdateDialog(String version, String changelog, String downloadUrl, bool isMandatory) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (context) => AlertDialog(
        title: Text('Mise à jour disponible (v$version)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMandatory
                    ? 'Une mise à jour obligatoire est disponible. Veuillez mettre à jour pour continuer.'
                    : 'Une nouvelle version est disponible. Souhaitez-vous la télécharger ?',
              ),
              const SizedBox(height: 16),
              const Text(
                'Notes de version:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(changelog),
            ],
          ),
        ),
        actions: [
          if (!isMandatory)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Plus tard'),
            ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return const AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Préparation de la mise à jour...'),
                      ],
                    ),
                  );
                },
              );
              
              try {
                final Uri url = Uri.parse(downloadUrl);
                
                // Ouvrir l'URL de téléchargement dans le navigateur
                await launchUrl(url, mode: LaunchMode.externalApplication);
                
                if (mounted) {
                  Navigator.of(context).pop(); // Fermer la boîte de dialogue de progression
                  
                  // Afficher une confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Téléchargement lancé dans votre navigateur'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                  
                  // Si la mise à jour est obligatoire, déconnecter l'utilisateur
                  if (isMandatory && mounted) {
                    // Attendre un moment avant de déconnecter
                    Future.delayed(const Duration(seconds: 3), () async {
                      await SupabaseService.signOut();
                      if (mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    });
                  }
                }
              } catch (e) {
                debugPrint('Erreur lors du lancement de l\'URL: $e');
                if (mounted) {
                  Navigator.of(context).pop(); // Fermer la boîte de dialogue de progression
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors du téléchargement: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                // Réinitialiser l'état de chargement
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
            child: const Text('Télécharger'),
          ),
        ],
      ),
    );
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
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo et titre
                        Center(
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3D54),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                "OXO",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Connexion',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3D54),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        
                        // Champ d'email
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFDDDDDD),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF1E3D54),
                                width: 2,
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        
                        // Champ de mot de passe
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFDDDDDD),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF1E3D54),
                                width: 2,
                              ),
                            ),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 8),
                        
                        // Message d'erreur
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                        
                        // Bouton de connexion
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3D54),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'SE CONNECTER',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Lien de récupération
                        TextButton(
                          onPressed: () {
                            // TODO: Implémenter la récupération de mot de passe
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Fonctionnalité à venir'),
                              ),
                            );
                          },
                          child: const Text(
                            'Mot de passe oublié?',
                            style: TextStyle(
                              color: Color(0xFF1E3D54),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
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
// lib/pages/login_page.dart
import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../models/user_role.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
        if (!mounted) return;
        
        final userRole = SupabaseService.currentUserRole;
        
        if (!mounted) return;
        
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
            Navigator.pushReplacementNamed(context, '/associate');
            break;
          case UserRole.partenaire:
            Navigator.pushReplacementNamed(context, '/partner');
            break;
          case UserRole.admin:
            Navigator.pushReplacementNamed(context, '/associate');
            break;
          case UserRole.client:
            Navigator.pushReplacementNamed(context, '/client');
            break;
          default:
            // Si le rôle n'est pas reconnu, rediriger vers la page de connexion
            setState(() {
              _errorMessage = 'Erreur: Rôle utilisateur non reconnu';
              _isLoading = false;
            });
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
        // Message d'erreur plus convivial
        String errorMsg = 'Une erreur est survenue lors de la connexion';
        if (e.toString().contains('Failed to fetch')) {
          errorMsg = 'Impossible de se connecter au serveur. Vérifiez votre connexion internet ou contactez l\'administrateur.';
        } else if (e.toString().contains('Invalid login credentials')) {
          errorMsg = 'Email ou mot de passe incorrect';
        }
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
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
                      final email = _emailController.text.trim();
                      if (email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Veuillez saisir votre adresse email avant de demander une réinitialisation'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Réinitialisation du mot de passe'),
                          content: Text(
                            'Un email de réinitialisation de mot de passe va être envoyé à $email.\n\n'
                            'Consultez votre boîte de réception et suivez les instructions pour réinitialiser votre mot de passe.'
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                try {
                                  await SupabaseService.client.auth.resetPasswordForEmail(email);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Email de réinitialisation envoyé. Vérifiez votre boîte de réception.'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Erreur lors de l\'envoi: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('Envoyer'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text(
                      'Mot de passe oublié ?',
                      style: TextStyle(
                        color: Color(0xFF1E3D54),
                        fontWeight: FontWeight.w500,
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
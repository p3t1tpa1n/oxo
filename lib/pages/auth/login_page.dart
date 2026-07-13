// lib/pages/login_page.dart
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/supabase_service.dart';
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
  bool _obscurePassword = true;

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
        
        // Récupérer le rôle via une fonction asynchrone pour s'assurer d'avoir le dernier état
        final userRole = await SupabaseService.getCurrentUserRole();
        debugPrint('Rôle utilisateur récupéré: $userRole');
        
        if (!mounted) return;
        
        if (userRole == null) {
          debugPrint('ERREUR: Rôle utilisateur est null');
          setState(() {
            _errorMessage = 'Erreur: Rôle utilisateur non défini';
            _isLoading = false;
          });
          return;
        }

        // Vérifier le rôle explicitement pour le débogage
        final roleValue = userRole.toString();
        debugPrint('Valeur du rôle utilisateur: $roleValue');

        // Gestion explicite du cas client pour Vercel
        if (roleValue.toLowerCase() == 'client') {
          debugPrint('Détection directe du rôle client par sa valeur, redirection vers /client/invoices');
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/client/invoices');
          return;
        }

        debugPrint('Rôle utilisateur: $userRole');
        switch (userRole.toString().toLowerCase()) {
          case 'associe':
          case 'associé':
            Navigator.pushReplacementNamed(context, '/projects');
            break;
          case 'partenaire':
            Navigator.pushReplacementNamed(context, '/projects');
            break;
          case 'admin':
          case 'administrateur':
            Navigator.pushReplacementNamed(context, '/projects');
            break;
          case 'client':
            debugPrint('Rôle client détecté dans le switch, redirection vers /client/invoices');
            Navigator.pushReplacementNamed(context, '/client/invoices');
            break;
          default:
            // Si le rôle n'est pas reconnu, rediriger vers la page de connexion
            debugPrint('Rôle non reconnu dans le switch: $userRole');
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
      backgroundColor: AppTheme.colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(32.0),
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: AppTheme.colors.surface,
                borderRadius: BorderRadius.circular(AppTheme.radius.large),
                border: Border.all(color: AppTheme.colors.border, width: 0.5),
                boxShadow: AppTheme.shadows.medium,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Marque
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.colors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          "OXO",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Connexion',
                    style: AppTheme.typography.h2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Accédez à votre espace OXO',
                    style: AppTheme.typography.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Champ d'email
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.username],
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Champ de mot de passe
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        tooltip: _obscurePassword
                            ? 'Afficher le mot de passe'
                            : 'Masquer le mot de passe',
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.password],
                    // Entrée = connexion
                    onSubmitted: (_) => _isLoading ? null : _login(),
                  ),

                  // Message d'erreur
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.colors.error.withOpacity(0.08),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radius.small),
                        border: Border.all(
                          color: AppTheme.colors.error.withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              size: 18, color: AppTheme.colors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                color: AppTheme.colors.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Bouton de connexion
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Se connecter',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Lien de récupération
                  TextButton(
                    onPressed: () {
                      final email = _emailController.text.trim();
                      if (email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Veuillez saisir votre adresse email avant de demander une réinitialisation'),
                            backgroundColor: const Color(0xFFB07B2E),
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
                                        backgroundColor: const Color(0xFF2E7D5B),
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
                    child: Text(
                      'Mot de passe oublié ?',
                      style: TextStyle(
                        color: AppTheme.colors.secondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
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
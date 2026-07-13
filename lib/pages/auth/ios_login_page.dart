import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../app/shells/mobile_shell_professional.dart';

class IOSLoginPage extends StatefulWidget {
  const IOSLoginPage({Key? key}) : super(key: key);

  @override
  State<IOSLoginPage> createState() => _IOSLoginPageState();
}

class _IOSLoginPageState extends State<IOSLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Veuillez remplir tous les champs');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = ''; });

    try {
      final result = await SupabaseService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (result.user != null) {
        if (!mounted) return;
        final userRole = await SupabaseService.getCurrentUserRole();
        if (!mounted) return;

        if (userRole == null) {
          setState(() { _errorMessage = 'Erreur: Rôle utilisateur non défini'; _isLoading = false; });
          return;
        }

        final roleValue = userRole.toString().toLowerCase();
        if (roleValue.contains('client')) {
          Navigator.of(context).pushNamedAndRemoveUntil('/client/invoices', (route) => false);
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MobileShellProfessional()),
            (route) => false,
          );
        }
      } else {
        setState(() { _errorMessage = 'Identifiants incorrects.'; _isLoading = false; });
      }
    } catch (e) {
      String msg = 'Une erreur est survenue';
      if (e.toString().contains('Failed to fetch')) msg = 'Impossible de se connecter. Vérifiez votre connexion.';
      if (e.toString().contains('Invalid login credentials')) msg = 'Email ou mot de passe incorrect';
      setState(() { _errorMessage = msg; _isLoading = false; });
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saisissez votre email d\'abord')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialisation du mot de passe'),
        content: Text('Un email de réinitialisation va être envoyé à $email.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Envoyer')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SupabaseService.client.auth.resetPasswordForEmail(email);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email envoyé. Vérifiez votre boîte de réception.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible d\'envoyer l\'email.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              // Logo
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.colors.primary,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Center(
                        child: Text(
                          'OXO',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Bienvenue', style: AppTheme.typography.h1),
                    const SizedBox(height: 8),
                    Text('Connectez-vous à votre compte',
                        style: AppTheme.typography.bodyMedium.copyWith(color: AppTheme.colors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              // Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Adresse e-mail',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              // Password
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  hintText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onSubmitted: (_) => _handleLogin(),
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.colors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppTheme.colors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMessage,
                            style: AppTheme.typography.bodySmall.copyWith(color: AppTheme.colors.error)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.colors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Se connecter',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _handleForgotPassword,
                  child: Text('Mot de passe oublié ?',
                      style: TextStyle(color: AppTheme.colors.primary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

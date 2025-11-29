import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../config/ios_theme.dart';
import '../../widgets/ios_widgets.dart';
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
  final _formKey = GlobalKey<FormState>();
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
    // Valider que les champs ne sont pas vides
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez remplir tous les champs';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      debugPrint('📱 iOS: Tentative de connexion avec: $email');

      final result = await SupabaseService.signIn(
        email: email,
        password: password,
      );

      if (result.user != null) {
        if (!mounted) return;
        
        // Récupérer le rôle utilisateur
        final userRole = await SupabaseService.getCurrentUserRole();
        debugPrint('📱 iOS: Rôle utilisateur récupéré: $userRole');
        
        if (!mounted) return;
        
        if (userRole == null) {
          debugPrint('❌ iOS: Rôle utilisateur est null');
          setState(() {
            _errorMessage = 'Erreur: Rôle utilisateur non défini';
            _isLoading = false;
          });
          return;
        }

        final roleValue = userRole.toString().toLowerCase();
        debugPrint('📱 iOS: Valeur du rôle: $roleValue');

        // Redirection selon le rôle - Utiliser pushAndRemoveUntil pour éviter le retour arrière
        if (roleValue == 'client') {
          debugPrint('📱 iOS: Redirection client vers /client/invoices');
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/client/invoices',
            (route) => false,
          );
        } else {
          // Pour associés, partenaires et admins : utiliser le shell iOS
          debugPrint('📱 iOS: Redirection vers MobileShellProfessional');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const MobileShellProfessional(),
            ),
            (route) => false,
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Identifiants incorrects. Veuillez réessayer.';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ iOS: Erreur de connexion: $e');
      String errorMsg = 'Une erreur est survenue lors de la connexion';
      if (e.toString().contains('Failed to fetch')) {
        errorMsg = 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
      } else if (e.toString().contains('Invalid login credentials')) {
        errorMsg = 'Email ou mot de passe incorrect';
      }
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      await IOSAlert.show(
        context: context,
        title: 'Email requis',
        message: 'Veuillez saisir votre adresse email avant de demander une réinitialisation.',
        confirmText: 'OK',
      );
      return;
    }

    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Réinitialisation du mot de passe'),
        content: Text(
          'Un email de réinitialisation va être envoyé à $email.\n\nConsultez votre boîte de réception et suivez les instructions.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Envoyer'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SupabaseService.client.auth.resetPasswordForEmail(email);
        if (mounted) {
          await IOSAlert.show(
            context: context,
            title: 'Email envoyé',
            message: 'Vérifiez votre boîte de réception pour réinitialiser votre mot de passe.',
            confirmText: 'OK',
          );
        }
      } catch (e) {
        if (mounted) {
          await IOSAlert.show(
            context: context,
            title: 'Erreur',
            message: 'Impossible d\'envoyer l\'email. Veuillez réessayer.',
            confirmText: 'OK',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IOSScaffold(
      backgroundColor: IOSTheme.systemGroupedBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                
                // Logo et titre - Style minimal
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: IOSTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Center(
                          child: Text(
                            "OXO",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Bienvenue",
                        style: IOSTheme.largeTitle.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Connectez-vous à votre compte",
                        style: IOSTheme.body.copyWith(color: IOSTheme.labelSecondary),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 50),
                
                // Formulaire de connexion
                IOSListSection(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          IOSTextField(
                            controller: _emailController,
                            placeholder: "Adresse e-mail",
                            keyboardType: TextInputType.emailAddress,
                            prefix: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(
                                CupertinoIcons.mail,
                                color: IOSTheme.systemGray,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          IOSTextField(
                            controller: _passwordController,
                            placeholder: "Mot de passe",
                            obscureText: !_isPasswordVisible,
                            prefix: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(
                                CupertinoIcons.lock,
                                color: IOSTheme.systemGray,
                                size: 20,
                              ),
                            ),
                            suffix: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Icon(
                                  _isPasswordVisible
                                      ? CupertinoIcons.eye_slash
                                      : CupertinoIcons.eye,
                                  color: IOSTheme.systemGray,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Message d'erreur
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: IOSTheme.systemRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.exclamationmark_circle,
                            color: IOSTheme.systemRed,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: IOSTheme.footnote.copyWith(
                                color: IOSTheme.systemRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Bouton de connexion
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: IOSPrimaryButton(
                    text: "Se connecter",
                    onPressed: _handleLogin,
                    isLoading: _isLoading,
                    isEnabled: !_isLoading,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Mot de passe oublié
                Center(
                  child: CupertinoButton(
                    onPressed: _handleForgotPassword,
                    child: Text(
                      "Mot de passe oublié ?",
                      style: IOSTheme.body.copyWith(color: IOSTheme.primaryBlue),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Informations supplémentaires
                IOSListSection(
                  title: "À propos",
                  children: [
                    const IOSListTile(
                      leading: Icon(
                        CupertinoIcons.info_circle,
                        color: IOSTheme.primaryBlue,
                      ),
                      title: Text("Version de l'application"),
                      trailing: Text(
                        "1.0.0",
                        style: TextStyle(
                          color: IOSTheme.labelSecondary,
                          fontSize: 17,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                    ),
                    IOSListTile(
                      leading: const Icon(
                        CupertinoIcons.shield,
                        color: IOSTheme.systemGreen,
                      ),
                      title: const Text("Confidentialité"),
                      trailing: const Icon(
                        CupertinoIcons.chevron_right,
                        color: IOSTheme.systemGray,
                        size: 16,
                      ),
                      onTap: () {
                        IOSAlert.show(
                          context: context,
                          title: 'Confidentialité',
                          message: 'Vos données sont protégées et chiffrées.',
                          confirmText: 'Compris',
                        );
                      },
                    ),
                    IOSListTile(
                      leading: const Icon(
                        CupertinoIcons.doc_text,
                        color: IOSTheme.systemOrange,
                      ),
                      title: const Text("Conditions d'utilisation"),
                      trailing: const Icon(
                        CupertinoIcons.chevron_right,
                        color: IOSTheme.systemGray,
                        size: 16,
                      ),
                      onTap: () {
                        IOSAlert.show(
                          context: context,
                          title: 'Conditions d\'utilisation',
                          message: 'Consultez nos conditions d\'utilisation.',
                          confirmText: 'OK',
                        );
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
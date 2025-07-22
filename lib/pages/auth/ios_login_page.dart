import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../config/ios_theme.dart';
import '../../widgets/ios_widgets.dart';
import '../../services/supabase_service.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await SupabaseService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (result.user != null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        }
      } else {
        if (mounted) {
          await IOSAlert.show(
            context: context,
            title: 'Erreur de connexion',
            message: 'Identifiants incorrects. Veuillez réessayer.',
            confirmText: 'OK',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        await IOSAlert.show(
          context: context,
          title: 'Erreur',
          message: 'Impossible de se connecter. Vérifiez votre connexion internet.',
          confirmText: 'OK',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
                
                // Logo et titre
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: IOSTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: IOSTheme.primaryBlue.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            "OXO",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 28,
                              fontFamily: '.SF Pro Display',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Bienvenue",
                        style: TextStyle(
                          color: IOSTheme.labelPrimary,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          fontFamily: '.SF Pro Display',
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Connectez-vous à votre compte",
                        style: TextStyle(
                          color: IOSTheme.labelSecondary,
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          fontFamily: '.SF Pro Text',
                        ),
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
                    onPressed: () {
                      IOSAlert.show(
                        context: context,
                        title: 'Mot de passe oublié',
                        message: 'Cette fonctionnalité sera bientôt disponible.',
                        confirmText: 'OK',
                      );
                    },
                    child: const Text(
                      "Mot de passe oublié ?",
                      style: TextStyle(
                        color: IOSTheme.primaryBlue,
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        fontFamily: '.SF Pro Text',
                      ),
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
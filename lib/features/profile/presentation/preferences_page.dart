// ============================================================================
// PREFERENCES PAGE - OXO TIME SHEETS
// Page de préférences utilisateur
// ============================================================================

import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../services/preferences_service.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({Key? key}) : super(key: key);

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);

    try {
      final notificationsEnabled = await PreferencesService.areNotificationsEnabled();
      final emailNotifications = await PreferencesService.areEmailNotificationsEnabled();
      final pushNotifications = await PreferencesService.arePushNotificationsEnabled();
      final themeMode = await PreferencesService.getThemeMode();

      setState(() {
        _notificationsEnabled = notificationsEnabled;
        _emailNotifications = emailNotifications;
        _pushNotifications = pushNotifications;
        _themeMode = themeMode;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: AppTheme.colors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Notifications
          Card(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notifications', style: AppTheme.typography.h3),
                  SizedBox(height: AppTheme.spacing.md),
                  SwitchListTile(
                    title: const Text('Notifications'),
                    subtitle: const Text('Activer les notifications'),
                    value: _notificationsEnabled,
                    onChanged: (value) async {
                      await PreferencesService.setNotificationsEnabled(value);
                      setState(() => _notificationsEnabled = value);
                    },
                  ),
                  if (_notificationsEnabled) ...[
                    SwitchListTile(
                      title: const Text('Notifications email'),
                      subtitle: const Text('Recevoir des emails'),
                      value: _emailNotifications,
                      onChanged: (value) async {
                        await PreferencesService.setEmailNotificationsEnabled(value);
                        setState(() => _emailNotifications = value);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Notifications push'),
                      subtitle: const Text('Recevoir des notifications push'),
                      value: _pushNotifications,
                      onChanged: (value) async {
                        await PreferencesService.setPushNotificationsEnabled(value);
                        setState(() => _pushNotifications = value);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          SizedBox(height: AppTheme.spacing.lg),

          // Section Apparence
          Card(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Apparence', style: AppTheme.typography.h3),
                  SizedBox(height: AppTheme.spacing.md),
                  ListTile(
                    title: const Text('Thème'),
                    subtitle: Text(_getThemeModeLabel(_themeMode)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showThemePicker,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: AppTheme.spacing.lg),

          // Section À propos
          Card(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('À propos', style: AppTheme.typography.h3),
                  SizedBox(height: AppTheme.spacing.md),
                  ListTile(
                    title: const Text('Version'),
                    subtitle: const Text('1.0.0'),
                  ),
                  ListTile(
                    title: const Text('Aide et support'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigation vers aide
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Choisir un thème', style: AppTheme.typography.h4),
            ),
            const Divider(height: 1),
            ListTile(title: const Text('Clair'), onTap: () => _setThemeMode(ThemeMode.light)),
            ListTile(title: const Text('Sombre'), onTap: () => _setThemeMode(ThemeMode.dark)),
            ListTile(title: const Text('Système'), onTap: () => _setThemeMode(ThemeMode.system)),
            ListTile(title: const Text('Annuler'), onTap: () => Navigator.pop(ctx)),
          ],
        ),
      ),
    );
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    await PreferencesService.setThemeMode(mode);
    setState(() => _themeMode = mode);
    Navigator.of(context).pop();
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Clair';
      case ThemeMode.dark:
        return 'Sombre';
      case ThemeMode.system:
        return 'Système';
    }
  }
}

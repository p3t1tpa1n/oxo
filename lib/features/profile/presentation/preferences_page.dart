// ============================================================================
// PREFERENCES PAGE - OXO TIME SHEETS
// Page de préférences utilisateur (iOS et Desktop)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../config/ios_theme.dart';
import '../../../config/app_theme.dart';
import '../../../services/preferences_service.dart';
import '../../../utils/device_detector.dart';
import '../../../widgets/ios_widgets.dart';

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
    final isIOS = DeviceDetector.shouldUseIOSInterface();
    
    if (isIOS) {
      return CupertinoPageScaffold(
        backgroundColor: IOSTheme.systemGroupedBackground,
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Paramètres'),
        ),
        child: SafeArea(
          child: _buildIOSContent(),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Paramètres'),
          backgroundColor: AppTheme.colors.primary,
          foregroundColor: Colors.white,
        ),
        body: _buildDesktopContent(),
      );
    }
  }

  Widget _buildIOSContent() {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          
          // Section Notifications
          IOSListSection(
            title: 'Notifications',
            children: [
              IOSListTile(
                leading: const Icon(CupertinoIcons.bell, color: IOSTheme.primaryBlue),
                title: const Text('Notifications', style: IOSTheme.body),
                subtitle: const Text('Activer les notifications', style: IOSTheme.footnote),
                trailing: CupertinoSwitch(
                  value: _notificationsEnabled,
                  onChanged: (value) async {
                    await PreferencesService.setNotificationsEnabled(value);
                    setState(() => _notificationsEnabled = value);
                  },
                ),
              ),
              if (_notificationsEnabled) ...[
                IOSListTile(
                  leading: const Icon(CupertinoIcons.mail, color: IOSTheme.systemOrange),
                  title: const Text('Notifications email', style: IOSTheme.body),
                  subtitle: const Text('Recevoir des emails', style: IOSTheme.footnote),
                  trailing: CupertinoSwitch(
                    value: _emailNotifications,
                    onChanged: (value) async {
                      await PreferencesService.setEmailNotificationsEnabled(value);
                      setState(() => _emailNotifications = value);
                    },
                  ),
                ),
                IOSListTile(
                  leading: const Icon(CupertinoIcons.bell_solid, color: IOSTheme.systemGreen),
                  title: const Text('Notifications push', style: IOSTheme.body),
                  subtitle: const Text('Recevoir des notifications push', style: IOSTheme.footnote),
                  trailing: CupertinoSwitch(
                    value: _pushNotifications,
                    onChanged: (value) async {
                      await PreferencesService.setPushNotificationsEnabled(value);
                      setState(() => _pushNotifications = value);
                    },
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Section Apparence
          IOSListSection(
            title: 'Apparence',
            children: [
              IOSListTile(
                leading: const Icon(CupertinoIcons.paintbrush, color: IOSTheme.systemPurple),
                title: const Text('Thème', style: IOSTheme.body),
                subtitle: Text(
                  _getThemeModeLabel(_themeMode),
                  style: IOSTheme.footnote,
                ),
                trailing: const Icon(CupertinoIcons.chevron_right, color: IOSTheme.systemGray),
                onTap: () => _showThemePicker(),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Section À propos
          IOSListSection(
            title: 'À propos',
            children: [
              IOSListTile(
                leading: const Icon(CupertinoIcons.info_circle, color: IOSTheme.primaryBlue),
                title: const Text('Version', style: IOSTheme.body),
                subtitle: const Text('1.0.0', style: IOSTheme.footnote),
              ),
              IOSListTile(
                leading: const Icon(CupertinoIcons.question_circle, color: IOSTheme.systemGray),
                title: const Text('Aide et support', style: IOSTheme.body),
                trailing: const Icon(CupertinoIcons.chevron_right, color: IOSTheme.systemGray),
                onTap: () {
                  // TODO: Navigation vers aide
                },
              ),
            ],
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDesktopContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
                  Text(
                    'Notifications',
                    style: AppTheme.typography.h3,
                  ),
                  SizedBox(height: AppTheme.spacing.md),
                  SwitchListTile(
                    title: const Text('Activer les notifications'),
                    subtitle: const Text('Recevoir des notifications de l\'application'),
                    value: _notificationsEnabled,
                    onChanged: (value) async {
                      await PreferencesService.setNotificationsEnabled(value);
                      setState(() => _notificationsEnabled = value);
                    },
                  ),
                  if (_notificationsEnabled) ...[
                    SwitchListTile(
                      title: const Text('Notifications email'),
                      subtitle: const Text('Recevoir des emails de notification'),
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
                  Text(
                    'Apparence',
                    style: AppTheme.typography.h3,
                  ),
                  SizedBox(height: AppTheme.spacing.md),
                  ListTile(
                    leading: Icon(Icons.palette, color: AppTheme.colors.primary),
                    title: const Text('Thème'),
                    subtitle: Text(_getThemeModeLabel(_themeMode)),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () => _showThemePicker(),
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
    final isIOS = DeviceDetector.shouldUseIOSInterface();
    
    if (isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text('Choisir un thème'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => _setThemeMode(ThemeMode.light),
              child: const Text('Clair'),
            ),
            CupertinoActionSheetAction(
              onPressed: () => _setThemeMode(ThemeMode.dark),
              child: const Text('Sombre'),
            ),
            CupertinoActionSheetAction(
              onPressed: () => _setThemeMode(ThemeMode.system),
              child: const Text('Système'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choisir un thème'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Clair'),
                leading: Radio<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: _themeMode,
                  onChanged: (value) {
                    if (value != null) _setThemeMode(value);
                  },
                ),
              ),
              ListTile(
                title: const Text('Sombre'),
                leading: Radio<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: _themeMode,
                  onChanged: (value) {
                    if (value != null) _setThemeMode(value);
                  },
                ),
              ),
              ListTile(
                title: const Text('Système'),
                leading: Radio<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: _themeMode,
                  onChanged: (value) {
                    if (value != null) _setThemeMode(value);
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    }
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


import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/supabase_service.dart';

class IOSPartnerDetailPage extends StatefulWidget {
  final Map<String, dynamic> partner;

  const IOSPartnerDetailPage({
    super.key,
    required this.partner,
  });

  @override
  State<IOSPartnerDetailPage> createState() => _IOSPartnerDetailPageState();
}

class _IOSPartnerDetailPageState extends State<IOSPartnerDetailPage> {
  Map<String, dynamic> _fullProfile = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFullProfile();
  }

  Future<void> _loadFullProfile() async {
    try {
      final userId = widget.partner['user_id']?.toString();
      debugPrint('🔍 Chargement du profil complet pour user_id: $userId');

      if (userId != null && userId.isNotEmpty) {
        // Essayer de charger depuis partner_profiles
        final response = await SupabaseService.client
            .from('partner_profiles')
            .select('*')
            .eq('user_id', userId)
            .maybeSingle();

        if (response != null) {
          debugPrint('✅ Profil complet chargé: ${response.keys}');
          setState(() {
            _fullProfile = {...widget.partner, ...response};
            _isLoading = false;
          });
          return;
        }
      }

      // Fallback: utiliser les données de base
      setState(() {
        _fullProfile = widget.partner;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement profil: $e');
      setState(() {
        _fullProfile = widget.partner;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colors.background,
      appBar: AppBar(
        backgroundColor: AppTheme.colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.colors.textPrimary),
        titleTextStyle: AppTheme.typography.h4.copyWith(color: AppTheme.colors.textPrimary),
        title: const Text('Profil Partenaire'),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: AppTheme.colors.primary),
            onPressed: () => _sharePartnerProfile(context),
          ),
        ],
      ),
      body: DefaultTextStyle(
        style: TextStyle(
          decoration: TextDecoration.none,
          color: AppTheme.colors.textPrimary,
        ),
        child: _isLoading
            ? Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(color: AppTheme.colors.primary, strokeWidth: 2),
                ),
              )
            : SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildPersonalInfo(),
                      _buildCompanyInfo(),
                      _buildActivityDomains(),
                      _buildLanguages(),
                      _buildDiplomas(),
                      _buildCareerPaths(),
                      _buildMainFunctions(),
                      _buildProfessionalExperiences(),
                      _buildActions(context),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    final firstName = _fullProfile['first_name'] ?? '';
    final lastName = _fullProfile['last_name'] ?? '';
    final companyName = _fullProfile['company_name'] ?? '';
    final email = _fullProfile['email'] ?? '';
    final phone = _fullProfile['phone'] ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: AppTheme.colors.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '${firstName.isNotEmpty ? firstName[0].toUpperCase() : ''}${lastName.isNotEmpty ? lastName[0].toUpperCase() : ''}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.colors.primary,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Nom complet
          Text(
            '$firstName $lastName',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.colors.textPrimary,
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.center,
          ),

          if (companyName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              companyName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.colors.textSecondary,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 16),

          // Contact
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (email.isNotEmpty) ...[
                _buildContactItem(
                  Icons.mail,
                  email,
                  'Email',
                ),
                if (phone.isNotEmpty) const SizedBox(width: 24),
              ],
              if (phone.isNotEmpty) ...[
                _buildContactItem(
                  Icons.phone,
                  phone,
                  'Téléphone',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.colors.primary,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.colors.textPrimary,
            decoration: TextDecoration.none,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.colors.textSecondary,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.md,
        vertical: AppTheme.spacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.colors.textSecondary,
              letterSpacing: 0.5,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.colors.border,
                width: 1,
              ),
            ),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return _buildSection(
      '🧍 INFORMATIONS PERSONNELLES',
      Column(
        children: [
          _buildInfoRow('Civilité', _fullProfile['civility']),
          _buildInfoRow('Prénom', _fullProfile['first_name']),
          _buildInfoRow('Nom', _fullProfile['last_name']),
          _buildInfoRow('Email', _fullProfile['email']),
          _buildInfoRow('Téléphone', _fullProfile['phone']),
          _buildInfoRow('Date de naissance', _fullProfile['birth_date']),
          _buildInfoRow('Adresse', _fullProfile['address']),
          _buildInfoRow('Code postal', _fullProfile['postal_code']),
          _buildInfoRow('Ville', _fullProfile['city']),
        ],
      ),
    );
  }

  Widget _buildCompanyInfo() {
    return _buildSection(
      '🏢 INFORMATIONS SOCIÉTÉ',
      Column(
        children: [
          _buildInfoRow('Nom de la société', _fullProfile['company_name']),
          _buildInfoRow('Forme juridique', _fullProfile['legal_form']),
          _buildInfoRow('Capital', _fullProfile['capital']),
          _buildInfoRow('Adresse du siège', _fullProfile['company_address']),
          _buildInfoRow('Code postal', _fullProfile['company_postal_code']),
          _buildInfoRow('Ville', _fullProfile['company_city']),
          _buildInfoRow('RCS', _fullProfile['rcs']),
          _buildInfoRow('SIREN', _fullProfile['siren']),
          _buildInfoRow('Représentant', _fullProfile['representative_name']),
          _buildInfoRow('Qualité du représentant', _fullProfile['representative_title']),
        ],
      ),
    );
  }

  Widget _buildActivityDomains() {
    final domains = _fullProfile['activity_domains'] as List<dynamic>? ?? [];

    return _buildSection(
      '💼 DOMAINES D\'ACTIVITÉ',
      domains.isEmpty
          ? Text(
              'Aucun domaine renseigné',
              style: TextStyle(
                color: AppTheme.colors.textSecondary,
                decoration: TextDecoration.none,
              ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: domains.map((domain) => _buildTag(domain.toString())).toList(),
            ),
    );
  }

  Widget _buildLanguages() {
    final languages = _fullProfile['languages'] as List<dynamic>? ?? [];

    return _buildSection(
      '🌍 LANGUES & NIVEAU',
      languages.isEmpty
          ? Text(
              'Aucune langue renseignée',
              style: TextStyle(
                color: AppTheme.colors.textSecondary,
                decoration: TextDecoration.none,
              ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: languages.map((language) => _buildTag(language.toString())).toList(),
            ),
    );
  }

  Widget _buildDiplomas() {
    final diplomas = _fullProfile['diplomas'] as List<dynamic>? ?? [];

    return _buildSection(
      '🎓 DIPLÔMES SIGNIFICATIFS',
      diplomas.isEmpty
          ? Text(
              'Aucun diplôme renseigné',
              style: TextStyle(
                color: AppTheme.colors.textSecondary,
                decoration: TextDecoration.none,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: diplomas.map((diploma) => _buildListItem(diploma.toString())).toList(),
            ),
    );
  }

  Widget _buildCareerPaths() {
    final careerPaths = _fullProfile['career_paths'] as List<dynamic>? ?? [];

    return _buildSection(
      '🧭 PARCOURS',
      careerPaths.isEmpty
          ? Text(
              'Aucun parcours renseigné',
              style: TextStyle(
                color: AppTheme.colors.textSecondary,
                decoration: TextDecoration.none,
              ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: careerPaths.map((path) => _buildTag(path.toString())).toList(),
            ),
    );
  }

  Widget _buildMainFunctions() {
    final functions = _fullProfile['main_functions'] as List<dynamic>? ?? [];

    return _buildSection(
      '👔 PRINCIPALE FONCTION',
      functions.isEmpty
          ? Text(
              'Aucune fonction renseignée',
              style: TextStyle(
                color: AppTheme.colors.textSecondary,
                decoration: TextDecoration.none,
              ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: functions.map((function) => _buildTag(function.toString())).toList(),
            ),
    );
  }

  Widget _buildProfessionalExperiences() {
    final experiences = _fullProfile['professional_experiences'] as List<dynamic>? ?? [];

    return _buildSection(
      '🧠 EXPÉRIENCES PROFESSIONNELLES',
      experiences.isEmpty
          ? Text(
              'Aucune expérience renseignée',
              style: TextStyle(
                color: AppTheme.colors.textSecondary,
                decoration: TextDecoration.none,
              ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: experiences.map((experience) => _buildTag(experience.toString())).toList(),
            ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return _buildSection(
      'ACTIONS',
      Column(
        children: [
          // Bouton principal
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.colors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => _assignMission(context),
              child: Text(
                'Assigner une mission',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Bouton secondaire
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.colors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => _sendMessage(context),
              child: Text(
                'Envoyer un message',
                style: TextStyle(
                  color: AppTheme.colors.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Bouton secondaire
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.colors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => _viewAvailability(context),
              child: Text(
                'Voir les disponibilités',
                style: TextStyle(
                  color: AppTheme.colors.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    final displayValue = value?.toString().isNotEmpty == true ? value.toString() : 'Non renseigné';
    final isNotSet = displayValue == 'Non renseigné';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.colors.textSecondary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: TextStyle(
                fontSize: 14,
                color: isNotSet ? AppTheme.colors.textSecondary : AppTheme.colors.textPrimary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.colors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.colors.primary.withOpacity(0.3),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: AppTheme.colors.primary,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _buildListItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppTheme.colors.primary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.colors.textPrimary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sharePartnerProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Partager le profil'),
        content: const Text('Fonctionnalité de partage à venir'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK')),
        ],
      ),
    );
  }

  void _assignMission(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Assigner une mission'),
        content: Text('Assigner une mission à ${_fullProfile['first_name']} ${_fullProfile['last_name']} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              _showSuccessMessage('Mission assignée avec succès');
            },
            child: const Text('Assigner'),
          ),
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context) {
    Navigator.pop(context);
    Navigator.of(context, rootNavigator: true).pushNamed(
      '/messaging',
      arguments: {
        'partner_id': _fullProfile['user_id'],
        'partner_name': '${_fullProfile['first_name']} ${_fullProfile['last_name']}',
        'partner_email': _fullProfile['email'],
      },
    );
  }

  void _viewAvailability(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Voir les disponibilités'),
        content: const Text('Redirection vers le calendrier des disponibilités...'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    debugPrint(message);
  }
}

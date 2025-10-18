import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../widgets/ios_widgets.dart';
import '../../config/ios_theme.dart';

class IOSPartnerDetailPage extends StatelessWidget {
  final Map<String, dynamic> partner;

  const IOSPartnerDetailPage({
    super.key,
    required this.partner,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Profil Partenaire',
          style: IOSTheme.title2,
        ),
        backgroundColor: CupertinoColors.systemBackground,
        border: null,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.share),
          onPressed: () => _sharePartnerProfile(context),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // En-tête avec photo et informations principales
              _buildHeader(),
              
              // Informations personnelles
              _buildPersonalInfo(),
              
              // Informations société
              _buildCompanyInfo(),
              
              // Domaines d'activité
              _buildActivityDomains(),
              
              // Langues
              _buildLanguages(),
              
              // Diplômes
              _buildDiplomas(),
              
              // Parcours
              _buildCareerPaths(),
              
              // Fonctions principales
              _buildMainFunctions(),
              
              // Expériences professionnelles
              _buildProfessionalExperiences(),
              
              // Actions
              _buildActions(context),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final firstName = partner['first_name'] ?? '';
    final lastName = partner['last_name'] ?? '';
    final companyName = partner['company_name'] ?? '';
    final email = partner['email'] ?? '';
    final phone = partner['phone'] ?? '';
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: IOSTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: IOSTheme.primaryBlue.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}',
                style: IOSTheme.largeTitle.copyWith(
                  color: IOSTheme.primaryBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Nom complet
          Text(
            '$firstName $lastName',
            style: IOSTheme.largeTitle.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (companyName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              companyName,
              style: IOSTheme.title3.copyWith(
                color: CupertinoColors.systemGrey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Contact
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (email.isNotEmpty) ...[
                _buildContactItem(
                  CupertinoIcons.mail,
                  email,
                  'Email',
                ),
              ],
              if (phone.isNotEmpty) ...[
                _buildContactItem(
                  CupertinoIcons.phone,
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
          color: IOSTheme.primaryBlue,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: IOSTheme.caption1.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          label,
          style: IOSTheme.caption1.copyWith(
            color: CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfo() {
    return IOSListSection(
      title: '🧍 Informations personnelles',
      children: [
        IOSCard(
          child: Column(
            children: [
              _buildInfoRow('Civilité', partner['civility'] ?? 'Non renseigné'),
              _buildInfoRow('Prénom', partner['first_name'] ?? 'Non renseigné'),
              _buildInfoRow('Nom', partner['last_name'] ?? 'Non renseigné'),
              _buildInfoRow('Email', partner['email'] ?? 'Non renseigné'),
              _buildInfoRow('Téléphone', partner['phone'] ?? 'Non renseigné'),
              _buildInfoRow('Date de naissance', partner['birth_date'] ?? 'Non renseigné'),
              _buildInfoRow('Adresse', partner['address'] ?? 'Non renseigné'),
              _buildInfoRow('Code postal', partner['postal_code'] ?? 'Non renseigné'),
              _buildInfoRow('Ville', partner['city'] ?? 'Non renseigné'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyInfo() {
    return IOSListSection(
      title: '🏢 Informations société',
      children: [
        IOSCard(
          child: Column(
            children: [
              _buildInfoRow('Nom de la société', partner['company_name'] ?? 'Non renseigné'),
              _buildInfoRow('Forme juridique', partner['legal_form'] ?? 'Non renseigné'),
              _buildInfoRow('Capital', partner['capital'] ?? 'Non renseigné'),
              _buildInfoRow('Adresse du siège', partner['company_address'] ?? 'Non renseigné'),
              _buildInfoRow('Code postal', partner['company_postal_code'] ?? 'Non renseigné'),
              _buildInfoRow('Ville', partner['company_city'] ?? 'Non renseigné'),
              _buildInfoRow('RCS', partner['rcs'] ?? 'Non renseigné'),
              _buildInfoRow('SIREN', partner['siren'] ?? 'Non renseigné'),
              _buildInfoRow('Représentant', partner['representative_name'] ?? 'Non renseigné'),
              _buildInfoRow('Qualité du représentant', partner['representative_title'] ?? 'Non renseigné'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityDomains() {
    final domains = partner['activity_domains'] as List<dynamic>? ?? [];
    
    return IOSListSection(
      title: '💼 Domaines d\'activité',
      children: [
        IOSCard(
          child: domains.isEmpty
              ? const Text('Aucun domaine renseigné')
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: domains.map((domain) => _buildTag(domain.toString())).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildLanguages() {
    final languages = partner['languages'] as List<dynamic>? ?? [];
    
    return IOSListSection(
      title: '🌍 Langues & Niveau',
      children: [
        IOSCard(
          child: languages.isEmpty
              ? const Text('Aucune langue renseignée')
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: languages.map((language) => _buildTag(language.toString())).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildDiplomas() {
    final diplomas = partner['diplomas'] as List<dynamic>? ?? [];
    
    return IOSListSection(
      title: '🎓 Diplômes significatifs',
      children: [
        IOSCard(
          child: diplomas.isEmpty
              ? const Text('Aucun diplôme renseigné')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: diplomas.map((diploma) => _buildListItem(diploma.toString())).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildCareerPaths() {
    final careerPaths = partner['career_paths'] as List<dynamic>? ?? [];
    
    return IOSListSection(
      title: '🧭 Parcours',
      children: [
        IOSCard(
          child: careerPaths.isEmpty
              ? const Text('Aucun parcours renseigné')
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: careerPaths.map((path) => _buildTag(path.toString())).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildMainFunctions() {
    final functions = partner['main_functions'] as List<dynamic>? ?? [];
    
    return IOSListSection(
      title: '👔 Principale fonction',
      children: [
        IOSCard(
          child: functions.isEmpty
              ? const Text('Aucune fonction renseignée')
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: functions.map((function) => _buildTag(function.toString())).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildProfessionalExperiences() {
    final experiences = partner['professional_experiences'] as List<dynamic>? ?? [];
    
    return IOSListSection(
      title: '🧠 Expériences professionnelles',
      children: [
        IOSCard(
          child: experiences.isEmpty
              ? const Text('Aucune expérience renseignée')
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: experiences.map((experience) => _buildTag(experience.toString())).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return IOSListSection(
      title: 'Actions',
      children: [
        IOSCard(
          child: Column(
            children: [
              IOSPrimaryButton(
                text: 'Assigner une mission',
                onPressed: () => _assignMission(context),
              ),
              const SizedBox(height: 12),
              IOSSecondaryButton(
                text: 'Envoyer un message',
                onPressed: () => _sendMessage(context),
              ),
              const SizedBox(height: 12),
              IOSSecondaryButton(
                text: 'Voir les disponibilités',
                onPressed: () => _viewAvailability(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: IOSTheme.body.copyWith(
                fontWeight: FontWeight.w500,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: IOSTheme.body,
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
        color: IOSTheme.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: IOSTheme.primaryBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        text,
        style: IOSTheme.caption1.copyWith(
          color: IOSTheme.primaryBlue,
          fontWeight: FontWeight.w500,
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
              color: IOSTheme.primaryBlue,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: IOSTheme.body,
            ),
          ),
        ],
      ),
    );
  }

  void _sharePartnerProfile(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Partager le profil'),
        content: const Text('Fonctionnalité de partage à implémenter'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _assignMission(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Assigner une mission'),
        content: Text('Assigner une mission à ${partner['first_name']} ${partner['last_name']} ?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Annuler'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Assigner'),
            onPressed: () {
              Navigator.pop(context);
              _showSuccessMessage('Mission assignée avec succès');
            },
          ),
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Envoyer un message'),
        content: const Text('Redirection vers la messagerie...'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _viewAvailability(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Voir les disponibilités'),
        content: const Text('Redirection vers le calendrier des disponibilités...'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    // Cette méthode devrait être dans le contexte parent
    // Pour l'instant, on affiche juste un debug print
    debugPrint(message);
  }
}

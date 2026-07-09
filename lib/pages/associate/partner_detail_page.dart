import 'package:flutter/material.dart';
import 'mission_assignment_page.dart';
import 'partner_availability_page.dart';
import '../../services/supabase_service.dart';

class PartnerDetailPage extends StatelessWidget {
  final Map<String, dynamic> partner;

  const PartnerDetailPage({
    super.key,
    required this.partner,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Partenaire'),
        backgroundColor: const Color(0xFF16283C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _sharePartnerProfile(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
    );
  }

  Widget _buildHeader() {
    final firstName = partner['first_name'] ?? '';
    final lastName = partner['last_name'] ?? '';
    final companyName = partner['company_name'] ?? '';
    final email = partner['email'] ?? '';
    final phone = partner['phone'] ?? '';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF16283C).withOpacity(0.05),
            Colors.white,
          ],
        ),
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFF16283C).withOpacity(0.1),
            child: Text(
              '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}',
              style: const TextStyle(
                color: Color(0xFF16283C),
                fontWeight: FontWeight.w700,
                fontSize: 32,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Nom complet
          Text(
            '$firstName $lastName',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (companyName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              companyName,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
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
                  Icons.email,
                  email,
                  'Email',
                ),
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
          color: const Color(0xFF16283C),
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfo() {
    return _buildSection(
      title: '🧍 Informations personnelles',
      child: _buildInfoCard([
        _buildInfoRow('Civilité', partner['civility'] ?? 'Non renseigné'),
        _buildInfoRow('Prénom', partner['first_name'] ?? 'Non renseigné'),
        _buildInfoRow('Nom', partner['last_name'] ?? 'Non renseigné'),
        _buildInfoRow('Email', partner['email'] ?? 'Non renseigné'),
        _buildInfoRow('Téléphone', partner['phone'] ?? 'Non renseigné'),
        _buildInfoRow('Date de naissance', partner['birth_date'] ?? 'Non renseigné'),
        _buildInfoRow('Adresse', partner['address'] ?? 'Non renseigné'),
        _buildInfoRow('Code postal', partner['postal_code'] ?? 'Non renseigné'),
        _buildInfoRow('Ville', partner['city'] ?? 'Non renseigné'),
      ]),
    );
  }

  Widget _buildCompanyInfo() {
    return _buildSection(
      title: '🏢 Informations société',
      child: _buildInfoCard([
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
      ]),
    );
  }

  Widget _buildActivityDomains() {
    final domains = partner['activity_domains'] as List<dynamic>? ?? [];
    
    return _buildSection(
      title: '💼 Domaines d\'activité',
      child: _buildInfoCard([
        domains.isEmpty
            ? const Text('Aucun domaine renseigné')
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: domains.map((domain) => _buildTag(domain.toString())).toList(),
              ),
      ]),
    );
  }

  Widget _buildLanguages() {
    final languages = partner['languages'] as List<dynamic>? ?? [];
    
    return _buildSection(
      title: '🌍 Langues & Niveau',
      child: _buildInfoCard([
        languages.isEmpty
            ? const Text('Aucune langue renseignée')
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: languages.map((language) => _buildTag(language.toString())).toList(),
              ),
      ]),
    );
  }

  Widget _buildDiplomas() {
    final diplomas = partner['diplomas'] as List<dynamic>? ?? [];
    
    return _buildSection(
      title: '🎓 Diplômes significatifs',
      child: _buildInfoCard([
        diplomas.isEmpty
            ? const Text('Aucun diplôme renseigné')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: diplomas.map((diploma) => _buildListItem(diploma.toString())).toList(),
              ),
      ]),
    );
  }

  Widget _buildCareerPaths() {
    final careerPaths = partner['career_paths'] as List<dynamic>? ?? [];
    
    return _buildSection(
      title: '🧭 Parcours',
      child: _buildInfoCard([
        careerPaths.isEmpty
            ? const Text('Aucun parcours renseigné')
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: careerPaths.map((path) => _buildTag(path.toString())).toList(),
              ),
      ]),
    );
  }

  Widget _buildMainFunctions() {
    final functions = partner['main_functions'] as List<dynamic>? ?? [];
    
    return _buildSection(
      title: '👔 Principale fonction',
      child: _buildInfoCard([
        functions.isEmpty
            ? const Text('Aucune fonction renseignée')
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: functions.map((function) => _buildTag(function.toString())).toList(),
              ),
      ]),
    );
  }

  Widget _buildProfessionalExperiences() {
    final experiences = partner['professional_experiences'] as List<dynamic>? ?? [];
    
    return _buildSection(
      title: '🧠 Expériences professionnelles',
      child: _buildInfoCard([
        experiences.isEmpty
            ? const Text('Aucune expérience renseignée')
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: experiences.map((experience) => _buildTag(experience.toString())).toList(),
              ),
      ]),
    );
  }

  Widget _buildActions(BuildContext context) {
    return _buildSection(
      title: 'Actions',
      child: _buildInfoCard([
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _assignMission(context),
                icon: const Icon(Icons.assignment),
                label: const Text('Assigner une mission'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16283C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _sendMessage(context),
                icon: const Icon(Icons.message),
                label: const Text('Envoyer un message'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF16283C),
                  side: const BorderSide(color: Color(0xFF16283C)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _viewAvailability(context),
            icon: const Icon(Icons.calendar_today),
            label: const Text('Voir les disponibilités'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF16283C),
              side: const BorderSide(color: Color(0xFF16283C)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF16283C),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
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
        color: const Color(0xFF16283C).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF16283C).withOpacity(0.3),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF16283C),
          fontWeight: FontWeight.w500,
          fontSize: 12,
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
            decoration: const BoxDecoration(
              color: Color(0xFF16283C),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _sharePartnerProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Partager le profil'),
        content: const Text('Fonctionnalité de partage à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _assignMission(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MissionAssignmentPage(partner: partner),
      ),
    );
    
    if (result == true) {
      // Mission assignée avec succès
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mission assignée avec succès !'),
            backgroundColor: const Color(0xFF2E7D5B),
          ),
        );
      }
    }
  }

  void _sendMessage(BuildContext context) async {
    // Redirection vers la messagerie avec le partenaire sélectionné
    Navigator.pushNamed(
      context,
      '/messaging',
      arguments: {
        'partner_id': partner['user_id'],
        'partner_name': '${partner['first_name']} ${partner['last_name']}',
        'partner_email': partner['email'],
      },
    );
  }

  void _viewAvailability(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PartnerAvailabilityPage(partner: partner),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    // Cette méthode devrait être dans le contexte parent
    // Pour l'instant, on affiche juste un debug print
    debugPrint(message);
  }
}

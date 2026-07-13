import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/partner_profile_service.dart';
import '../../config/app_theme.dart';

class IOSPartnerQuestionnairePage extends StatefulWidget {
  const IOSPartnerQuestionnairePage({super.key});

  @override
  State<IOSPartnerQuestionnairePage> createState() => _IOSPartnerQuestionnairePageState();
}

class _IOSPartnerQuestionnairePageState extends State<IOSPartnerQuestionnairePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 8;

  // Données du formulaire
  final Map<String, dynamic> _formData = {};
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colors.background,
      appBar: AppBar(
        backgroundColor: AppTheme.colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.colors.textPrimary),
        titleTextStyle: AppTheme.typography.h4.copyWith(color: AppTheme.colors.textPrimary),
        title: Text('Profil Partenaire', style: AppTheme.typography.h3),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Indicateur de progression
            _buildProgressIndicator(),

            // Contenu du questionnaire
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildPersonalInfoPage(),
                  _buildCompanyInfoPage(),
                  _buildActivityDomainsPage(),
                  _buildLanguagesPage(),
                  _buildDiplomasPage(),
                  _buildCareerPathsPage(),
                  _buildMainFunctionsPage(),
                  _buildProfessionalExperiencesPage(),
                ],
              ),
            ),

            // Navigation
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Étape ${_currentPage + 1} sur $_totalPages',
                style: AppTheme.typography.bodyMedium.copyWith(color: AppTheme.colors.textSecondary),
              ),
              Text(
                '${((_currentPage + 1) / _totalPages * 100).round()}%',
                style: AppTheme.typography.bodyMedium.copyWith(
                  color: AppTheme.colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentPage + 1) / _totalPages,
            backgroundColor: AppTheme.colors.border,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.colors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('🧍 Informations personnelles'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDropdownField('Civilité', 'civility', ['M.', 'Mme', 'Dr', 'Prof']),
                  const SizedBox(height: 16),
                  _buildTextField('Prénom', 'first_name'),
                  const SizedBox(height: 16),
                  _buildTextField('Nom', 'last_name'),
                  const SizedBox(height: 16),
                  _buildTextField('Email', 'email', keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildTextField('Téléphone', 'phone', keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildDateField('Date de naissance', 'birth_date'),
                  const SizedBox(height: 16),
                  _buildTextField('Adresse', 'address'),
                  const SizedBox(height: 16),
                  _buildTextField('Code postal', 'postal_code'),
                  const SizedBox(height: 16),
                  _buildTextField('Ville', 'city'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('🏢 Informations société'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTextField('Nom de la société', 'company_name'),
                  const SizedBox(height: 16),
                  _buildTextField('Forme juridique', 'legal_form'),
                  const SizedBox(height: 16),
                  _buildTextField('Capital', 'capital'),
                  const SizedBox(height: 16),
                  _buildTextField('Adresse du siège', 'company_address'),
                  const SizedBox(height: 16),
                  _buildTextField('Code postal', 'company_postal_code'),
                  const SizedBox(height: 16),
                  _buildTextField('Ville', 'company_city'),
                  const SizedBox(height: 16),
                  _buildTextField('RCS', 'rcs'),
                  const SizedBox(height: 16),
                  _buildTextField('SIREN', 'siren'),
                  const SizedBox(height: 16),
                  _buildTextField('Représentant', 'representative_name'),
                  const SizedBox(height: 16),
                  _buildTextField('Qualité du représentant', 'representative_title'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityDomainsPage() {
    final domains = [
      'Direction Financière',
      'Direction Juridique',
      'Direction Générale',
      'Direction Transformation'
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('💼 Domaines d\'activité'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sélectionnez vos domaines d\'expertise :',
                    style: AppTheme.typography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  ...domains.map((domain) => _buildCheckboxTile(domain, 'activity_domains')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagesPage() {
    final languages = [
      'Anglais bilingue',
      'Anglais courant',
      'Anglais technique',
      'Allemand bilingue',
      'Allemand courant',
      'Allemand technique'
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('🌍 Langues & Niveau'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sélectionnez vos compétences linguistiques :',
                    style: AppTheme.typography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  ...languages.map((language) => _buildCheckboxTile(language, 'languages')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiplomasPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('🎓 Diplômes significatifs'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTextField('Diplôme 1', 'diploma_1'),
                  const SizedBox(height: 16),
                  _buildTextField('Diplôme 2', 'diploma_2'),
                  const SizedBox(height: 16),
                  _buildTextField('Diplôme 3', 'diploma_3'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerPathsPage() {
    final careerPaths = [
      'Commerce',
      'Finance',
      'Industriel',
      'Marketing',
      'Opérations',
      'Ressources Humaines'
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('🧭 Parcours'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sélectionnez vos parcours :',
                    style: AppTheme.typography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  ...careerPaths.map((path) => _buildCheckboxTile(path, 'career_paths')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainFunctionsPage() {
    final functions = [
      'Président',
      'Directeur Général Groupe',
      'Directeur Général Filiale',
      'Directeur d\'Établissement',
      'Directeur de Transformation'
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('👔 Principale fonction'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sélectionnez vos fonctions principales :',
                    style: AppTheme.typography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  ...functions.map((function) => _buildCheckboxTile(function, 'main_functions')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalExperiencesPage() {
    final experiences = [
      'Accompagnement Ciri',
      'Accompagnement Cofédi',
      'Acquisition',
      'Carve-out',
      'Cession',
      'Conciliation',
      'Fermeture',
      'In bonis',
      'Levée de fonds',
      'Liquidation',
      'Mandat ad hoc',
      'Mandat social',
      'PDV',
      'Procédure collective',
      'PSE',
      'RCC',
      'Renégociation de dette',
      'Réorganisation',
      'Restructuration',
      'RJ',
      'Spin-off',
      'Split-off'
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('🧠 Expériences professionnelles'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sélectionnez vos expériences :',
                    style: AppTheme.typography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  ...experiences.map((experience) => _buildCheckboxTile(experience, 'professional_experiences')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(title, style: AppTheme.typography.bodySmall.copyWith(color: AppTheme.colors.textSecondary)),
    );
  }

  Widget _buildTextField(String label, String key, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.typography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: _formData[key]?.toString()),
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: 'Saisir $label',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onChanged: (value) {
            _formData[key] = value;
          },
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String key, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.typography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showDropdownPicker(label, key, options),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.colors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formData[key] ?? 'Sélectionner',
                  style: AppTheme.typography.bodyMedium.copyWith(
                    color: _formData[key] != null
                        ? AppTheme.colors.textPrimary
                        : AppTheme.colors.textSecondary,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.colors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, String key) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.typography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showDatePicker(label, key),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.colors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formData[key] != null
                      ? _formData[key].toString()
                      : 'Sélectionner une date',
                  style: AppTheme.typography.bodyMedium.copyWith(
                    color: _formData[key] != null
                        ? AppTheme.colors.textPrimary
                        : AppTheme.colors.textSecondary,
                  ),
                ),
                Icon(Icons.calendar_today, size: 16, color: AppTheme.colors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxTile(String title, String key) {
    final List<dynamic> selectedItems = _formData[key] ?? [];
    final bool isSelected = selectedItems.contains(title);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedItems.remove(title);
          } else {
            selectedItems.add(title);
          }
          _formData[key] = selectedItems;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              color: isSelected ? AppTheme.colors.primary : AppTheme.colors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTheme.typography.bodyMedium.copyWith(
                  color: isSelected ? AppTheme.colors.textPrimary : AppTheme.colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Text('Précédent'),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            child: _currentPage == _totalPages - 1
                ? ElevatedButton(
                    onPressed: _isLoading ? null : _saveQuestionnaire,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.colors.primary, minimumSize: const Size(double.infinity, 50)),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Terminer', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  )
                : ElevatedButton(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.colors.primary, minimumSize: const Size(double.infinity, 50)),
                    child: const Text('Suivant', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
          ),
        ],
      ),
    );
  }

  void _showDropdownPicker(String label, String key, List<String> options) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...options.map((option) => ListTile(
                title: Text(option),
                onTap: () {
                  setState(() {
                    _formData[key] = option;
                  });
                  Navigator.pop(context);
                },
              )),
          ListTile(
            title: Text('Annuler', style: TextStyle(color: AppTheme.colors.textSecondary)),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showDatePicker(String label, String key) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _formData[key] = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _saveQuestionnaire() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Préparer les données pour Supabase
      final profileData = {
        'user_id': SupabaseService.currentUser?.id,
        'civility': _formData['civility'],
        'first_name': _formData['first_name'],
        'last_name': _formData['last_name'],
        'email': _formData['email'],
        'phone': _formData['phone'],
        'birth_date': _formData['birth_date'],
        'address': _formData['address'],
        'postal_code': _formData['postal_code'],
        'city': _formData['city'],
        'company_name': _formData['company_name'],
        'legal_form': _formData['legal_form'],
        'capital': _formData['capital'],
        'company_address': _formData['company_address'],
        'company_postal_code': _formData['company_postal_code'],
        'company_city': _formData['company_city'],
        'rcs': _formData['rcs'],
        'siren': _formData['siren'],
        'representative_name': _formData['representative_name'],
        'representative_title': _formData['representative_title'],
        'activity_domains': _formData['activity_domains'] ?? [],
        'languages': _formData['languages'] ?? [],
        'diplomas': [
          if (_formData['diploma_1'] != null) _formData['diploma_1'],
          if (_formData['diploma_2'] != null) _formData['diploma_2'],
          if (_formData['diploma_3'] != null) _formData['diploma_3'],
        ].where((d) => d != null && d.isNotEmpty).toList(),
        'career_paths': _formData['career_paths'] ?? [],
        'main_functions': _formData['main_functions'] ?? [],
        'professional_experiences': _formData['professional_experiences'] ?? [],
        'questionnaire_completed': true,
        'completed_at': DateTime.now().toIso8601String(),
      };

      // Sauvegarder le profil
      await PartnerProfileService.createPartnerProfile(profileData);

      if (mounted) {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Profil créé !'),
            content: const Text('Votre profil partenaire a été enregistré avec succès.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(c); // Fermer le dialog
                  // Rediriger vers le dashboard partenaire
                  Navigator.pushReplacementNamed(context, '/partner_dashboard');
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Erreur'),
            content: Text('Erreur lors de la sauvegarde : $e'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK')),
            ],
          ),
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
}

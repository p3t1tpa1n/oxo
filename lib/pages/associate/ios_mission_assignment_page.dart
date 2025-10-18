import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../widgets/ios_widgets.dart';
import '../../config/ios_theme.dart';

class IOSMissionAssignmentPage extends StatefulWidget {
  final Map<String, dynamic>? partnerProfile;
  
  const IOSMissionAssignmentPage({
    super.key,
    this.partnerProfile,
  });

  @override
  State<IOSMissionAssignmentPage> createState() => _IOSMissionAssignmentPageState();
}

class _IOSMissionAssignmentPageState extends State<IOSMissionAssignmentPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;
  
  // Données du formulaire
  final Map<String, dynamic> _missionData = {};
  List<Map<String, dynamic>> _suggestedPartners = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Assignation de Mission'),
        backgroundColor: CupertinoColors.systemBackground,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Annuler'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Indicateur de progression
            _buildProgressIndicator(),
            
            // Contenu du formulaire
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildMissionDetailsPage(),
                  _buildCriteriaPage(),
                  _buildPartnerSelectionPage(),
                  _buildConfirmationPage(),
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
                'Étape ${_currentStep + 1} sur $_totalSteps',
                style: IOSTheme.body.copyWith(
                  color: CupertinoColors.systemGrey,
                ),
              ),
              Text(
                '${((_currentStep + 1) / _totalSteps * 100).round()}%',
                style: IOSTheme.body.copyWith(
                  color: CupertinoColors.systemBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CupertinoSlider(
            value: (_currentStep + 1) / _totalSteps,
            onChanged: null,
            activeColor: CupertinoColors.systemBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildMissionDetailsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IOSListSection(
            title: '📋 Détails de la mission',
            children: [
              IOSCard(
                child: Column(
                  children: [
                    _buildTextField('Titre de la mission', 'title'),
                    const SizedBox(height: 16),
                    _buildTextField('Description', 'description'),
                    const SizedBox(height: 16),
                    _buildDateField('Date de début', 'start_date'),
                    const SizedBox(height: 16),
                    _buildDateField('Date de fin', 'end_date'),
                    const SizedBox(height: 16),
                    _buildTextField('Durée estimée (jours)', 'estimated_duration', keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    _buildTextField('Budget', 'budget', keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    _buildTextField('Lieu', 'location'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IOSListSection(
            title: '🎯 Critères de sélection',
            children: [
              IOSCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Domaines d\'expertise requis :',
                      style: IOSTheme.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._buildDomainCheckboxes(),
                    const SizedBox(height: 24),
                    
                    Text(
                      'Expériences professionnelles requises :',
                      style: IOSTheme.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._buildExperienceCheckboxes(),
                    const SizedBox(height: 24),
                    
                    Text(
                      'Secteurs d\'activité requis :',
                      style: IOSTheme.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._buildSectorCheckboxes(),
                    const SizedBox(height: 24),
                    
                    Text(
                      'Langues requises :',
                      style: IOSTheme.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._buildLanguageCheckboxes(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerSelectionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IOSListSection(
            title: '👥 Partenaires suggérés',
            children: [
              if (_suggestedPartners.isEmpty)
                IOSCard(
                  child: Column(
                    children: [
                      const Icon(
                        CupertinoIcons.person_2,
                        size: 48,
                        color: CupertinoColors.systemGrey3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun partenaire suggéré',
                        style: IOSTheme.body.copyWith(
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Recherchez des partenaires en fonction des critères définis.',
                        style: IOSTheme.caption1.copyWith(
                          color: CupertinoColors.systemGrey2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ..._suggestedPartners.map((partner) => _buildPartnerCard(partner)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IOSListSection(
            title: '✅ Confirmation',
            children: [
              IOSCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Résumé de la mission',
                      style: IOSTheme.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryRow('Titre', _missionData['title']),
                    _buildSummaryRow('Description', _missionData['description']),
                    _buildSummaryRow('Date de début', _missionData['start_date']),
                    _buildSummaryRow('Date de fin', _missionData['end_date']),
                    _buildSummaryRow('Durée', '${_missionData['estimated_duration']} jours'),
                    _buildSummaryRow('Budget', '${_missionData['budget']} €'),
                    _buildSummaryRow('Lieu', _missionData['location']),
                    const SizedBox(height: 16),
                    Text(
                      'Partenaires sélectionnés : ${_suggestedPartners.length}',
                      style: IOSTheme.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String key, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: IOSTheme.body.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        IOSTextField(
          placeholder: 'Saisir $label',
          keyboardType: keyboardType,
          onChanged: (value) {
            _missionData[key] = value;
          },
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
          style: IOSTheme.body.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        CupertinoButton(
          padding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: CupertinoColors.systemGrey4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _missionData[key] != null 
                      ? _missionData[key].toString()
                      : 'Sélectionner une date',
                  style: IOSTheme.body.copyWith(
                    color: _missionData[key] != null 
                        ? CupertinoColors.label 
                        : CupertinoColors.systemGrey,
                  ),
                ),
                const Icon(
                  CupertinoIcons.calendar,
                  size: 16,
                  color: CupertinoColors.systemGrey,
                ),
              ],
            ),
          ),
          onPressed: () {
            _showDatePicker(label, key);
          },
        ),
      ],
    );
  }

  List<Widget> _buildDomainCheckboxes() {
    final domains = [
      'Direction Financière',
      'Direction Juridique',
      'Direction Générale',
      'Direction Transformation'
    ];
    
    return domains.map((domain) => _buildCheckboxTile(domain, 'required_domains')).toList();
  }

  List<Widget> _buildExperienceCheckboxes() {
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
    
    return experiences.map((experience) => _buildCheckboxTile(experience, 'required_experiences')).toList();
  }

  List<Widget> _buildSectorCheckboxes() {
    final sectors = [
      'Administration',
      'Aéronautique',
      'Agroalimentaire',
      'Assurance',
      'Banque',
      'Biens de consommation',
      'Biotech',
      'BTP',
      'Chimie',
      'Collectivité',
      'Conseil',
      'Constructeurs',
      'Défense',
      'Distribution',
      'Emballage',
      'Énergies fossiles',
      'Énergies renouvelables',
      'Équipement de la maison',
      'Équipement de la personne',
      'Équipementiers',
      'Ferroviaire',
      'Finance',
      'Fonds d\'investissement',
      'Gestion d\'actifs',
      'Gestion de filiale',
      'Grande consommation',
      'Hôtellerie',
      'Immobilier',
      'Imprimeries',
      'Industrie',
      'Logistique',
      'Loisir',
      'Luxe',
      'Média',
      'Médical',
      'Métallurgie',
      'Négoce',
      'Nucléaire',
      'Plasturgie',
      'Presse',
      'Retail',
      'Santé',
      'Service',
      'Sidérurgie',
      'Tech',
      'Tourisme',
      'Transport'
    ];
    
    return sectors.map((sector) => _buildCheckboxTile(sector, 'required_sectors')).toList();
  }

  List<Widget> _buildLanguageCheckboxes() {
    final languages = [
      'Anglais bilingue',
      'Anglais courant',
      'Anglais technique',
      'Allemand bilingue',
      'Allemand courant',
      'Allemand technique'
    ];
    
    return languages.map((language) => _buildCheckboxTile(language, 'required_languages')).toList();
  }

  Widget _buildCheckboxTile(String title, String key) {
    final List<dynamic> selectedItems = _missionData[key] ?? [];
    final bool isSelected = selectedItems.contains(title);
    
    return CupertinoButton(
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              isSelected ? CupertinoIcons.checkmark_square_fill : CupertinoIcons.square,
              color: isSelected ? CupertinoColors.systemBlue : CupertinoColors.systemGrey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: IOSTheme.body.copyWith(
                  color: isSelected ? CupertinoColors.label : CupertinoColors.systemGrey,
                ),
              ),
            ),
          ],
        ),
      ),
      onPressed: () {
        setState(() {
          if (isSelected) {
            selectedItems.remove(title);
          } else {
            selectedItems.add(title);
          }
          _missionData[key] = selectedItems;
        });
      },
    );
  }

  Widget _buildPartnerCard(Map<String, dynamic> partner) {
    final matchScore = partner['match_score'] ?? 0.0;
    final matchReasons = partner['match_reasons'] as Map<String, dynamic>? ?? {};
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IOSCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '${partner['partner_name']?.toString().substring(0, 1).toUpperCase() ?? '?'}',
                      style: IOSTheme.body.copyWith(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partner['partner_name'] ?? 'Nom non renseigné',
                        style: IOSTheme.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Score: ${matchScore.toStringAsFixed(1)}/10',
                        style: IOSTheme.caption1.copyWith(
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBlue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Sélectionner',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  onPressed: () {
                    // TODO: Implémenter la sélection du partenaire
                  },
                ),
              ],
            ),
            
            if (matchReasons.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Correspondances :',
                style: IOSTheme.caption1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 4),
              ..._buildMatchReasons(matchReasons),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMatchReasons(Map<String, dynamic> reasons) {
    final List<Widget> widgets = [];
    
    if (reasons['domains'] != null && (reasons['domains'] as List).isNotEmpty) {
      widgets.add(_buildReasonChip('Domaines', reasons['domains']));
    }
    
    if (reasons['experiences'] != null && (reasons['experiences'] as List).isNotEmpty) {
      widgets.add(_buildReasonChip('Expériences', reasons['experiences']));
    }
    
    if (reasons['sectors'] != null && (reasons['sectors'] as List).isNotEmpty) {
      widgets.add(_buildReasonChip('Secteurs', reasons['sectors']));
    }
    
    if (reasons['languages'] != null && (reasons['languages'] as List).isNotEmpty) {
      widgets.add(_buildReasonChip('Langues', reasons['languages']));
    }
    
    return widgets;
  }

  Widget _buildReasonChip(String label, List<dynamic> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: IOSTheme.caption1.copyWith(
              fontWeight: FontWeight.w500,
              color: CupertinoColors.systemGrey,
            ),
          ),
          Expanded(
            child: Text(
              items.take(3).join(', '),
              style: IOSTheme.caption1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
              value?.toString() ?? 'Non renseigné',
              style: IOSTheme.body,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: IOSSecondaryButton(
                text: 'Précédent',
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                  setState(() {
                    _currentStep--;
                  });
                },
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              child: _currentStep == _totalSteps - 1
                  ? IOSPrimaryButton(
                      text: _isLoading ? 'Assignation...' : 'Assigner la mission',
                      onPressed: _isLoading ? null : _assignMission,
                    )
                  : IOSPrimaryButton(
                      text: _currentStep == 2 ? 'Rechercher partenaires' : 'Suivant',
                      onPressed: _currentStep == 2 ? _searchPartners : _nextStep,
                    ),
            ),
        ],
      ),
    );
  }

  void _nextStep() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() {
      _currentStep++;
    });
  }

  void _showDatePicker(String label, String key) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Annuler'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('Valider'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: DateTime.now(),
                minimumDate: DateTime.now(),
                onDateTimeChanged: (date) {
                  setState(() {
                    _missionData[key] = date.toIso8601String().split('T')[0];
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _searchPartners() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final criteria = {
        'required_domains': _missionData['required_domains'] ?? [],
        'required_languages': _missionData['required_languages'] ?? [],
        'required_experiences': _missionData['required_experiences'] ?? [],
        'required_sectors': _missionData['required_sectors'] ?? [],
        'required_functions': _missionData['required_functions'] ?? [],
        'required_structure_types': _missionData['required_structure_types'] ?? [],
      };

      final partners = await SupabaseService.findBestPartnersForMission(criteria, limit: 10);
      
      setState(() {
        _suggestedPartners = partners;
        _isLoading = false;
      });

      _nextStep();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Erreur'),
            content: Text('Erreur lors de la recherche de partenaires: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _assignMission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implémenter l'assignation de mission
      await Future.delayed(const Duration(seconds: 2)); // Simulation
      
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Mission assignée !'),
            content: const Text('La mission a été assignée avec succès.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Erreur'),
            content: Text('Erreur lors de l\'assignation: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }
}

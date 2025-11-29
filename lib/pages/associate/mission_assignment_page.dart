import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class MissionAssignmentPage extends StatefulWidget {
  final Map<String, dynamic> partner;

  const MissionAssignmentPage({
    super.key,
    required this.partner,
  });

  @override
  State<MissionAssignmentPage> createState() => _MissionAssignmentPageState();
}

class _MissionAssignmentPageState extends State<MissionAssignmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  
  bool _isLoading = false;
  
  // Variables pour l'autocomplétion des missions
  List<Map<String, dynamic>> _existingMissions = [];
  List<Map<String, dynamic>> _filteredMissions = [];
  bool _isLoadingMissions = false;
  Map<String, dynamic>? _selectedMission;

  @override
  void initState() {
    super.initState();
    _loadExistingMissions();
    _titleController.addListener(_onTitleChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    super.dispose();
  }

  // Charger les missions existantes
  Future<void> _loadExistingMissions() async {
    setState(() {
      _isLoadingMissions = true;
    });

    try {
      debugPrint('🔍 Chargement des missions existantes...');
      // Récupérer les missions existantes depuis Supabase avec tous les détails
      final missions = await SupabaseService.getExistingMissionsWithDetails();
      debugPrint('📊 ${missions.length} missions récupérées');
      debugPrint('📋 Première mission: ${missions.isNotEmpty ? missions.first : "Aucune"}');
      
      setState(() {
        _existingMissions = missions;
        _filteredMissions = missions;
        _isLoadingMissions = false;
      });
      debugPrint('✅ Missions chargées dans l\'état');
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement des missions: $e');
      setState(() {
        _isLoadingMissions = false;
      });
    }
  }

  // Filtrer les missions selon la saisie
  void _onTitleChanged() {
    final query = _titleController.text.toLowerCase();
    debugPrint('🔍 Recherche: "$query"');
    debugPrint('📊 Missions disponibles: ${_existingMissions.length}');
    
    setState(() {
      if (query.isEmpty) {
        _filteredMissions = _existingMissions;
        debugPrint('📋 Affichage de toutes les missions: ${_filteredMissions.length}');
      } else {
        _filteredMissions = _existingMissions
            .where((mission) => mission['title'].toLowerCase().contains(query))
            .toList();
        debugPrint('📋 Missions filtrées: ${_filteredMissions.length}');
        for (var mission in _filteredMissions) {
          debugPrint('  - ${mission['title']}');
        }
      }
    });
  }

  // Sélectionner une mission
  void _selectMission(Map<String, dynamic> mission) {
    setState(() {
      _selectedMission = mission;
      _titleController.text = mission['title'];
      _filteredMissions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Proposer mission - ${widget.partner['first_name']} ${widget.partner['last_name']}'),
        backgroundColor: const Color(0xFF1E3D54),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informations du partenaire
                    _buildPartnerInfo(),
                    const SizedBox(height: 24),
                    
                    // Formulaire de mission
                    _buildMissionForm(),
                    const SizedBox(height: 24),
                    
                    // Boutons d'action
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPartnerInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Partenaire sélectionné',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3D54),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(0xFF1E3D54).withValues(alpha: 0.1),
                  child: Text(
                    '${widget.partner['first_name']?[0] ?? ''}${widget.partner['last_name']?[0] ?? ''}',
                    style: const TextStyle(
                      color: Color(0xFF1E3D54),
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.partner['first_name']} ${widget.partner['last_name']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.partner['company_name'] != null)
                        Text(
                          widget.partner['company_name'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      if (widget.partner['email'] != null)
                        Text(
                          widget.partner['email'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Détails de la mission',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3D54),
              ),
            ),
            const SizedBox(height: 16),
            
            // Titre de la mission avec autocomplétion
            _buildMissionTitleField(),
            
            // Indicateur de chargement ou nombre de missions
            if (_isLoadingMissions)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Chargement des missions...'),
                  ],
                ),
              )
            else if (_existingMissions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '${_existingMissions.length} missions disponibles',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Aucune mission disponible',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E3D54),
              side: const BorderSide(color: Color(0xFF1E3D54)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Annuler'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _assignMission,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3D54),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Proposer la mission'),
          ),
        ),
      ],
    );
  }


  Future<void> _assignMission() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMission == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une mission existante'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Créer une proposition de mission (assignation d'une mission existante)
      final missionProposalData = {
        'mission_id': _selectedMission!['id'],
        'partner_id': widget.partner['user_id'],
        'associate_id': SupabaseService.client.auth.currentUser?.id,
        'proposed_at': DateTime.now().toIso8601String(),
        'status': 'pending', // Le partenaire peut accepter ou refuser
      };

      final success = await SupabaseService.createMissionProposal(missionProposalData);

      if (success) {
        // Envoyer une notification au partenaire
        await SupabaseService.sendNotificationToPartner(
          widget.partner['user_id'],
          'Mission proposée',
          'Une mission vous a été proposée: ${_selectedMission!['title']}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mission proposée avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Erreur lors de la proposition de la mission');
      }
    } catch (e) {
      debugPrint('Erreur lors de la proposition de mission: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
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

  // Widget pour le champ de titre avec autocomplétion
  Widget _buildMissionTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Titre de la mission *',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.assignment),
            suffixIcon: _isLoadingMissions 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.search),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Le titre est obligatoire';
            }
            return null;
          },
        ),
        if (_filteredMissions.isNotEmpty) ...[
          _buildSuggestionsList(),
        ],
      ],
    );
  }

  // Construire la liste des suggestions
  Widget _buildSuggestionsList() {
    debugPrint('🎯 Affichage des suggestions: ${_filteredMissions.length}');
    
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _filteredMissions.length > 5 ? 5 : _filteredMissions.length,
        itemBuilder: (context, index) {
          final mission = _filteredMissions[index];
          return ListTile(
            dense: true,
            title: Text(
              mission['title'],
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mission['description'] != null && mission['description'].isNotEmpty)
                  Text(
                    mission['description'],
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Row(
                  children: [
                    if (mission['budget'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${mission['budget']}€',
                          style: TextStyle(fontSize: 10, color: Colors.blue[700]),
                        ),
                      ),
                    const SizedBox(width: 8),
                    if (mission['priority'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(mission['priority']).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          mission['priority'],
                          style: TextStyle(fontSize: 10, color: _getPriorityColor(mission['priority'])),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            onTap: () {
              _selectMission(mission);
            },
          );
        },
      ),
    );
  }

  // Obtenir la couleur selon la priorité
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critique':
        return Colors.red;
      case 'élevée':
        return Colors.orange;
      case 'moyenne':
        return Colors.blue;
      case 'faible':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

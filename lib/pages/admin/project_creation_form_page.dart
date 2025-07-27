import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/ios_theme.dart';
import '../../widgets/ios_widgets.dart';
import '../../services/supabase_service.dart';
import '../../models/user_role.dart';

class ProjectCreationFormPage extends StatefulWidget {
  const ProjectCreationFormPage({super.key});

  @override
  State<ProjectCreationFormPage> createState() => _ProjectCreationFormPageState();
}

class _ProjectCreationFormPageState extends State<ProjectCreationFormPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _estimatedDaysController = TextEditingController();
  final TextEditingController _dailyRateController = TextEditingController();
  
  DateTime? _selectedEndDate;
  Map<String, dynamic>? _selectedClient;
  List<Map<String, dynamic>> _clients = [];
  bool _isSubmitting = false;
  bool _isLoadingClients = true;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _estimatedDaysController.dispose();
    _dailyRateController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    try {
      setState(() { _isLoadingClients = true; });
      final clients = await SupabaseService.getCompanyClients();
      setState(() {
        _clients = clients;
        _isLoadingClients = false;
      });
    } catch (e) {
      setState(() { _isLoadingClients = false; });
      _showError('Erreur lors du chargement des clients: $e');
    }
  }

  Future<void> _selectEndDate() async {
    // Créer une date de référence unique pour éviter les race conditions
    final DateTime now = DateTime.now();
    final DateTime minimumDate = now.subtract(const Duration(minutes: 1));
    final DateTime initialDate = _selectedEndDate ?? now.add(const Duration(days: 30));
    final DateTime maximumDate = now.add(const Duration(days: 365));
    
    DateTime? tempSelectedDate = initialDate;
    
    final DateTime? picked = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
        color: IOSTheme.systemBackground,
        child: Column(
          children: [
            Container(
              height: 50,
              color: IOSTheme.systemGray6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Annuler'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  CupertinoButton(
                    child: const Text('Confirmer'),
                    onPressed: () => Navigator.of(context).pop(tempSelectedDate),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initialDate,
                minimumDate: minimumDate,
                maximumDate: maximumDate,
                onDateTimeChanged: (DateTime dateTime) {
                  tempSelectedDate = dateTime;
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (picked != null && picked != _selectedEndDate) {
      setState(() {
        _selectedEndDate = picked;
      });
    }
  }

  Future<void> _selectClient() async {
    if (_clients.isEmpty) {
      _showError('Aucun client disponible. Veuillez d\'abord créer un client.');
      return;
    }

    showCupertinoModalPopup<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Sélectionner un client'),
        message: const Text('Pour quel client créez-vous ce projet ?'),
        actions: _clients.map((client) {
          return CupertinoActionSheetAction(
            child: Text(
              client['full_name'] ?? client['email'] ?? 'Client',
              style: IOSTheme.body,
            ),
            onPressed: () {
              Navigator.of(context).pop(client);
            },
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Annuler'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    ).then((selectedClient) {
      if (selectedClient != null) {
        setState(() {
          _selectedClient = selectedClient;
        });
      }
    });
  }

  Future<void> _submitProject() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Veuillez saisir un nom pour le projet.');
      return;
    }

    if (_selectedClient == null) {
      _showError('Veuillez sélectionner un client pour ce projet.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final estimatedDays = double.tryParse(_estimatedDaysController.text.trim());
      final dailyRate = double.tryParse(_dailyRateController.text.trim());

      final projectId = await SupabaseService.createProjectWithClient(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim() 
            : null,
        clientId: _selectedClient!['user_id'],
        estimatedDays: estimatedDays,
        dailyRate: dailyRate,
        endDate: _selectedEndDate,
      );

      if (projectId != null && mounted) {
        Navigator.of(context).pop();
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Succès'),
            content: Text('Projet "${_nameController.text.trim()}" créé avec succès pour ${_selectedClient!['full_name']}.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      } else {
        _showError('Erreur lors de la création du projet.');
      }
    } catch (e) {
      _showError('Erreur lors de la création du projet: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Erreur'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IOSScaffold(
      navigationBar: IOSNavigationBar(
        title: "Nouveau Projet",
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _isSubmitting ? null : _submitProject,
            child: _isSubmitting
                ? const CupertinoActivityIndicator()
                : const Text(
                    'Créer',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
      body: _isLoadingClients
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoActivityIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des clients...', style: IOSTheme.body),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: IOSTheme.cardDecoration.copyWith(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          IOSTheme.primaryBlue.withValues(alpha: 0.05),
                          IOSTheme.systemBackground,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          CupertinoIcons.folder_badge_plus,
                          size: 40,
                          color: IOSTheme.primaryBlue,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nouveau projet client',
                          style: IOSTheme.title2,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Créez un projet pour un client spécifique avec toutes les informations nécessaires.',
                          style: IOSTheme.body.copyWith(color: IOSTheme.labelSecondary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Informations du projet
                  IOSListSection(
                    title: "Informations du projet",
                    children: [
                      IOSListTile(
                        title: const Text('Nom du projet *', style: IOSTheme.body),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: CupertinoTextField(
                            controller: _nameController,
                            placeholder: 'Ex: Site web entreprise ABC',
                            style: IOSTheme.body,
                            decoration: const BoxDecoration(),
                          ),
                        ),
                      ),
                      IOSListTile(
                        title: const Text('Description', style: IOSTheme.body),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: CupertinoTextField(
                            controller: _descriptionController,
                            placeholder: 'Description détaillée du projet...',
                            style: IOSTheme.body,
                            maxLines: 4,
                            decoration: const BoxDecoration(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Client et planification
                  IOSListSection(
                    title: "Client et planification",
                    children: [
                      IOSListTile(
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: IOSTheme.primaryBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            CupertinoIcons.person_fill,
                            color: IOSTheme.primaryBlue,
                            size: 18,
                          ),
                        ),
                        title: const Text('Client assigné *', style: IOSTheme.body),
                        subtitle: Text(
                          _selectedClient != null 
                              ? _selectedClient!['full_name'] ?? _selectedClient!['email'] ?? 'Client'
                              : 'Aucun client sélectionné',
                          style: IOSTheme.footnote.copyWith(
                            color: _selectedClient != null 
                                ? IOSTheme.labelPrimary 
                                : IOSTheme.systemRed,
                          ),
                        ),
                        trailing: const Icon(CupertinoIcons.chevron_right, color: IOSTheme.primaryBlue),
                        onTap: _selectClient,
                      ),
                      IOSListTile(
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: IOSTheme.warningColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            CupertinoIcons.calendar,
                            color: IOSTheme.warningColor,
                            size: 18,
                          ),
                        ),
                        title: const Text('Date de fin souhaitée', style: IOSTheme.body),
                        subtitle: Text(
                          _selectedEndDate != null
                              ? DateFormat('dd/MM/yyyy').format(_selectedEndDate!)
                              : 'Aucune date définie',
                          style: IOSTheme.footnote.copyWith(
                            color: _selectedEndDate != null 
                                ? IOSTheme.labelPrimary 
                                : IOSTheme.labelTertiary,
                          ),
                        ),
                        trailing: const Icon(CupertinoIcons.chevron_right, color: IOSTheme.warningColor),
                        onTap: _selectEndDate,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Estimation (optionnel)
                  IOSListSection(
                    title: "Estimation (optionnel)",
                    children: [
                      IOSListTile(
                        title: const Text('Nombre de jours estimé', style: IOSTheme.body),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: CupertinoTextField(
                            controller: _estimatedDaysController,
                            placeholder: 'Ex: 15',
                            style: IOSTheme.body,
                            keyboardType: TextInputType.number,
                            decoration: const BoxDecoration(),
                          ),
                        ),
                      ),
                      IOSListTile(
                        title: const Text('Tarif journalier (€)', style: IOSTheme.body),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: CupertinoTextField(
                            controller: _dailyRateController,
                            placeholder: 'Ex: 500',
                            style: IOSTheme.body,
                            keyboardType: TextInputType.number,
                            decoration: const BoxDecoration(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Bouton de création
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      borderRadius: BorderRadius.circular(12),
                      onPressed: _isSubmitting ? null : _submitProject,
                      child: _isSubmitting
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CupertinoActivityIndicator(color: Colors.white),
                                const SizedBox(width: 12),
                                Text(
                                  'Création en cours...',
                                  style: IOSTheme.body.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(CupertinoIcons.folder_badge_plus, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  'Créer le projet',
                                  style: IOSTheme.body.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: IOSTheme.systemGray6,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          CupertinoIcons.info_circle_fill,
                          color: IOSTheme.primaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Une fois créé, le projet sera visible par le client sélectionné. Vous pourrez y ajouter des tâches et suivre son avancement.',
                            style: IOSTheme.footnote.copyWith(color: IOSTheme.labelSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
} 
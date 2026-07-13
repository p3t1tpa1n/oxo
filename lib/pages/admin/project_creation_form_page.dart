import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
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
    final DateTime now = DateTime.now();
    final DateTime initialDate = _selectedEndDate ?? now.add(const Duration(days: 30));
    final DateTime maximumDate = now.add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: maximumDate,
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

    showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Sélectionner un client',
              style: AppTheme.typography.h4,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              children: [
                ..._clients.map((client) => ListTile(
                  title: Text(client['full_name'] ?? client['email'] ?? 'Client'),
                  onTap: () => Navigator.of(context).pop(client),
                )),
                ListTile(
                  title: Text('Annuler', style: TextStyle(color: AppTheme.colors.textSecondary)),
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ],
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
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Succès'),
            content: Text('Projet "${_nameController.text.trim()}" créé avec succès pour ${_selectedClient!['full_name']}.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('OK')),
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
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Erreur'),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('OK')),
          ],
        ),
      );
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
        title: const Text('Nouveau Projet'),
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitProject,
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Créer', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _isLoadingClients
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(height: 16),
                  Text('Chargement des clients...', style: AppTheme.typography.bodyMedium),
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
                    decoration: BoxDecoration(
                      color: AppTheme.colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.colors.border),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.colors.primary.withOpacity(0.05),
                          AppTheme.colors.surface,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.create_new_folder, size: 40, color: AppTheme.colors.primary),
                        const SizedBox(height: 12),
                        Text('Nouveau projet client', style: AppTheme.typography.h3),
                        const SizedBox(height: 8),
                        Text(
                          'Créez un projet pour un client spécifique avec toutes les informations nécessaires.',
                          style: AppTheme.typography.bodyMedium.copyWith(color: AppTheme.colors.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Informations du projet
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 8),
                    child: Text('Informations du projet', style: AppTheme.typography.bodySmall.copyWith(color: AppTheme.colors.textSecondary)),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        ListTile(
                          title: Text('Nom du projet *', style: AppTheme.typography.bodyMedium),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                hintText: 'Ex: Site web entreprise ABC',
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: AppTheme.colors.textSecondary),
                              ),
                              style: AppTheme.typography.bodyMedium,
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          title: Text('Description', style: AppTheme.typography.bodyMedium),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextField(
                              controller: _descriptionController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Description détaillée du projet...',
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: AppTheme.colors.textSecondary),
                              ),
                              style: AppTheme.typography.bodyMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Client et planification
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 8),
                    child: Text('Client et planification', style: AppTheme.typography.bodySmall.copyWith(color: AppTheme.colors.textSecondary)),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.colors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.person, color: AppTheme.colors.primary, size: 18),
                          ),
                          title: Text('Client assigné *', style: AppTheme.typography.bodyMedium),
                          subtitle: Text(
                            _selectedClient != null
                                ? _selectedClient!['full_name'] ?? _selectedClient!['email'] ?? 'Client'
                                : 'Aucun client sélectionné',
                            style: AppTheme.typography.bodySmall.copyWith(
                              color: _selectedClient != null
                                  ? AppTheme.colors.textPrimary
                                  : AppTheme.colors.error,
                            ),
                          ),
                          trailing: Icon(Icons.chevron_right, color: AppTheme.colors.primary),
                          onTap: _selectClient,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.colors.warning.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.calendar_today, color: AppTheme.colors.warning, size: 18),
                          ),
                          title: Text('Date de fin souhaitée', style: AppTheme.typography.bodyMedium),
                          subtitle: Text(
                            _selectedEndDate != null
                                ? DateFormat('dd/MM/yyyy').format(_selectedEndDate!)
                                : 'Aucune date définie',
                            style: AppTheme.typography.bodySmall.copyWith(
                              color: _selectedEndDate != null
                                  ? AppTheme.colors.textPrimary
                                  : AppTheme.colors.textSecondary,
                            ),
                          ),
                          trailing: Icon(Icons.chevron_right, color: AppTheme.colors.warning),
                          onTap: _selectEndDate,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Estimation (optionnel)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 8),
                    child: Text('Estimation (optionnel)', style: AppTheme.typography.bodySmall.copyWith(color: AppTheme.colors.textSecondary)),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        ListTile(
                          title: Text('Nombre de jours estimé', style: AppTheme.typography.bodyMedium),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextField(
                              controller: _estimatedDaysController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Ex: 15',
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: AppTheme.colors.textSecondary),
                              ),
                              style: AppTheme.typography.bodyMedium,
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          title: Text('Tarif journalier (€)', style: AppTheme.typography.bodyMedium),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextField(
                              controller: _dailyRateController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Ex: 500',
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: AppTheme.colors.textSecondary),
                              ),
                              style: AppTheme.typography.bodyMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Bouton de création
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.colors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _isSubmitting ? null : _submitProject,
                        child: _isSubmitting
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Création en cours...',
                                    style: AppTheme.typography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.create_new_folder, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Créer le projet',
                                    style: AppTheme.typography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Note
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.colors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.colors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info, color: AppTheme.colors.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Une fois créé, le projet sera visible par le client sélectionné. Vous pourrez y ajouter des tâches et suivre son avancement.',
                              style: AppTheme.typography.bodySmall.copyWith(color: AppTheme.colors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

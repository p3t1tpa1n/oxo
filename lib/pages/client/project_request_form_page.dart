import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../services/project_proposal_service.dart';
import '../../services/document_storage_service.dart';

class ProjectRequestFormPage extends StatefulWidget {
  const ProjectRequestFormPage({super.key});

  @override
  State<ProjectRequestFormPage> createState() => _ProjectRequestFormPageState();
}

class _ProjectRequestFormPageState extends State<ProjectRequestFormPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  DateTime? _selectedEndDate;
  List<PlatformFile> _selectedFiles = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
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

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'png'],
      );

      if (result != null) {
        setState(() {
          _selectedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Erreur'),
            content: Text('Impossible de sélectionner les fichiers: $e'),
            actions: [
              TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('OK')),
            ],
          ),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _submitRequest() async {
    if (_titleController.text.trim().isEmpty) {
      _showError('Veuillez saisir un titre pour votre projet.');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showError('Veuillez saisir une description pour votre projet.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Conversion du budget
      final budgetValue = double.tryParse(_budgetController.text.trim()) ?? 0.0;

      // Upload des documents si nécessaire
      List<Map<String, dynamic>>? documents;
      if (_selectedFiles.isNotEmpty) {
        documents = await DocumentStorageService.uploadDocuments(_selectedFiles);
      }

      // Soumission de la demande
      final proposalId = await ProjectProposalService.submitProjectProposal(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        estimatedBudget: budgetValue > 0 ? budgetValue : null,
        endDate: _selectedEndDate,
        documents: documents,
      );

      if (proposalId != null && mounted) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Succès'),
            content: const Text('Votre demande de projet a été envoyée avec succès.\n\nVotre équipe vous contactera bientôt.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('OK')),
            ],
          ),
        );
      }
    } catch (e) {
      _showError('Erreur lors de l\'envoi de la demande: $e');
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
        title: const Text('Nouvelle Demande'),
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitRequest,
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Envoyer', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                  Icon(Icons.description, size: 40, color: AppTheme.colors.primary),
                  const SizedBox(height: 12),
                  Text('Nouvelle demande de projet', style: AppTheme.typography.h3),
                  const SizedBox(height: 8),
                  Text(
                    'Décrivez votre projet en détail pour que notre équipe puisse vous proposer la meilleure solution.',
                    style: AppTheme.typography.bodyMedium.copyWith(color: AppTheme.colors.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Formulaire
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text('Informations du projet', style: AppTheme.typography.bodySmall.copyWith(color: AppTheme.colors.textSecondary)),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ListTile(
                    title: Text('Titre du projet *', style: AppTheme.typography.bodyMedium),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Ex: Site web vitrine pour mon entreprise',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: AppTheme.colors.textSecondary),
                        ),
                        style: AppTheme.typography.bodyMedium,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text('Description détaillée *', style: AppTheme.typography.bodyMedium),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextField(
                        controller: _descriptionController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText: 'Décrivez votre projet, vos besoins, objectifs...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: AppTheme.colors.textSecondary),
                        ),
                        style: AppTheme.typography.bodyMedium,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text('Budget estimé (€)', style: AppTheme.typography.bodyMedium),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextField(
                        controller: _budgetController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Ex: 5000',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: AppTheme.colors.textSecondary),
                        ),
                        style: AppTheme.typography.bodyMedium,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text('Date de fin souhaitée', style: AppTheme.typography.bodyMedium),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GestureDetector(
                        onTap: _selectEndDate,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.colors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _selectedEndDate != null
                                ? DateFormat('dd/MM/yyyy').format(_selectedEndDate!)
                                : 'Sélectionner une date',
                            style: AppTheme.typography.bodyMedium.copyWith(
                              color: _selectedEndDate != null
                                  ? AppTheme.colors.textPrimary
                                  : AppTheme.colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Documents
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text('Documents (optionnel)', style: AppTheme.typography.bodySmall.copyWith(color: AppTheme.colors.textSecondary)),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.attach_file, color: AppTheme.colors.primary),
                    title: Text('Ajouter des fichiers', style: AppTheme.typography.bodyMedium),
                    subtitle: Text('PDF, DOC, Images...', style: AppTheme.typography.bodySmall),
                    trailing: Icon(Icons.add, color: AppTheme.colors.primary),
                    onTap: _pickFiles,
                  ),
                  if (_selectedFiles.isNotEmpty)
                    ..._selectedFiles.asMap().entries.map((entry) {
                      final index = entry.key;
                      final file = entry.value;
                      return ListTile(
                        leading: Icon(Icons.insert_drive_file, color: AppTheme.colors.textSecondary),
                        title: Text(
                          file.name,
                          style: AppTheme.typography.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${(file.size / 1024).round()} KB',
                          style: AppTheme.typography.bodySmall,
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.remove_circle, color: AppTheme.colors.error),
                          onPressed: () => _removeFile(index),
                          padding: EdgeInsets.zero,
                        ),
                      );
                    }),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Bouton d'envoi
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
                  onPressed: _isSubmitting ? null : _submitRequest,
                  child: _isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                            const SizedBox(width: 12),
                            Text(
                              'Envoi en cours...',
                              style: AppTheme.typography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Envoyer la demande',
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
                        'Votre demande sera examinée par notre équipe. Vous recevrez une réponse sous 48h avec un devis détaillé.',
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

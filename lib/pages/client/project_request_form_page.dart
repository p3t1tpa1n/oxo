import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../config/ios_theme.dart';
import '../../widgets/ios_widgets.dart';
import '../../services/supabase_service.dart';

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
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Erreur'),
            content: Text('Impossible de sélectionner les fichiers: $e'),
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
        documents = await SupabaseService.uploadDocuments(_selectedFiles);
      }

      // Soumission de la demande
      final proposalId = await SupabaseService.submitProjectProposal(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        estimatedBudget: budgetValue > 0 ? budgetValue : null,
        endDate: _selectedEndDate,
        documents: documents,
      );

      if (proposalId != null && mounted) {
        Navigator.of(context).pop();
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Succès'),
            content: const Text('Votre demande de projet a été envoyée avec succès.\n\nVotre équipe vous contactera bientôt.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
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
        title: "Nouvelle Demande",
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _isSubmitting ? null : _submitRequest,
            child: _isSubmitting
                ? const CupertinoActivityIndicator()
                : const Text(
                    'Envoyer',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
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
              decoration: IOSTheme.cardDecoration.copyWith(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    IOSTheme.primaryBlue.withOpacity(0.05),
                    IOSTheme.systemBackground,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    CupertinoIcons.doc_text_fill,
                    size: 40,
                    color: IOSTheme.primaryBlue,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nouvelle demande de projet',
                    style: IOSTheme.title2,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Décrivez votre projet en détail pour que notre équipe puisse vous proposer la meilleure solution.',
                    style: IOSTheme.body.copyWith(color: IOSTheme.labelSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Formulaire
            IOSListSection(
              title: "Informations du projet",
              children: [
                IOSListTile(
                  title: const Text('Titre du projet *', style: IOSTheme.body),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: CupertinoTextField(
                      controller: _titleController,
                      placeholder: 'Ex: Site web vitrine pour mon entreprise',
                      style: IOSTheme.body,
                      decoration: const BoxDecoration(),
                    ),
                  ),
                ),
                IOSListTile(
                  title: const Text('Description détaillée *', style: IOSTheme.body),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: CupertinoTextField(
                      controller: _descriptionController,
                      placeholder: 'Décrivez votre projet, vos besoins, objectifs...',
                      style: IOSTheme.body,
                      maxLines: 6,
                      decoration: const BoxDecoration(),
                    ),
                  ),
                ),
                IOSListTile(
                  title: const Text('Budget estimé (€)', style: IOSTheme.body),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: CupertinoTextField(
                      controller: _budgetController,
                      placeholder: 'Ex: 5000',
                      style: IOSTheme.body,
                      keyboardType: TextInputType.number,
                      decoration: const BoxDecoration(),
                    ),
                  ),
                ),
                IOSListTile(
                  title: const Text('Date de fin souhaitée', style: IOSTheme.body),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _selectEndDate,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: IOSTheme.systemGray6,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _selectedEndDate != null
                              ? DateFormat('dd/MM/yyyy').format(_selectedEndDate!)
                              : 'Sélectionner une date',
                          style: IOSTheme.body.copyWith(
                            color: _selectedEndDate != null
                                ? IOSTheme.labelPrimary
                                : IOSTheme.labelTertiary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Documents
            IOSListSection(
              title: "Documents (optionnel)",
              children: [
                IOSListTile(
                  leading: const Icon(CupertinoIcons.doc_fill, color: IOSTheme.primaryBlue),
                  title: const Text('Ajouter des fichiers', style: IOSTheme.body),
                  subtitle: const Text('PDF, DOC, Images...', style: IOSTheme.footnote),
                  trailing: const Icon(CupertinoIcons.add, color: IOSTheme.primaryBlue),
                  onTap: _pickFiles,
                ),
                if (_selectedFiles.isNotEmpty)
                  ..._selectedFiles.asMap().entries.map((entry) {
                    final index = entry.key;
                    final file = entry.value;
                    return IOSListTile(
                      leading: const Icon(CupertinoIcons.doc, color: IOSTheme.systemGray),
                      title: Text(
                        file.name,
                        style: IOSTheme.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${(file.size / 1024).round()} KB',
                        style: IOSTheme.footnote,
                      ),
                      trailing: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _removeFile(index),
                        child: const Icon(
                          CupertinoIcons.minus_circle_fill,
                          color: IOSTheme.systemRed,
                        ),
                      ),
                    );
                  }),
              ],
            ),

            const SizedBox(height: 32),

            // Bouton d'envoi
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                borderRadius: BorderRadius.circular(12),
                onPressed: _isSubmitting ? null : _submitRequest,
                child: _isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CupertinoActivityIndicator(color: Colors.white),
                          const SizedBox(width: 12),
                          Text(
                            'Envoi en cours...',
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
                          const Icon(CupertinoIcons.paperplane_fill, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Envoyer la demande',
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
                      'Votre demande sera examinée par notre équipe. Vous recevrez une réponse sous 48h avec un devis détaillé.',
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
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../config/ios_theme.dart';
import '../../widgets/ios_widgets.dart';
import '../../services/supabase_service.dart';

class IOSMobileCreateClientPage extends StatefulWidget {
  const IOSMobileCreateClientPage({Key? key}) : super(key: key);

  @override
  State<IOSMobileCreateClientPage> createState() => _IOSMobileCreateClientPageState();
}

class _IOSMobileCreateClientPageState extends State<IOSMobileCreateClientPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isLoading = false;
  bool _isExpanded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _createClient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('🔍 Tentative de création du client...');
      print('📝 Nom: ${_nameController.text.trim()}');
      print('📧 Email: ${_emailController.text.trim()}');
      
      final client = await SupabaseService.createClient(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        company: _companyController.text.trim().isNotEmpty ? _companyController.text.trim() : null,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      print('📊 Résultat: $client');

      if (client != null) {
        print('✅ Client créé avec succès');
        _showSuccessDialog();
      } else {
        print('❌ Client est null');
        _showErrorDialog('Erreur lors de la création du client');
      }
    } catch (e) {
      print('💥 Erreur: $e');
      _showErrorDialog('Erreur: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Succès'),
        content: const Text('Le client a été créé avec succès.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(); // Fermer le dialogue
              Navigator.of(context).pop(); // Retourner à la page précédente
            },
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
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

  @override
  Widget build(BuildContext context) {
    return IOSScaffold(
      navigationBar: IOSNavigationBar(
        title: "Nouveau Client",
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(
            CupertinoIcons.back,
            color: IOSTheme.primaryBlue,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildBasicInfoSection(),
              const SizedBox(height: 16),
              _buildOptionalInfoSection(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: IOSTheme.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: IOSTheme.systemGray5, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: IOSTheme.primaryBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.person_add,
                  color: IOSTheme.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Créer un nouveau client',
                      style: IOSTheme.title2.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ajoutez les informations du client',
                      style: IOSTheme.body.copyWith(color: IOSTheme.labelSecondary),
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

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IOSTheme.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: IOSTheme.systemGray5, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations principales',
            style: IOSTheme.title3.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          
          // Nom
          Text(
            'Nom complet *',
            style: IOSTheme.footnote.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          IOSTextField(
            controller: _nameController,
            placeholder: 'Ex: Jean Dupont',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le nom est requis';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Email
          Text(
            'Adresse email *',
            style: IOSTheme.footnote.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          IOSTextField(
            controller: _emailController,
            placeholder: 'Ex: jean.dupont@email.com',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'L\'email est requis';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Format d\'email invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Téléphone
          Text(
            'Téléphone',
            style: IOSTheme.footnote.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          IOSTextField(
            controller: _phoneController,
            placeholder: 'Ex: 01 23 45 67 89',
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IOSTheme.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: IOSTheme.systemGray5, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Informations complémentaires',
                  style: IOSTheme.title3.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() => _isExpanded = !_isExpanded);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isExpanded ? 'Masquer' : 'Afficher',
                      style: IOSTheme.body.copyWith(color: IOSTheme.primaryBlue),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                      color: IOSTheme.primaryBlue,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (_isExpanded) ...[
            const SizedBox(height: 16),
            
            // Entreprise
            Text(
              'Entreprise',
              style: IOSTheme.footnote.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            IOSTextField(
              controller: _companyController,
              placeholder: 'Ex: Acme Corporation',
            ),
            const SizedBox(height: 16),
            
            // Adresse
            Text(
              'Adresse',
              style: IOSTheme.footnote.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            IOSTextField(
              controller: _addressController,
              placeholder: 'Ex: 123 Rue de la Paix, 75001 Paris',
            ),
            const SizedBox(height: 16),
            
            // Notes
            Text(
              'Notes',
              style: IOSTheme.footnote.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            IOSTextField(
              controller: _notesController,
              placeholder: 'Informations supplémentaires...',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: IOSPrimaryButton(
        text: _isLoading ? 'Création...' : 'Créer le client',
        onPressed: _isLoading ? null : _createClient,
        isLoading: _isLoading,
      ),
    );
  }
}

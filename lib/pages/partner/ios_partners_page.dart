import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../config/ios_theme.dart';
import '../../widgets/ios_widgets.dart';
import '../../services/supabase_service.dart';
import '../messaging/ios_messaging_page.dart';

class IOSPartnersPage extends StatefulWidget {
  const IOSPartnersPage({Key? key}) : super(key: key);

  @override
  State<IOSPartnersPage> createState() => _IOSPartnersPageState();
}

class _IOSPartnersPageState extends State<IOSPartnersPage> {
  List<Map<String, dynamic>> _partners = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  Future<void> _loadPartners() async {
    setState(() => _isLoading = true);
    
    try {
      final partners = await SupabaseService.getPartners();
      if (mounted) {
        setState(() {
          _partners = partners;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Erreur lors du chargement des partenaires: $e');
      }
    }
  }

  void _showError(String message) {
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

  List<Map<String, dynamic>> get _filteredPartners {
    if (_searchQuery.isEmpty) return _partners;
    
    return _partners.where((partner) {
      final fullName = '${partner['first_name'] ?? ''} ${partner['last_name'] ?? ''}'.toLowerCase();
      final email = (partner['email'] ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      return fullName.contains(query) || email.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return IOSScaffold(
      navigationBar: IOSNavigationBar(
        title: "Partenaires",
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _loadPartners,
            child: const Icon(CupertinoIcons.refresh, color: IOSTheme.primaryBlue),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : Column(
              children: [
                _buildSearchBar(),
                Expanded(child: _buildPartnersList()),
              ],
            ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: IOSTheme.systemGroupedBackground,
      padding: const EdgeInsets.all(16),
      child: CupertinoSearchTextField(
        placeholder: 'Rechercher un partenaire...',
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildPartnersList() {
    final filteredPartners = _filteredPartners;
    
    if (filteredPartners.isEmpty) {
      return _buildEmptyState();
    }

    return IOSListSection(
      children: filteredPartners.map((partner) => _buildPartnerTile(partner)).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.person_2,
            size: 64,
            color: IOSTheme.systemGray3,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty 
                ? 'Aucun partenaire trouvé'
                : 'Aucun résultat pour "$_searchQuery"',
            style: IOSTheme.title3.copyWith(color: IOSTheme.systemGray, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Les partenaires apparaîtront ici'
                : 'Essayez un autre terme de recherche',
            style: IOSTheme.footnote.copyWith(color: IOSTheme.systemGray2),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerTile(Map<String, dynamic> partner) {
    final firstName = partner['first_name'] ?? '';
    final lastName = partner['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final email = partner['email'] ?? '';
    final phone = partner['phone'];
    final initials = '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();

    return IOSListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: IOSTheme.primaryBlue,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            initials.isNotEmpty ? initials : '?',
            style: IOSTheme.body.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      title: Text(
        fullName.isNotEmpty ? fullName : 'Nom non défini',
        style: IOSTheme.body.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(CupertinoIcons.mail, size: 14, color: IOSTheme.systemGray),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    email,
                    style: IOSTheme.footnote.copyWith(color: IOSTheme.systemGray),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (phone != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(CupertinoIcons.phone, size: 14, color: IOSTheme.systemGray),
                const SizedBox(width: 4),
                Text(
                  phone,
                  style: IOSTheme.footnote.copyWith(color: IOSTheme.systemGray),
                ),
              ],
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _contactPartner(partner),
            child: Icon(
              CupertinoIcons.chat_bubble,
              color: IOSTheme.primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            CupertinoIcons.forward,
            color: IOSTheme.systemGray3,
            size: 16,
          ),
        ],
      ),
      onTap: () => _showPartnerDetails(partner),
    );
  }

  void _contactPartner(Map<String, dynamic> partner) {
    // Rediriger vers la messagerie générale
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const IOSMessagingPage(),
      ),
    );
  }

  void _showPartnerDetails(Map<String, dynamic> partner) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _buildPartnerDetailsSheet(partner),
    );
  }

  Widget _buildPartnerDetailsSheet(Map<String, dynamic> partner) {
    final firstName = partner['first_name'] ?? '';
    final lastName = partner['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final email = partner['email'] ?? '';
    final phone = partner['phone'];
    final status = partner['status'] ?? 'unknown';

    return CupertinoActionSheet(
      title: Text(
        fullName.isNotEmpty ? fullName : 'Partenaire',
        style: IOSTheme.title3,
      ),
      message: Column(
        children: [
          if (email.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.mail, size: 16, color: IOSTheme.systemGray),
                const SizedBox(width: 4),
                Text(email, style: IOSTheme.footnote),
              ],
            ),
          ],
          if (phone != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.phone, size: 16, color: IOSTheme.systemGray),
                const SizedBox(width: 4),
                Text(phone, style: IOSTheme.footnote),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getStatusLabel(status),
              style: IOSTheme.caption1.copyWith(
                color: _getStatusColor(status),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.of(context).pop();
            _contactPartner(partner);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.chat_bubble, color: IOSTheme.primaryBlue),
              const SizedBox(width: 8),
              Text('Envoyer un message'),
            ],
          ),
        ),
        if (phone != null)
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implémenter l'appel téléphonique
              _showError('Fonctionnalité d\'appel en cours de développement');
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.phone, color: IOSTheme.primaryBlue),
                const SizedBox(width: 8),
                Text('Appeler'),
              ],
            ),
          ),
        if (email.isNotEmpty)
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implémenter l'envoi d'email
              _showError('Fonctionnalité d\'email en cours de développement');
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.mail, color: IOSTheme.primaryBlue),
                const SizedBox(width: 8),
                Text('Envoyer un email'),
              ],
            ),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Fermer'),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'actif':
      case 'active':
        return IOSTheme.successColor;
      case 'inactif':
      case 'inactive':
        return IOSTheme.warningColor;
      case 'suspendu':
      case 'suspended':
        return IOSTheme.errorColor;
      default:
        return IOSTheme.systemGray;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'actif':
      case 'active':
        return 'Actif';
      case 'inactif':
      case 'inactive':
        return 'Inactif';
      case 'suspendu':
      case 'suspended':
        return 'Suspendu';
      default:
        return 'Inconnu';
    }
  }
} 
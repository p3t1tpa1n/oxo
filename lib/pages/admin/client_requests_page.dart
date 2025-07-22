import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:html' as html if (dart.library.html) '';
import 'dart:io' if (dart.library.io) '';
import 'package:path_provider/path_provider.dart' if (dart.library.io) '';
import '../../models/user_role.dart';
import '../../services/supabase_service.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/side_menu.dart';
import '../../widgets/messaging_button.dart';

class ClientRequestsPage extends StatefulWidget {
  const ClientRequestsPage({super.key});

  @override
  State<ClientRequestsPage> createState() => _ClientRequestsPageState();
}

class _ClientRequestsPageState extends State<ClientRequestsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _projectProposals = [];
  List<Map<String, dynamic>> _timeExtensions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final proposals = await SupabaseService.getProjectProposals();
      final extensions = await SupabaseService.getTimeExtensionRequests();

      if (mounted) {
        setState(() {
          _projectProposals = proposals;
          _timeExtensions = extensions;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des demandes: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des demandes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 1000,
            minHeight: 800,
          ),
          child: Column(
            children: [
              SizedBox(
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(child: TopBar(title: 'Gestion des demandes client')),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (screenWidth > 700) 
                      SideMenu(
                        userRole: UserRole.associe,
                        selectedRoute: '/admin/client-requests',
                      ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _buildTabContent(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: const MessagingFloatingButton(),
    );
  }

  Widget _buildTabContent() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF1E3D54),
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: const Color(0xFF1E3D54),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.business_center, size: 20),
                    const SizedBox(width: 8),
                    Text('Propositions de projets (${_projectProposals.where((p) => p['status'] == 'pending').length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time, size: 20),
                    const SizedBox(width: 8),
                    Text('Demandes d\'extension (${_timeExtensions.where((e) => e['status'] == 'pending').length})'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProjectProposalsTab(),
              _buildTimeExtensionsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProjectProposalsTab() {
    final pendingProposals = _projectProposals.where((p) => p['status'] == 'pending').toList();
    final otherProposals = _projectProposals.where((p) => p['status'] != 'pending').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pendingProposals.isNotEmpty) ...[
            const Text(
              'Propositions en attente',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3D54),
              ),
            ),
            const SizedBox(height: 16),
            ...pendingProposals.map((proposal) => _buildProposalCard(proposal, true)),
            const SizedBox(height: 32),
          ],
          
          if (otherProposals.isNotEmpty) ...[
            const Text(
              'Propositions traitées',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3D54),
              ),
            ),
            const SizedBox(height: 16),
            ...otherProposals.map((proposal) => _buildProposalCard(proposal, false)),
          ],
          
          if (_projectProposals.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: Text(
                  'Aucune proposition de projet reçue',
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeExtensionsTab() {
    final pendingExtensions = _timeExtensions.where((e) => e['status'] == 'pending').toList();
    final otherExtensions = _timeExtensions.where((e) => e['status'] != 'pending').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pendingExtensions.isNotEmpty) ...[
            const Text(
              'Demandes en attente',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3D54),
              ),
            ),
            const SizedBox(height: 16),
            ...pendingExtensions.map((extension) => _buildExtensionCard(extension, true)),
            const SizedBox(height: 32),
          ],
          
          if (otherExtensions.isNotEmpty) ...[
            const Text(
              'Demandes traitées',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3D54),
              ),
            ),
            const SizedBox(height: 16),
            ...otherExtensions.map((extension) => _buildExtensionCard(extension, false)),
          ],
          
          if (_timeExtensions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: Text(
                  'Aucune demande d\'extension reçue',
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProposalCard(Map<String, dynamic> proposal, bool isPending) {
    final createdAt = DateTime.parse(proposal['created_at']);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    proposal['title'] ?? 'Proposition sans titre',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3D54),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(proposal['status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _getStatusColor(proposal['status']).withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    _formatStatus(proposal['status']),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(proposal['status']),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              proposal['description'] ?? 'Aucune description',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (proposal['estimated_budget'] != null) ...[
                  const Icon(Icons.euro, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    '${proposal['estimated_budget']}€',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                if (proposal['estimated_days'] != null) ...[
                  const Icon(Icons.access_time, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    '${proposal['estimated_days']}j',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy à HH:mm').format(createdAt),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            if (proposal['response_message'] != null && proposal['response_message'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Réponse:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      proposal['response_message'],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
            // Section documents
            const SizedBox(height: 16),
            _buildDocumentsSection(proposal['id']),
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleProposalAction(proposal, 'approved'),
                      icon: const Icon(Icons.check),
                      label: const Text('Approuver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleProposalAction(proposal, 'rejected'),
                      icon: const Icon(Icons.close),
                      label: const Text('Rejeter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExtensionCard(Map<String, dynamic> extension, bool isPending) {
    final createdAt = DateTime.parse(extension['created_at']);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Demande d\'extension - Projet ${extension['project_id']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3D54),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(extension['status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _getStatusColor(extension['status']).withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    _formatStatus(extension['status']),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(extension['status']),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
                          Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    '${extension['days_requested']}j supplémentaires demandés',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Text(
              'Justification:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              extension['reason'] ?? 'Aucune justification',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy à HH:mm').format(createdAt),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            if (extension['response_message'] != null && extension['response_message'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Réponse:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      extension['response_message'],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleExtensionAction(extension, 'approved'),
                      icon: const Icon(Icons.check),
                      label: const Text('Approuver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleExtensionAction(extension, 'rejected'),
                      icon: const Icon(Icons.close),
                      label: const Text('Rejeter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleProposalAction(Map<String, dynamic> proposal, String action) {
    final TextEditingController messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(action == 'approved' ? 'Approuver la proposition' : 'Rejeter la proposition'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Proposition: ${proposal['title']}'),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message de réponse (optionnel)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _updateProposalStatus(proposal['id'], action, messageController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: action == 'approved' ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(action == 'approved' ? 'Approuver' : 'Rejeter'),
            ),
          ],
        );
      },
    );
  }

  void _handleExtensionAction(Map<String, dynamic> extension, String action) {
    final TextEditingController messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(action == 'approved' ? 'Approuver l\'extension' : 'Rejeter l\'extension'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${extension['days_requested']}j supplémentaires demandés'),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message de réponse (optionnel)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _updateExtensionStatus(extension['id'], action, messageController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: action == 'approved' ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(action == 'approved' ? 'Approuver' : 'Rejeter'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDocumentsSection(String proposalId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SupabaseService.getProposalDocuments(proposalId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 40,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Erreur lors du chargement des documents: ${snapshot.error}',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          );
        }

        final documents = snapshot.data ?? [];

        if (documents.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Row(
              children: [
                Icon(Icons.description_outlined, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Aucun document joint',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.attach_file, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    '${documents.length} document(s) joint(s)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...documents.map((doc) => _buildDocumentItem(doc)).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocumentItem(Map<String, dynamic> document) {
    final fileName = document['file_name'] ?? 'Document';
    final fileSize = document['file_size'] ?? 0;
    final filePath = document['file_path'] ?? '';
    
    // Formater la taille du fichier
    String formatFileSize(int bytes) {
      if (bytes < 1024) return '${bytes}B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(
            _getFileIcon(fileName),
            size: 20,
            color: Colors.blue[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  formatFileSize(fileSize),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _downloadDocument(fileName, filePath),
            icon: const Icon(Icons.download, size: 18),
            tooltip: 'Télécharger',
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _downloadDocument(String fileName, String filePath) async {
    try {
      // Afficher un indicateur de chargement
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text('Téléchargement de $fileName...'),
            ],
          ),
          duration: const Duration(seconds: 5),
        ),
      );

      // Télécharger le fichier depuis Supabase
      final fileBytes = await SupabaseService.downloadDocument(filePath);
      
      if (fileBytes != null) {
        // Sauvegarder selon la plateforme
        await _saveFileToDevice(fileName, fileBytes);
        
        // Masquer le SnackBar précédent et afficher le succès
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$fileName téléchargé avec succès!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception('Impossible de télécharger le fichier');
      }
    } catch (e) {
      // Masquer le SnackBar de chargement et afficher l'erreur
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du téléchargement: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _saveFileToDevice(String fileName, Uint8List fileBytes) async {
    try {
      if (kIsWeb) {
        _downloadForWeb(fileName, fileBytes);
      } else {
        // Sauvegarder sur mobile/desktop
        await _downloadForMobile(fileName, fileBytes);
      }
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde: $e');
      rethrow;
    }
  }

  void _downloadForWeb(String fileName, Uint8List fileBytes) {
    if (kIsWeb) {
      try {
        // Créer un Blob avec les données du fichier
        final mimeType = _getMimeType(fileName);
        final blob = html.Blob([fileBytes], mimeType);
        
        // Créer une URL temporaire pour le Blob
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        // Créer un élément <a> pour forcer le téléchargement
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..style.display = 'none';
        
        // Ajouter au DOM, cliquer pour déclencher le téléchargement, puis nettoyer
        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);
        
        // Libérer l'URL temporaire
        html.Url.revokeObjectUrl(url);
        
        debugPrint('✅ Téléchargement web déclenché: $fileName');
        
        // Message de confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📥 $fileName téléchargé dans votre dossier Téléchargements'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
      } catch (e) {
        debugPrint('❌ Erreur téléchargement web: $e');
        _showWebDownloadDialog(fileName, fileBytes);
      }
    }
  }

  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  void _showWebDownloadDialog(String fileName, Uint8List fileBytes) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Téléchargement alternatif'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Le téléchargement automatique a échoué pour "$fileName".'),
              const SizedBox(height: 12),
              Text(
                'Taille: ${(fileBytes.length / 1024).toStringAsFixed(1)} KB',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                'Solutions alternatives:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Vérifiez que les pop-ups ne sont pas bloquées'),
              const Text('• Essayez avec un autre navigateur'),
              const Text('• Contactez le support si le problème persiste'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _saveWebFileAlternative(fileName, fileBytes);
              },
              child: const Text('Réessayer'),
            ),
          ],
        );
      },
    );
  }

  void _saveWebFileAlternative(String fileName, Uint8List fileBytes) {
    try {
      // Méthode alternative: créer un lien de données et l'ouvrir dans un nouvel onglet
      final base64String = base64Encode(fileBytes);
      final mimeType = _getMimeType(fileName);
      final dataUrl = 'data:$mimeType;base64,$base64String';
      
      // Ouvrir dans un nouvel onglet
      html.window.open(dataUrl, '_blank');
      
      final sizeKB = (fileBytes.length / 1024).toStringAsFixed(1);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📂 $fileName ouvert dans un nouvel onglet'),
              Text(
                'Taille: $sizeKB KB - Clic droit > "Enregistrer sous..." pour télécharger',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Compris',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Erreur téléchargement alternatif: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Impossible de télécharger le fichier. Contactez le support.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _downloadForMobile(String fileName, Uint8List fileBytes) async {
    if (!kIsWeb) {
      try {
        // Pour mobile/desktop, sauvegarder dans le dossier Documents
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        
        await file.writeAsBytes(fileBytes);
        
        debugPrint('✅ Fichier sauvegardé: ${file.path}');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📥 $fileName téléchargé avec succès'),
                Text(
                  'Emplacement: ${file.path}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      } catch (e) {
        debugPrint('❌ Erreur téléchargement mobile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors du téléchargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateProposalStatus(String proposalId, String status, String message) async {
    try {
      bool success = false;
      
      if (status == 'approved') {
        final projectId = await SupabaseService.approveProjectProposal(
          proposalId: proposalId,
          responseMessage: message.isNotEmpty ? message : null,
        );
        success = projectId != null;
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Proposition approuvée et projet créé avec succès ! ID: $projectId'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        success = await SupabaseService.rejectProjectProposal(
          proposalId: proposalId,
          responseMessage: message.isNotEmpty ? message : null,
        );
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Proposition rejetée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (success) {
        _loadData(); // Recharger les données
      } else {
        throw Exception('Échec de la mise à jour');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateExtensionStatus(String extensionId, String status, String message) async {
    try {
      bool success = false;
      
      if (status == 'approved') {
        success = await SupabaseService.approveTimeExtensionRequest(
          requestId: extensionId,
          responseMessage: message.isNotEmpty ? message : null,
        );
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Extension approuvée et temps ajouté au projet avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        success = await SupabaseService.rejectTimeExtensionRequest(
          requestId: extensionId,
          responseMessage: message.isNotEmpty ? message : null,
        );
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Demande d\'extension rejetée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (success) {
        _loadData(); // Recharger les données
      } else {
        throw Exception('Échec de la mise à jour');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'in_review':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String? status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'approved':
        return 'Approuvé';
      case 'rejected':
        return 'Rejeté';
      case 'in_review':
        return 'En révision';
      default:
        return 'Inconnu';
    }
  }
} 
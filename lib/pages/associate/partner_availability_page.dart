import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class PartnerAvailabilityPage extends StatefulWidget {
  final Map<String, dynamic> partner;

  const PartnerAvailabilityPage({
    super.key,
    required this.partner,
  });

  @override
  State<PartnerAvailabilityPage> createState() => _PartnerAvailabilityPageState();
}

class _PartnerAvailabilityPageState extends State<PartnerAvailabilityPage> {
  List<Map<String, dynamic>> _availability = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  String _selectedView = 'week'; // 'week' ou 'month'

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final availability = await SupabaseService.getPartnerAvailability(
        widget.partner['user_id'],
        _selectedDate,
        _selectedView,
      );
      
      setState(() {
        _availability = availability;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Disponibilités - ${widget.partner['first_name']} ${widget.partner['last_name']}'),
        backgroundColor: const Color(0xFF1E3D54),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailability,
          ),
        ],
      ),
      body: Column(
        children: [
          // Contrôles de navigation
          _buildControls(),
          
          // Contenu principal
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _availability.isEmpty
                    ? _buildEmptyState()
                    : _buildAvailabilityContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          // Sélecteur de vue
          Row(
            children: [
              const Text(
                'Vue:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'week',
                      label: Text('Semaine'),
                      icon: Icon(Icons.view_week),
                    ),
                    ButtonSegment(
                      value: 'month',
                      label: Text('Mois'),
                      icon: Icon(Icons.calendar_month),
                    ),
                  ],
                  selected: {_selectedView},
                  onSelectionChanged: (Set<String> selection) {
                    setState(() {
                      _selectedView = selection.first;
                    });
                    _loadAvailability();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Navigation par date
          Row(
            children: [
              IconButton(
                onPressed: _previousPeriod,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  _getPeriodTitle(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: _nextPeriod,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune disponibilité renseignée',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ce partenaire n\'a pas encore renseigné ses disponibilités',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _sendAvailabilityRequest,
            icon: const Icon(Icons.send),
            label: const Text('Demander les disponibilités'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3D54),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityContent() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availability.length,
      itemBuilder: (context, index) {
        final slot = _availability[index];
        return _buildAvailabilitySlot(slot);
      },
    );
  }

  Widget _buildAvailabilitySlot(Map<String, dynamic> slot) {
    final startTime = DateTime.parse(slot['start_time']);
    final endTime = DateTime.parse(slot['end_time']);
    final isAvailable = slot['is_available'] == true;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Indicateur de statut
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isAvailable ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            
            // Informations de la plage horaire
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${startTime.day}/${startTime.month}/${startTime.year}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  if (slot['notes'] != null && slot['notes'].isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      slot['notes'],
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Badge de statut
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isAvailable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAvailable ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Text(
                isAvailable ? 'Disponible' : 'Indisponible',
                style: TextStyle(
                  color: isAvailable ? Colors.green[700] : Colors.red[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPeriodTitle() {
    if (_selectedView == 'week') {
      final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return '${startOfWeek.day}/${startOfWeek.month} - ${endOfWeek.day}/${endOfWeek.month}/${endOfWeek.year}';
    } else {
      return '${_selectedDate.month}/${_selectedDate.year}';
    }
  }

  void _previousPeriod() {
    setState(() {
      if (_selectedView == 'week') {
        _selectedDate = _selectedDate.subtract(const Duration(days: 7));
      } else {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, _selectedDate.day);
      }
    });
    _loadAvailability();
  }

  void _nextPeriod() {
    setState(() {
      if (_selectedView == 'week') {
        _selectedDate = _selectedDate.add(const Duration(days: 7));
      } else {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, _selectedDate.day);
      }
    });
    _loadAvailability();
  }

  Future<void> _sendAvailabilityRequest() async {
    try {
      await SupabaseService.sendNotificationToPartner(
        widget.partner['user_id'],
        'Demande de disponibilités',
        'Veuillez mettre à jour vos disponibilités pour les prochaines semaines.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande envoyée au partenaire'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

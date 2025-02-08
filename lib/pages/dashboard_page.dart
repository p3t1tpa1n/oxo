import 'package:flutter/material.dart';
import '../widgets/top_bar.dart';
import '../widgets/side_menu.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/calendar_widget.dart';
import 'calendar_page.dart'; // Page du calendrier en grand
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    // Définition dynamique des colonnes : 1 seule colonne si trop petit
    int crossAxisCount = screenWidth < 500 ? 1 : 2;

    return Scaffold(
      backgroundColor: const Color(0xFF1784af),
      body: SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 1200,  // Largeur minimum augmentée
            minHeight: 800, // Hauteur minimum augmentée
          ),
          child: Column(
            children: [
              // TopBar + Menu Déroulant si l'écran est trop petit
              SizedBox(
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(child: TopBar()),
                    if (screenWidth < 700) 
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: _buildDropdownMenu(),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (screenWidth > 700) const SideMenu(), // ✅ Cache le menu latéral si écran trop petit
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final availableHeight = constraints.maxHeight;
                            final cardHeight = availableHeight * 0.45; // 45% de la hauteur disponible
                            
                            return Column(
                              children: [
                                if (crossAxisCount > 1)
                                  SizedBox(
                                    height: cardHeight,
                                    child: Card(
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          color: Colors.white,
                                          border: Border.all(color: const Color(0xFF1784af), width: 2),
                                        ),
                                        width: double.infinity,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.check_circle_outline,
                                              size: 40,
                                              color: Color(0xFF1784af),
                                            ),
                                            const SizedBox(height: 8),
                                            if (screenWidth > 600)
                                              const Text(
                                                'Tâches',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF122b35),
                                                ),
                                              ),
                                            if (screenWidth > 700)
                                              const Text(
                                                'Vos tâches assignées',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF122b35),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Expanded(
                                        flex: 3, // 75% de l'espace pour les calendriers
                                        child: GridView.custom(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: crossAxisCount,
                                            mainAxisSpacing: 16,
                                            crossAxisSpacing: 16,
                                            childAspectRatio: (constraints.maxWidth / crossAxisCount) / ((constraints.maxHeight * 0.75) / 2),
                                          ),
                                          childrenDelegate: SliverChildListDelegate([
                                            // Planning Global détaillé
                                            Card(
                                              elevation: 4,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(16),
                                                  color: Colors.white,
                                                  border: Border.all(color: const Color(0xFF1784af), width: 2),
                                                ),
                                                child: CalendarWidget(
                                                  showTitle: true,
                                                  title: 'Planning Global',
                                                  onDaySelected: (date) {
                                                    debugPrint('Jour sélectionné: ${date.toString()}');
                                                  },
                                                  isExpanded: false,
                                                  onExpandToggle: null,
                                                ),
                                              ),
                                            ),
                                            // Planning Personnel
                                            Card(
                                              elevation: 4,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(16),
                                                  color: Colors.white,
                                                  border: Border.all(color: const Color(0xFF1784af), width: 2),
                                                ),
                                                child: CalendarWidget(
                                                  showTitle: true,
                                                  title: 'Timesheet Personnel',
                                                  onDaySelected: (date) {
                                                    // Afficher une boîte de dialogue pour saisir les heures
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) {
                                                        TimeOfDay startTime = TimeOfDay.now();
                                                        TimeOfDay endTime = TimeOfDay.now();
                                                        
                                                        return StatefulBuilder(
                                                          builder: (context, setState) => AlertDialog(
                                                            title: Text('Saisie des heures - ${DateFormat('dd/MM/yyyy').format(date)}'),
                                                            content: SingleChildScrollView(
                                                              child: Column(
                                                                mainAxisSize: MainAxisSize.min,
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  // Projet
                                                                  DropdownButtonFormField<String>(
                                                                    decoration: const InputDecoration(
                                                                      labelText: 'Projet',
                                                                      border: OutlineInputBorder(),
                                                                    ),
                                                                    items: const [
                                                                      DropdownMenuItem(value: 'projet1', child: Text('Projet 1')),
                                                                      DropdownMenuItem(value: 'projet2', child: Text('Projet 2')),
                                                                      DropdownMenuItem(value: 'projet3', child: Text('Projet 3')),
                                                                    ],
                                                                    onChanged: (value) {},
                                                                  ),
                                                                  const SizedBox(height: 16),
                                                                  
                                                                  // Tâche
                                                                  DropdownButtonFormField<String>(
                                                                    decoration: const InputDecoration(
                                                                      labelText: 'Tâche',
                                                                      border: OutlineInputBorder(),
                                                                    ),
                                                                    items: const [
                                                                      DropdownMenuItem(value: 'tache1', child: Text('Développement')),
                                                                      DropdownMenuItem(value: 'tache2', child: Text('Design')),
                                                                      DropdownMenuItem(value: 'tache3', child: Text('Tests')),
                                                                      DropdownMenuItem(value: 'tache4', child: Text('Documentation')),
                                                                    ],
                                                                    onChanged: (value) {},
                                                                  ),
                                                                  const SizedBox(height: 16),
                                                                  
                                                                  // Heures de début et fin
                                                                  Row(
                                                                    children: [
                                                                      Expanded(
                                                                        child: InkWell(
                                                                          onTap: () async {
                                                                            final TimeOfDay? picked = await showTimePicker(
                                                                              context: context,
                                                                              initialTime: startTime,
                                                                            );
                                                                            if (picked != null) {
                                                                              setState(() => startTime = picked);
                                                                            }
                                                                          },
                                                                          child: InputDecorator(
                                                                            decoration: const InputDecoration(
                                                                              labelText: 'Début',
                                                                              border: OutlineInputBorder(),
                                                                            ),
                                                                            child: Text(startTime.format(context)),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      const SizedBox(width: 16),
                                                                      Expanded(
                                                                        child: InkWell(
                                                                          onTap: () async {
                                                                            final TimeOfDay? picked = await showTimePicker(
                                                                              context: context,
                                                                              initialTime: endTime,
                                                                            );
                                                                            if (picked != null) {
                                                                              setState(() => endTime = picked);
                                                                            }
                                                                          },
                                                                          child: InputDecorator(
                                                                            decoration: const InputDecoration(
                                                                              labelText: 'Fin',
                                                                              border: OutlineInputBorder(),
                                                                            ),
                                                                            child: Text(endTime.format(context)),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  const SizedBox(height: 16),
                                                                  
                                                                  // Description
                                                                  const TextField(
                                                                    decoration: InputDecoration(
                                                                      labelText: 'Description',
                                                                      hintText: 'Description de l\'activité',
                                                                      border: OutlineInputBorder(),
                                                                    ),
                                                                    maxLines: 3,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () => Navigator.pop(context),
                                                                child: const Text('Annuler'),
                                                              ),
                                                              ElevatedButton(
                                                                onPressed: () {
                                                                  // TODO: Sauvegarder les données
                                                                  Navigator.pop(context);
                                                                },
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor: const Color(0xFF1784af),
                                                                ),
                                                                child: const Text(
                                                                  'Enregistrer',
                                                                  style: TextStyle(color: Colors.white),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  },
                                                  isTimesheet: true,
                                                ),
                                              ),
                                            ),
                                          ]),
                                        ),
                                      ),
                                      if (constraints.maxHeight > 600) // On affiche les événements seulement si l'écran est assez grand
                                        Expanded(
                                          flex: 1, // 25% de l'espace pour les événements
                                          child: Padding(
                                            padding: const EdgeInsets.only(top: 16),
                                            child: Row(
                                              children: [
                                                // Section événements Planning Global
                                                Expanded(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(16),
                                                      border: Border.all(color: const Color(0xFF1784af), width: 2),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.all(8),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF1784af).withOpacity(0.1),
                                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              SizedBox(
                                                                width: 14,
                                                                height: 14,
                                                                child: Icon(Icons.event, size: 12, color: Color(0xFF1784af)),
                                                              ),
                                                              const SizedBox(width: 4),
                                                              Expanded(
                                                                child: Text(
                                                                  'Événements Planning Global',
                                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                                    fontSize: 10,
                                                                    fontWeight: FontWeight.w600,
                                                                    color: const Color(0xFF122b35),
                                                                  ),
                                                                  overflow: TextOverflow.ellipsis,
                                                                  maxLines: 1,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: ListView(
                                                            padding: const EdgeInsets.all(8),
                                                            children: const [
                                                              Text(
                                                                'Aucun événement',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: Color(0xFF666666),
                                                                  fontStyle: FontStyle.italic,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                // Section événements Planning Personnel
                                                Expanded(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(16),
                                                      border: Border.all(color: const Color(0xFF1784af), width: 2),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.all(8),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF1784af).withOpacity(0.1),
                                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              SizedBox(
                                                                width: 14,
                                                                height: 14,
                                                                child: Icon(Icons.event, size: 12, color: Color(0xFF1784af)),
                                                              ),
                                                              const SizedBox(width: 4),
                                                              Expanded(
                                                                child: Text(
                                                                  'Événements Planning Personnel',
                                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                                    fontSize: 10,
                                                                    fontWeight: FontWeight.w600,
                                                                    color: const Color(0xFF122b35),
                                                                  ),
                                                                  overflow: TextOverflow.ellipsis,
                                                                  maxLines: 1,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: ListView(
                                                            padding: const EdgeInsets.all(8),
                                                            children: const [
                                                              Text(
                                                                'Aucun événement',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: Color(0xFF666666),
                                                                  fontStyle: FontStyle.italic,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Menu Déroulant en haut pour petit écran
  Widget _buildDropdownMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu, color: Colors.white), // ✅ Icône du menu
      onSelected: (String route) {
        Navigator.pushNamed(context, route);
      },
      itemBuilder: (BuildContext context) {
        return [
          _buildMenuItem('Fiche Associé', '/associate'),
          _buildMenuItem('Planning Global', '/planning'),
          _buildMenuItem('Partenaires', '/partners'),
          _buildMenuItem('Messagerie', '/messaging'),
          _buildMenuItem('Actions Commerciales', '/actions'),
          _buildMenuItem('Chiffres Entreprise', '/figures'),
        ];
      },
    );
  }

  // ✅ Fonction pour générer un élément du menu déroulant
  PopupMenuItem<String> _buildMenuItem(String title, String route) {
    return PopupMenuItem<String>(
      value: route,
      child: Text(title, style: const TextStyle(color: Color(0xFF122b35))),
    );
  }
}

// ✅ Mini-planning corrigé pour éviter l'overflow
class CalendarMiniWidget extends StatefulWidget {
  final bool showText;
  const CalendarMiniWidget({super.key, required this.showText});

  @override
  CalendarMiniWidgetState createState() => CalendarMiniWidgetState();
}

class CalendarMiniWidgetState extends State<CalendarMiniWidget> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  final List<String> months = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    maxWidth: 36,
                  ),
                  icon: const Icon(Icons.calendar_month, color: Color(0xFF122b35), size: 20),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CalendarPage()),
                    );
                  },
                ),
                if (widget.showText)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text(
                      "Planning",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF122b35),
                      ),
                    ),
                  ),
              ],
            ),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isDense: true,
                    isExpanded: true,
                    value: months[(selectedMonth - 1).clamp(0, 11)],
                    onChanged: (String? newValue) {
                      if (newValue != null && mounted) {
                        setState(() {
                          selectedMonth = months.indexOf(newValue) + 1;
                        });
                      }
                    },
                    dropdownColor: Colors.white,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                    items: months.map((String month) {
                      return DropdownMenuItem<String>(
                        value: month,
                        child: Text(month),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: index % 7 == 0 ? Colors.grey.shade200 : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Center(
                  child: Text(
                    "${index + 1}",
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
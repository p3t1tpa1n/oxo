import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/side_menu.dart';
import '../../widgets/calendar_widget.dart';
import '../../widgets/messaging_button.dart';
import '../shared/calendar_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _loadEvents();
  }

  Future<void> _loadTasks() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await SupabaseService.fetchTasks();
      
      if (mounted) {
        setState(() {
          _tasks = response.map((task) => task).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des tâches: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadEvents() async {
    // Cette méthode charge les événements du calendrier
    // Pour l'instant, elle est vide car nous n'avons pas encore implémenté le calendrier
    debugPrint('Chargement des événements du calendrier...');
    // Implémentation à venir
  }

  Future<void> _updateTaskStatus(Map<String, dynamic> taskData, String newStatus) async {
    if (!mounted) return;
    final localContext = context;
    try {
      await SupabaseService.client
          .from('tasks')
          .update({
            'status': newStatus,
          })
          .eq('id', taskData['id']);
      
      await _loadTasks();
      if (mounted) {
        ScaffoldMessenger.of(localContext).showSnackBar(
          const SnackBar(content: Text('Statut mis à jour avec succès')),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du statut: $e');
      if (mounted) {
        ScaffoldMessenger.of(localContext).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showAddTaskDialog() async {
    if (!mounted) return;
    final dialogContext = context;
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final dueDateController = TextEditingController();
    final projectNameController = TextEditingController();
    final projectDescriptionController = TextEditingController();
    DateTime? selectedDate;
    String? selectedProject;
    String? selectedPartnerId;
    bool isCreatingNewProject = false;

    try {
      await showDialog(
        context: dialogContext,
        builder: (BuildContext context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Nouvelle tâche'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FutureBuilder<List<dynamic>>(
                          future: SupabaseService.client
                            .from('projects')
                            .select()
                            .order('name'),
                          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }

                            if (snapshot.hasError) {
                              return Text('Erreur: ${snapshot.error}');
                            }

                            final projects = List<Map<String, dynamic>>.from(snapshot.data ?? []);

                            return DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Projet',
                                border: OutlineInputBorder(),
                              ),
                              value: selectedProject,
                              items: projects.map((project) => DropdownMenuItem<String>(
                                value: project['id'].toString(),
                                child: Text(project['name'] as String),
                              )).toList(),
                              onChanged: isCreatingNewProject ? null : (String? value) {
                                setState(() {
                                  selectedProject = value;
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          isCreatingNewProject ? Icons.close : Icons.add_circle,
                          color: const Color(0xFF1784af),
                        ),
                        onPressed: () {
                          setState(() {
                            isCreatingNewProject = !isCreatingNewProject;
                            if (!isCreatingNewProject) {
                              projectNameController.clear();
                              projectDescriptionController.clear();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  if (isCreatingNewProject) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: projectNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du projet',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: projectDescriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description du projet',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titre de la tâche',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description de la tâche',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          selectedDate = date;
                          dueDateController.text = DateFormat('dd/MM/yyyy').format(date);
                        });
                      }
                    },
                    child: IgnorePointer(
                      child: TextField(
                        controller: dueDateController,
                        decoration: const InputDecoration(
                          labelText: 'Date d\'échéance',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: SupabaseService.getPartners(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      
                      if (snapshot.hasError) {
                        return Text('Erreur: ${snapshot.error}');
                      }
                      
                      final partners = snapshot.data ?? [];
                      
                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Attribuer à un partenaire',
                          border: OutlineInputBorder(),
                          helperText: 'Facultatif - Laissez vide pour attribution automatique',
                        ),
                        value: selectedPartnerId,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Attribution automatique'),
                          ),
                          ...partners.map((partner) => DropdownMenuItem<String>(
                            value: partner['user_id'],
                            child: Text(partner['user_email'] ?? 'Partenaire sans email'),
                          )).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedPartnerId = value;
                          });
                        },
                      );
                    },
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
                onPressed: () async {
                  if (titleController.text.isEmpty || selectedDate == null || 
                      (isCreatingNewProject && projectNameController.text.isEmpty) ||
                      (!isCreatingNewProject && selectedProject == null)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
                    );
                    return;
                  }

                  try {
                    dynamic projectId;
                    if (isCreatingNewProject) {
                      final projectResponse = await SupabaseService.client
                          .from('projects')
                          .insert({
                            'name': projectNameController.text,
                            'description': projectDescriptionController.text,
                            'status': 'active',
                            'start_date': DateTime.now().toIso8601String(),
                            'end_date': selectedDate!.toIso8601String(),
                            'created_at': DateTime.now().toIso8601String(),
                            'updated_at': DateTime.now().toIso8601String(),
                          })
                          .select()
                          .single();
                      projectId = projectResponse['id'];
                    } else {
                      projectId = selectedProject!;
                    }

                    await SupabaseService.client
                        .from('tasks')
                        .insert({
                          'title': titleController.text,
                          'description': descriptionController.text,
                          'due_date': selectedDate!.toIso8601String(),
                          'status': 'todo',
                          'project_id': projectId,
                          'user_id': SupabaseService.currentUser!.id,
                          'partner_id': selectedPartnerId,
                          'created_by': SupabaseService.currentUser!.id,
                          'updated_by': SupabaseService.currentUser!.id,
                        });
                    
                    if (!mounted) return;
                    Navigator.pop(context);
                    await _loadTasks();
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          isCreatingNewProject 
                            ? 'Projet et tâche créés avec succès' 
                            : 'Tâche créée avec succès'
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Erreur: ${e.toString()}')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1784af),
                ),
                child: const Text(
                  'Ajouter',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    } finally {
      titleController.dispose();
      descriptionController.dispose();
      dueDateController.dispose();
      projectNameController.dispose();
      projectDescriptionController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Menu latéral
          SideMenu(
            selectedRoute: '/dashboard',
            userRole: SupabaseService.currentUserRole,
          ),
          
          // Contenu principal
          Expanded(
            child: Column(
              children: [
                // Barre supérieure
                const TopBar(title: 'Dashboard'),
                
                // Contenu du tableau de bord
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildDashboardContent(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          MessagingFloatingButton(
            backgroundColor: const Color(0xFF1784af),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _showAddTaskDialog,
            backgroundColor: const Color(0xFF1784af),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth < 500 ? 1 : 2;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec stats
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTasksSection(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Calendriers
          LayoutBuilder(
            builder: (context, constraints) {
              return _buildCalendarsSection(constraints, crossAxisCount);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTasksSection() {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          border: Border.all(color: const Color(0xFF1784af), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tâches',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF122b35),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Color(0xFF1784af)),
                  onPressed: _showAddTaskDialog,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colonne "À faire"
                Expanded(
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.assignment_outlined,
                                    size: 20,
                                    color: Color(0xFF1784af),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'À faire',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1784af),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _tasks.where((task) => task['status'] == 'todo').length.toString(),
                                  style: const TextStyle(
                                    color: Color(0xFF1784af),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: DragTarget<Map<String, dynamic>>(
                            onWillAcceptWithDetails: (details) => true,
                            onAcceptWithDetails: (details) {
                              _updateTaskStatus(details.data, 'todo');
                            },
                            builder: (context, candidateData, rejectedData) {
                              return ListView(
                                children: _tasks
                                  .where((task) => task['status'] == 'todo')
                                  .map((task) => Column(
                                    children: [
                                      _buildTaskCard(
                                        task['title'],
                                        task['description'],
                                        DateTime.parse(task['due_date']),
                                        isDone: task['isDone'] ?? false,
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ))
                                  .toList(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Colonne "En cours"
                Expanded(
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.pending_actions,
                                    size: 20,
                                    color: Color(0xFFFF9800),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'En cours',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFF9800),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: DragTarget<Map<String, dynamic>>(
                            onWillAcceptWithDetails: (details) => true,
                            onAcceptWithDetails: (details) {
                              _updateTaskStatus(details.data, 'in_progress');
                            },
                            builder: (context, candidateData, rejectedData) {
                              return ListView(
                                children: _tasks
                                  .where((task) => task['status'] == 'in_progress')
                                  .map((task) => Column(
                                    children: [
                                      _buildTaskCard(
                                        task['title'],
                                        task['description'],
                                        DateTime.parse(task['due_date']),
                                        isDone: task['isDone'] ?? false,
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ))
                                  .toList(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Colonne "Fait"
                Expanded(
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.task_alt,
                                    size: 20,
                                    color: Color(0xFF4CAF50),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Fait',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4CAF50),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: DragTarget<Map<String, dynamic>>(
                            onWillAcceptWithDetails: (details) => true,
                            onAcceptWithDetails: (details) {
                              _updateTaskStatus(details.data, 'done');
                            },
                            builder: (context, candidateData, rejectedData) {
                              return ListView(
                                children: _tasks
                                  .where((task) => task['status'] == 'done')
                                  .map((task) => Column(
                                    children: [
                                      _buildTaskCard(
                                        task['title'],
                                        task['description'],
                                        DateTime.parse(task['due_date']),
                                        isDone: task['isDone'] ?? false,
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ))
                                  .toList(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarsSection(BoxConstraints constraints, int crossAxisCount) {
    // Calculer un aspect ratio fixe pour éviter les valeurs négatives ou nulles
    double width = constraints.maxWidth / crossAxisCount;
    double height = width * 0.75; // Ratio 4:3
    double aspectRatio = width / height;

    return GridView.custom(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: aspectRatio,
      ),
      childrenDelegate: SliverChildListDelegate([
        Card(
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CalendarWidget(
              showTitle: true,
              title: 'Planning Global',
              isExpanded: false,
              onExpandToggle: () {},
              isTimesheet: false,
              onDaySelected: (date) {
                debugPrint('Selected date: $date');
              },
            ),
          ),
        ),
        Card(
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CalendarWidget(
              showTitle: true,
              title: 'Timesheet Personnel',
              isExpanded: false,
              onExpandToggle: () {},
              isTimesheet: true,
              onDaySelected: (date) async {
                if (!mounted) return;
                await showDialog(
                  context: context,
                  builder: (context) => TimesheetDialog(selectedDate: date),
                );
              },
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildTaskCard(String title, String description, DateTime dueDate, {bool isDone = false}) {
    final task = _tasks.firstWhere(
      (task) => task['title'] == title && 
                task['description'] == description && 
                DateTime.parse(task['due_date']).isAtSameMomentAs(dueDate),
    );

    return Draggable<Map<String, dynamic>>(
      data: task,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildTaskCardContent(title, description, dueDate, isDone: isDone),
      ),
      child: _buildTaskCardContent(title, description, dueDate, isDone: isDone),
    );
  }

  Widget _buildTaskCardContent(String title, String description, DateTime dueDate, {bool isDone = false}) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDone ? const Color(0xFF4CAF50) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? const Color(0xFF4CAF50) : Colors.grey[300],
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormat('dd/MM/yyyy').format(dueDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Menu Déroulant en haut pour petit écran
  Widget _buildDropdownMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu, color: Colors.white),
      onSelected: (String route) {
        Navigator.of(context).pushNamed(route);
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
        Flexible(
          fit: FlexFit.loose,
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

class TimesheetDialog extends StatefulWidget {
  final DateTime selectedDate;

  const TimesheetDialog({
    Key? key,
    required this.selectedDate,
  }) : super(key: key);

  @override
  State<TimesheetDialog> createState() => _TimesheetDialogState();
}

class _TimesheetDialogState extends State<TimesheetDialog> {
  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay endTime = TimeOfDay.now();
  String? selectedProject;
  String? selectedTask;
  final descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: SupabaseService.client
          .from('projects')
          .select()
          .order('name'),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AlertDialog(
            content: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return AlertDialog(
            content: Center(
              child: Text('Erreur: ${snapshot.error}'),
            ),
          );
        }

        final projects = List<Map<String, dynamic>>.from(snapshot.data ?? []);

        return AlertDialog(
          title: Text('Saisie des heures - ${DateFormat('dd/MM/yyyy').format(widget.selectedDate)}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Projet',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedProject,
                  items: projects.map((project) => DropdownMenuItem<String>(
                    value: project['id'].toString(),
                    child: Text(project['name'] as String),
                  )).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      selectedProject = value;
                      selectedTask = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                if (selectedProject?.isNotEmpty == true)
                  FutureBuilder<List<dynamic>>(
                    future: SupabaseService.client
                        .from('tasks')
                        .select()
                        .eq('project_id', selectedProject!)
                        .order('title'),
                    builder: (context, AsyncSnapshot<List<dynamic>> taskSnapshot) {
                      final tasks = List<Map<String, dynamic>>.from(taskSnapshot.data ?? []);
                      
                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Tâche',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedTask,
                        items: tasks.map((task) => DropdownMenuItem<String>(
                          value: task['id'].toString(),
                          child: Text(task['title'] as String),
                        )).toList(),
                        onChanged: (String? value) {
                          setState(() => selectedTask = value);
                        },
                      );
                    },
                  ),
                const SizedBox(height: 16),
                
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
                
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
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
              onPressed: () async {
                if (selectedProject != null && selectedTask != null) {
                  final startDateTime = DateTime(
                    widget.selectedDate.year,
                    widget.selectedDate.month,
                    widget.selectedDate.day,
                    startTime.hour,
                    startTime.minute,
                  );
                  final endDateTime = DateTime(
                    widget.selectedDate.year,
                    widget.selectedDate.month,
                    widget.selectedDate.day,
                    endTime.hour,
                    endTime.minute,
                  );
                  
                  if (endDateTime.isBefore(startDateTime)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('L\'heure de fin doit être après l\'heure de début'),
                      ),
                    );
                    return;
                  }

                  final hours = endDateTime.difference(startDateTime).inMinutes / 60.0;
                  
                  if (hours <= 0 || hours > 24) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Le nombre d\'heures doit être entre 0 et 24'),
                      ),
                    );
                    return;
                  }

                  try {
                    // Gérer l'ID de tâche de manière flexible
                    dynamic taskIdValue = selectedTask!;
                    try {
                      taskIdValue = int.parse(selectedTask!);
                    } catch (e) {
                      // Si la conversion échoue, c'est probablement un UUID
                      debugPrint('Task ID est probablement un UUID: $selectedTask');
                    }

                    await SupabaseService.client
                        .from('timesheet_entries')
                        .insert({
                      'user_id': SupabaseService.currentUser!.id,
                      'task_id': taskIdValue, // Utiliser la valeur appropriée
                      'date': widget.selectedDate.toIso8601String(),
                      'hours': hours,
                      'description': descriptionController.text,
                      'status': 'pending', // Ajouter le status requis
                    });

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Heures enregistrées avec succès')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: ${e.toString()}')),
                      );
                    }
                  }
                }
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
        );
      },
    );
  }
}
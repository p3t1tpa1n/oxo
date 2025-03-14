import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../widgets/top_bar.dart';
import '../widgets/side_menu.dart';
import '../widgets/calendar_widget.dart';
import 'calendar_page.dart'; // Page du calendrier en grand

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _createTestProjectIfNeeded();
  }

  Future<void> _loadTasks() async {
    try {
      final response = await SupabaseService.client
          .from('tasks')
          .select()
          .eq('user_id', SupabaseService.currentUser!.id)
          .order('created_at', ascending: false);
      
      setState(() {
        _tasks = List<Map<String, dynamic>>.from(response.map((task) => {
          ...task,
          'isDone': task['status'] == 'done',
        }));
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des tâches: $e');
    }
  }

  Future<void> _createTestProjectIfNeeded() async {
    if (!mounted) return;
    final localContext = context;
    try {
      final projects = await SupabaseService.client
          .from('projects')
          .select()
          .limit(1);

      if (projects.isEmpty) {
        final projectResponse = await SupabaseService.client
            .from('projects')
            .insert({
              'name': 'Projet Test',
              'description': 'Un projet de test',
              'status': 'en_cours',
              'start_date': DateTime.now().toIso8601String(),
              'end_date': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();

        await SupabaseService.client
            .from('tasks')
            .insert([
              {
                'title': 'Tâche 1',
                'description': 'Description de la tâche 1',
                'status': 'todo',
                'due_date': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
                'project_id': projectResponse['id'],
                'user_id': SupabaseService.currentUser!.id,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              },
              {
                'title': 'Tâche 2',
                'description': 'Description de la tâche 2',
                'status': 'in_progress',
                'due_date': DateTime.now().add(const Duration(days: 14)).toIso8601String(),
                'project_id': projectResponse['id'],
                'user_id': SupabaseService.currentUser!.id,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              }
            ]);

        if (mounted) {
          ScaffoldMessenger.of(localContext).showSnackBar(
            const SnackBar(content: Text('Projet et tâches de test créés avec succès')),
          );
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la création des données de test: $e');
      if (mounted) {
        ScaffoldMessenger.of(localContext).showSnackBar(
          SnackBar(content: Text('Erreur lors de la création des données de test: ${e.toString()}')),
        );
      }
    }
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
    DateTime? selectedDate;
    String? selectedProject;

    try {
      await showDialog(
        context: dialogContext,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Nouvelle tâche'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FutureBuilder<List<dynamic>>(
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
                      onChanged: (String? value) {
                        selectedProject = value;
                      },
                      validator: (value) => value == null ? 'Veuillez sélectionner un projet' : null,
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titre',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
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
                      selectedDate = date;
                      dueDateController.text = DateFormat('dd/MM/yyyy').format(date);
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
                if (titleController.text.isNotEmpty && selectedDate != null && selectedProject != null) {
                  try {
                    await SupabaseService.client
                        .from('tasks')
                        .insert({
                          'title': titleController.text,
                          'description': descriptionController.text,
                          'due_date': selectedDate!.toIso8601String(),
                          'status': 'todo',
                          'project_id': int.parse(selectedProject!),
                          'user_id': SupabaseService.currentUser!.id,
                        });
                    
                    if (!mounted) return;
                    Navigator.pop(context);
                    await _loadTasks();
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Erreur: ${e.toString()}')),
                    );
                  }
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
      );
    } finally {
      titleController.dispose();
      descriptionController.dispose();
      dueDateController.dispose();
    }
  }

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
                            final cardHeight = availableHeight * 0.35; // Réduit de 0.45 à 0.35 pour le bloc de tâches
                            
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
                                            Expanded(
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Colonne "À faire"
                                                  Expanded(
                                                    child: Column(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.all(8),
                                                          decoration: const BoxDecoration(
                                                            color: Color(0xFFE3F2FD),
                                                            borderRadius: BorderRadius.all(Radius.circular(8)),
                                                          ),
                                                          child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              const Text(
                                                                'À faire',
                                                                style: TextStyle(
                                                                  fontWeight: FontWeight.bold,
                                                                  color: Color(0xFF1784af),
                                                                ),
                                                              ),
                                                              Text(
                                                                _tasks.where((task) => task['status'] == 'todo').length.toString(),
                                                                style: const TextStyle(
                                                                  color: Color(0xFF1784af),
                                                                  fontWeight: FontWeight.bold,
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
                                                                children: _tasks.where((task) => task['status'] == 'todo').map((task) => Column(
                                                                  children: [
                                                                    _buildTaskCard(
                                                                      task['title'],
                                                                      task['description'],
                                                                      DateTime.parse(task['due_date']),
                                                                      isDone: task['isDone'],
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
                                                  const SizedBox(width: 16),
                                                  // Colonne "En cours"
                                                  Expanded(
                                                    child: Column(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.all(8),
                                                          decoration: const BoxDecoration(
                                                            color: Color(0xFFFFF3E0),
                                                            borderRadius: BorderRadius.all(Radius.circular(8)),
                                                          ),
                                                          child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              const Text(
                                                                'En cours',
                                                                style: TextStyle(
                                                                  fontWeight: FontWeight.bold,
                                                                  color: Color(0xFFFF9800),
                                                                ),
                                                              ),
                                                              Text(
                                                                _tasks.where((task) => task['status'] == 'in_progress').length.toString(),
                                                                style: const TextStyle(
                                                                  color: Color(0xFFFF9800),
                                                                  fontWeight: FontWeight.bold,
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
                                                              _updateTaskStatus(details.data, 'in_progress');
                                                            },
                                                            builder: (context, candidateData, rejectedData) {
                                                              return ListView(
                                                                children: _tasks.where((task) => task['status'] == 'in_progress').map((task) => Column(
                                                                  children: [
                                                                    _buildTaskCard(
                                                                      task['title'],
                                                                      task['description'],
                                                                      DateTime.parse(task['due_date']),
                                                                      isDone: task['isDone'],
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
                                                  const SizedBox(width: 16),
                                                  // Colonne "Fait"
                                                  Expanded(
                                                    child: Column(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.all(8),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFE8F5E9),
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              const Text(
                                                                'Fait',
                                                                style: TextStyle(
                                                                  fontWeight: FontWeight.bold,
                                                                  color: Color(0xFF4CAF50),
                                                                ),
                                                              ),
                                                              Text(
                                                                _tasks.where((task) => task['status'] == 'done').length.toString(),
                                                                style: const TextStyle(
                                                                  color: Color(0xFF4CAF50),
                                                                  fontWeight: FontWeight.bold,
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
                                                              _updateTaskStatus(details.data, 'done');
                                                            },
                                                            builder: (context, candidateData, rejectedData) {
                                                              return ListView(
                                                                children: _tasks.where((task) => task['status'] == 'done').map((task) => Column(
                                                                  children: [
                                                                    _buildTaskCard(
                                                                      task['title'],
                                                                      task['description'],
                                                                      DateTime.parse(task['due_date']),
                                                                      isDone: task['isDone'],
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
                                                ],
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
                                        flex: 4,
                                        child: GridView.custom(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                                            childAspectRatio: (constraints.maxWidth / crossAxisCount) / ((constraints.maxHeight * 1.0) / 2),
                                          ),
                                          childrenDelegate: SliverChildListDelegate([
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
                                                  onExpandToggle: () {},
                                                  isTimesheet: false,
                                                ),
                                              ),
                                ),
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
                                                  onDaySelected: (date) async {
                                                    // Afficher une boîte de dialogue pour saisir les heures
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) {
                                                        TimeOfDay startTime = TimeOfDay.now();
                                                        TimeOfDay endTime = TimeOfDay.now();
                                                        String? selectedProject;
                                                        String? selectedTask;
                                                        final descriptionController = TextEditingController();

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
                                                                      
                                                                      // Tâche
                                                                      if (selectedProject?.isNotEmpty == true)
                                                                        FutureBuilder<List<dynamic>>(
                                                                          future: SupabaseService.client
                                                                              .from('tasks')
                                                                              .select()
                                                                              .eq('project_id', int.parse(selectedProject!))
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
                                                                        // Calculer le nombre d'heures
                                                                        final startDateTime = DateTime(
                                                                          date.year,
                                                                          date.month,
                                                                          date.day,
                                                                          startTime.hour,
                                                                          startTime.minute,
                                                                        );
                                                                        final endDateTime = DateTime(
                                                                          date.year,
                                                                          date.month,
                                                                          date.day,
                                                                          endTime.hour,
                                                                          endTime.minute,
                                                                        );
                                                                        
                                                                        // Vérifier que l'heure de fin est après l'heure de début
                                                                        if (endDateTime.isBefore(startDateTime)) {
                                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                                            const SnackBar(
                                                                              content: Text('L\'heure de fin doit être après l\'heure de début'),
                                                                            ),
                                                                          );
                                                                          return;
                                                                        }

                                                                        final hours = endDateTime.difference(startDateTime).inMinutes / 60.0;
                                                                        
                                                                        // Vérifier que le nombre d'heures est valide
                                                                        if (hours <= 0 || hours > 24) {
                                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                                            const SnackBar(
                                                                              content: Text('Le nombre d\'heures doit être entre 0 et 24'),
                                                                            ),
                                                                          );
                                                                          return;
                                                                        }

                                                                        try {
                                                                          await SupabaseService.client
                                                                              .from('timesheet_entries')
                                                                              .insert({
                                                                            'user_id': SupabaseService.currentUser!.id,
                                                                            'task_id': int.parse(selectedTask!),
                                                                            'date': date.toIso8601String(),
                                                                            'hours': hours,
                                                                            'description': descriptionController.text,
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
                                                              ),
                                                            );
                                                          },
                                                        );
                                                      },
                                                    );
                                                  },
                                                  isExpanded: false,
                                                  onExpandToggle: () {},
                                                  isTimesheet: true,
                                                ),
                                              ),
                                            ),
                                          ]),
                                        ),
                                      ),
                                      if (constraints.maxHeight > 600)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 16.0),
                                          child: SizedBox(
                                            height: 85,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(color: const Color(0xFF1784af), width: 2),
                                              ),
                                              child: Column(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF1784af).withValues(red: 23, green: 132, blue: 175, alpha: 25),
                                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                                    ),
                                                    child: const Row(
                                                      children: [
                                                        Icon(Icons.event, size: 16, color: Color(0xFF1784af)),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          'Événements',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            color: Color(0xFF122b35),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const Expanded(
                                  child: Padding(
                                                      padding: EdgeInsets.all(8.0),
                                                      child: Center(
                                                        child: Text(
                                                          'Aucun événement',
                                                          style: TextStyle(
                                                            color: Colors.grey,
                                                            fontStyle: FontStyle.italic,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
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

  Widget _buildTaskCard(String title, String description, DateTime dueDate, {bool isDone = false}) {
    final task = _tasks.firstWhere(
      (task) => task['title'] == title && 
                task['description'] == description && 
                DateTime.parse(task['due_date']).isAtSameMomentAs(dueDate),
      orElse: () => {
        'title': title,
        'description': description,
        'due_date': dueDate.toIso8601String(),
        'status': isDone ? 'done' : 'todo',
      },
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        padding: const EdgeInsets.all(8),
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
                      fontWeight: FontWeight.bold,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? const Color(0xFF4CAF50) : Colors.grey[300],
                  ),
                  child: Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy').format(dueDate),
                  style: TextStyle(
                    fontSize: 10,
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
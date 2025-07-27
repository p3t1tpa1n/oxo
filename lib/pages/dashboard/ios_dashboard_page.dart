import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../config/ios_theme.dart';
import '../../widgets/ios_widgets.dart';
import '../../services/supabase_service.dart';
import '../../models/user_role.dart';
import '../messaging/ios_messaging_page.dart';
import '../client/project_request_form_page.dart';
import '../admin/project_creation_form_page.dart';

class IOSDashboardPage extends StatefulWidget {
  const IOSDashboardPage({Key? key}) : super(key: key);

  @override
  State<IOSDashboardPage> createState() => _IOSDashboardPageState();
}

class _IOSDashboardPageState extends State<IOSDashboardPage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _projects = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  UserRole? _userRole;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _userRole = SupabaseService.currentUserRole;
    _tabController = TabController(length: _getTabCount(), vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _getTabCount() {
    switch (_userRole) {
      case UserRole.admin:
        return 5; // Accueil, Projets, Tâches, Gestion, Profil
      case UserRole.associe:
        return 4; // Accueil, Projets, Tâches, Profil
      case UserRole.partenaire:
        return 4; // Accueil, Mes Projets, Mes Tâches, Profil
      case UserRole.client:
        return 4; // Accueil, Mes Projets, Demandes, Profil
      default:
        return 2; // Accueil, Profil seulement
    }
  }

  List<BottomNavigationBarItem> _getTabItems() {
    switch (_userRole) {
      case UserRole.admin:
        return const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.doc_text), label: 'Projets'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.checkmark_alt_circle), label: 'Tâches'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.settings), label: 'Gestion'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person), label: 'Profil'),
        ];
      case UserRole.associe:
        return const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.doc_text), label: 'Projets'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.checkmark_alt_circle), label: 'Tâches'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person), label: 'Profil'),
        ];
      case UserRole.partenaire:
        return const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.briefcase), label: 'Mes Projets'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.list_bullet), label: 'Mes Tâches'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person), label: 'Profil'),
        ];
      case UserRole.client:
        return const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.folder), label: 'Mes Projets'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.paperplane), label: 'Demandes'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person), label: 'Profil'),
        ];
      default:
        return const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person), label: 'Profil'),
        ];
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> tasks = [];
      List<Map<String, dynamic>> projects = [];

      // Charger les données selon le rôle
      switch (_userRole) {
        case UserRole.admin:
        case UserRole.associe:
          // Admins et associés voient toutes les données de l'entreprise
          tasks = await SupabaseService.getCompanyTasks();
          projects = await SupabaseService.getProjectProposals();
          break;
          
        case UserRole.partenaire:
          // Partenaires voient seulement leurs tâches assignées
          final allTasks = await SupabaseService.getCompanyTasks();
          tasks = allTasks.where((t) => 
            t['assigned_to'] == SupabaseService.currentUser?.id ||
            t['created_by'] == SupabaseService.currentUser?.id
          ).toList();
          
          // Projets où le partenaire est impliqué
          final allProjects = await SupabaseService.getProjectProposals();
          projects = allProjects.where((p) => 
            tasks.any((t) => t['project_id'] == p['id'])
          ).toList();
          break;
          
        case UserRole.client:
          // Clients voient seulement leurs projets et tâches
          projects = await SupabaseService.getClientRecentProjects();
          tasks = await SupabaseService.getClientActiveTasks();
          break;
          
        default:
          // Rôle non reconnu - données limitées
          tasks = [];
          projects = [];
      }
      
      final completedTasks = tasks.where((t) => t['status'] == 'done').length;
      final totalTasks = tasks.length;
      final urgentTasks = tasks.where((t) => t['priority'] == 'urgent' && t['status'] != 'done').length;
      final inProgressProjects = projects.where((p) => p['status'] == 'in_progress').length;

      setState(() {
        _tasks = tasks.take(10).toList();
        _projects = projects.take(5).toList();
        _stats = {
          'total_tasks': totalTasks,
          'completed_tasks': completedTasks,
          'urgent_tasks': urgentTasks,
          'in_progress_projects': inProgressProjects,
          'completion_rate': totalTasks > 0 ? (completedTasks / totalTasks * 100).round() : 0,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      backgroundColor: IOSTheme.systemGroupedBackground,
      tabBar: CupertinoTabBar(
        backgroundColor: IOSTheme.systemBackground,
        activeColor: IOSTheme.primaryBlue,
        inactiveColor: IOSTheme.systemGray,
        items: _getTabItems(),
      ),
      tabBuilder: (context, index) {
        switch (_userRole) {
          case UserRole.admin:
            switch (index) {
              case 0: return _buildHomeTab();
              case 1: return _buildProjectsTab();
              case 2: return _buildTasksTab();
              case 3: return _buildAdminManagementTab();
              case 4: return _buildProfileTab();
              default: return _buildHomeTab();
            }
          case UserRole.associe:
            switch (index) {
              case 0: return _buildHomeTab();
              case 1: return _buildProjectsTab();
              case 2: return _buildTasksTab();
              case 3: return _buildProfileTab();
              default: return _buildHomeTab();
            }
          case UserRole.partenaire:
            switch (index) {
              case 0: return _buildPartnerHomeTab();
              case 1: return _buildPartnerProjectsTab();
              case 2: return _buildPartnerTasksTab();
              case 3: return _buildProfileTab();
              default: return _buildPartnerHomeTab();
            }
          case UserRole.client:
            switch (index) {
              case 0: return _buildClientHomeTab();
              case 1: return _buildClientProjectsTab();
              case 2: return _buildClientRequestsTab();
              case 3: return _buildProfileTab();
              default: return _buildClientHomeTab();
            }
          default:
            switch (index) {
              case 0: return _buildHomeTab();
              case 1: return _buildProfileTab();
              default: return _buildHomeTab();
            }
        }
      },
    );
  }

  // ================================
  // ONGLETS POUR ADMIN/ASSOCIÉ
  // ================================
  
  Widget _buildHomeTab() {
    return IOSScaffold(
      navigationBar: IOSNavigationBar(
        title: "Tableau de bord",
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (context) => const IOSMessagingPage(),
              ),
            ),
            child: const Icon(CupertinoIcons.chat_bubble, color: IOSTheme.primaryBlue),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeHeader(),
                    const SizedBox(height: 24),
                    _buildStatsOverview(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildRecentTasks(),
                    const SizedBox(height: 24),
                    _buildRecentProjects(),
                  ],
                ),
              ),
            ),
    );
  }

  // ================================
  // ONGLETS SPÉCIFIQUES PARTENAIRE
  // ================================
  
  Widget _buildPartnerHomeTab() {
    return IOSScaffold(
      navigationBar: IOSNavigationBar(
        title: "Mon activité",
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (context) => const IOSMessagingPage(),
              ),
            ),
            child: const Icon(CupertinoIcons.chat_bubble, color: IOSTheme.primaryBlue),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPartnerWelcomeHeader(),
                    const SizedBox(height: 24),
                    _buildPartnerStatsOverview(),
                    const SizedBox(height: 24),
                    _buildPartnerQuickActions(),
                    const SizedBox(height: 24),
                    _buildMyRecentTasks(),
                    const SizedBox(height: 24),
                    _buildMyRecentProjects(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPartnerProjectsTab() {
    return IOSScaffold(
      navigationBar: const IOSNavigationBar(title: "Mes Projets"),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : _projects.isEmpty
              ? _buildEmptyState(
                  icon: CupertinoIcons.briefcase,
                  title: 'Aucun projet assigné',
                  subtitle: 'Vous serez notifié lorsque des projets vous seront assignés.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _projects.length,
                  itemBuilder: (context, index) {
                    return _buildProjectTile(_projects[index], isLimited: true);
                  },
                ),
    );
  }

  Widget _buildPartnerTasksTab() {
    return IOSScaffold(
      navigationBar: const IOSNavigationBar(title: "Mes Tâches"),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : _tasks.isEmpty
              ? _buildEmptyState(
                  icon: CupertinoIcons.list_bullet,
                  title: 'Aucune tâche assignée',
                  subtitle: 'Vos tâches apparaîtront ici une fois assignées.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    return _buildTaskTile(_tasks[index], isLimited: true);
                  },
                ),
    );
  }

  // ================================
  // ONGLETS SPÉCIFIQUES CLIENT
  // ================================
  
  Widget _buildClientHomeTab() {
    return IOSScaffold(
      navigationBar: IOSNavigationBar(
        title: "Mes projets",
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (context) => const IOSMessagingPage(),
              ),
            ),
            child: const Icon(CupertinoIcons.chat_bubble, color: IOSTheme.primaryBlue),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildClientWelcomeHeader(),
                    const SizedBox(height: 24),
                    _buildClientStatsOverview(),
                    const SizedBox(height: 24),
                    _buildClientQuickActions(),
                    const SizedBox(height: 24),
                    _buildMyRecentProjects(),
                    const SizedBox(height: 24),
                    _buildMyActiveTasks(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildClientProjectsTab() {
    return IOSScaffold(
      navigationBar: const IOSNavigationBar(title: "Mes Projets"),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : _projects.isEmpty
              ? _buildEmptyState(
                  icon: CupertinoIcons.folder,
                  title: 'Aucun projet en cours',
                  subtitle: 'Créez une demande de projet pour commencer.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _projects.length,
                  itemBuilder: (context, index) {
                    return _buildProjectTile(_projects[index], isClientView: true);
                  },
                ),
    );
  }

  Widget _buildClientRequestsTab() {
    return IOSScaffold(
      navigationBar: IOSNavigationBar(
        title: "Mes Demandes",
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _showCreateProjectRequestDialog,
            child: const Icon(CupertinoIcons.add, color: IOSTheme.primaryBlue),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: IOSTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        CupertinoIcons.paperplane_fill,
                        size: 50,
                        color: IOSTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Aucune demande',
                      style: IOSTheme.title2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Créez une demande de projet ou d\'extension.\nVotre équipe vous répondra rapidement.',
                      style: IOSTheme.body.copyWith(color: IOSTheme.labelSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        borderRadius: BorderRadius.circular(12),
                        onPressed: _showCreateProjectRequestDialog,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(CupertinoIcons.plus, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Nouvelle demande',
                              style: IOSTheme.body.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
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
    );
  }

  // ================================
  // ONGLET GESTION ADMIN
  // ================================
  
  Widget _buildAdminManagementTab() {
    return IOSScaffold(
      navigationBar: const IOSNavigationBar(title: "Gestion"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            IOSListSection(
              children: [
                IOSListTile(
                  leading: const Icon(CupertinoIcons.person_add, color: IOSTheme.primaryBlue),
                  title: const Text('Gestion des utilisateurs', style: IOSTheme.body),
                  subtitle: const Text('Ajouter, modifier, gérer les rôles', style: IOSTheme.footnote),
                  trailing: const Icon(CupertinoIcons.chevron_right, color: IOSTheme.systemGray),
                  onTap: () {
                    // TODO: Navigation vers gestion utilisateurs
                  },
                ),
                IOSListTile(
                  leading: const Icon(CupertinoIcons.building_2_fill, color: IOSTheme.systemOrange),
                  title: const Text('Gestion des entreprises', style: IOSTheme.body),
                  subtitle: const Text('Créer, assigner des entreprises', style: IOSTheme.footnote),
                  trailing: const Icon(CupertinoIcons.chevron_right, color: IOSTheme.systemGray),
                  onTap: () {
                    // TODO: Navigation vers gestion entreprises
                  },
                ),
                IOSListTile(
                  leading: const Icon(CupertinoIcons.doc_text_search, color: IOSTheme.systemGreen),
                  title: const Text('Demandes clients', style: IOSTheme.body),
                  subtitle: const Text('Examiner les propositions de projets', style: IOSTheme.footnote),
                  trailing: const Icon(CupertinoIcons.chevron_right, color: IOSTheme.systemGray),
                  onTap: () {
                    // TODO: Navigation vers demandes clients
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final userName = SupabaseService.currentUser?.email?.split('@').first ?? 'Utilisateur';
    final greeting = _getGreeting();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$greeting $userName",
            style: IOSTheme.largeTitle,
          ),
          const SizedBox(height: 8),
          Text(
            "Voici votre activité du jour",
            style: IOSTheme.body.copyWith(color: IOSTheme.labelSecondary),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Bonjour";
    if (hour < 17) return "Bonne après-midi";
    return "Bonsoir";
  }

  Widget _buildStatsOverview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Vue d'ensemble", style: IOSTheme.title3),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: "Tâches",
                  value: "${_stats['completed_tasks']}/${_stats['total_tasks']}",
                  subtitle: "Terminées",
                  color: IOSTheme.successColor,
                  icon: CupertinoIcons.checkmark_circle_fill,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: "Urgentes",
                  value: "${_stats['urgent_tasks']}",
                  subtitle: "À traiter",
                  color: IOSTheme.errorColor,
                  icon: CupertinoIcons.exclamationmark_triangle_fill,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: "Projets",
                  value: "${_stats['in_progress_projects']}",
                  subtitle: "En cours",
                  color: IOSTheme.warningColor,
                  icon: CupertinoIcons.doc_text_fill,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: "Progression",
                  value: "${_stats['completion_rate']}%",
                  subtitle: "Complété",
                  color: IOSTheme.primaryBlue,
                  icon: CupertinoIcons.chart_pie_fill,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: IOSTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: IOSTheme.footnote),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: IOSTheme.title2.copyWith(color: color),
          ),
          Text(
            subtitle,
            style: IOSTheme.caption1.copyWith(color: IOSTheme.labelTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return IOSListSection(
      title: "Actions rapides",
      children: [
        _buildQuickActionTile(
          icon: CupertinoIcons.add_circled,
          iconColor: IOSTheme.primaryBlue,
          title: "Nouvelle tâche",
          onTap: _showCreateTaskDialog,
        ),
        _buildQuickActionTile(
          icon: CupertinoIcons.doc_text_search,
          iconColor: IOSTheme.systemPurple,
          title: "Nouveau projet",
          onTap: _showCreateProjectDialog,
        ),
        if (_userRole == 'admin' || _userRole == 'associe') ...[
          _buildQuickActionTile(
            icon: CupertinoIcons.person_add,
            iconColor: IOSTheme.systemGreen,
            title: "Inviter un utilisateur",
            onTap: () => Navigator.of(context).pushNamed('/add_user'),
          ),
        ],
        _buildQuickActionTile(
          icon: CupertinoIcons.calendar_badge_plus,
          iconColor: IOSTheme.systemOrange,
          title: "Planifier une réunion",
          onTap: () => Navigator.of(context).pushNamed('/calendar'),
        ),
      ],
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return IOSListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(title, style: IOSTheme.body),
      trailing: const Icon(CupertinoIcons.chevron_right, color: IOSTheme.systemGray, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildRecentTasks() {
    if (_tasks.isEmpty) {
      return IOSListSection(
        title: "Tâches récentes",
        children: [
          _buildEmptyState(
            icon: CupertinoIcons.checkmark_alt_circle,
            title: "Aucune tâche",
            subtitle: "Créez votre première tâche",
            actionTitle: "Créer une tâche",
            onAction: _showCreateTaskDialog,
          ),
        ],
      );
    }

    return IOSListSection(
      title: "Tâches récentes",
      children: _tasks.take(3).map((task) => _buildTaskTile(task)).toList(),
    );
  }

  Widget _buildRecentProjects() {
    if (_projects.isEmpty) {
      return IOSListSection(
        title: "Projets récents",
        children: [
          _buildEmptyState(
            icon: CupertinoIcons.doc_text,
            title: "Aucun projet",
            subtitle: "Créez votre premier projet",
            actionTitle: "Créer un projet",
            onAction: _showCreateProjectDialog,
          ),
        ],
      );
    }

    return IOSListSection(
      title: "Projets récents",
      children: _projects.take(3).map((project) => _buildProjectTile(project)).toList(),
    );
  }

  Widget _buildTaskTile(Map<String, dynamic> task, {bool isLimited = false, bool isClientView = false}) {
    final priority = task['priority'] ?? 'medium';
    final isCompleted = task['status'] == 'done';

    return IOSListTile(
      leading: Icon(
        isCompleted ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
        color: isCompleted ? IOSTheme.successColor : IOSTheme.systemGray,
        size: 24,
      ),
      title: Text(
        task['title'] ?? 'Tâche sans titre',
        style: IOSTheme.body.copyWith(
          decoration: isCompleted ? TextDecoration.lineThrough : null,
          color: isCompleted ? IOSTheme.labelSecondary : IOSTheme.labelPrimary,
        ),
      ),
      subtitle: Text(
        task['project_name'] ?? 'Aucun projet',
        style: IOSTheme.footnote,
      ),
      trailing: isLimited || isClientView 
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: IOSTheme.getPriorityColor(priority).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                IOSTheme.getPriorityLabel(priority),
                style: IOSTheme.caption2.copyWith(
                  color: IOSTheme.getPriorityColor(priority),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: IOSTheme.getPriorityColor(priority).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                IOSTheme.getPriorityLabel(priority),
                style: IOSTheme.caption2.copyWith(
                  color: IOSTheme.getPriorityColor(priority),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      onTap: isClientView ? null : () => _showTaskDetail(task),
    );
  }

  Widget _buildProjectTile(Map<String, dynamic> project, {bool isLimited = false, bool isClientView = false}) {
    final status = project['status'] ?? 'pending';
    final statusColor = IOSTheme.getStatusColor(status);

    return IOSListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          CupertinoIcons.doc_text,
          color: statusColor,
          size: 20,
        ),
      ),
      title: Text(
        project['name'] ?? project['title'] ?? 'Projet sans titre',
        style: IOSTheme.body,
      ),
      subtitle: Text(
        project['client_name'] ?? project['company_name'] ?? 'Aucun client',
        style: IOSTheme.footnote,
      ),
      trailing: isLimited 
          ? null 
          : const Icon(CupertinoIcons.chevron_right, color: IOSTheme.systemGray, size: 16),
      onTap: isLimited 
          ? null 
          : () => Navigator.of(context).pushNamed('/project_detail', arguments: project['id']),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionTitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return       Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(icon, size: 64, color: IOSTheme.systemGray3),
            const SizedBox(height: 16),
            Text(title, style: IOSTheme.headline),
            const SizedBox(height: 8),
            Text(subtitle, style: IOSTheme.footnote, textAlign: TextAlign.center),
            if (onAction != null) ...[
              const SizedBox(height: 24),
              CupertinoButton.filled(
                onPressed: onAction,
                child: Text(actionTitle ?? actionText ?? 'Action'),
              ),
            ],
          ],
        ),
      );
  }

  Widget _buildProjectsTab() {
    return IOSScaffold(
      navigationBar: IOSNavigationBar(
        title: "Projets",
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _showCreateProjectDialog,
            child: const Icon(CupertinoIcons.add, color: IOSTheme.primaryBlue),
          ),
        ],
      ),
      body: _projects.isEmpty
          ? Center(
              child: _buildEmptyState(
                icon: CupertinoIcons.doc_text,
                title: "Aucun projet",
                subtitle: "Créez votre premier projet pour commencer",
                actionTitle: "Créer un projet",
                onAction: _showCreateProjectDialog,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 20),
              itemCount: _projects.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Container(
                  decoration: IOSTheme.cardDecoration,
                  child: _buildProjectTile(_projects[index]),
                ),
              ),
            ),
    );
  }

  Widget _buildTasksTab() {
    return IOSScaffold(
      navigationBar: IOSNavigationBar(
        title: "Tâches",
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _showCreateTaskDialog,
            child: const Icon(CupertinoIcons.add, color: IOSTheme.primaryBlue),
          ),
        ],
      ),
      body: _tasks.isEmpty
          ? Center(
              child: _buildEmptyState(
                icon: CupertinoIcons.checkmark_alt_circle,
                title: "Aucune tâche",
                subtitle: "Créez votre première tâche pour commencer",
                actionTitle: "Créer une tâche",
                onAction: _showCreateTaskDialog,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 20),
              itemCount: _tasks.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Container(
                  decoration: IOSTheme.cardDecoration,
                  child: _buildTaskTile(_tasks[index]),
                ),
              ),
            ),
    );
  }

  Widget _buildProfileTab() {
    final user = SupabaseService.currentUser;

    return IOSScaffold(
      navigationBar: const IOSNavigationBar(title: "Profil"),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            
            // Avatar et infos utilisateur
            _buildProfileHeader(user),
            
            const SizedBox(height: 30),
            
            // Menu des paramètres
            _buildSettingsMenu(),
            
            const SizedBox(height: 30),
            
            // Actions de déconnexion
            _buildLogoutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: IOSTheme.primaryBlue,
          child: Text(
            user?.email?.substring(0, 1).toUpperCase() ?? 'U',
            style: IOSTheme.largeTitle.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user?.email?.split('@').first ?? 'Utilisateur',
          style: IOSTheme.title2,
        ),
        Text(
          user?.email ?? '',
          style: IOSTheme.footnote,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: IOSTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _getRoleLabel(_userRole),
            style: IOSTheme.footnote.copyWith(
              color: IOSTheme.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsMenu() {
    return IOSListSection(
      title: "Paramètres",
      children: [
        _buildSettingsTile(
          icon: CupertinoIcons.person_circle,
          iconColor: IOSTheme.primaryBlue,
          title: "Informations personnelles",
          onTap: () {
            // Navigation vers les paramètres de profil
          },
        ),
        _buildSettingsTile(
          icon: CupertinoIcons.bell,
          iconColor: IOSTheme.systemOrange,
          title: "Notifications",
          onTap: () {
            // Navigation vers les paramètres de notifications
          },
        ),
        _buildSettingsTile(
          icon: CupertinoIcons.lock,
          iconColor: IOSTheme.systemGreen,
          title: "Sécurité et confidentialité",
          onTap: () {
            // Navigation vers les paramètres de sécurité
          },
        ),
        _buildSettingsTile(
          icon: CupertinoIcons.question_circle,
          iconColor: IOSTheme.systemGray,
          title: "Aide et support",
          onTap: () {
            // Navigation vers l'aide
          },
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return IOSListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: IOSTheme.body),
      trailing: const Icon(CupertinoIcons.chevron_right, color: IOSTheme.systemGray, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildLogoutSection() {
    return IOSListSection(
      children: [
        IOSListTile(
          leading: const Icon(CupertinoIcons.square_arrow_right, color: IOSTheme.systemRed),
          title: Text(
            "Déconnexion",
            style: IOSTheme.body.copyWith(color: IOSTheme.systemRed),
          ),
          onTap: _handleLogout,
        ),
      ],
    );
  }

  // Actions et dialogues simplifiés
  void _showCreateTaskDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String selectedPriority = 'medium';
    String? selectedProjectId;
    String? selectedPartnerId;
    List<Map<String, dynamic>> projects = [];
    List<Map<String, dynamic>> partners = [];
    bool isLoading = true;

    // Charger les données
    Future.wait([
      SupabaseService.getCompanyProjects(),
      SupabaseService.getPartners(),
    ]).then((results) {
      projects = results[0];
      partners = results[1];
      isLoading = false;
      if (mounted) setState(() {});
    });
    
    showCupertinoDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => CupertinoAlertDialog(
          title: const Text('Nouvelle Tâche'),
          content: SizedBox(
            height: 400,
            width: 300,
            child: isLoading 
                ? const Center(child: CupertinoActivityIndicator())
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),
                        CupertinoTextField(
                          controller: titleController,
                          placeholder: 'Titre de la tâche *',
                          style: IOSTheme.body,
                        ),
                        const SizedBox(height: 12),
                        CupertinoTextField(
                          controller: descriptionController,
                          placeholder: 'Description (optionnel)',
                          style: IOSTheme.body,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        
                        // Sélection du projet
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Projet *', style: IOSTheme.footnote),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: IOSTheme.systemGray4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => _showProjectPicker(projects, (projectId) {
                              setDialogState(() {
                                selectedProjectId = projectId;
                              });
                            }),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    selectedProjectId != null 
                                        ? projects.firstWhere((p) => p['id'].toString() == selectedProjectId)['name'] ?? 'Projet'
                                        : 'Sélectionner un projet',
                                    style: IOSTheme.body,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(CupertinoIcons.chevron_down, size: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Sélection du partenaire
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Partenaire *', style: IOSTheme.footnote),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: IOSTheme.systemGray4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => _showPartnerPicker(partners, (partnerId) {
                              setDialogState(() {
                                selectedPartnerId = partnerId;
                              });
                            }),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    selectedPartnerId != null 
                                        ? _getPartnerName(partners, selectedPartnerId!)
                                        : 'Sélectionner un partenaire',
                                    style: IOSTheme.body,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(CupertinoIcons.chevron_down, size: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Priorité
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Priorité', style: IOSTheme.footnote),
                        ),
                        const SizedBox(height: 8),
                        CupertinoSegmentedControl<String>(
                          children: const {
                            'low': Text('Basse'),
                            'medium': Text('Moyenne'),
                            'high': Text('Haute'),
                            'urgent': Text('Urgente'),
                          },
                          onValueChanged: (String value) {
                            setDialogState(() {
                              selectedPriority = value;
                            });
                          },
                          groupValue: selectedPriority,
                        ),
                      ],
                    ),
                  ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            CupertinoDialogAction(
              child: const Text('Créer'),
              onPressed: () {
                if (titleController.text.trim().isNotEmpty && 
                    selectedProjectId != null && 
                    selectedPartnerId != null) {
                  Navigator.of(context).pop();
                  _createTask({
                    'title': titleController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'priority': selectedPriority,
                    'projectId': selectedProjectId,
                    'partnerId': selectedPartnerId,
                  });
                } else {
                  // Afficher erreur
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text('Champs requis'),
                      content: const Text('Veuillez remplir le titre, sélectionner un projet et un partenaire.'),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('OK'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showProjectPicker(List<Map<String, dynamic>> projects, Function(String) onSelected) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: CupertinoPicker(
            itemExtent: 32,
            onSelectedItemChanged: (index) => onSelected(projects[index]['id'].toString()),
            children: projects.map((project) => Text(project['name'] ?? 'Projet sans nom')).toList(),
          ),
        ),
      ),
    );
  }

  void _showPartnerPicker(List<Map<String, dynamic>> partners, Function(String) onSelected) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: CupertinoPicker(
            itemExtent: 32,
            onSelectedItemChanged: (index) => onSelected(partners[index]['user_id'].toString()),
            children: partners.map((partner) => Text(_getPartnerName([partner], partner['user_id']))).toList(),
          ),
        ),
      ),
    );
  }

  String _getPartnerName(List<Map<String, dynamic>> partners, String partnerId) {
    final partner = partners.firstWhere(
      (p) => p['user_id'] == partnerId,
      orElse: () => <String, dynamic>{},
    );
    
    if (partner.isNotEmpty) {
      final firstName = partner['first_name'] ?? '';
      final lastName = partner['last_name'] ?? '';
      return '$firstName $lastName'.trim().isNotEmpty 
          ? '$firstName $lastName'.trim() 
          : partner['email'] ?? 'Partenaire';
    }
    return 'Partenaire inconnu';
  }

  void _showCreateProjectDialog() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const ProjectCreationFormPage(),
      ),
    ).then((_) {
      // Recharger les données après création du projet
      _loadData();
    });
  }

  Future<void> _createTask(Map<String, dynamic> data) async {
    try {
      final projectId = data['projectId'] as String;
      final partnerId = data['partnerId'] as String;

      await SupabaseService.createTaskForCompany(
        projectId: projectId,
        title: data['title'],
        description: data['description'],
        priority: data['priority'] ?? 'medium',
        partnerId: partnerId,
      );
        
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Succès'),
            content: const Text('Tâche créée avec succès'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Erreur'),
            content: Text('Erreur lors de la création de la tâche: $e'),
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



  void _showTaskDetail(Map<String, dynamic> task) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(task['title'] ?? 'Tâche'),
        content: Text(task['description'] ?? 'Aucune description'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Fermer'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Déconnexion'),
            onPressed: () async {
              await SupabaseService.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  // ================================
  // MÉTHODES SPÉCIFIQUES PARTENAIRE
  // ================================
  
  Widget _buildPartnerWelcomeHeader() {
    final greeting = _getGreeting();
    final userName = SupabaseService.currentUser?.email?.split('@')[0] ?? 'Partenaire';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: IOSTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$greeting $userName",
            style: IOSTheme.largeTitle,
          ),
          const SizedBox(height: 8),
          Text(
            "Voici vos projets et tâches assignées",
            style: IOSTheme.body.copyWith(color: IOSTheme.labelSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerStatsOverview() {
    final myTasks = _stats['total_tasks'] ?? 0;
    final completedTasks = _stats['completed_tasks'] ?? 0;
    final myProjects = _projects.length;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Mon activité", style: IOSTheme.title3),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: "Mes Tâches",
                  value: "$completedTasks/$myTasks",
                  subtitle: "Terminées",
                  color: IOSTheme.successColor,
                  icon: CupertinoIcons.checkmark_circle_fill,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: "Mes Projets",
                  value: "$myProjects",
                  subtitle: "Assignés",
                  color: IOSTheme.primaryBlue,
                  icon: CupertinoIcons.briefcase_fill,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Actions rapides", style: IOSTheme.title3),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: "Messagerie",
                  subtitle: "Contacter l'équipe",
                  icon: CupertinoIcons.chat_bubble_fill,
                  color: IOSTheme.primaryBlue,
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => const IOSMessagingPage(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  title: "Profil",
                  subtitle: "Mes informations",
                  icon: CupertinoIcons.person_fill,
                  color: IOSTheme.systemGray,
                  onTap: () => _tabController.animateTo(3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyRecentTasks() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Mes tâches récentes", style: IOSTheme.title3),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _tabController.animateTo(2),
                child: Text(
                  "Voir tout",
                  style: IOSTheme.body.copyWith(color: IOSTheme.primaryBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_tasks.isEmpty)
            _buildEmptyState(
              icon: CupertinoIcons.list_bullet,
              title: 'Aucune tâche assignée',
              subtitle: 'Vos tâches apparaîtront ici.',
            )
          else
            ...(_tasks.take(3).map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildTaskTile(task, isLimited: true),
            ))),
        ],
      ),
    );
  }

  Widget _buildMyRecentProjects() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Mes projets", style: IOSTheme.title3),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _tabController.animateTo(1),
                child: Text(
                  "Voir tout",
                  style: IOSTheme.body.copyWith(color: IOSTheme.primaryBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_projects.isEmpty)
            _buildEmptyState(
              icon: CupertinoIcons.briefcase,
              title: 'Aucun projet assigné',
              subtitle: 'Vos projets apparaîtront ici.',
            )
          else
            ...(_projects.take(2).map((project) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildProjectTile(project, isLimited: true),
            ))),
        ],
      ),
    );
  }

  // ================================
  // MÉTHODES SPÉCIFIQUES CLIENT
  // ================================
  
  Widget _buildClientWelcomeHeader() {
    final greeting = _getGreeting();
    final userName = SupabaseService.currentUser?.email?.split('@')[0] ?? 'Client';
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: IOSTheme.cardDecoration.copyWith(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            IOSTheme.primaryBlue.withValues(alpha: 0.05),
            IOSTheme.systemBackground,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: IOSTheme.primaryBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  CupertinoIcons.person_fill,
                  color: IOSTheme.primaryBlue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$greeting $userName",
                      style: IOSTheme.largeTitle.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Suivez l'avancement de vos projets",
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

  Widget _buildClientStatsOverview() {
    final totalProjects = _projects.length;
    final activeTasks = _tasks.where((t) => t['status'] != 'done').length;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Mes projets", style: IOSTheme.title3),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: "Projets",
                  value: "$totalProjects",
                  subtitle: "En cours",
                  color: IOSTheme.primaryBlue,
                  icon: CupertinoIcons.folder_fill,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: "Tâches",
                  value: "$activeTasks",
                  subtitle: "Actives",
                  color: IOSTheme.warningColor,
                  icon: CupertinoIcons.list_bullet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text("Actions", style: IOSTheme.title3),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildClientActionCard(
                  title: "Nouvelle demande",
                  subtitle: "Créer un projet",
                  icon: CupertinoIcons.plus_circle_fill,
                  color: IOSTheme.successColor,
                  onTap: _showCreateProjectRequestDialog,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildClientActionCard(
                  title: "Messagerie",
                  subtitle: "Contacter l'équipe",
                  icon: CupertinoIcons.chat_bubble_2_fill,
                  color: IOSTheme.primaryBlue,
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => const IOSMessagingPage(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyActiveTasks() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Mes tâches actives", style: IOSTheme.title3),
          const SizedBox(height: 16),
          if (_tasks.isEmpty)
            _buildEmptyState(
              icon: CupertinoIcons.list_bullet,
              title: 'Aucune tâche active',
              subtitle: 'Vos tâches apparaîtront ici.',
            )
          else
            ...(_tasks.take(5).map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildTaskTile(task, isClientView: true),
            ))),
        ],
      ),
    );
  }

  // ================================
  // DIALOGUES ET ACTIONS
  // ================================
  
  void _showCreateProjectRequestDialog() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const ProjectRequestFormPage(),
      ),
    );
  }



  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: IOSTheme.cardDecoration,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: IOSTheme.body.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: IOSTheme.footnote,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130, // Hauteur augmentée pour éviter l'overflow
        padding: const EdgeInsets.all(16), // Padding réduit pour plus d'espace
        decoration: IOSTheme.cardDecoration.copyWith(
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Éviter l'expansion excessive
          children: [
            Container(
              width: 44, // Légèrement réduit pour plus d'espace
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: color,
                size: 26, // Taille légèrement réduite
              ),
            ),
            const SizedBox(height: 10), // Espacement réduit
            Flexible( // Permet au texte de s'adapter
              child: Text(
                title,
                style: IOSTheme.body.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14, // Taille légèrement réduite
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2), // Espacement réduit
            Flexible( // Permet au texte de s'adapter
              child: Text(
                subtitle,
                style: IOSTheme.footnote.copyWith(fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleLabel(UserRole? role) {
    switch (role) {
      case UserRole.admin: return 'Administrateur';
      case UserRole.associe: return 'Associé';
      case UserRole.partenaire: return 'Partenaire';
      case UserRole.client: return 'Client';
      default: return 'Utilisateur';
    }
  }
} 
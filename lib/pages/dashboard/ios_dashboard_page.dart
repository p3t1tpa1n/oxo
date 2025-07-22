import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../config/ios_theme.dart';
import '../../widgets/ios_widgets.dart';
import '../../services/supabase_service.dart';

class IOSDashboardPage extends StatefulWidget {
  const IOSDashboardPage({Key? key}) : super(key: key);

  @override
  State<IOSDashboardPage> createState() => _IOSDashboardPageState();
}

class _IOSDashboardPageState extends State<IOSDashboardPage> {
  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      backgroundColor: IOSTheme.systemGroupedBackground,
      tabBar: CupertinoTabBar(
        backgroundColor: IOSTheme.systemBackground,
        activeColor: IOSTheme.primaryBlue,
        inactiveColor: IOSTheme.systemGray,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.checkmark_alt_circle),
            label: 'Tâches',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.calendar),
            label: 'Planning',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_bar),
            label: 'Statistiques',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            label: 'Profil',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return _buildHomeTab();
          case 1:
            return _buildTasksTab();
          case 2:
            return _buildPlanningTab();
          case 3:
            return _buildStatsTab();
          case 4:
            return _buildProfileTab();
          default:
            return _buildHomeTab();
        }
      },
    );
  }

  Widget _buildHomeTab() {
    return IOSScaffold(
      navigationBar: IOSNavigationBar(
        title: "Tableau de bord",
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              Navigator.of(context).pushNamed('/messaging');
            },
            child: const Icon(
              CupertinoIcons.chat_bubble,
              color: IOSTheme.primaryBlue,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // Message de bienvenue
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bonjour ${SupabaseService.currentUser?.email?.split('@').first ?? 'Utilisateur'}",
                    style: const TextStyle(
                      color: IOSTheme.labelPrimary,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      fontFamily: '.SF Pro Display',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Voici votre activité du jour",
                    style: TextStyle(
                      color: IOSTheme.labelSecondary,
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Cartes de statistiques rapides
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildStatCard(
                    icon: CupertinoIcons.checkmark_alt_circle_fill,
                    iconColor: IOSTheme.systemGreen,
                    title: "Tâches terminées",
                    value: "12",
                    subtitle: "Cette semaine",
                  ),
                  _buildStatCard(
                    icon: CupertinoIcons.clock_fill,
                    iconColor: IOSTheme.systemOrange,
                    title: "Heures travaillées",
                    value: "32h",
                    subtitle: "Cette semaine",
                  ),
                  _buildStatCard(
                    icon: CupertinoIcons.person_2_fill,
                    iconColor: IOSTheme.primaryBlue,
                    title: "Réunions",
                    value: "5",
                    subtitle: "Aujourd'hui",
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Actions rapides
            IOSListSection(
              title: "Actions rapides",
              children: [
                IOSListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: IOSTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: const Text("Nouvelle tâche"),
                  trailing: const Icon(
                    CupertinoIcons.chevron_right,
                    color: IOSTheme.systemGray,
                    size: 16,
                  ),
                  onTap: () {
                    // Navigation vers la création de tâche
                  },
                ),
                IOSListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: IOSTheme.systemGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.calendar_badge_plus,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: const Text("Planifier une réunion"),
                  trailing: const Icon(
                    CupertinoIcons.chevron_right,
                    color: IOSTheme.systemGray,
                    size: 16,
                  ),
                  onTap: () {
                    // Navigation vers la planification
                  },
                ),
                IOSListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: IOSTheme.systemPurple,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.doc_text,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: const Text("Générer un rapport"),
                  trailing: const Icon(
                    CupertinoIcons.chevron_right,
                    color: IOSTheme.systemGray,
                    size: 16,
                  ),
                  onTap: () {
                    // Navigation vers les rapports
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Tâches récentes
            IOSListSection(
              title: "Tâches récentes",
              children: [
                _buildTaskTile(
                  title: "Révision du code",
                  subtitle: "Projet Alpha",
                  priority: "Haute",
                  priorityColor: IOSTheme.systemRed,
                  isCompleted: false,
                ),
                _buildTaskTile(
                  title: "Réunion équipe",
                  subtitle: "14:00 - Salle de conférence",
                  priority: "Moyenne",
                  priorityColor: IOSTheme.systemOrange,
                  isCompleted: true,
                ),
                _buildTaskTile(
                  title: "Documentation API",
                  subtitle: "À terminer avant vendredi",
                  priority: "Basse",
                  priorityColor: IOSTheme.systemGreen,
                  isCompleted: false,
                ),
              ],
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      width: 160,
      height: 110, // Hauteur fixe pour éviter le débordement
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(12), // Réduction du padding
      decoration: BoxDecoration(
        color: IOSTheme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 20, // Réduction de la taille de l'icône
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: IOSTheme.labelPrimary,
                    fontSize: 20, // Réduction de la taille de police
                    fontWeight: FontWeight.w700,
                    fontFamily: '.SF Pro Display',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    color: IOSTheme.labelSecondary,
                    fontSize: 11, // Réduction de la taille de police
                    fontWeight: FontWeight.w400,
                    fontFamily: '.SF Pro Text',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: IOSTheme.labelTertiary,
              fontSize: 10, // Réduction de la taille de police
              fontWeight: FontWeight.w400,
              fontFamily: '.SF Pro Text',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile({
    required String title,
    required String subtitle,
    required String priority,
    required Color priorityColor,
    required bool isCompleted,
  }) {
    return IOSListTile(
      leading: Icon(
        isCompleted
            ? CupertinoIcons.checkmark_circle_fill
            : CupertinoIcons.circle,
        color: isCompleted ? IOSTheme.systemGreen : IOSTheme.systemGray,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          decoration: isCompleted ? TextDecoration.lineThrough : null,
          color: isCompleted ? IOSTheme.labelSecondary : IOSTheme.labelPrimary,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: priorityColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          priority,
          style: TextStyle(
            color: priorityColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: '.SF Pro Text',
          ),
        ),
      ),
      onTap: () {
        // Navigation vers les détails de la tâche
      },
    );
  }

  Widget _buildTasksTab() {
    return const IOSScaffold(
      navigationBar: IOSNavigationBar(title: "Tâches"),
      body: Center(
        child: Text("Onglet Tâches - À implémenter"),
      ),
    );
  }

  Widget _buildPlanningTab() {
    return const IOSScaffold(
      navigationBar: IOSNavigationBar(title: "Planning"),
      body: Center(
        child: Text("Onglet Planning - À implémenter"),
      ),
    );
  }

  Widget _buildStatsTab() {
    return const IOSScaffold(
      navigationBar: IOSNavigationBar(title: "Statistiques"),
      body: Center(
        child: Text("Onglet Statistiques - À implémenter"),
      ),
    );
  }

  Widget _buildProfileTab() {
    return const IOSScaffold(
      navigationBar: IOSNavigationBar(title: "Profil"),
      body: Center(
        child: Text("Onglet Profil - À implémenter"),
      ),
    );
  }
} 
// ============================================================================
// SYSTÈME D'ICÔNES UNIFIÉ - OXO TIME SHEETS
// Mapping fonction → icône pour cohérence visuelle
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Icônes unifiées de l'application OXO
/// Utiliser `AppIcons.missions` au lieu de définir des icônes en dur
/// Supporte automatiquement Material (desktop) et Cupertino (iOS)
class AppIcons {
  const AppIcons._();
  
  // ══════════════════════════════════════════════════════════════════════════
  // NAVIGATION PRINCIPALE
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Icône pour le dashboard / accueil
  static const IconData home = Icons.home_outlined;
  static const IconData homeIOS = CupertinoIcons.home;
  
  /// Icône pour les missions / projets
  static const IconData missions = Icons.folder_outlined;
  static const IconData missionsIOS = CupertinoIcons.folder;
  
  /// Icône pour le planning / calendrier
  static const IconData planning = Icons.calendar_month;
  static const IconData planningIOS = CupertinoIcons.calendar;
  
  /// Icône pour la saisie du temps / timesheet
  static const IconData timesheet = Icons.schedule;
  static const IconData timesheetIOS = CupertinoIcons.clock;
  
  /// Icône pour les disponibilités
  static const IconData availability = Icons.event_available;
  static const IconData availabilityIOS = CupertinoIcons.calendar_badge_plus;
  
  /// Icône pour les actions commerciales
  static const IconData actions = Icons.business_center;
  static const IconData actionsIOS = CupertinoIcons.briefcase;
  
  /// Icône pour les partenaires et clients
  static const IconData partners = Icons.people;
  static const IconData partnersIOS = CupertinoIcons.person_2;
  
  /// Icône pour les clients
  static const IconData clients = Icons.business_center;
  static const IconData clientsIOS = CupertinoIcons.building_2_fill;
  
  /// Icône pour la messagerie
  static const IconData messaging = Icons.chat_outlined;
  static const IconData messagingIOS = CupertinoIcons.chat_bubble;
  
  /// Icône pour le profil utilisateur
  static const IconData profile = Icons.person;
  static const IconData profileIOS = CupertinoIcons.person;
  
  /// Icône pour les paramètres
  static const IconData settings = Icons.settings;
  static const IconData settingsIOS = CupertinoIcons.settings;
  
  // ══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Icône pour ajouter / créer
  static const IconData add = Icons.add;
  static const IconData addIOS = CupertinoIcons.add;
  
  /// Icône pour éditer / modifier
  static const IconData edit = Icons.edit_outlined;
  static const IconData editIOS = CupertinoIcons.pencil;
  
  /// Icône pour supprimer
  static const IconData delete = Icons.delete_outline;
  static const IconData deleteIOS = CupertinoIcons.trash;
  
  /// Icône pour sauvegarder
  static const IconData save = Icons.save;
  static const IconData saveIOS = CupertinoIcons.floppy_disk;
  
  /// Icône pour rechercher
  static const IconData search = Icons.search;
  static const IconData searchIOS = CupertinoIcons.search;
  
  /// Icône pour filtrer
  static const IconData filter = Icons.filter_list;
  static const IconData filterIOS = CupertinoIcons.line_horizontal_3_decrease;
  
  /// Icône pour trier
  static const IconData sort = Icons.sort;
  static const IconData sortIOS = CupertinoIcons.arrow_up_arrow_down;
  
  /// Icône pour rafraîchir
  static const IconData refresh = Icons.refresh;
  static const IconData refreshIOS = CupertinoIcons.refresh;
  
  /// Icône pour télécharger / exporter
  static const IconData download = Icons.download;
  static const IconData downloadIOS = CupertinoIcons.arrow_down_circle;
  
  /// Icône pour partager
  static const IconData share = Icons.share;
  static const IconData shareIOS = CupertinoIcons.share;
  
  // ══════════════════════════════════════════════════════════════════════════
  // STATUTS ET ÉTATS
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Icône pour succès / validé
  static const IconData success = Icons.check_circle;
  static const IconData successIOS = CupertinoIcons.check_mark_circled;
  
  /// Icône pour erreur / échoué
  static const IconData error = Icons.error;
  static const IconData errorIOS = CupertinoIcons.exclamationmark_circle;
  
  /// Icône pour avertissement
  static const IconData warning = Icons.warning;
  static const IconData warningIOS = CupertinoIcons.exclamationmark_triangle;
  
  /// Icône pour information
  static const IconData info = Icons.info;
  static const IconData infoIOS = CupertinoIcons.info_circle;
  
  /// Icône pour en attente / pending
  static const IconData pending = Icons.schedule;
  static const IconData pendingIOS = CupertinoIcons.time;
  
  /// Icône pour en cours / in progress
  static const IconData inProgress = Icons.play_circle_outline;
  static const IconData inProgressIOS = CupertinoIcons.play_circle;
  
  /// Icône pour terminé / done
  static const IconData done = Icons.check_circle_outline;
  static const IconData doneIOS = CupertinoIcons.checkmark_circle;
  
  // ══════════════════════════════════════════════════════════════════════════
  // NAVIGATION (FLÈCHES, RETOUR)
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Icône pour retour / back
  static const IconData back = Icons.arrow_back;
  static const IconData backIOS = CupertinoIcons.back;
  
  /// Icône pour suivant / next
  static const IconData next = Icons.arrow_forward;
  static const IconData nextIOS = CupertinoIcons.forward;
  
  /// Icône pour fermer
  static const IconData close = Icons.close;
  static const IconData closeIOS = CupertinoIcons.xmark;
  
  /// Icône pour menu / hamburger
  static const IconData menu = Icons.menu;
  static const IconData menuIOS = CupertinoIcons.line_horizontal_3;
  
  /// Icône pour plus d'options
  static const IconData moreVert = Icons.more_vert;
  static const IconData moreVertIOS = CupertinoIcons.ellipsis_vertical;
  
  static const IconData moreHoriz = Icons.more_horiz;
  static const IconData moreHorizIOS = CupertinoIcons.ellipsis;
  
  // ══════════════════════════════════════════════════════════════════════════
  // FONCTIONNALITÉS SPÉCIFIQUES
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Icône pour notifications
  static const IconData notifications = Icons.notifications_outlined;
  static const IconData notificationsIOS = CupertinoIcons.bell;
  
  /// Icône pour factures / invoices
  static const IconData invoices = Icons.receipt_long;
  static const IconData invoicesIOS = CupertinoIcons.doc_text;
  
  /// Icône pour reporting / statistiques
  static const IconData reporting = Icons.assessment;
  static const IconData reportingIOS = CupertinoIcons.graph_square;
  
  /// Icône pour demandes / requests
  static const IconData requests = Icons.request_page_outlined;
  static const IconData requestsIOS = CupertinoIcons.doc_plaintext;
  
  /// Icône pour administration
  static const IconData admin = Icons.admin_panel_settings;
  static const IconData adminIOS = CupertinoIcons.shield;
  
  /// Icône pour déconnexion
  static const IconData logout = Icons.logout;
  static const IconData logoutIOS = CupertinoIcons.square_arrow_right;
  
  /// Icône pour entreprise / société
  static const IconData company = Icons.business;
  static const IconData companyIOS = CupertinoIcons.building_2_fill;
  
  /// Icône pour groupe d'investissement
  static const IconData group = Icons.account_balance;
  static const IconData groupIOS = CupertinoIcons.building_2_fill;
  
  // ══════════════════════════════════════════════════════════════════════════
  // MÉTHODE UTILITAIRE
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Retourne l'icône adaptée à la plateforme
  /// Utiliser `AppIcons.forPlatform(AppIcons.missions, AppIcons.missionsIOS)`
  static IconData forPlatform(IconData material, IconData cupertino) {
    // Vérifier si on est sur iOS (natif ou web mobile)
    // Cette logique devrait être cohérente avec DeviceDetector
    return material; // Par défaut Material, à ajuster selon DeviceDetector
  }
}

// ══════════════════════════════════════════════════════════════════════════
// HELPER WIDGET POUR ICÔNE ADAPTATIVE
// ══════════════════════════════════════════════════════════════════════════

/// Widget qui affiche automatiquement l'icône adaptée à la plateforme
class AdaptiveIcon extends StatelessWidget {
  final IconData materialIcon;
  final IconData? cupertinoIcon;
  final double? size;
  final Color? color;
  
  const AdaptiveIcon({
    Key? key,
    required this.materialIcon,
    this.cupertinoIcon,
    this.size,
    this.color,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // TODO: Utiliser DeviceDetector.shouldUseIOSInterface()
    final isIOS = false; // À remplacer par la vraie logique
    
    return Icon(
      isIOS && cupertinoIcon != null ? cupertinoIcon : materialIcon,
      size: size,
      color: color,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// HELPER POUR BADGES DE STATUT
// ══════════════════════════════════════════════════════════════════════════

/// Mapping statut → icône
class StatusIcons {
  static IconData forStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'en_attente':
      case 'à_assigner':
        return AppIcons.pending;
      case 'in_progress':
      case 'en_cours':
        return AppIcons.inProgress;
      case 'completed':
      case 'done':
      case 'fait':
      case 'terminé':
        return AppIcons.done;
      case 'error':
      case 'erreur':
      case 'échoué':
        return AppIcons.error;
      case 'warning':
      case 'avertissement':
        return AppIcons.warning;
      default:
        return AppIcons.info;
    }
  }
}






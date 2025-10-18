/// Utilitaires pour calculer la progression des projets
class ProgressUtils {
  
  /// Calcule le pourcentage de progression temporelle d'un projet
  /// basé sur la date de début, date de fin prévue et date actuelle
  static double calculateTimeProgress({
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
  }) {
    final now = DateTime.now();
    
    // Si pas de date de fin, impossible de calculer la progression temporelle
    if (endDate == null) {
      return 0.0;
    }
    
    // Utiliser la date de début si disponible, sinon la date de création, sinon maintenant
    final effectiveStartDate = startDate ?? createdAt ?? now;
    
    // Si le projet n'a pas encore commencé
    if (now.isBefore(effectiveStartDate)) {
      return 0.0;
    }
    
    // Si le projet est déjà terminé (date de fin dépassée)
    if (now.isAfter(endDate)) {
      return 1.0; // 100%
    }
    
    // Calculer la durée totale du projet
    final totalDuration = endDate.difference(effectiveStartDate).inDays;
    
    // Si la durée totale est de 0 jour ou moins (dates invalides)
    if (totalDuration <= 0) {
      return 1.0;
    }
    
    // Calculer le temps écoulé depuis le début
    final elapsedDuration = now.difference(effectiveStartDate).inDays;
    
    // Calculer le pourcentage (entre 0.0 et 1.0)
    final progress = elapsedDuration / totalDuration;
    
    // S'assurer que le résultat est entre 0.0 et 1.0
    return progress.clamp(0.0, 1.0);
  }
  
  /// Calcule le pourcentage de progression temporelle et retourne les informations détaillées
  static Map<String, dynamic> calculateTimeProgressDetails({
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
  }) {
    final now = DateTime.now();
    final progress = calculateTimeProgress(
      startDate: startDate,
      endDate: endDate,
      createdAt: createdAt,
    );
    
    if (endDate == null) {
      return {
        'progress': 0.0,
        'percentage': 0,
        'daysElapsed': 0,
        'totalDays': 0,
        'daysRemaining': 0,
        'isOverdue': false,
        'status': 'Pas de date de fin définie',
      };
    }
    
    final effectiveStartDate = startDate ?? createdAt ?? now;
    final totalDays = endDate.difference(effectiveStartDate).inDays;
    final daysElapsed = now.difference(effectiveStartDate).inDays;
    final daysRemaining = endDate.difference(now).inDays;
    final isOverdue = now.isAfter(endDate);
    
    String status;
    if (isOverdue) {
      status = 'En retard de ${(-daysRemaining)} jour${(-daysRemaining) > 1 ? 's' : ''}';
    } else if (daysRemaining == 0) {
      status = 'Se termine aujourd\'hui';
    } else if (daysRemaining == 1) {
      status = 'Se termine demain';
    } else {
      status = 'Reste ${daysRemaining} jour${daysRemaining > 1 ? 's' : ''}';
    }
    
    return {
      'progress': progress,
      'percentage': (progress * 100).round(),
      'daysElapsed': daysElapsed.clamp(0, totalDays),
      'totalDays': totalDays,
      'daysRemaining': daysRemaining,
      'isOverdue': isOverdue,
      'status': status,
    };
  }
  
  /// Détermine la couleur de la barre de progression selon l'avancement et le statut
  static String getTimeProgressColor(double timeProgress, bool isOverdue) {
    if (isOverdue) {
      return '#FF3B30'; // Rouge iOS pour en retard
    } else if (timeProgress >= 0.8) {
      return '#FF9500'; // Orange iOS pour fin proche
    } else if (timeProgress >= 0.5) {
      return '#FFCC00'; // Jaune iOS pour à mi-chemin
    } else {
      return '#34C759'; // Vert iOS pour dans les temps
    }
  }
  
  /// Calcule la progression des tâches (garde l'ancienne logique pour comparaison)
  static double calculateTaskProgress(List<Map<String, dynamic>> tasks) {
    if (tasks.isEmpty) return 0.0;
    
    final completedTasks = tasks.where((task) => 
      task['status'] == 'done' || task['status'] == 'completed'
    ).length;
    
    return completedTasks / tasks.length;
  }
} 
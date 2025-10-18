// Test de connexion Supabase
// Exécutez ce fichier pour tester la connexion

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Test de connexion avec vos credentials
  const String url = 'https://dswirxxbzbyhnxsrzyzi.supabase.co';
  const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzd2lyeHhiemJ5aG54c3J6eXppIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkxMTE0MTksImV4cCI6MjA2NDY4NzQxOX0.eIpOuCszUaldsiIxb9WzQcra34VbImWaRHx5lysPtOg';
  
  try {
    print('🔄 Test de connexion à Supabase...');
    print('URL: $url');
    
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: true,
    );
    
    final client = Supabase.instance.client;
    
    // Test simple de connexion
    final response = await client.from('auth.users').select('count').limit(1);
    
    print('✅ Connexion réussie !');
    print('Réponse: $response');
    
  } catch (e) {
    print('❌ Erreur de connexion: $e');
    
    if (e.toString().contains('Failed host lookup')) {
      print('🔍 Problème DNS - Le projet Supabase n\'existe plus ou est inaccessible');
      print('💡 Solution: Créer un nouveau projet Supabase');
    } else if (e.toString().contains('401')) {
      print('🔍 Problème d\'authentification - Clé API invalide');
    } else if (e.toString().contains('404')) {
      print('🔍 Projet non trouvé - URL incorrecte ou projet supprimé');
    }
  }
}

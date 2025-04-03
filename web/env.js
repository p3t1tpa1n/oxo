// Ce fichier est généré pendant le déploiement et contient les variables d'environnement injectées
window.ENV = {
  SUPABASE_URL: "__SUPABASE_URL__",
  SUPABASE_ANON_KEY: "__SUPABASE_ANON_KEY__"
};

// Logs de débogage
console.log("env.js chargé avec succès");
console.log("ENV disponible:", !!window.ENV);
console.log("SUPABASE_URL:", window.ENV.SUPABASE_URL);
console.log("SUPABASE_ANON_KEY (première partie):", window.ENV.SUPABASE_ANON_KEY ? window.ENV.SUPABASE_ANON_KEY.substring(0, 10) + "..." : "Non définie"); 
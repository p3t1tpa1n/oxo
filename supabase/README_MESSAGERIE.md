# 🚨 INSTALLATION REQUISE : Tables de Messagerie

**La messagerie ne fonctionnera pas tant que vous n'aurez pas exécuté le script SQL dans Supabase.**

## ⚡ Installation Rapide (2 minutes)

### Étape 1 : Ouvrez l'éditeur SQL de Supabase
1. Allez sur https://app.supabase.com
2. Connectez-vous et sélectionnez votre projet **Oxo**
3. Dans le menu de gauche, cliquez sur **"SQL Editor"**

### Étape 2 : Exécutez le script
1. **Copiez TOUT le contenu** du fichier `supabase/simple_messaging_setup.sql`
2. **Collez-le** dans l'éditeur SQL de Supabase
3. Cliquez sur le bouton **"Run"** (en haut à droite)

### Étape 3 : Vérifiez l'installation
Après exécution, vérifiez dans l'onglet **"Table Editor"** que vous avez :
- ✅ Table `conversations`
- ✅ Table `conversation_participants`
- ✅ Table `messages`

## 🔧 Script à utiliser

**Utilisez le fichier :** `supabase/simple_messaging_setup.sql`
*(Plus simple et plus fiable que fix_conversations_table.sql)*

## ❌ Messages d'erreur courants

### "column c.is_group does not exist"
➜ **Solution :** Exécutez le script SQL (les tables n'existent pas encore)

### "table already exists" 
➜ **Normal :** Le script gère cette situation automatiquement

### "function already exists"
➜ **Normal :** Le script recrée les fonctions automatiquement

### "permission denied"
➜ **Solution :** Assurez-vous d'être connecté comme propriétaire du projet

## 🧪 Test après installation

1. Redémarrez l'application Flutter
2. Allez dans la section **Messagerie**
3. Sélectionnez un utilisateur
4. ✅ Ça devrait maintenant fonctionner !

## 📞 Besoin d'aide ?

Si ça ne fonctionne toujours pas :
1. Vérifiez que toutes les tables sont créées dans Supabase
2. Vérifiez les logs de l'application Flutter
3. Assurez-vous que le script s'est exécuté sans erreur

---

**⏱️ Temps estimé : 2 minutes maximum** 
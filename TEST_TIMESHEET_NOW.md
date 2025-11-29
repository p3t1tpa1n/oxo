# 🧪 GUIDE DE TEST - MODULE TIMESHEET

## 🚀 Lancer l'Application

```bash
cd /Users/paul.p/Documents/develompent/oxo
flutter run
```

---

## ✅ Tests à Effectuer

### 1️⃣ **Menu Latéral**

#### Test 1.1: Vérifier la disparition de "Timesheet"
- [ ] Ouvrir le menu latéral
- [ ] **Vérifier:** L'onglet "Timesheet" n'existe plus
- [ ] **Vérifier:** "Saisie du temps" est directement visible

#### Test 1.2: Vérifier "Disponibilités" (Partenaires uniquement)
- [ ] Se connecter avec un compte **partenaire**
- [ ] **Vérifier:** L'onglet "Mes Disponibilités" est présent
- [ ] Cliquer dessus
- [ ] **Résultat attendu:** Page de disponibilités s'affiche

---

### 2️⃣ **Saisie du Temps**

#### Test 2.1: Dropdown Demi-journée/Journée
- [ ] Cliquer sur "Saisie du temps"
- [ ] Sélectionner une date (ex: 01/11)
- [ ] Cliquer sur le champ "Heures"
- [ ] **Vérifier:** Un dropdown s'affiche (pas un champ texte)
- [ ] **Vérifier:** 2 options uniquement:
  - Demi-journée (0.5)
  - Journée (1.0)

#### Test 2.2: Sélection Demi-journée
- [ ] Sélectionner "Demi-journée (0.5)"
- [ ] Sélectionner un client dans la liste
- [ ] **Vérifier:** La colonne "Tarif" affiche un montant (ex: 450.00)
- [ ] **Vérifier:** La colonne "Montant" affiche la moitié (ex: 225.00)

#### Test 2.3: Sélection Journée
- [ ] Sélectionner "Journée (1.0)"
- [ ] Sélectionner un client dans la liste
- [ ] **Vérifier:** La colonne "Tarif" affiche un montant (ex: 450.00)
- [ ] **Vérifier:** La colonne "Montant" affiche le total (ex: 450.00)

#### Test 2.4: Enregistrement
- [ ] Remplir tous les champs:
  - Client: [Sélectionner un client]
  - Durée: [Demi-journée ou Journée]
  - Commentaire: "Test saisie"
- [ ] Cliquer sur le bouton "Enregistrer" (icône disquette verte)
- [ ] **Résultat attendu:** Message "✅ Saisie enregistrée"
- [ ] **Vérifier:** La ligne devient non-éditable
- [ ] **Vérifier:** Les valeurs sont conservées

#### Test 2.5: Validation
- [ ] Essayer d'enregistrer sans sélectionner de durée
- [ ] **Résultat attendu:** Message d'erreur "Veuillez sélectionner une durée"
- [ ] Essayer d'enregistrer sans sélectionner de client
- [ ] **Résultat attendu:** Message d'erreur "Veuillez sélectionner un client"

---

### 3️⃣ **Paramètres Timesheet** (Associés uniquement)

#### Test 3.1: Accès à la page
- [ ] Se connecter avec un compte **associé**
- [ ] Cliquer sur "Paramètres Timesheet"
- [ ] **Résultat attendu:** Page avec 2 onglets:
  - Tarifs Journaliers
  - Autorisations Clients

#### Test 3.2: Onglet "Tarifs Journaliers"
- [ ] Cliquer sur "Tarifs Journaliers"
- [ ] **Vérifier:** Liste des tarifs existants s'affiche
- [ ] Cliquer sur "Ajouter un tarif"
- [ ] **Vérifier:** Formulaire s'affiche avec:
  - Dropdown "Partenaire"
  - Dropdown "Client"
  - Champ "Tarif journalier"
  - Dates de validité

#### Test 3.3: Création d'un tarif
- [ ] Sélectionner un partenaire
- [ ] Sélectionner un client
- [ ] Saisir un tarif (ex: 500)
- [ ] Sélectionner une date de début
- [ ] Cliquer sur "Enregistrer"
- [ ] **Résultat attendu:** Message "✅ Tarif créé avec succès"
- [ ] **Vérifier:** Le nouveau tarif apparaît dans la liste

#### Test 3.4: Onglet "Autorisations Clients"
- [ ] Cliquer sur "Autorisations Clients"
- [ ] **Vérifier:** Liste des autorisations existantes s'affiche
- [ ] Cliquer sur "Ajouter une autorisation"
- [ ] **Vérifier:** Formulaire s'affiche avec:
  - Dropdown "Partenaire"
  - Dropdown "Client"

#### Test 3.5: Création d'une autorisation
- [ ] Sélectionner un partenaire
- [ ] Sélectionner un client
- [ ] Cliquer sur "Enregistrer"
- [ ] **Résultat attendu:** Message "✅ Autorisation créée avec succès"
- [ ] **Vérifier:** La nouvelle autorisation apparaît dans la liste

---

### 4️⃣ **Reporting Timesheet** (Associés uniquement)

#### Test 4.1: Accès à la page
- [ ] Se connecter avec un compte **associé**
- [ ] Cliquer sur "Reporting Timesheet"
- [ ] **Résultat attendu:** Page avec 3 onglets:
  - Timesheet
  - Disponibilités
  - (Autres)

#### Test 4.2: Onglet "Timesheet"
- [ ] Cliquer sur "Timesheet"
- [ ] **Vérifier:** Statistiques affichées:
  - Total Entrées
  - Total Jours (au lieu de "Total Heures")
  - Partenaires Actifs
  - Moyenne/Entrée

#### Test 4.3: Filtres
- [ ] Sélectionner un partenaire dans le dropdown
- [ ] Sélectionner un statut
- [ ] Sélectionner des dates
- [ ] Cliquer sur "Réinitialiser"
- [ ] **Résultat attendu:** Filtres sont réinitialisés

#### Test 4.4: Tableau des entrées
- [ ] **Vérifier:** Colonnes affichées:
  - Date
  - Jour
  - Client / Affaire
  - Jours (au lieu de "Heures")
  - Commentaire
  - Tarif
  - Montant
  - Actions

---

## 🎯 Scénario Complet (End-to-End)

### Scénario: Créer une saisie complète

1. **Préparation (Associé)**
   - [ ] Se connecter en tant qu'**associé**
   - [ ] Aller dans "Paramètres Timesheet"
   - [ ] Créer un tarif: Partenaire X + Client Y = 450€/jour
   - [ ] Créer une autorisation: Partenaire X → Client Y

2. **Saisie (Partenaire)**
   - [ ] Se déconnecter
   - [ ] Se connecter en tant que **partenaire X**
   - [ ] Aller dans "Saisie du temps"
   - [ ] Sélectionner la date du jour
   - [ ] Sélectionner "Client Y" (autorisé)
   - [ ] Sélectionner "Journée (1.0)"
   - [ ] Ajouter un commentaire: "Développement module timesheet"
   - [ ] Cliquer sur "Enregistrer"
   - [ ] **Vérifier:** Tarif = 450€, Montant = 450€

3. **Vérification (Associé)**
   - [ ] Se déconnecter
   - [ ] Se connecter en tant qu'**associé**
   - [ ] Aller dans "Reporting Timesheet"
   - [ ] Filtrer par "Partenaire X"
   - [ ] **Vérifier:** L'entrée apparaît dans le tableau
   - [ ] **Vérifier:** Total Jours = 1.0 j
   - [ ] **Vérifier:** Montant = 450.00 €

4. **Modification (Partenaire)**
   - [ ] Se déconnecter
   - [ ] Se connecter en tant que **partenaire X**
   - [ ] Aller dans "Saisie du temps"
   - [ ] Trouver l'entrée créée
   - [ ] Modifier la durée: "Demi-journée (0.5)"
   - [ ] Cliquer sur "Enregistrer"
   - [ ] **Vérifier:** Montant = 225€ (450 × 0.5)

5. **Validation Finale (Associé)**
   - [ ] Se déconnecter
   - [ ] Se connecter en tant qu'**associé**
   - [ ] Aller dans "Reporting Timesheet"
   - [ ] **Vérifier:** Total Jours = 0.5 j
   - [ ] **Vérifier:** Montant = 225.00 €

---

## 🐛 Problèmes Connus à Vérifier

### Si "Paramètres Timesheet" ne charge pas:
```
Erreur possible: get_users() ne retourne pas les bons champs
Solution: Vérifier les logs Flutter
```

### Si les tarifs ne s'affichent pas:
```
Erreur possible: Aucune autorisation client créée
Solution: Créer d'abord une autorisation dans "Paramètres Timesheet"
```

### Si le dropdown ne s'affiche pas:
```
Erreur possible: Cache Flutter
Solution: flutter clean && flutter run
```

---

## 📊 Checklist Finale

| Fonctionnalité | Statut |
|----------------|--------|
| Menu sans "Timesheet" | ⬜ |
| Dropdown Demi-journée/Journée | ⬜ |
| Calcul Tarif correct | ⬜ |
| Calcul Montant correct | ⬜ |
| Enregistrement fonctionne | ⬜ |
| Paramètres Timesheet charge | ⬜ |
| Création tarif fonctionne | ⬜ |
| Création autorisation fonctionne | ⬜ |
| Reporting affiche "Jours" | ⬜ |
| Scénario E2E complet | ⬜ |

---

## 🎉 Résultat Attendu

Tous les tests doivent être ✅ **PASSÉS** pour valider le module.

**Bon test ! 🚀**



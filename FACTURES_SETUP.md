# 🧾 Système de Facturation - Documentation

## Vue d'ensemble

Le système de facturation a été intégré au projet oxo pour permettre aux associés de créer et gérer des factures pour leurs clients. Ce système s'intègre parfaitement avec le système multi-tenancy par entreprise déjà en place.

## ✨ Fonctionnalités

### 🔧 Côté Associé/Admin
- **Gestion clients améliorée** : Visualisation des clients avec leurs informations d'entreprise
- **Création de factures** : Interface intuitive pour créer des factures directement depuis la page clients
- **Calcul automatique** : TVA et montant total calculés automatiquement
- **Liaison projets** : Possibilité de lier une facture à un projet existant
- **Gestion des statuts** : Brouillon, Envoyée, En attente, Payée, En retard, Annulée

### 👤 Côté Client
- **Consultation des factures** : Page dédiée pour voir toutes leurs factures
- **Résumé financier** : Cartes avec total facturé, montant en attente, montant payé
- **Actions disponibles** : Visualiser, télécharger, payer en ligne
- **Statuts visuels** : Codes couleur pour identifier rapidement l'état des factures

## 🗄️ Structure de la Base de Données

### Table `invoices`

```sql
CREATE TABLE public.invoices (
    id BIGSERIAL PRIMARY KEY,
    invoice_number VARCHAR(50) UNIQUE NOT NULL,  -- Auto-généré (INV-2024-001)
    company_id BIGINT NOT NULL,                  -- Lien vers l'entreprise
    client_user_id UUID,                         -- Lien vers l'utilisateur client
    project_id BIGINT,                          -- Lien optionnel vers un projet
    
    -- Détails financiers
    title VARCHAR(255) NOT NULL,
    description TEXT,
    amount DECIMAL(10,2) NOT NULL,               -- Montant HT
    tax_rate DECIMAL(5,2) DEFAULT 20.00,         -- Taux TVA
    tax_amount DECIMAL(10,2),                    -- Montant TVA (calculé)
    total_amount DECIMAL(10,2),                  -- Montant TTC (calculé)
    
    -- Dates
    invoice_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL,
    
    -- Statut et paiement
    status VARCHAR(20) DEFAULT 'draft',
    payment_method VARCHAR(50),
    payment_date DATE,
    payment_reference VARCHAR(255),
    
    -- Métadonnées
    created_by UUID NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Vue `invoice_details`

Vue enrichie qui joint les informations :
- Entreprise (nom)
- Client (nom complet, email)
- Projet (nom)
- Créateur (nom complet)

### Fonctions automatiques

1. **Génération numéro de facture** : `generate_invoice_number()`
   - Format : `INV-YYYY-NNN` (ex: INV-2024-001)
   - Incrémentation automatique par année

2. **Mise à jour statuts** : `update_invoice_status()`
   - Marque automatiquement les factures en retard
   - Transition sent → pending

## 🔒 Sécurité (RLS)

### Politiques d'accès

- **Admins/Associés** : Accès complet (lecture, création, modification)
- **Clients** : Lecture uniquement de leurs propres factures
- **Partenaires** : Lecture des factures de leur entreprise
- **Suppression** : Admins uniquement

### Intégration Multi-tenancy

- Chaque facture est liée à une entreprise (`company_id`)
- Filtrage automatique par entreprise selon l'utilisateur connecté
- Respect des politiques RLS existantes

## 🚀 Installation

### 1. Exécuter le script SQL

```bash
# Dans l'éditeur SQL de Supabase
```

Exécutez le contenu du fichier `supabase/create_invoices_table.sql`

### 2. Vérification

Après exécution, vous devriez voir :
- ✅ Table `invoices` créée
- ✅ Vue `invoice_details` disponible
- ✅ Politiques RLS actives
- ✅ Fonctions automatiques opérationnelles
- ✅ Données de démonstration (optionnel)

## 🔧 API (SupabaseService)

### Méthodes disponibles

```dart
// Récupération
static Future<List<Map<String, dynamic>>> getAllInvoices()
static Future<List<Map<String, dynamic>>> getClientInvoices([String? clientUserId])

// Création/Modification
static Future<Map<String, dynamic>?> createInvoice({...})
static Future<void> updateInvoice(int invoiceId, Map<String, dynamic> updates)
static Future<void> deleteInvoice(int invoiceId)

// Actions spéciales
static Future<void> markInvoiceAsPaid(int invoiceId, {...})
```

### Exemple d'utilisation

```dart
// Créer une facture
await SupabaseService.createInvoice(
  clientUserId: 'uuid-client',
  title: 'Services de développement',
  description: 'Développement application mobile',
  amount: 2500.00,
  dueDate: DateTime.now().add(Duration(days: 30)),
  projectId: 123,
  taxRate: 20.0,
  status: 'draft',
);

// Récupérer les factures d'un client
final factures = await SupabaseService.getClientInvoices('uuid-client');
```

## 📱 Interface Utilisateur

### Page Clients (Associés)

**Nouvelles fonctionnalités :**
- ✅ Affichage correct des clients depuis `user_company_info`
- ✅ Bouton "Créer une facture" sur chaque client
- ✅ Modal de création de facture complet
- ✅ Sélection de projet dans le formulaire
- ✅ Calcul automatique TVA/Total
- ✅ Sélection des dates (facture + échéance)

### Page Factures (Clients)

**Fonctionnalités :**
- ✅ Résumé financier avec cartes statistiques
- ✅ Liste des factures avec statuts visuels
- ✅ Actions : Voir, Télécharger, Payer
- ✅ Gestion des factures en retard
- ✅ Interface responsive et moderne

## 📊 Statuts des Factures

| Statut | Description | Couleur | Actions |
|--------|-------------|---------|---------|
| `draft` | Brouillon | Gris | Modifier, Envoyer |
| `sent` | Envoyée | Bleu | Voir, Télécharger |
| `pending` | En attente | Orange | Voir, Télécharger, Payer |
| `paid` | Payée | Vert | Voir, Télécharger |
| `overdue` | En retard | Rouge | Voir, Télécharger, Payer |
| `cancelled` | Annulée | Rouge foncé | Voir uniquement |

## 🔄 Workflow Type

1. **Associé** crée une facture pour un client
2. Facture en statut `draft` → possibilité de modification
3. Associé passe en `sent` → facture envoyée au client
4. Automatiquement `pending` à la date de facture
5. Client consulte et peut payer en ligne
6. Statut `paid` une fois le paiement confirmé
7. Si échéance dépassée → automatiquement `overdue`

## ⚙️ Configuration

### Variables importantes

```dart
// Taux de TVA par défaut
tax_rate: 20.00

// Délai d'échéance par défaut
due_date: +30 jours

// Format numéro de facture
invoice_number: 'INV-YYYY-NNN'
```

### Personnalisation

Pour adapter le système :
1. Modifier les statuts disponibles dans les contraintes SQL
2. Ajuster les taux de TVA par défaut
3. Personnaliser le format des numéros de facture
4. Ajouter des champs personnalisés selon les besoins

## 🚨 Notes Importantes

- **Sécurité** : Toutes les opérations respectent les politiques RLS
- **Performance** : Index créés sur les colonnes principales
- **Compatibilité** : S'intègre avec le système multi-tenancy existant
- **Évolutivité** : Structure extensible pour futures fonctionnalités

## 📝 TODO Future

- [ ] Génération PDF des factures
- [ ] Intégration paiement en ligne (Stripe/PayPal)
- [ ] Templates de factures personnalisables
- [ ] Relances automatiques
- [ ] Rapports financiers avancés
- [ ] Export comptable (CSV/Excel)

---

🎉 **Le système de facturation est maintenant opérationnel !** 
#!/bin/bash

# ============================================================================
# Script d'Exécution des Migrations Supabase
# ============================================================================
# Usage: ./run_migrations.sh [test|prod] [all|1|2|3|4]
# 
# Exemples:
#   ./run_migrations.sh test all    # Exécute toutes les migrations en test
#   ./run_migrations.sh test 1      # Exécute seulement la migration 1 en test
#   ./run_migrations.sh prod all    # Exécute toutes les migrations en prod
# ============================================================================

set -e  # Arrêter en cas d'erreur

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Chemins
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MIGRATIONS_DIR="$SCRIPT_DIR"

# Fichiers de migration
MIGRATION_1="20251007_fix_schema_issues_part1_structure.sql"
MIGRATION_2="20251007_fix_schema_issues_part2_rls.sql"
MIGRATION_3="20251007_fix_schema_issues_part3_data_functions.sql"
MIGRATION_4="20251007_fix_schema_issues_part4_optional_cleanup.sql"

# ============================================================================
# Fonctions utilitaires
# ============================================================================

print_header() {
    echo -e "\n${BLUE}================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# ============================================================================
# Vérifications préalables
# ============================================================================

check_prerequisites() {
    print_header "Vérification des prérequis"
    
    # Vérifier que supabase CLI est installé
    if ! command -v supabase &> /dev/null; then
        print_error "Supabase CLI n'est pas installé"
        echo "Installer avec: brew install supabase/tap/supabase"
        exit 1
    fi
    print_success "Supabase CLI installé"
    
    # Vérifier que les fichiers de migration existent
    for file in "$MIGRATION_1" "$MIGRATION_2" "$MIGRATION_3" "$MIGRATION_4"; do
        if [ ! -f "$MIGRATIONS_DIR/$file" ]; then
            print_error "Fichier de migration manquant: $file"
            exit 1
        fi
    done
    print_success "Tous les fichiers de migration sont présents"
}

# ============================================================================
# Création de sauvegarde
# ============================================================================

create_backup() {
    local env=$1
    print_header "Création de la sauvegarde ($env)"
    
    local backup_file="backup_${env}_$(date +%Y%m%d_%H%M%S).sql"
    local backup_path="$PROJECT_ROOT/backups/$backup_file"
    
    # Créer le dossier backups s'il n'existe pas
    mkdir -p "$PROJECT_ROOT/backups"
    
    print_info "Création de la sauvegarde: $backup_file"
    
    if [ "$env" = "test" ]; then
        supabase db dump > "$backup_path" 2>&1
    else
        # Pour la prod, utiliser le project-ref
        print_warning "Pour la production, créez d'abord une sauvegarde depuis l'interface Supabase"
        read -p "Avez-vous créé une sauvegarde de la prod ? (oui/non) " -n 3 -r
        echo
        if [[ ! $REPLY =~ ^[Oo][Uu][Ii]$ ]]; then
            print_error "Sauvegarde requise avant de continuer"
            exit 1
        fi
    fi
    
    print_success "Sauvegarde créée"
}

# ============================================================================
# Exécution d'une migration
# ============================================================================

run_migration() {
    local migration_file=$1
    local migration_name=$2
    
    print_header "Exécution: $migration_name"
    
    local migration_path="$MIGRATIONS_DIR/$migration_file"
    
    if [ ! -f "$migration_path" ]; then
        print_error "Fichier non trouvé: $migration_path"
        return 1
    fi
    
    print_info "Exécution de $migration_file..."
    
    # Exécuter la migration
    if supabase db execute < "$migration_path"; then
        print_success "Migration $migration_name terminée avec succès"
        return 0
    else
        print_error "Erreur lors de l'exécution de la migration $migration_name"
        return 1
    fi
}

# ============================================================================
# Vérifications post-migration
# ============================================================================

run_verifications() {
    print_header "Vérifications post-migration"
    
    print_info "Vérification des foreign keys..."
    supabase db execute <<EOF
DO \$\$
DECLARE
    fk_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO fk_count
    FROM information_schema.table_constraints
    WHERE constraint_type = 'FOREIGN KEY'
      AND table_schema = 'public';
    
    RAISE NOTICE 'Foreign keys créées: %', fk_count;
END \$\$;
EOF
    
    print_info "Vérification des politiques RLS..."
    supabase db execute <<EOF
DO \$\$
DECLARE
    policy_count INTEGER;
    public_policies INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE schemaname = 'public';
    
    SELECT COUNT(*) INTO public_policies
    FROM pg_policies
    WHERE schemaname = 'public'
      AND 'public' = ANY(roles);
    
    RAISE NOTICE 'Politiques RLS: %', policy_count;
    
    IF public_policies > 0 THEN
        RAISE WARNING '% politiques utilisent encore le rôle public', public_policies;
    ELSE
        RAISE NOTICE 'Aucune politique n''utilise le rôle public ✓';
    END IF;
END \$\$;
EOF
    
    print_info "Vérification des fonctions..."
    supabase db execute <<EOF
DO \$\$
DECLARE
    functions_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO functions_count
    FROM pg_proc
    WHERE proname IN (
      'get_user_company_id',
      'can_message_user',
      'can_participate_in_conversation',
      'get_user_role',
      'is_admin_or_associate'
    )
    AND pronamespace = 'public'::regnamespace;
    
    RAISE NOTICE 'Fonctions RLS créées: %/5', functions_count;
END \$\$;
EOF
    
    print_success "Vérifications terminées"
}

# ============================================================================
# Menu principal
# ============================================================================

show_menu() {
    echo ""
    echo "==================================================="
    echo "    Script de Migration Supabase - OXO App"
    echo "==================================================="
    echo ""
    echo "Migrations disponibles:"
    echo "  1. Structure (Foreign keys, index, contraintes)"
    echo "  2. RLS (Politiques de sécurité)"
    echo "  3. Fonctions (Fonctions RLS, soft delete)"
    echo "  4. Cleanup (OPTIONNEL - Suppression user_roles)"
    echo "  all. Exécuter toutes les migrations obligatoires (1-3)"
    echo ""
    echo "Environnements:"
    echo "  - test: Base de données locale/dev"
    echo "  - prod: Base de données production (ATTENTION!)"
    echo ""
    echo "==================================================="
    echo ""
}

# ============================================================================
# Point d'entrée principal
# ============================================================================

main() {
    # Vérifier les arguments
    if [ $# -lt 2 ]; then
        show_menu
        echo "Usage: $0 [test|prod] [all|1|2|3|4]"
        echo ""
        echo "Exemples:"
        echo "  $0 test all    # Toutes les migrations en test"
        echo "  $0 test 1      # Migration 1 seulement en test"
        echo "  $0 prod all    # Toutes les migrations en prod"
        echo ""
        exit 1
    fi
    
    local env=$1
    local migration=$2
    
    # Valider l'environnement
    if [ "$env" != "test" ] && [ "$env" != "prod" ]; then
        print_error "Environnement invalide: $env (utilisez 'test' ou 'prod')"
        exit 1
    fi
    
    # Avertissement pour la prod
    if [ "$env" = "prod" ]; then
        print_warning "ATTENTION: Vous êtes sur le point de modifier la base de données de PRODUCTION !"
        read -p "Êtes-vous ABSOLUMENT sûr de vouloir continuer ? (tapez 'OUI' en majuscules) " -r
        echo
        if [ "$REPLY" != "OUI" ]; then
            print_info "Migration annulée"
            exit 0
        fi
    fi
    
    # Vérifier les prérequis
    check_prerequisites
    
    # Créer une sauvegarde
    create_backup "$env"
    
    # Exécuter les migrations
    case "$migration" in
        1)
            run_migration "$MIGRATION_1" "Part 1 - Structure"
            ;;
        2)
            run_migration "$MIGRATION_2" "Part 2 - RLS"
            ;;
        3)
            run_migration "$MIGRATION_3" "Part 3 - Fonctions"
            ;;
        4)
            print_warning "Migration 4 est OPTIONNELLE et DESTRUCTIVE"
            print_warning "Lisez le fichier $MIGRATION_4 avant de continuer"
            read -p "Voulez-vous vraiment exécuter la migration 4 ? (oui/non) " -n 3 -r
            echo
            if [[ $REPLY =~ ^[Oo][Uu][Ii]$ ]]; then
                run_migration "$MIGRATION_4" "Part 4 - Cleanup (OPTIONNEL)"
            else
                print_info "Migration 4 ignorée"
            fi
            ;;
        all)
            print_header "Exécution de toutes les migrations obligatoires"
            
            if run_migration "$MIGRATION_1" "Part 1 - Structure" && \
               run_migration "$MIGRATION_2" "Part 2 - RLS" && \
               run_migration "$MIGRATION_3" "Part 3 - Fonctions"; then
                print_success "Toutes les migrations ont été exécutées avec succès"
            else
                print_error "Une erreur est survenue lors des migrations"
                exit 1
            fi
            ;;
        *)
            print_error "Migration invalide: $migration (utilisez all, 1, 2, 3 ou 4)"
            exit 1
            ;;
    esac
    
    # Vérifications
    run_verifications
    
    # Message final
    print_header "Migration terminée !"
    print_info "Prochaines étapes:"
    echo "  1. Testez votre application Flutter"
    echo "  2. Vérifiez que toutes les fonctionnalités marchent"
    echo "  3. Consultez README_MIGRATIONS.md pour les détails"
    echo "  4. Mettez à jour votre code Dart si nécessaire"
    echo ""
    print_success "Migration complète"
}

# Exécuter le script
main "$@"



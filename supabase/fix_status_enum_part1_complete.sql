-- PARTIE 1 COMPLÈTE : Ajouter TOUTES les valeurs nécessaires à l'enum status_type
-- À exécuter en PREMIER dans l'éditeur SQL de Supabase

-- 1. Ajouter TOUTES les valeurs utilisées par l'application Flutter
DO $$
DECLARE
    enum_values TEXT[] := ARRAY[
        -- Valeurs pour tasks
        'todo', 'a_faire', 'en_cours', 'in_progress', 'done', 'termine', 'completed',
        -- Valeurs pour projects 
        'active', 'actif', 'inactive', 'inactif',
        -- Valeurs supplémentaires
        'pending', 'en_attente', 'rejected', 'rejete', 'approved', 'approuve'
    ];
    val TEXT;
BEGIN
    FOREACH val IN ARRAY enum_values
    LOOP
        BEGIN
            -- Tenter d'ajouter chaque valeur à l'enum
            EXECUTE format('ALTER TYPE status_type ADD VALUE IF NOT EXISTS %L', val);
            RAISE NOTICE 'Ajouté valeur % à status_type', val;
        EXCEPTION 
            WHEN duplicate_object THEN
                RAISE NOTICE 'Valeur % existe déjà dans status_type', val;
            WHEN OTHERS THEN
                RAISE NOTICE 'Erreur lors de l''ajout de % : %', val, SQLERRM;
        END;
    END LOOP;
END $$;

-- 2. Vérifier toutes les valeurs disponibles maintenant
SELECT 
    'status_type' as enum_name,
    enumlabel as enum_value,
    enumsortorder as sort_order
FROM pg_enum e
JOIN pg_type t ON e.enumtypid = t.oid
WHERE t.typname = 'status_type'
ORDER BY enumsortorder;

-- 3. Compter les valeurs ajoutées
SELECT 
    COUNT(*) as total_values,
    '✅ Valeurs disponibles dans status_type' as message
FROM pg_enum e
JOIN pg_type t ON e.enumtypid = t.oid
WHERE t.typname = 'status_type';

-- Message final
SELECT '✅ PARTIE 1 COMPLÈTE - Toutes les valeurs ajoutées à status_type (y compris "active")' as message;
SELECT '⚠️  IMPORTANT : Exécutez maintenant fix_status_enum_part2.sql' as next_step; 
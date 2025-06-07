-- PARTIE 1 : Ajouter les nouvelles valeurs à l'enum status_type
-- À exécuter en PREMIER dans l'éditeur SQL de Supabase

-- 1. Ajouter les valeurs manquantes à l'enum status_type existant
DO $$
DECLARE
    enum_values TEXT[] := ARRAY['todo', 'a_faire', 'en_cours', 'in_progress', 'done', 'termine', 'completed'];
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

-- 2. Vérifier les nouvelles valeurs ajoutées
SELECT 
    'status_type' as enum_name,
    enumlabel as enum_value,
    enumsortorder as sort_order
FROM pg_enum e
JOIN pg_type t ON e.enumtypid = t.oid
WHERE t.typname = 'status_type'
ORDER BY enumsortorder;

-- Message
SELECT '✅ PARTIE 1 TERMINÉE - Nouvelles valeurs ajoutées à status_type' as message;
SELECT '⚠️  IMPORTANT : Exécutez maintenant fix_status_enum_part2.sql' as next_step; 
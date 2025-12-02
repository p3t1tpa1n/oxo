-- ============================================================================
-- FIX COMPLET: Sauvegarde Timesheet avec mission_id
-- ============================================================================
-- EXÉCUTEZ CE SCRIPT DANS SUPABASE SQL EDITOR
-- ============================================================================

-- 1. Vérifier et ajouter la colonne mission_id si elle n'existe pas
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'timesheet_entries' 
        AND column_name = 'mission_id'
    ) THEN
        ALTER TABLE public.timesheet_entries 
        ADD COLUMN mission_id UUID REFERENCES public.missions(id) ON DELETE SET NULL;
        
        RAISE NOTICE '✅ Colonne mission_id ajoutée à timesheet_entries';
    ELSE
        RAISE NOTICE '✅ Colonne mission_id existe déjà';
    END IF;
END $$;

-- 2. Créer l'index sur mission_id s'il n'existe pas
CREATE INDEX IF NOT EXISTS idx_timesheet_entries_mission_id 
ON public.timesheet_entries(mission_id);

-- 3. Vérifier la structure actuelle de la table
SELECT 
    'Structure de la table timesheet_entries' as info,
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'timesheet_entries'
ORDER BY ordinal_position;

-- 4. Supprimer la contrainte de jours si elle est trop restrictive
DO $$ 
BEGIN
    -- Supprimer la contrainte sur days si elle existe
    ALTER TABLE public.timesheet_entries 
    DROP CONSTRAINT IF EXISTS timesheet_entries_days_check;
    
    ALTER TABLE public.timesheet_entries 
    DROP CONSTRAINT IF EXISTS timesheet_entries_hours_check;
    
    RAISE NOTICE '✅ Contraintes restrictives supprimées';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '⚠️ Pas de contrainte à supprimer';
END $$;

-- 5. S'assurer que la colonne days existe et accepte des valeurs
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'timesheet_entries' 
        AND column_name = 'days'
    ) THEN
        -- Si 'days' n'existe pas mais 'hours' existe, renommer
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'timesheet_entries' 
            AND column_name = 'hours'
        ) THEN
            ALTER TABLE public.timesheet_entries RENAME COLUMN hours TO days;
            RAISE NOTICE '✅ Colonne hours renommée en days';
        ELSE
            ALTER TABLE public.timesheet_entries 
            ADD COLUMN days DECIMAL(4,2) DEFAULT 1.0;
            RAISE NOTICE '✅ Colonne days ajoutée';
        END IF;
    ELSE
        RAISE NOTICE '✅ Colonne days existe déjà';
    END IF;
END $$;

-- 6. Désactiver temporairement RLS pour debug (à réactiver après)
-- ALTER TABLE public.timesheet_entries DISABLE ROW LEVEL SECURITY;

-- 7. Supprimer TOUTES les politiques existantes
DO $$ 
DECLARE
    pol record;
BEGIN
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'timesheet_entries' 
        AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.timesheet_entries', pol.policyname);
        RAISE NOTICE 'Politique supprimée: %', pol.policyname;
    END LOOP;
END $$;

-- 8. Créer des politiques RLS simplifiées
-- Politique pour SELECT (tous les utilisateurs authentifiés peuvent voir leurs entrées)
CREATE POLICY "timesheet_select_own"
ON public.timesheet_entries FOR SELECT
TO authenticated
USING (partner_id = auth.uid());

-- Politique pour INSERT (tous les utilisateurs authentifiés peuvent créer)
CREATE POLICY "timesheet_insert_own"
ON public.timesheet_entries FOR INSERT
TO authenticated
WITH CHECK (partner_id = auth.uid());

-- Politique pour UPDATE (tous les utilisateurs authentifiés peuvent modifier leurs entrées)
CREATE POLICY "timesheet_update_own"
ON public.timesheet_entries FOR UPDATE
TO authenticated
USING (partner_id = auth.uid())
WITH CHECK (partner_id = auth.uid());

-- Politique pour DELETE (tous les utilisateurs authentifiés peuvent supprimer leurs entrées)
CREATE POLICY "timesheet_delete_own"
ON public.timesheet_entries FOR DELETE
TO authenticated
USING (partner_id = auth.uid());

-- 9. Politique pour les associés (voir tout)
CREATE POLICY "timesheet_associe_all"
ON public.timesheet_entries FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.user_id = auth.uid()
        AND profiles.role = 'associe'
    )
);

-- 10. Réactiver RLS
ALTER TABLE public.timesheet_entries ENABLE ROW LEVEL SECURITY;

-- 11. Vérifier les politiques créées
SELECT 
    'Politiques RLS créées' as info,
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename = 'timesheet_entries'
AND schemaname = 'public'
ORDER BY policyname;

-- 12. Test d'insertion (commenté, à adapter)
/*
INSERT INTO public.timesheet_entries (
    partner_id, 
    mission_id, 
    entry_date, 
    days, 
    daily_rate, 
    is_weekend, 
    status
) VALUES (
    auth.uid(),
    'VOTRE-MISSION-ID-ICI',
    '2025-12-01',
    1.0,
    450.0,
    false,
    'draft'
);
*/

-- 13. Afficher un résumé
DO $$
DECLARE
    col_count INTEGER;
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO col_count
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'timesheet_entries';
    
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE tablename = 'timesheet_entries'
    AND schemaname = 'public';
    
    RAISE NOTICE '';
    RAISE NOTICE '════════════════════════════════════════════════════════';
    RAISE NOTICE '✅ CONFIGURATION TERMINÉE';
    RAISE NOTICE '════════════════════════════════════════════════════════';
    RAISE NOTICE '📊 Colonnes dans timesheet_entries: %', col_count;
    RAISE NOTICE '🔒 Politiques RLS actives: %', policy_count;
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  Vérifiez que mission_id est présent dans la structure';
    RAISE NOTICE '════════════════════════════════════════════════════════';
END $$;


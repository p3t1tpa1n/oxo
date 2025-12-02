-- ============================================================================
-- 🚨 URGENT: EXÉCUTEZ CE SCRIPT DANS SUPABASE SQL EDITOR
-- ============================================================================

-- 1. VÉRIFIER LA STRUCTURE DE timesheet_entries
SELECT 
    '📊 STRUCTURE timesheet_entries' as info,
    column_name, 
    data_type
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'timesheet_entries'
ORDER BY ordinal_position;

-- 2. AJOUTER mission_id SI MANQUANT
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'timesheet_entries' 
        AND column_name = 'mission_id'
    ) THEN
        ALTER TABLE public.timesheet_entries 
        ADD COLUMN mission_id UUID;
        RAISE NOTICE '✅ Colonne mission_id AJOUTÉE';
    ELSE
        RAISE NOTICE '✅ Colonne mission_id existe déjà';
    END IF;
END $$;

-- 3. AJOUTER assigned_to À LA TABLE missions SI MANQUANT
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'missions' 
        AND column_name = 'assigned_to'
    ) THEN
        ALTER TABLE public.missions 
        ADD COLUMN assigned_to UUID;
        RAISE NOTICE '✅ Colonne assigned_to AJOUTÉE à missions';
    ELSE
        RAISE NOTICE '✅ Colonne assigned_to existe déjà';
    END IF;
END $$;

-- 4. SUPPRIMER TOUTES LES POLITIQUES RLS EXISTANTES
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
    END LOOP;
    RAISE NOTICE '✅ Anciennes politiques supprimées';
END $$;

-- 5. CRÉER POLITIQUES SIMPLES
-- SELECT: voir ses propres entrées
CREATE POLICY "ts_select" ON public.timesheet_entries 
FOR SELECT TO authenticated
USING (partner_id = auth.uid());

-- INSERT: créer ses propres entrées
CREATE POLICY "ts_insert" ON public.timesheet_entries 
FOR INSERT TO authenticated
WITH CHECK (partner_id = auth.uid());

-- UPDATE: modifier ses entrées
CREATE POLICY "ts_update" ON public.timesheet_entries 
FOR UPDATE TO authenticated
USING (partner_id = auth.uid());

-- DELETE: supprimer ses entrées
CREATE POLICY "ts_delete" ON public.timesheet_entries 
FOR DELETE TO authenticated
USING (partner_id = auth.uid());

-- Associés voient tout
CREATE POLICY "ts_associe" ON public.timesheet_entries 
FOR ALL TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.user_id = auth.uid()
        AND profiles.role = 'associe'
    )
);

-- 6. ACTIVER RLS
ALTER TABLE public.timesheet_entries ENABLE ROW LEVEL SECURITY;

-- 7. TEST: Insérer une entrée test
-- Remplacez les UUID par les vrais IDs
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
    'bbfd419c-4c15-4ad6-8f34-0fad1f9092c7',  -- partner_id (part@gmail.com)
    '27cd5d1d-8d24-4e9b-8c56-fe67afe3d2d2',  -- mission_id (TEST ALL)
    '2025-12-01',
    1.0,
    450.0,
    false,
    'draft'
);
*/

-- 8. VÉRIFICATION FINALE
SELECT '🔒 POLITIQUES RLS' as info, policyname, cmd
FROM pg_policies 
WHERE tablename = 'timesheet_entries'
ORDER BY policyname;

SELECT '✅ CONFIGURATION TERMINÉE' as resultat;


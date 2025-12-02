-- ============================================================================
-- 🚨 FIX URGENT: Rendre client_id nullable dans timesheet_entries
-- ============================================================================
-- EXÉCUTEZ CE SCRIPT MAINTENANT DANS SUPABASE SQL EDITOR
-- ============================================================================

-- 1. Rendre client_id NULLABLE (car on utilise mission_id maintenant)
ALTER TABLE public.timesheet_entries 
ALTER COLUMN client_id DROP NOT NULL;

-- 2. Vérifier que mission_id existe
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
        RAISE NOTICE '✅ Colonne mission_id ajoutée';
    ELSE
        RAISE NOTICE '✅ Colonne mission_id existe déjà';
    END IF;
END $$;

-- 3. Créer l'index si nécessaire
CREATE INDEX IF NOT EXISTS idx_timesheet_entries_mission_id 
ON public.timesheet_entries(mission_id);

-- 4. Vérification
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'timesheet_entries'
AND column_name IN ('client_id', 'mission_id')
ORDER BY column_name;

-- ✅ Si vous voyez "YES" pour is_nullable de client_id, c'est bon !
SELECT '✅ FIX APPLIQUÉ - client_id est maintenant nullable' as resultat;


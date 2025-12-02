-- ============================================================================
-- VÉRIFICATION ET CORRECTION: Sauvegarde Timesheet avec mission_id
-- ============================================================================
-- Exécutez ce script dans l'éditeur SQL de Supabase pour vérifier la config

-- 1. Vérifier que la colonne mission_id existe
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'timesheet_entries' AND column_name = 'mission_id'
    ) THEN
        -- Ajouter la colonne mission_id si elle n'existe pas
        ALTER TABLE timesheet_entries ADD COLUMN mission_id UUID REFERENCES missions(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Colonne mission_id ajoutée';
    ELSE
        RAISE NOTICE '✅ Colonne mission_id existe déjà';
    END IF;
END $$;

-- 2. Créer l'index sur mission_id s'il n'existe pas
CREATE INDEX IF NOT EXISTS idx_timesheet_entries_mission_id ON timesheet_entries(mission_id);

-- 3. Vérifier la structure actuelle de la table
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'timesheet_entries'
ORDER BY ordinal_position;

-- 4. Mettre à jour les politiques RLS pour permettre l'insertion/mise à jour
-- Supprimer les anciennes politiques qui pourraient poser problème
DROP POLICY IF EXISTS "Partenaires peuvent créer leurs propres saisies" ON timesheet_entries;
DROP POLICY IF EXISTS "Partenaires peuvent modifier leurs propres saisies en brouillon" ON timesheet_entries;
DROP POLICY IF EXISTS "Partenaires peuvent voir leurs propres saisies" ON timesheet_entries;
DROP POLICY IF EXISTS "Partenaires peuvent supprimer leurs propres saisies en brouillon" ON timesheet_entries;

-- Politique SELECT pour les partenaires
CREATE POLICY "Partenaires peuvent voir leurs propres saisies"
  ON timesheet_entries FOR SELECT
  TO authenticated
  USING (partner_id = auth.uid());

-- Politique INSERT pour les partenaires
CREATE POLICY "Partenaires peuvent créer leurs propres saisies"
  ON timesheet_entries FOR INSERT
  TO authenticated
  WITH CHECK (partner_id = auth.uid());

-- Politique UPDATE pour les partenaires (brouillons uniquement)
CREATE POLICY "Partenaires peuvent modifier leurs propres saisies en brouillon"
  ON timesheet_entries FOR UPDATE
  TO authenticated
  USING (partner_id = auth.uid() AND status = 'draft')
  WITH CHECK (partner_id = auth.uid());

-- Politique DELETE pour les partenaires (brouillons uniquement)
CREATE POLICY "Partenaires peuvent supprimer leurs propres saisies en brouillon"
  ON timesheet_entries FOR DELETE
  TO authenticated
  USING (partner_id = auth.uid() AND status = 'draft');

-- 5. Vérifier que les politiques sont bien créées
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE tablename = 'timesheet_entries'
ORDER BY policyname;

-- 6. Tester la création d'une entrée (en commentaire, à adapter avec vos IDs)
-- INSERT INTO timesheet_entries (partner_id, mission_id, entry_date, days, daily_rate, status, is_weekend)
-- VALUES (auth.uid(), 'votre-mission-id', '2025-12-01', 1.0, 450.0, 'draft', false);

-- 7. Afficher le nombre d'entrées par statut
SELECT 
    status,
    COUNT(*) as count,
    SUM(days) as total_days
FROM timesheet_entries
GROUP BY status
ORDER BY status;

-- Message de confirmation
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================================';
    RAISE NOTICE '✅ Vérification terminée !';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'La table timesheet_entries est prête pour la sauvegarde.';
    RAISE NOTICE 'Colonnes requises: partner_id, mission_id, entry_date, days';
    RAISE NOTICE 'Les politiques RLS sont configurées pour les partenaires.';
    RAISE NOTICE '============================================================';
END $$;


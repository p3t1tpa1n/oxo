-- ============================================================================
-- FIX: Permettre NULL sur client_id dans partner_rates
-- ============================================================================
-- Problème: La colonne client_id a une contrainte NOT NULL qui empêche
-- l'insertion de nouveaux tarifs utilisant uniquement company_id
-- Solution: Supprimer la contrainte NOT NULL sur client_id

-- Permettre NULL sur client_id pour la transition
ALTER TABLE partner_rates 
ALTER COLUMN client_id DROP NOT NULL;

-- Vérifier que la contrainte a été supprimée
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'partner_rates' 
        AND column_name = 'client_id' 
        AND is_nullable = 'NO'
    ) THEN
        RAISE EXCEPTION 'La contrainte NOT NULL sur client_id n''a pas été supprimée';
    ELSE
        RAISE NOTICE '✅ La colonne client_id accepte maintenant NULL';
    END IF;
END $$;



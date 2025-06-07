-- Script pour créer la table des factures
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Créer la table des factures
CREATE TABLE IF NOT EXISTS public.invoices (
    id BIGSERIAL PRIMARY KEY,
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    company_id BIGINT NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    client_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    project_id UUID REFERENCES public.projects(id) ON DELETE SET NULL,
    
    -- Détails de la facture
    title VARCHAR(255) NOT NULL,
    description TEXT,
    amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    tax_rate DECIMAL(5,2) DEFAULT 20.00 CHECK (tax_rate >= 0 AND tax_rate <= 100),
    tax_amount DECIMAL(10,2) GENERATED ALWAYS AS (amount * tax_rate / 100) STORED,
    total_amount DECIMAL(10,2) GENERATED ALWAYS AS (amount + (amount * tax_rate / 100)) STORED,
    
    -- Dates
    invoice_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL,
    
    -- Statut
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'pending', 'paid', 'overdue', 'cancelled')),
    
    -- Informations de paiement
    payment_method VARCHAR(50),
    payment_date DATE,
    payment_reference VARCHAR(255),
    
    -- Métadonnées
    created_by UUID NOT NULL REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Index pour améliorer les performances
    CONSTRAINT unique_invoice_number UNIQUE (invoice_number)
);

-- 2. Créer des index pour améliorer les performances
CREATE INDEX IF NOT EXISTS invoices_company_id_idx ON public.invoices(company_id);
CREATE INDEX IF NOT EXISTS invoices_client_user_id_idx ON public.invoices(client_user_id);
CREATE INDEX IF NOT EXISTS invoices_status_idx ON public.invoices(status);
CREATE INDEX IF NOT EXISTS invoices_invoice_date_idx ON public.invoices(invoice_date);
CREATE INDEX IF NOT EXISTS invoices_due_date_idx ON public.invoices(due_date);

-- 3. Créer une fonction pour générer automatiquement les numéros de facture
CREATE OR REPLACE FUNCTION generate_invoice_number()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    year_part TEXT;
    sequence_part TEXT;
    new_number TEXT;
BEGIN
    -- Obtenir l'année actuelle
    year_part := EXTRACT(YEAR FROM CURRENT_DATE)::TEXT;
    
    -- Obtenir le prochain numéro de séquence pour cette année
    SELECT COALESCE(
        LPAD(
            (MAX(
                CASE 
                    WHEN invoice_number LIKE 'INV-' || year_part || '-%' 
                    THEN CAST(SUBSTRING(invoice_number FROM LENGTH('INV-' || year_part || '-') + 1) AS INTEGER)
                    ELSE 0
                END
            ) + 1)::TEXT, 
            3, 
            '0'
        ), 
        '001'
    ) INTO sequence_part
    FROM public.invoices
    WHERE invoice_number LIKE 'INV-' || year_part || '-%';
    
    -- Construire le numéro de facture complet
    new_number := 'INV-' || year_part || '-' || sequence_part;
    
    RETURN new_number;
END;
$$;

-- 4. Créer un trigger pour générer automatiquement le numéro de facture
CREATE OR REPLACE FUNCTION set_invoice_number()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.invoice_number IS NULL OR NEW.invoice_number = '' THEN
        NEW.invoice_number := generate_invoice_number();
    END IF;
    
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_set_invoice_number
    BEFORE INSERT OR UPDATE ON public.invoices
    FOR EACH ROW
    EXECUTE FUNCTION set_invoice_number();

-- 5. Créer des politiques RLS pour les factures
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;

-- Politique pour la lecture
CREATE POLICY "invoices_select_policy"
ON public.invoices FOR SELECT
TO authenticated
USING (
    -- Admins et associés peuvent voir toutes les factures
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'associe')
    )
    OR
    -- Clients peuvent voir leurs propres factures
    (
        client_user_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE user_id = auth.uid() 
            AND role = 'client'
        )
    )
    OR
    -- Partenaires peuvent voir les factures de leur entreprise
    (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE user_id = auth.uid() 
            AND role = 'partenaire'
            AND company_id = invoices.company_id
        )
    )
);

-- Politique pour l'insertion
CREATE POLICY "invoices_insert_policy"
ON public.invoices FOR INSERT
TO authenticated
WITH CHECK (
    -- Seuls les admins et associés peuvent créer des factures
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'associe')
    )
    AND created_by = auth.uid()
);

-- Politique pour la modification
CREATE POLICY "invoices_update_policy"
ON public.invoices FOR UPDATE
TO authenticated
USING (
    -- Seuls les admins et associés peuvent modifier les factures
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'associe')
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'associe')
    )
);

-- Politique pour la suppression
CREATE POLICY "invoices_delete_policy"
ON public.invoices FOR DELETE
TO authenticated
USING (
    -- Seuls les admins peuvent supprimer les factures
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE user_id = auth.uid() 
        AND role = 'admin'
    )
);

-- 6. Créer une vue pour faciliter les requêtes
CREATE OR REPLACE VIEW invoice_details AS
SELECT 
    i.*,
    c.name as company_name,
    p.first_name || ' ' || p.last_name as client_name,
    p.email as client_email,
    proj.name as project_name,
    creator.first_name || ' ' || creator.last_name as created_by_name
FROM public.invoices i
LEFT JOIN public.companies c ON i.company_id = c.id
LEFT JOIN public.profiles p ON i.client_user_id = p.user_id
LEFT JOIN public.projects proj ON i.project_id = proj.id
LEFT JOIN public.profiles creator ON i.created_by = creator.user_id;

-- 7. Fonction pour mettre à jour le statut automatiquement
CREATE OR REPLACE FUNCTION update_invoice_status()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    -- Marquer les factures en retard
    UPDATE public.invoices 
    SET status = 'overdue', updated_at = NOW()
    WHERE status = 'pending' 
    AND due_date < CURRENT_DATE;
    
    -- Marquer les factures envoyées comme en attente si elles ont dépassé la date d'envoi
    UPDATE public.invoices 
    SET status = 'pending', updated_at = NOW()
    WHERE status = 'sent' 
    AND invoice_date <= CURRENT_DATE;
END;
$$;

-- 8. Créer des factures de démonstration (optionnel - à supprimer en production)
DO $$
DECLARE
    demo_company_id BIGINT;
    demo_client_id UUID;
    demo_admin_id UUID;
BEGIN
    -- Récupérer l'ID de la première entreprise
    SELECT id INTO demo_company_id FROM public.companies LIMIT 1;
    
    -- Récupérer l'ID d'un client
    SELECT user_id INTO demo_client_id 
    FROM public.profiles 
    WHERE role = 'client' 
    LIMIT 1;
    
    -- Récupérer l'ID d'un admin/associé
    SELECT user_id INTO demo_admin_id 
    FROM public.profiles 
    WHERE role IN ('admin', 'associe') 
    LIMIT 1;
    
    -- Insérer des factures de démonstration seulement si les données existent
    IF demo_company_id IS NOT NULL AND demo_client_id IS NOT NULL AND demo_admin_id IS NOT NULL THEN
        INSERT INTO public.invoices (
            company_id, 
            client_user_id, 
            title, 
            description, 
            amount, 
            invoice_date, 
            due_date, 
            status, 
            created_by
        ) VALUES 
        (
            demo_company_id,
            demo_client_id,
            'Services de développement web - Janvier 2024',
            'Développement site vitrine entreprise avec CMS intégré',
            2500.00,
            CURRENT_DATE - INTERVAL '30 days',
            CURRENT_DATE - INTERVAL '15 days',
            'paid',
            demo_admin_id
        ),
        (
            demo_company_id,
            demo_client_id,
            'Services de développement web - Février 2024',
            'Développement application mobile iOS/Android',
            3200.00,
            CURRENT_DATE - INTERVAL '15 days',
            CURRENT_DATE + INTERVAL '15 days',
            'pending',
            demo_admin_id
        ),
        (
            demo_company_id,
            demo_client_id,
            'Maintenance et support - Mars 2024',
            'Maintenance mensuelle et support technique',
            1800.00,
            CURRENT_DATE - INTERVAL '5 days',
            CURRENT_DATE + INTERVAL '25 days',
            'sent',
            demo_admin_id
        );
    END IF;
END;
$$;

-- 9. Vérifications finales
SELECT 'STRUCTURE TABLE INVOICES' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'invoices'
ORDER BY ordinal_position;

SELECT 'FACTURES DE DÉMONSTRATION CRÉÉES' as info;
SELECT 
    invoice_number,
    title,
    amount,
    status,
    invoice_date,
    due_date
FROM public.invoices 
ORDER BY created_at DESC;

-- Message final
SELECT '✅ Table des factures créée avec succès !' as result; 
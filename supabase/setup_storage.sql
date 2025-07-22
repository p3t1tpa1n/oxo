-- Configuration de Supabase Storage pour les documents

-- 1. Créer le bucket "documents" s'il n'existe pas
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', false)
ON CONFLICT (id) DO NOTHING;

-- 2. Configurer les politiques RLS pour le bucket documents
-- D'abord supprimer les politiques existantes si elles existent
DROP POLICY IF EXISTS "Users can upload documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can view company documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their documents" ON storage.objects;

-- Politique pour permettre l'upload aux utilisateurs authentifiés
CREATE POLICY "Users can upload documents" ON storage.objects 
FOR INSERT TO authenticated 
WITH CHECK (bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Politique pour permettre la lecture des documents aux utilisateurs de la même entreprise
CREATE POLICY "Users can view company documents" ON storage.objects 
FOR SELECT TO authenticated 
USING (
    bucket_id = 'documents' 
    AND (
        -- L'utilisateur peut voir ses propres documents
        auth.uid()::text = (storage.foldername(name))[1]
        OR
        -- Ou si c'est un admin/associé
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE user_id = auth.uid() 
            AND role IN ('admin', 'associe')
        )
    )
);

-- Politique pour permettre la mise à jour des documents aux propriétaires
CREATE POLICY "Users can update their documents" ON storage.objects 
FOR UPDATE TO authenticated 
USING (bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Politique pour permettre la suppression des documents aux propriétaires
CREATE POLICY "Users can delete their documents" ON storage.objects 
FOR DELETE TO authenticated 
USING (bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1]);

-- 3. Vérification
SELECT 'Bucket "documents" configuré avec succès !' as result;
SELECT 'Politiques RLS appliquées pour la sécurité des documents' as info; 
-- Script pour vérifier l'état des missions et de la colonne progress_status

-- 1. Vérifier si la colonne progress_status existe
SELECT 
    column_name,
    data_type,
    udt_name,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'missions' 
  AND column_name = 'progress_status';

-- 2. Vérifier les valeurs possibles de l'enum (si la colonne existe)
SELECT 
    t.typname AS enum_name,
    e.enumlabel AS enum_value,
    e.enumsortorder AS sort_order
FROM pg_type t
JOIN pg_enum e ON t.oid = e.enumtypid
WHERE t.typname = 'mission_progress_type'
ORDER BY e.enumsortorder;

-- 3. Compter le nombre total de missions
SELECT COUNT(*) as total_missions FROM missions;

-- 4. Voir la distribution des statuts progress_status (si la colonne existe)
SELECT 
    COALESCE(progress_status::text, 'NULL') as progress_status,
    COUNT(*) as count
FROM missions 
GROUP BY progress_status
ORDER BY count DESC;

-- 5. Voir quelques exemples de missions
SELECT 
    id,
    title,
    status,
    progress_status,
    created_at
FROM missions 
ORDER BY created_at DESC 
LIMIT 10;

-- 6. Si la colonne n'existe pas, voir les colonnes actuelles
SELECT column_name, data_type
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'missions'
ORDER BY ordinal_position;

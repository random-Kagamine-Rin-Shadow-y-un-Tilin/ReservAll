BEGIN;

-- HU_14: el nombre de categoría es único, sin importar mayúsculas ni espacios.
-- Si una base antigua ya tiene duplicados, se omite el índice para no bloquear
-- el despliegue; la API también valida este caso con un 409.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_indexes
        WHERE schemaname = 'public'
          AND indexname = 'ux_categorias_nombre_categoria'
    ) AND NOT EXISTS (
        SELECT 1
        FROM public.categorias
        GROUP BY LOWER(TRIM(nombre_categoria))
        HAVING COUNT(*) > 1
    ) THEN
        CREATE UNIQUE INDEX ux_categorias_nombre_categoria
            ON public.categorias (LOWER(TRIM(nombre_categoria)));
    END IF;
END $$;

COMMIT;

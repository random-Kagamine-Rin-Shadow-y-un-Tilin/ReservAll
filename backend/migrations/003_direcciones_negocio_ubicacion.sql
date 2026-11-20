-- EP07 - Ubicaciones y mapas
-- Validaciones e índices para las coordenadas de las direcciones de negocio.
--
-- * Las coordenadas se usan para pintar marcadores y calcular distancias.
-- * Un negocio debe tener una sola dirección; si ya existen duplicados, la
--   migración no crea el índice único para no fallar (hay que limpiarlos antes).
-- * Las restricciones se agregan como NOT VALID para no romper datos viejos;
--   los registros nuevos sí quedan validados.

BEGIN;

-- Búsquedas por negocio (obtener/actualizar su dirección).
CREATE INDEX IF NOT EXISTS idx_direcciones_negocio_negocio
    ON public.direcciones_negocio (negocio_id);

-- Filtros del mapa por zona visible y orden por distancia.
CREATE INDEX IF NOT EXISTS idx_direcciones_negocio_coords
    ON public.direcciones_negocio (latitud, longitud)
    WHERE latitud IS NOT NULL AND longitud IS NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'public.direcciones_negocio'::regclass
          AND conname = 'direcciones_negocio_latitud_check'
    ) THEN
        ALTER TABLE public.direcciones_negocio
            ADD CONSTRAINT direcciones_negocio_latitud_check
            CHECK (latitud IS NULL OR (latitud >= -90 AND latitud <= 90))
            NOT VALID;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'public.direcciones_negocio'::regclass
          AND conname = 'direcciones_negocio_longitud_check'
    ) THEN
        ALTER TABLE public.direcciones_negocio
            ADD CONSTRAINT direcciones_negocio_longitud_check
            CHECK (longitud IS NULL OR (longitud >= -180 AND longitud <= 180))
            NOT VALID;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_indexes
        WHERE schemaname = 'public'
          AND indexname = 'ux_direcciones_negocio_negocio'
    ) AND NOT EXISTS (
        SELECT 1
        FROM public.direcciones_negocio
        GROUP BY negocio_id
        HAVING COUNT(*) > 1
    ) THEN
        EXECUTE
            'CREATE UNIQUE INDEX ux_direcciones_negocio_negocio '
            'ON public.direcciones_negocio (negocio_id)';
    END IF;
END $$;

COMMIT;

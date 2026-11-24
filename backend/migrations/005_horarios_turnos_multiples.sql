BEGIN;

-- HU_25/HU_27: varios turnos por día, descanso configurable y día inactivo.

ALTER TABLE public.horarios
    ADD COLUMN IF NOT EXISTS descanso_duracion_min INTEGER NOT NULL DEFAULT 60;

DO $$
DECLARE
    constraint_name TEXT;
BEGIN
    SELECT con.conname
      INTO constraint_name
      FROM pg_constraint AS con
     WHERE con.conrelid = 'public.horarios'::regclass
       AND con.contype = 'u'
       AND ARRAY(
             SELECT att.attname
               FROM unnest(con.conkey) AS key_attnum
               JOIN pg_attribute AS att
                 ON att.attrelid = con.conrelid
                AND att.attnum = key_attnum
              ORDER BY att.attname
           ) = ARRAY['dia', 'negocio_id']
     LIMIT 1;

    IF constraint_name IS NOT NULL THEN
        EXECUTE format('ALTER TABLE public.horarios DROP CONSTRAINT %I', constraint_name);
    END IF;
END $$;

-- Algunas bases crearon el índice único sin constraint: también se elimina.
DO $$
DECLARE
    index_name TEXT;
BEGIN
    SELECT indexname
      INTO index_name
      FROM pg_indexes
     WHERE schemaname = 'public'
       AND tablename = 'horarios'
       AND indexdef ILIKE '%UNIQUE%'
       AND indexdef ILIKE '%negocio_id%'
       AND indexdef ILIKE '%dia%'
     LIMIT 1;

    IF index_name IS NOT NULL THEN
        EXECUTE format('DROP INDEX IF EXISTS public.%I', index_name);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_horarios_negocio_dia_apertura
    ON public.horarios (negocio_id, dia, hora_apertura);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'public.horarios'::regclass
          AND conname = 'horarios_descanso_duracion_check'
    ) THEN
        ALTER TABLE public.horarios
            ADD CONSTRAINT horarios_descanso_duracion_check
            CHECK (descanso_duracion_min BETWEEN 0 AND 240)
            NOT VALID;
    END IF;
END $$;

COMMIT;

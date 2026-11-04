-- EP04 - Agenda y disponibilidad
-- Tabla de bloqueos de agenda (HU_22 y HU_24).
--
-- Un registro sin hora_inicio/hora_fin bloquea el día completo.
-- Un registro con ambas horas bloquea únicamente ese rango.

BEGIN;

CREATE TABLE IF NOT EXISTS public.bloqueos_agenda (
    id_bloqueo integer GENERATED ALWAYS AS IDENTITY NOT NULL,
    negocio_id integer NOT NULL,
    fecha date NOT NULL,
    hora_inicio time without time zone,
    hora_fin time without time zone,
    motivo text,
    fecha_creacion timestamp without time zone NOT NULL DEFAULT now(),
    CONSTRAINT bloqueos_agenda_pkey PRIMARY KEY (id_bloqueo),
    CONSTRAINT bloqueos_agenda_negocio_id_fkey
        FOREIGN KEY (negocio_id) REFERENCES public.negocios(id) ON DELETE CASCADE,
    CONSTRAINT bloqueos_agenda_horas_check CHECK (
        (hora_inicio IS NULL AND hora_fin IS NULL)
        OR (
            hora_inicio IS NOT NULL
            AND hora_fin IS NOT NULL
            AND hora_inicio < hora_fin
        )
    )
);

CREATE INDEX IF NOT EXISTS idx_bloqueos_agenda_negocio_fecha
    ON public.bloqueos_agenda (negocio_id, fecha);

COMMIT;

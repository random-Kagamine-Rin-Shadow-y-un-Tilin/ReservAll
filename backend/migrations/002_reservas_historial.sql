-- EP06 - Sistema de reservas (HU_43 a HU_53)
-- Columnas de apoyo para comentarios, motivos e historial de cambios.
--
-- * comentario: nota opcional que el cliente deja al crear la reserva.
-- * motivo: motivo opcional de cancelación/rechazo o del último cambio.
-- * fecha_actualizacion: permite ordenar y auditar el historial.

BEGIN;

ALTER TABLE public.reservas
    ADD COLUMN IF NOT EXISTS comentario text,
    ADD COLUMN IF NOT EXISTS motivo text,
    ADD COLUMN IF NOT EXISTS fecha_actualizacion timestamp without time zone
        DEFAULT now();

-- Consultas del cliente (mis reservas e historial).
CREATE INDEX IF NOT EXISTS idx_reservas_cliente_fecha
    ON public.reservas (cliente_id, fecha, hora_inicio);

-- Consultas del negocio (agenda, historial y reportes).
CREATE INDEX IF NOT EXISTS idx_reservas_servicio_fecha_estado
    ON public.reservas (servicio_id, fecha, estado);

COMMIT;

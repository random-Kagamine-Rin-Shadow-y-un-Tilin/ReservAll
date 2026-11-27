-- EP07 - Notificaciones push de reservas
-- Suscripciones Web Push por usuario y registro de avisos enviados para no
-- repetir la misma notificación.

BEGIN;

CREATE TABLE IF NOT EXISTS public.push_subscriptions (
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    user_id integer NOT NULL,
    endpoint text NOT NULL,
    p256dh text NOT NULL,
    auth text NOT NULL,
    user_agent text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT push_subscriptions_pkey PRIMARY KEY (id),
    CONSTRAINT push_subscriptions_endpoint_key UNIQUE (endpoint),
    CONSTRAINT push_subscriptions_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES public.usuarios(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_push_subscriptions_user
    ON public.push_subscriptions (user_id);

CREATE TABLE IF NOT EXISTS public.push_notifications_log (
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    reserva_id integer NOT NULL,
    kind text NOT NULL DEFAULT 'reserva',
    sent_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT push_notifications_log_pkey PRIMARY KEY (id),
    CONSTRAINT push_notifications_log_unique UNIQUE (reserva_id, kind),
    CONSTRAINT push_notifications_log_reserva_id_fkey
        FOREIGN KEY (reserva_id) REFERENCES public.reservas(id_reserva)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_push_notifications_log_sent_at
    ON public.push_notifications_log (sent_at);

COMMIT;

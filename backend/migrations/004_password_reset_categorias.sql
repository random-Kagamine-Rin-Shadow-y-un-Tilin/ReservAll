BEGIN;

-- HU_03: códigos de recuperación de contraseña.
CREATE TABLE IF NOT EXISTS public.password_reset_codes (
    id BIGSERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
    code_hash TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    usado BOOLEAN NOT NULL DEFAULT FALSE,
    usado_en TIMESTAMPTZ,
    intentos INTEGER NOT NULL DEFAULT 0,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.password_reset_codes
    ADD COLUMN IF NOT EXISTS intentos INTEGER NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_password_reset_codes_user_id
    ON public.password_reset_codes (user_id, usado, expires_at DESC);

-- HU_14: metadatos adicionales de categorías.
ALTER TABLE public.categorias
    ADD COLUMN IF NOT EXISTS descripcion VARCHAR(500);

ALTER TABLE public.categorias
    ADD COLUMN IF NOT EXISTS estado BOOLEAN;

UPDATE public.categorias SET estado = TRUE WHERE estado IS NULL;

ALTER TABLE public.categorias
    ALTER COLUMN estado SET DEFAULT TRUE,
    ALTER COLUMN estado SET NOT NULL;

COMMIT;

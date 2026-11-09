# Migraciones

## 001_create_bloqueos_agenda.sql

Crea la tabla `public.bloqueos_agenda`, necesaria para las HU_22 (bloquear
fechas) y HU_24 (bloquear horarios específicos) del módulo 4.

- Un registro con `hora_inicio` y `hora_fin` en `NULL` bloquea el día completo.
- Un registro con ambas horas bloquea únicamente ese rango.
- `motivo` es opcional.

La migración usa `CREATE TABLE IF NOT EXISTS` e `CREATE INDEX IF NOT EXISTS`,
por lo que es idempotente y se puede volver a ejecutar sin errores.

### Opción 1: `psql`

Desde `backend/`, con la `DATABASE_URL` del `.env`:

```powershell
psql "$env:DATABASE_URL" -f migrations/001_create_bloqueos_agenda.sql
```

### Opción 2: script de Python

Desde `backend/`:

```powershell
@'
import asyncio, os
import asyncpg
from dotenv import load_dotenv

load_dotenv()
sql = open("migrations/001_create_bloqueos_agenda.sql", encoding="utf-8").read()

async def main():
    conn = await asyncpg.connect(os.environ["DATABASE_URL"])
    try:
        await conn.execute(sql)
    finally:
        await conn.close()

asyncio.run(main())
'@ | .\.venv\Scripts\python -
```

Verificar que la tabla existe:

```powershell
psql "$env:DATABASE_URL" -c "\d public.bloqueos_agenda"
```

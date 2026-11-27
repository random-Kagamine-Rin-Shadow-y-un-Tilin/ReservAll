import asyncio
from contextlib import asynccontextmanager

from app.repositories import shop_schedule_repository as repo


class FakeConn:
    def __init__(self, has_column: bool):
        self.has_column = has_column
        self.query = ""
        self.args: tuple = ()

    async def fetchval(self, query):
        return self.has_column

    async def fetchrow(self, query, *args):
        self.query = query
        self.args = args
        return {"ok": True}

    async def fetch(self, query, *args):
        self.query = query
        self.args = args
        return []


class FakePool:
    def __init__(self, conn: FakeConn):
        self.conn = conn

    @asynccontextmanager
    async def acquire(self):
        yield self.conn


def test_create_schedule_adapta_columna_ausente():
    conn = FakeConn(has_column=False)
    result = asyncio.run(
        repo.create_schedule(
            FakePool(conn),
            shop_id=1,
            day="lunes",
            open_hour="09:00",
            close_hour="18:00",
            break_hour="13:00",
            break_duration_min=45,
        )
    )

    assert result == {"ok": True}
    assert "descanso_duracion_min, estado_horario" not in conn.query
    assert len(conn.args) == 6


def test_create_schedule_usa_columna_cuando_existe():
    conn = FakeConn(has_column=True)
    asyncio.run(
        repo.create_schedule(
            FakePool(conn),
            shop_id=1,
            day="lunes",
            open_hour="09:00",
            close_hour="18:00",
            break_duration_min=45,
        )
    )

    assert "descanso_duracion_min, estado_horario" in conn.query
    assert conn.args[-2] == 45


def test_update_schedule_ignora_duracion_sin_columna():
    conn = FakeConn(has_column=False)
    asyncio.run(
        repo.update_schedule(
            FakePool(conn), 7, {"descanso_duracion_min": 30}
        )
    )

    # No hay campos actualizables: se lee el horario en vez de hacer UPDATE.
    assert conn.query.lstrip().upper().startswith("SELECT")


def test_update_schedule_incluye_duracion_con_columna():
    conn = FakeConn(has_column=True)
    asyncio.run(
        repo.update_schedule(
            FakePool(conn), 7, {"descanso_duracion_min": 30}
        )
    )

    assert "UPDATE horarios" in conn.query
    assert "descanso_duracion_min = $1" in conn.query

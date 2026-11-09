"""Utilidades compartidas para horarios, días y generación de espacios.

El enum ``dia_semana`` de PostgreSQL usa etiquetas en minúscula y sin acentos
(``lunes``, ``miercoles``, ...). Estas utilidades normalizan cualquier variante
recibida por la API a esa representación canónica.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date, time
from typing import Iterable
import unicodedata


DIAS_SEMANA: tuple[str, ...] = (
    "lunes",
    "martes",
    "miercoles",
    "jueves",
    "viernes",
    "sabado",
    "domingo",
)

DIAS_LABEL: dict[str, str] = {
    "lunes": "Lunes",
    "martes": "Martes",
    "miercoles": "Miércoles",
    "jueves": "Jueves",
    "viernes": "Viernes",
    "sabado": "Sábado",
    "domingo": "Domingo",
}


def _sin_acentos(value: str) -> str:
    decomposed = unicodedata.normalize("NFKD", value)
    return "".join(char for char in decomposed if not unicodedata.combining(char))


def normalize_day(value: str) -> str:
    """Devuelve el día en el formato del enum ``dia_semana``.

    Acepta mayúsculas, minúsculas y acentos: ``"Miércoles"`` -> ``"miercoles"``.
    """

    if not isinstance(value, str) or not value.strip():
        raise ValueError("El día de la semana es obligatorio.")

    key = _sin_acentos(value.strip().lower())
    if key not in DIAS_SEMANA:
        opciones = ", ".join(DIAS_LABEL[dia] for dia in DIAS_SEMANA)
        raise ValueError(f"Día inválido: '{value}'. Usa uno de: {opciones}.")
    return key


def day_for_date(fecha: date) -> str:
    """Día canónico correspondiente a una fecha (lunes = 0)."""

    return DIAS_SEMANA[fecha.weekday()]


def day_label(value: str) -> str:
    try:
        return DIAS_LABEL[normalize_day(value)]
    except ValueError:
        return value


def to_minutes(value: time) -> int:
    return value.hour * 60 + value.minute


def to_time(total_minutes: int) -> time:
    total_minutes %= 24 * 60
    return time(hour=total_minutes // 60, minute=total_minutes % 60)


def overlaps(start: int, end: int, other_start: int, other_end: int) -> bool:
    return start < other_end and end > other_start


@dataclass(frozen=True)
class Slot:
    hora_inicio: time
    hora_fin: time
    disponible: bool
    motivo: str | None = None


def build_slots(
    *,
    apertura_min: int,
    cierre_min: int,
    duracion_min: int,
    intervalo_min: int,
    descanso_min: int | None = None,
    descanso_duracion_min: int = 60,
    reservas: Iterable[tuple[int, int]] = (),
    bloqueos: Iterable[tuple[int, int]] = (),
) -> list[Slot]:
    """Genera los espacios de una jornada.

    ``reservas`` y ``bloqueos`` se reciben como intervalos en minutos desde
    medianoche. Los bloqueos de día completo se gestionan fuera de esta función.
    """

    if duracion_min <= 0 or intervalo_min <= 0 or cierre_min <= apertura_min:
        return []

    reservas = list(reservas)
    bloqueos = list(bloqueos)
    descanso_fin = (
        descanso_min + descanso_duracion_min if descanso_min is not None else None
    )

    slots: list[Slot] = []
    inicio = apertura_min
    while inicio + duracion_min <= cierre_min:
        fin = inicio + duracion_min
        motivo: str | None = None

        if any(overlaps(inicio, fin, r_ini, r_fin) for r_ini, r_fin in reservas):
            motivo = "reservado"
        elif any(
            overlaps(inicio, fin, b_ini, b_fin) for b_ini, b_fin in bloqueos
        ):
            motivo = "bloqueo"
        elif (
            descanso_min is not None
            and descanso_fin is not None
            and overlaps(inicio, fin, descanso_min, descanso_fin)
        ):
            motivo = "descanso"

        slots.append(
            Slot(
                hora_inicio=to_time(inicio),
                hora_fin=to_time(fin),
                disponible=motivo is None,
                motivo=motivo,
            )
        )
        inicio += intervalo_min

    return slots

import { Link } from "react-router-dom";

export function Brand({
  compact = false,
  inverted = false,
}: {
  compact?: boolean;
  inverted?: boolean;
}) {
  return (
    <Link
      to="/dashboard"
      className="group inline-flex items-center gap-3"
      aria-label="ReservAll, ir al panel"
    >
      <span
        className={`relative flex size-10 shrink-0 items-center justify-center rounded-xl font-display text-xl font-extrabold text-white shadow-[0_8px_18px_-10px_rgba(159,64,45,0.9)] transition-transform group-hover:-rotate-3 ${
          inverted ? "bg-white text-primary" : "bg-primary"
        }`}
      >
        R
        <span
          className={`absolute -right-1 -top-1 size-2.5 rounded-full ${
            inverted ? "bg-highlight-soft" : "bg-highlight-soft"
          }`}
        />
      </span>
      {!compact && (
        <span className="flex flex-col leading-none">
          <span
            className={`font-display text-xl font-extrabold tracking-tight ${
              inverted ? "text-white" : "text-foreground"
            }`}
          >
            ReservAll
          </span>
          <span
            className={`mt-1 text-[10px] font-semibold uppercase tracking-[0.18em] ${
              inverted ? "text-white/70" : "text-secondary-text"
            }`}
          >
            Panel de negocio
          </span>
        </span>
      )}
    </Link>
  );
}

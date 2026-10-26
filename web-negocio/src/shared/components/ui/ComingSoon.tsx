import type { ReactNode } from "react";
import { Link } from "react-router-dom";
import { LuArrowLeft, LuSparkles } from "react-icons/lu";
import { Badge } from "./Badge";

export function ComingSoon({
  eyebrow = "Próximamente",
  title,
  description,
  icon,
  features = [],
}: {
  eyebrow?: string;
  title: string;
  description: string;
  icon?: ReactNode;
  features?: string[];
}) {
  return (
    <div className="mx-auto max-w-4xl">
      <div className="relative overflow-hidden rounded-3xl border border-border bg-card px-6 py-12 shadow-soft sm:px-12 sm:py-16">
        <div className="pointer-events-none absolute -right-24 -top-24 size-72 rounded-full bg-highlight-soft/20 blur-2xl" />
        <div className="pointer-events-none absolute -bottom-32 -left-24 size-80 rounded-full bg-secondary-soft/10 blur-2xl" />

        <div className="relative flex flex-col items-center text-center">
          <span className="flex size-16 items-center justify-center rounded-2xl bg-primary-tint text-3xl text-primary">
            {icon ?? <LuSparkles />}
          </span>
          <Badge tone="gold" className="mt-5">
            {eyebrow}
          </Badge>
          <h1 className="mt-4 max-w-2xl font-display text-3xl font-extrabold text-foreground sm:text-4xl">
            {title}
          </h1>
          <p className="mt-3 max-w-xl text-base leading-relaxed text-secondary-text">
            {description}
          </p>

          {features.length > 0 && (
            <div className="mt-8 grid w-full max-w-2xl gap-2 text-left sm:grid-cols-2">
              {features.map((feature) => (
                <div
                  key={feature}
                  className="flex items-start gap-2.5 rounded-xl border border-border/70 bg-surface/70 px-4 py-3"
                >
                  <span className="mt-1.5 size-1.5 shrink-0 rounded-full bg-primary-soft" />
                  <span className="text-sm text-secondary-text">{feature}</span>
                </div>
              ))}
            </div>
          )}

          <div className="mt-9 flex flex-wrap items-center justify-center gap-3">
            <Link
              to="/dashboard"
              className="inline-flex h-11 items-center gap-2 rounded-xl bg-primary px-5 text-sm font-semibold text-primary-foreground transition-colors hover:bg-primary-soft"
            >
              <LuArrowLeft />
              Volver al panel
            </Link>
            <p className="text-xs font-medium text-secondary-text">
              Estamos preparando esta sección para la siguiente fase.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

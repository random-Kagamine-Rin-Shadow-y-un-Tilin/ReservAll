import type { ReactNode } from "react";

export function Card({
  className = "",
  children,
}: {
  className?: string;
  children: ReactNode;
}) {
  return (
    <section
      className={`rounded-2xl border border-border/80 bg-card shadow-soft ${className}`}
    >
      {children}
    </section>
  );
}

export function CardHeader({
  title,
  subtitle,
  icon,
  action,
  className = "",
}: {
  title: string;
  subtitle?: string;
  icon?: ReactNode;
  action?: ReactNode;
  className?: string;
}) {
  return (
    <div
      className={`flex flex-wrap items-start justify-between gap-3 border-b border-border/70 px-5 py-4 ${className}`}
    >
      <div className="flex items-start gap-3">
        {icon && (
          <span className="mt-0.5 flex size-9 shrink-0 items-center justify-center rounded-xl bg-primary-tint text-lg text-primary">
            {icon}
          </span>
        )}
        <div>
          <h2 className="font-display text-base font-bold text-foreground">{title}</h2>
          {subtitle && (
            <p className="mt-0.5 text-sm text-secondary-text">{subtitle}</p>
          )}
        </div>
      </div>
      {action}
    </div>
  );
}

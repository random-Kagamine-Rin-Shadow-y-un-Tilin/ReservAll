import type { ReactNode } from "react";
import { LuCircleAlert, LuInbox } from "react-icons/lu";
import { Button } from "./Button";

export function Spinner({ className = "size-5" }: { className?: string }) {
  return (
    <span
      className={`inline-block animate-spin rounded-full border-2 border-primary/30 border-t-primary ${className}`}
      aria-label="Cargando"
    />
  );
}

export function PageLoader({ label = "Cargando información..." }: { label?: string }) {
  return (
    <div className="flex min-h-[40vh] flex-col items-center justify-center gap-3 text-secondary-text">
      <Spinner className="size-8" />
      <p className="text-sm font-medium">{label}</p>
    </div>
  );
}

export function ErrorState({
  title = "No pudimos cargar la información",
  message,
  onRetry,
}: {
  title?: string;
  message?: string;
  onRetry?: () => void;
}) {
  return (
    <div className="flex flex-col items-center justify-center gap-3 rounded-2xl border border-dashed border-error/30 bg-error-tint/40 px-6 py-12 text-center">
      <span className="flex size-11 items-center justify-center rounded-full bg-error-tint text-error">
        <LuCircleAlert size={22} />
      </span>
      <div>
        <h3 className="font-display text-base font-bold text-foreground">{title}</h3>
        {message && <p className="mt-1 max-w-md text-sm text-secondary-text">{message}</p>}
      </div>
      {onRetry && (
        <Button variant="outline" size="sm" onClick={onRetry}>
          Reintentar
        </Button>
      )}
    </div>
  );
}

export function EmptyState({
  icon,
  title,
  description,
  action,
}: {
  icon?: ReactNode;
  title: string;
  description?: string;
  action?: ReactNode;
}) {
  return (
    <div className="flex flex-col items-center justify-center gap-3 rounded-2xl border border-dashed border-border-strong bg-surface/70 px-6 py-12 text-center">
      <span className="flex size-12 items-center justify-center rounded-2xl bg-primary-tint text-xl text-primary">
        {icon ?? <LuInbox />}
      </span>
      <div>
        <h3 className="font-display text-base font-bold text-foreground">{title}</h3>
        {description && (
          <p className="mx-auto mt-1 max-w-md text-sm text-secondary-text">{description}</p>
        )}
      </div>
      {action}
    </div>
  );
}

import type {
  InputHTMLAttributes,
  ReactNode,
  SelectHTMLAttributes,
  TextareaHTMLAttributes,
} from "react";

export function Field({
  label,
  htmlFor,
  hint,
  error,
  required,
  children,
  className = "",
}: {
  label: string;
  htmlFor?: string;
  hint?: string;
  error?: string | null;
  required?: boolean;
  children: ReactNode;
  className?: string;
}) {
  return (
    <div className={`flex flex-col gap-1.5 ${className}`}>
      <label htmlFor={htmlFor} className="text-sm font-semibold text-foreground">
        {label}
        {required && <span className="ml-0.5 text-primary-soft">*</span>}
      </label>
      {children}
      {error ? (
        <p className="text-xs font-medium text-error">{error}</p>
      ) : hint ? (
        <p className="text-xs text-secondary-text">{hint}</p>
      ) : null}
    </div>
  );
}

const controlBase =
  "w-full rounded-xl border border-border bg-card px-3.5 py-2.5 text-sm text-foreground shadow-[0_1px_0_rgba(36,28,22,0.02)] transition-colors placeholder:text-muted/80 hover:border-border-strong focus:border-primary-soft focus:outline-none focus:ring-4 focus:ring-primary-tint disabled:bg-surface-muted disabled:text-secondary-text";

export function Input({
  className = "",
  ...props
}: InputHTMLAttributes<HTMLInputElement>) {
  return <input className={`${controlBase} ${className}`} {...props} />;
}

export function Textarea({
  className = "",
  rows = 3,
  ...props
}: TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return (
    <textarea
      rows={rows}
      className={`${controlBase} resize-none leading-relaxed ${className}`}
      {...props}
    />
  );
}

export function Select({
  className = "",
  children,
  ...props
}: SelectHTMLAttributes<HTMLSelectElement>) {
  return (
    <select className={`${controlBase} pr-9 ${className}`} {...props}>
      {children}
    </select>
  );
}

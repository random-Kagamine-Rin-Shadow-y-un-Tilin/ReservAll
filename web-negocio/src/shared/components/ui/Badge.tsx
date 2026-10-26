import type { ReactNode } from "react";

type BadgeTone = "primary" | "secondary" | "gold" | "neutral" | "success" | "danger";

const tones: Record<BadgeTone, string> = {
  primary: "bg-primary-tint text-primary",
  secondary: "bg-secondary-tint text-secondary",
  gold: "bg-highlight-tint text-highlight",
  neutral: "bg-surface-muted text-secondary-text",
  success: "bg-success-tint text-success",
  danger: "bg-error-tint text-error",
};

export function Badge({
  tone = "neutral",
  dot = false,
  className = "",
  children,
}: {
  tone?: BadgeTone;
  dot?: boolean;
  className?: string;
  children: ReactNode;
}) {
  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-semibold ${tones[tone]} ${className}`}
    >
      {dot && <span className="size-1.5 rounded-full bg-current" />}
      {children}
    </span>
  );
}

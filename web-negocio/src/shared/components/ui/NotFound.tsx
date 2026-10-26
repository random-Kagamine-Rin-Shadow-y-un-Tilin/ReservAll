import { Link } from "react-router-dom";
import { LuArrowLeft, LuCompass } from "react-icons/lu";
import { Button } from "./Button";

export function NotFound() {
  return (
    <div className="flex min-h-screen items-center justify-center px-4">
      <div className="w-full max-w-md rounded-3xl border border-border bg-card p-8 text-center shadow-soft">
        <span className="mx-auto flex size-14 items-center justify-center rounded-2xl bg-primary-tint text-2xl text-primary">
          <LuCompass />
        </span>
        <p className="mt-4 font-display text-4xl font-extrabold text-foreground">404</p>
        <h1 className="mt-1 font-display text-lg font-bold text-foreground">
          Esta página no existe
        </h1>
        <p className="mt-2 text-sm text-secondary-text">
          Puede que el enlace haya cambiado o que la sección aún no esté disponible.
        </p>
        <Link to="/dashboard" className="mt-6 inline-block">
          <Button leftIcon={<LuArrowLeft size={15} />}>Volver al panel</Button>
        </Link>
      </div>
    </div>
  );
}

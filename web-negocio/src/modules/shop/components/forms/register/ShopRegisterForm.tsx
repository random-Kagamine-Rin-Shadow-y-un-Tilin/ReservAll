import { useState, type ChangeEvent, type FormEvent } from "react";
import { useNavigate } from "react-router-dom";
import { LuImagePlus, LuSparkles, LuStore } from "react-icons/lu";
import { registerShop, uploadShopImage } from "../../../api";
import { useShop } from "../../../hooks/useShop";
import { SHOP_CATEGORIES } from "../../../../negocio/constants";
import { Button } from "../../../../../shared/components/ui/Button";
import { Field, Input, Select, Textarea } from "../../../../../shared/components/ui/Field";

export function ShopRegisterForm() {
  const navigate = useNavigate();
  const { refreshShops, selectShop } = useShop();

  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [category, setCategory] = useState<number>(SHOP_CATEGORIES[0].id);
  const [file, setFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);

  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  function handleFileChange(event: ChangeEvent<HTMLInputElement>) {
    const selected = event.target.files?.[0];
    if (!selected) return;

    if (!["image/jpeg", "image/png", "image/webp"].includes(selected.type)) {
      setError("Formato no permitido. Usa JPG, PNG o WEBP.");
      return;
    }
    if (selected.size > 5 * 1024 * 1024) {
      setError("La imagen no debe superar los 5 MB.");
      return;
    }

    setError(null);
    setFile(selected);
    setPreviewUrl(URL.createObjectURL(selected));
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError(null);

    if (!name.trim() || !description.trim()) {
      setError("El nombre y la descripción son obligatorios.");
      return;
    }

    setLoading(true);
    try {
      let imageUrl: string | undefined;
      if (file) {
        imageUrl = await uploadShopImage(file);
      }

      const shop = await registerShop({
        nombre: name.trim(),
        descripcion: description.trim(),
        imagen_negocio: imageUrl,
        categoria_negocio: category,
      });

      await refreshShops();
      selectShop(shop.id);
      navigate("/negocio", { replace: true });
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "No pudimos registrar tu negocio.",
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="grid gap-6 lg:grid-cols-[1.4fr_1fr]"
    >
      <div className="rounded-2xl border border-border bg-card p-5 shadow-soft sm:p-6">
        <div className="space-y-4">
          <Field label="Nombre del negocio" htmlFor="shop-name" required>
            <Input
              id="shop-name"
              value={name}
              onChange={(event) => setName(event.target.value)}
              placeholder="Ej. Barbería Aurora"
            />
          </Field>

          <Field
            label="Descripción"
            htmlFor="shop-description"
            hint="Cuéntale a tus clientes qué ofreces y qué te hace diferente."
            required
          >
            <Textarea
              id="shop-description"
              rows={4}
              value={description}
              onChange={(event) => setDescription(event.target.value)}
              placeholder="Ej. Barbería de barrio con atención personalizada, cortes clásicos y arreglo de barba."
            />
          </Field>

          <Field label="Categoría" htmlFor="shop-category" required>
            <Select
              id="shop-category"
              value={category}
              onChange={(event) => setCategory(Number(event.target.value))}
            >
              {SHOP_CATEGORIES.map((item) => (
                <option key={item.id} value={item.id}>
                  {item.nombre}
                </option>
              ))}
            </Select>
          </Field>

          <div>
            <p className="mb-2 text-sm font-semibold text-foreground">
              Imagen de portada
            </p>
            <div className="flex flex-wrap items-center gap-4 rounded-xl border border-border bg-surface/60 p-3">
              {previewUrl ? (
                <img
                  src={previewUrl}
                  alt="Vista previa"
                  className="size-20 rounded-xl border border-border object-cover"
                />
              ) : (
                <span className="flex size-20 items-center justify-center rounded-xl border border-dashed border-border-strong bg-card text-secondary-text">
                  <LuStore size={24} />
                </span>
              )}
              <div className="flex flex-col gap-1.5">
                <label
                  htmlFor="shop-cover"
                  className="inline-flex h-9 cursor-pointer items-center gap-2 rounded-lg border border-border bg-card px-3 text-xs font-semibold text-foreground transition-colors hover:border-primary-soft hover:text-primary"
                >
                  <LuImagePlus size={14} />
                  Seleccionar imagen
                </label>
                <input
                  id="shop-cover"
                  type="file"
                  accept="image/jpeg,image/png,image/webp"
                  onChange={handleFileChange}
                  className="hidden"
                />
                <p className="text-[11px] text-secondary-text">
                  JPG, PNG o WEBP · máx. 5 MB
                </p>
              </div>
            </div>
          </div>

          {error && (
            <div className="rounded-xl border border-error/20 bg-error-tint px-4 py-3 text-sm font-medium text-error">
              {error}
            </div>
          )}

          <div className="flex flex-col-reverse gap-2 border-t border-border/70 pt-4 sm:flex-row sm:justify-end">
            <Button
              variant="outline"
              onClick={() => navigate("/dashboard")}
              disabled={loading}
            >
              Cancelar
            </Button>
            <Button
              type="submit"
              loading={loading}
              leftIcon={<LuSparkles size={15} />}
            >
              Registrar negocio
            </Button>
          </div>
        </div>
      </div>

      <aside className="space-y-4">
        <div className="rounded-2xl border border-primary/15 bg-primary-tint/40 p-5">
          <span className="flex size-10 items-center justify-center rounded-xl bg-primary text-white">
            <LuStore size={18} />
          </span>
          <h3 className="mt-3 font-display text-base font-bold text-foreground">
            Después de registrarlo
          </h3>
          <ul className="mt-3 space-y-2.5">
            {[
              "Agrega tus servicios con duración y precio.",
              "Registra a las personas de tu equipo.",
              "Configura tus horarios de atención.",
              "Completa contactos y dirección.",
            ].map((item) => (
              <li key={item} className="flex items-start gap-2 text-xs text-secondary-text">
                <span className="mt-1.5 size-1.5 shrink-0 rounded-full bg-primary-soft" />
                {item}
              </li>
            ))}
          </ul>
        </div>

        <div className="rounded-2xl border border-border bg-card p-5 shadow-soft">
          <p className="text-[10px] font-bold uppercase tracking-[0.18em] text-secondary-text">
            Fase 1
          </p>
          <p className="mt-2 text-sm leading-relaxed text-secondary-text">
            El perfil del negocio, los servicios, los profesionales y los horarios ya
            están disponibles. Las reservas y los reportes llegarán después.
          </p>
        </div>
      </aside>
    </form>
  );
}

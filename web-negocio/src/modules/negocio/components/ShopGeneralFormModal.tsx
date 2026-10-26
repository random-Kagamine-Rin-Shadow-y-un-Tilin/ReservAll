import { useEffect, useState, type ChangeEvent } from "react";
import { LuImagePlus, LuStore } from "react-icons/lu";
import { editShop, uploadShopImage } from "../../shop/api";
import type { ShopGeneralInfo } from "../../shop/types";
import { Modal } from "../../../shared/components/Modal";
import { Button } from "../../../shared/components/ui/Button";
import { Field, Input, Select, Textarea } from "../../../shared/components/ui/Field";
import { SHOP_CATEGORIES } from "../constants";

interface ShopGeneralFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  shop: ShopGeneralInfo;
  onSaved: () => Promise<void> | void;
}

export function ShopGeneralFormModal({
  isOpen,
  onClose,
  shop,
  onSaved,
}: ShopGeneralFormModalProps) {
  const [nombre, setNombre] = useState(shop.nombre);
  const [descripcion, setDescripcion] = useState(shop.descripcion ?? "");
  const [categoria, setCategoria] = useState(shop.id_categoria);
  const [file, setFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const hasImage = Boolean(shop.imagen_negocio) && shop.imagen_negocio !== "null";

  useEffect(() => {
    if (!isOpen) return;
    setNombre(shop.nombre);
    setDescripcion(shop.descripcion ?? "");
    setCategoria(shop.id_categoria);
    setFile(null);
    setPreview(null);
    setError(null);
  }, [isOpen, shop]);

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
    setPreview(URL.createObjectURL(selected));
  }

  async function handleSubmit() {
    setError(null);

    if (!nombre.trim() || !descripcion.trim()) {
      setError("El nombre y la descripción son obligatorios.");
      return;
    }

    setLoading(true);
    try {
      let imageUrl = hasImage ? shop.imagen_negocio : "null";
      if (file) {
        imageUrl = await uploadShopImage(file);
      }

      await editShop(
        {
          nombre: nombre.trim(),
          descripcion: descripcion.trim(),
          imagen_negocio: imageUrl,
          fk_categoria: categoria,
        },
        shop.id,
      );

      await onSaved();
      onClose();
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "No pudimos actualizar el negocio.",
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Editar información del negocio"
      description="Estos datos se muestran en tu perfil público."
    >
      <div className="space-y-4">
        <Field label="Nombre del negocio" htmlFor="shop-name" required>
          <Input
            id="shop-name"
            value={nombre}
            onChange={(event) => setNombre(event.target.value)}
            placeholder="Ej. Barbería Aurora"
          />
        </Field>

        <Field label="Descripción" htmlFor="shop-description" required>
          <Textarea
            id="shop-description"
            value={descripcion}
            onChange={(event) => setDescripcion(event.target.value)}
            placeholder="Describe tu negocio y lo que lo hace especial."
          />
        </Field>

        <Field label="Categoría" htmlFor="shop-category" required>
          <Select
            id="shop-category"
            value={categoria}
            onChange={(event) => setCategoria(Number(event.target.value))}
          >
            {SHOP_CATEGORIES.map((category) => (
              <option key={category.id} value={category.id}>
                {category.nombre}
              </option>
            ))}
          </Select>
        </Field>

        <div>
          <p className="mb-2 text-sm font-semibold text-foreground">
            Imagen de portada
          </p>
          <div className="flex flex-wrap items-center gap-4 rounded-xl border border-border bg-surface/60 p-3">
            {preview || hasImage ? (
              <img
                src={preview ?? shop.imagen_negocio}
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
                {hasImage || preview ? "Cambiar imagen" : "Subir imagen"}
              </label>
              <input
                id="shop-cover"
                type="file"
                accept="image/jpeg,image/png,image/webp"
                onChange={handleFileChange}
                className="hidden"
              />
              <p className="text-[11px] text-secondary-text">JPG, PNG o WEBP · máx. 5 MB</p>
            </div>
          </div>
        </div>

        {error && (
          <div className="rounded-xl border border-error/20 bg-error-tint px-4 py-3 text-sm font-medium text-error">
            {error}
          </div>
        )}

        <div className="flex flex-col-reverse gap-2 border-t border-border/70 pt-4 sm:flex-row sm:justify-end">
          <Button variant="outline" onClick={onClose}>
            Cancelar
          </Button>
          <Button onClick={handleSubmit} loading={loading}>
            Guardar cambios
          </Button>
        </div>
      </div>
    </Modal>
  );
}

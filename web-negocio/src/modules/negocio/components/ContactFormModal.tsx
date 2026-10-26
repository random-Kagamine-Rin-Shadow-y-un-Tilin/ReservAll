import { useEffect, useState } from "react";
import { LuLink, LuPlus, LuSave } from "react-icons/lu";
import { registerContact } from "../../shop/api";
import type { ShopContactInfo } from "../../shop/types";
import { editContact } from "../api";
import { SOCIAL_NETWORKS, socialLabel } from "../constants";
import { Modal } from "../../../shared/components/Modal";
import { Button } from "../../../shared/components/ui/Button";
import { Field, Input, Select } from "../../../shared/components/ui/Field";

interface ContactFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  shopId: number;
  contact?: ShopContactInfo | null;
  existingNetworks: string[];
  onSaved: () => Promise<void> | void;
}

export function ContactFormModal({
  isOpen,
  onClose,
  shopId,
  contact,
  existingNetworks,
  onSaved,
}: ContactFormModalProps) {
  const [network, setNetwork] = useState("instagram");
  const [url, setUrl] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const isEditing = Boolean(contact);
  const available = SOCIAL_NETWORKS.filter(
    (item) => !existingNetworks.includes(item.value),
  );

  useEffect(() => {
    if (!isOpen) return;
    setNetwork(contact?.nombre_red ?? available[0]?.value ?? "instagram");
    setUrl(contact?.url ?? "");
    setError(null);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isOpen, contact]);

  async function handleSubmit() {
    setError(null);

    if (!url.trim()) {
      setError("La URL o dato de contacto es obligatorio.");
      return;
    }

    setLoading(true);
    try {
      if (contact && contact.id_social) {
        await editContact(shopId, contact.id_social, url.trim());
      } else {
        await registerContact(shopId, {
          nombre_red: network,
          url: url.trim(),
        });
      }
      await onSaved();
      onClose();
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "No pudimos guardar el contacto.",
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={isEditing ? "Editar contacto" : "Nuevo contacto"}
      description="Agrega una forma para que tus clientes se comuniquen contigo."
      size="sm"
    >
      <div className="space-y-4">
        <Field label="Tipo de contacto" htmlFor="contact-network" required>
          {isEditing ? (
            <div className="rounded-xl border border-border bg-surface px-3.5 py-2.5 text-sm font-semibold text-foreground">
              {socialLabel(network)}
            </div>
          ) : available.length === 0 ? (
            <div className="rounded-xl border border-dashed border-border-strong bg-surface/60 px-4 py-3 text-xs text-secondary-text">
              Ya registraste todos los tipos de contacto disponibles.
            </div>
          ) : (
            <Select
              id="contact-network"
              value={network}
              onChange={(event) => setNetwork(event.target.value)}
            >
              {available.map((item) => (
                <option key={item.value} value={item.value}>
                  {item.label}
                </option>
              ))}
            </Select>
          )}
        </Field>

        <Field
          label="URL o dato"
          htmlFor="contact-url"
          hint="Ej. https://instagram.com/tu_negocio o +52 555 123 4567"
          required
        >
          <div className="relative">
            <LuLink
              size={15}
              className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-secondary-text"
            />
            <Input
              id="contact-url"
              value={url}
              onChange={(event) => setUrl(event.target.value)}
              className="pl-9"
              placeholder="https://..."
            />
          </div>
        </Field>

        {error && (
          <div className="rounded-xl border border-error/20 bg-error-tint px-4 py-3 text-sm font-medium text-error">
            {error}
          </div>
        )}

        <div className="flex flex-col-reverse gap-2 border-t border-border/70 pt-4 sm:flex-row sm:justify-end">
          <Button variant="outline" onClick={onClose}>
            Cancelar
          </Button>
          <Button
            onClick={handleSubmit}
            loading={loading}
            disabled={!isEditing && available.length === 0}
            leftIcon={isEditing ? <LuSave size={15} /> : <LuPlus size={15} />}
          >
            {isEditing ? "Guardar cambios" : "Agregar contacto"}
          </Button>
        </div>
      </div>
    </Modal>
  );
}

import { useState } from "react";
import { LuMapPin, LuMapPinned } from "react-icons/lu";
import { registerAddress } from "../../shop/api";
import type { ShopAddressRegister } from "../../shop/types";
import { useGeoLocation } from "../../ubication/hooks/useGeoLocation";
import { getAddressByCoord } from "../../ubication/api";
import { MapSelector } from "../../ubication/components/MapSelector";
import { Modal } from "../../../shared/components/Modal";
import { Button } from "../../../shared/components/ui/Button";
import { Field, Input } from "../../../shared/components/ui/Field";
import { Spinner } from "../../../shared/components/ui/Feedback";

interface AddressFormModalProps {
  onClose: () => void;
  shopId: number;
  onSaved: () => Promise<void> | void;
}

export function AddressFormModal({
  onClose,
  shopId,
  onSaved,
}: AddressFormModalProps) {
  const { coords, loading: geoLoading } = useGeoLocation();
  const [form, setForm] = useState<ShopAddressRegister>({
    direccion_calle: "",
    ciudad: "",
    estado: "",
    codigo_postal: "",
    pais: "México",
    latitud: coords.lat,
    longitud: coords.lng,
    osm_id: "",
    numero_local: "",
    numero_interior: "",
  });
  const [loadingAddress, setLoadingAddress] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  function update<K extends keyof ShopAddressRegister>(
    key: K,
    value: ShopAddressRegister[K],
  ) {
    setForm((current) => ({ ...current, [key]: value }));
  }

  async function handleChangePosition(position: { lat: number; lng: number }) {
    setLoadingAddress(true);
    setError(null);
    try {
      const data = await getAddressByCoord(position.lat, position.lng);
      setForm((current) => ({
        ...current,
        ...data,
        latitud: position.lat,
        longitud: position.lng,
        numero_local: current.numero_local,
        numero_interior: current.numero_interior,
      }));
    } catch {
      setError("No pudimos obtener la dirección de ese punto. Intenta con otro.");
    } finally {
      setLoadingAddress(false);
    }
  }

  async function handleSubmit() {
    setError(null);

    if (
      !form.direccion_calle.trim() ||
      !form.ciudad.trim() ||
      !form.estado.trim() ||
      !form.codigo_postal.trim() ||
      !form.numero_local.trim() ||
      !form.pais.trim()
    ) {
      setError("Completa los campos obligatorios de la dirección.");
      return;
    }

    setLoading(true);
    try {
      await registerAddress(shopId, form);
      await onSaved();
      onClose();
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "No pudimos registrar la dirección.",
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <Modal
      isOpen
      onClose={onClose}
      title="Registrar dirección"
      description="Selecciona la ubicación en el mapa y completa los datos del local."
      size="lg"
    >
      <div className="space-y-4">
        {geoLoading ? (
          <div className="flex h-48 flex-col items-center justify-center gap-2 rounded-xl border border-border bg-surface/60 text-secondary-text">
            <Spinner />
            <p className="text-xs font-medium">Detectando tu ubicación...</p>
          </div>
        ) : (
          <div className="overflow-hidden rounded-xl border border-border">
            <MapSelector initialPosition={coords} onChangePosition={handleChangePosition} />
          </div>
        )}

        <div className="flex items-center gap-2 text-xs text-secondary-text">
          <LuMapPinned size={14} className="text-primary" />
          Toca el mapa o arrastra el marcador para fijar la ubicación.
          {loadingAddress && <Spinner className="size-3.5" />}
        </div>

        <Field label="Calle" htmlFor="address-street" required>
          <Input
            id="address-street"
            value={form.direccion_calle}
            onChange={(event) => update("direccion_calle", event.target.value)}
            placeholder="Ej. Calle Francisco I. Madero"
          />
        </Field>

        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Ciudad" htmlFor="address-city" required>
            <Input
              id="address-city"
              value={form.ciudad}
              onChange={(event) => update("ciudad", event.target.value)}
              placeholder="Ej. Ciudad de México"
            />
          </Field>
          <Field label="Estado" htmlFor="address-state" required>
            <Input
              id="address-state"
              value={form.estado}
              onChange={(event) => update("estado", event.target.value)}
              placeholder="Ej. Tlaxcala"
            />
          </Field>
          <Field label="Código postal" htmlFor="address-zip" required>
            <Input
              id="address-zip"
              value={form.codigo_postal}
              onChange={(event) => update("codigo_postal", event.target.value)}
              placeholder="Ej. 90410"
            />
          </Field>
          <Field label="País" htmlFor="address-country" required>
            <Input
              id="address-country"
              value={form.pais}
              onChange={(event) => update("pais", event.target.value)}
            />
          </Field>
          <Field label="Número exterior" htmlFor="address-number" required>
            <Input
              id="address-number"
              value={form.numero_local}
              onChange={(event) => update("numero_local", event.target.value)}
              placeholder="Ej. 123"
            />
          </Field>
          <Field label="Número interior" htmlFor="address-interior" hint="Opcional">
            <Input
              id="address-interior"
              value={form.numero_interior}
              onChange={(event) => update("numero_interior", event.target.value)}
              placeholder="Ej. A"
            />
          </Field>
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
          <Button
            onClick={handleSubmit}
            loading={loading}
            leftIcon={<LuMapPin size={15} />}
          >
            Guardar dirección
          </Button>
        </div>
      </div>
    </Modal>
  );
}

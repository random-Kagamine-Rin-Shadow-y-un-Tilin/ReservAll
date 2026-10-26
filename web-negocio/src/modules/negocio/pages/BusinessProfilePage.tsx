import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import {
  LuExternalLink,
  LuEye,
  LuEyeOff,
  LuGlobe,
  LuInfo,
  LuMapPin,
  LuPencil,
  LuPlus,
  LuStore,
  LuTrash2,
} from "react-icons/lu";
import { getContactsByShop, getShopForId } from "../../shop/api";
import type { ShopContactInfo, ShopFullProfileOut } from "../../shop/types";
import { useShop } from "../../shop/hooks/useShop";
import { deleteContact, getPublicShopIds, toggleShopStatus } from "../api";
import { SOCIAL_NETWORKS, categoryLabel, socialLabel } from "../constants";
import { AddressFormModal } from "../components/AddressFormModal";
import { ContactFormModal } from "../components/ContactFormModal";
import { ContactIcon } from "../components/ContactIcon";
import { ShopGeneralFormModal } from "../components/ShopGeneralFormModal";
import { Badge } from "../../../shared/components/ui/Badge";
import { Button } from "../../../shared/components/ui/Button";
import { Card, CardHeader } from "../../../shared/components/ui/Card";
import { PageHeader } from "../../../shared/components/ui/PageHeader";
import {
  EmptyState,
  ErrorState,
  PageLoader,
} from "../../../shared/components/ui/Feedback";
import { Modal } from "../../../shared/components/Modal";

export function BusinessProfilePage() {
  const {
    selectedShop,
    selectedShopId,
    loading: shopLoading,
    refreshShops,
  } = useShop();

  const [profile, setProfile] = useState<ShopFullProfileOut | null>(null);
  const [contacts, setContacts] = useState<ShopContactInfo[]>([]);
  const [isPublic, setIsPublic] = useState<boolean | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [reloadKey, setReloadKey] = useState(0);

  const [generalModalOpen, setGeneralModalOpen] = useState(false);
  const [contactModalOpen, setContactModalOpen] = useState(false);
  const [editingContact, setEditingContact] = useState<ShopContactInfo | null>(null);
  const [toDeleteContact, setToDeleteContact] = useState<ShopContactInfo | null>(null);
  const [deletingContact, setDeletingContact] = useState(false);
  const [contactDeleteError, setContactDeleteError] = useState<string | null>(null);
  const [addressModalOpen, setAddressModalOpen] = useState(false);
  const [togglingStatus, setTogglingStatus] = useState(false);
  const [statusError, setStatusError] = useState<string | null>(null);

  useEffect(() => {
    if (!selectedShopId) {
      setLoading(false);
      return;
    }

    let active = true;
    setLoading(true);
    setError(null);

    Promise.allSettled([
      getShopForId(String(selectedShopId)),
      getContactsByShop(selectedShopId),
      getPublicShopIds(),
    ]).then(([profileResult, contactsResult, publicResult]) => {
      if (!active) return;

      if (profileResult.status === "fulfilled") {
        setProfile(profileResult.value);
      } else {
        setError(
          profileResult.reason instanceof Error
            ? profileResult.reason.message
            : "No pudimos cargar tu negocio.",
        );
      }

      if (contactsResult.status === "fulfilled") {
        setContacts(contactsResult.value);
      }

      if (publicResult.status === "fulfilled") {
        setIsPublic(
          publicResult.value
            ? publicResult.value.includes(selectedShopId)
            : null,
        );
      }

      setLoading(false);
    });

    return () => {
      active = false;
    };
  }, [selectedShopId, reloadKey]);

  async function reload() {
    setReloadKey((key) => key + 1);
  }

  async function handleGeneralSaved() {
    await refreshShops();
    await reload();
  }

  async function handleDeleteContact() {
    if (!selectedShopId || !toDeleteContact?.id_social) return;
    setDeletingContact(true);
    setContactDeleteError(null);
    try {
      await deleteContact(selectedShopId, toDeleteContact.id_social);
      setToDeleteContact(null);
      await reload();
    } catch (err) {
      setContactDeleteError(
        err instanceof Error ? err.message : "No pudimos eliminar el contacto.",
      );
    } finally {
      setDeletingContact(false);
    }
  }

  async function handleToggleStatus() {
    if (!selectedShopId || isPublic === null) return;
    setTogglingStatus(true);
    setStatusError(null);
    try {
      await toggleShopStatus(selectedShopId, !isPublic);
      setIsPublic(!isPublic);
    } catch (err) {
      setStatusError(
        err instanceof Error ? err.message : "No pudimos cambiar la visibilidad.",
      );
    } finally {
      setTogglingStatus(false);
    }
  }

  if (shopLoading || loading) {
    return <PageLoader label="Cargando el perfil de tu negocio..." />;
  }

  if (!selectedShopId || !selectedShop) {
    return (
      <EmptyState
        icon={<LuStore />}
        title="Todavía no tienes un negocio"
        description="Registra tu negocio para completar el perfil, contactos y dirección."
        action={
          <Link to="/negocio/registrar">
            <Button size="sm">Registrar negocio</Button>
          </Link>
        }
      />
    );
  }

  if (error || !profile) {
    return (
      <ErrorState
        title="No pudimos cargar tu negocio"
        message={error ?? undefined}
        onRetry={reload}
      />
    );
  }

  const general = profile.general;
  const address = profile.direccion;
  const hasImage = Boolean(general.imagen_negocio) && general.imagen_negocio !== "null";
  const existingNetworks = contacts.map((contact) => contact.nombre_red);

  return (
    <div className="space-y-6">
      <PageHeader
        eyebrow="Perfil público"
        title="Mi negocio"
        description="Administra la información que tus clientes verán, tus formas de contacto y tu ubicación."
        actions={
          <Button
            variant="outline"
            leftIcon={<LuPencil size={15} />}
            onClick={() => setGeneralModalOpen(true)}
          >
            Editar información
          </Button>
        }
      />

      <section className="overflow-hidden rounded-3xl border border-border bg-card shadow-soft">
        <div className="relative h-32 bg-gradient-to-r from-primary via-primary-soft to-highlight-soft sm:h-40">
          <div className="absolute inset-0 bg-[radial-gradient(circle_at_20%_20%,rgba(255,255,255,0.25),transparent_45%)]" />
        </div>
        <div className="px-5 pb-5 sm:px-6">
          <div className="flex items-end justify-between gap-4">
            <div className="-mt-12 sm:-mt-14">
              {hasImage ? (
                <img
                  src={general.imagen_negocio}
                  alt={general.nombre}
                  className="size-24 rounded-2xl border-4 border-card object-cover shadow-lg sm:size-28"
                />
              ) : (
                <span className="flex size-24 items-center justify-center rounded-2xl border-4 border-card bg-surface-muted text-3xl text-primary shadow-lg sm:size-28">
                  <LuStore />
                </span>
              )}
            </div>

            {isPublic !== null && (
              <Badge tone={isPublic ? "success" : "neutral"} dot className="mb-1">
                {isPublic ? "Visible al público" : "Oculto al público"}
              </Badge>
            )}
          </div>

          <div className="mt-3">
            <Badge tone="secondary">{categoryLabel(general.categoria_negocio)}</Badge>
            <h2 className="mt-1.5 font-display text-2xl font-extrabold text-foreground">
              {general.nombre}
            </h2>
          </div>

          <p className="mt-3 max-w-3xl text-sm leading-relaxed text-secondary-text">
            {general.descripcion || "Aún no has agregado una descripción."}
          </p>
        </div>
      </section>

      <div className="grid items-start gap-6 xl:grid-cols-2">
        <Card>
          <CardHeader
            title="Formas de contacto"
            subtitle="Canales visibles en tu perfil"
            icon={<LuGlobe />}
            action={
              <Button
                variant="outline"
                size="sm"
                leftIcon={<LuPlus size={14} />}
                onClick={() => {
                  setEditingContact(null);
                  setContactModalOpen(true);
                }}
                disabled={contacts.length >= SOCIAL_NETWORKS.length}
              >
                Agregar
              </Button>
            }
          />

          <div className="p-4">
            {contacts.length === 0 ? (
              <div className="rounded-xl border border-dashed border-border-strong bg-surface/60 px-4 py-8 text-center">
                <p className="text-sm font-semibold text-foreground">
                  Sin contactos registrados
                </p>
                <p className="mt-1 text-xs text-secondary-text">
                  Agrega redes sociales, teléfono o sitio web.
                </p>
              </div>
            ) : (
              <ul className="space-y-2">
                {contacts.map((contact) => (
                  <li
                    key={`${contact.nombre_red}-${contact.id_social ?? contact.url}`}
                    className="flex items-center gap-3 rounded-xl border border-border/70 bg-surface/50 px-3 py-2.5"
                  >
                    <span className="flex size-9 shrink-0 items-center justify-center rounded-xl bg-primary-tint text-primary">
                      <ContactIcon network={contact.nombre_red} size={17} />
                    </span>
                    <div className="min-w-0 flex-1">
                      <p className="text-xs font-semibold text-foreground">
                        {socialLabel(contact.nombre_red)}
                      </p>
                      <a
                        href={contact.url}
                        target="_blank"
                        rel="noreferrer"
                        className="flex items-center gap-1 truncate text-[11px] text-secondary-text hover:text-primary"
                      >
                        <span className="truncate">{contact.url}</span>
                        <LuExternalLink size={10} className="shrink-0" />
                      </a>
                    </div>
                    <div className="flex shrink-0 items-center gap-1">
                      <button
                        type="button"
                        aria-label="Editar contacto"
                        onClick={() => {
                          setEditingContact(contact);
                          setContactModalOpen(true);
                        }}
                        className="flex size-8 items-center justify-center rounded-lg text-secondary-text transition-colors hover:bg-primary-tint hover:text-primary"
                      >
                        <LuPencil size={14} />
                      </button>
                      <button
                        type="button"
                        aria-label="Eliminar contacto"
                        onClick={() => {
                          setContactDeleteError(null);
                          setToDeleteContact(contact);
                        }}
                        className="flex size-8 items-center justify-center rounded-lg text-secondary-text transition-colors hover:bg-error-tint hover:text-error"
                      >
                        <LuTrash2 size={14} />
                      </button>
                    </div>
                  </li>
                ))}
              </ul>
            )}
          </div>
        </Card>

        <div className="space-y-6">
          <Card>
            <CardHeader
              title="Dirección"
              subtitle="Ubicación de tu local"
              icon={<LuMapPin />}
              action={
                !address ? (
                  <Button
                    variant="outline"
                    size="sm"
                    leftIcon={<LuPlus size={14} />}
                    onClick={() => setAddressModalOpen(true)}
                  >
                    Registrar
                  </Button>
                ) : undefined
              }
            />

            <div className="p-4">
              {address ? (
                <div className="space-y-3">
                  <div className="rounded-xl border border-border/70 bg-surface/50 p-4">
                    <p className="text-sm font-semibold text-foreground">
                      {address.direccion_calle} {address.numero_local}
                      {address.numero_interior &&
                      address.numero_interior !== "Sin Número"
                        ? `, Int. ${address.numero_interior}`
                        : ""}
                    </p>
                    <p className="mt-1 text-xs text-secondary-text">
                      {address.ciudad}, {address.estado} · CP {address.codigo_postal}
                    </p>
                    <p className="text-xs text-secondary-text">{address.pais}</p>
                  </div>

                  <div className="flex items-center justify-between gap-2">
                    <a
                      href={`https://www.google.com/maps?q=${address.latitud},${address.longitud}`}
                      target="_blank"
                      rel="noreferrer"
                      className="inline-flex items-center gap-1.5 text-xs font-semibold text-primary hover:underline"
                    >
                      <LuExternalLink size={12} />
                      Ver en el mapa
                    </a>
                    <span className="flex items-center gap-1 text-[10px] font-medium text-secondary-text">
                      <LuInfo size={11} />
                      La edición llegará pronto
                    </span>
                  </div>
                </div>
              ) : (
                <div className="rounded-xl border border-dashed border-border-strong bg-surface/60 px-4 py-6 text-center">
                  <p className="text-sm font-semibold text-foreground">
                    Sin dirección registrada
                  </p>
                  <p className="mt-1 text-xs text-secondary-text">
                    Registra la ubicación para que tus clientes puedan encontrarte.
                  </p>
                </div>
              )}
            </div>
          </Card>

          <Card>
            <CardHeader
              title="Visibilidad"
              subtitle="Controla si apareces en el directorio"
              icon={isPublic ? <LuEye /> : <LuEyeOff />}
            />
            <div className="p-4">
              <div className="flex items-center justify-between gap-3 rounded-xl border border-border/70 bg-surface/50 px-4 py-3">
                <div>
                  <p className="text-sm font-semibold text-foreground">
                    {isPublic === null
                      ? "Estado no disponible"
                      : isPublic
                        ? "Tu negocio es visible"
                        : "Tu negocio está oculto"}
                  </p>
                  <p className="mt-0.5 text-xs text-secondary-text">
                    {isPublic === null
                      ? "No pudimos consultar la visibilidad actual."
                      : isPublic
                        ? "Los clientes pueden encontrarte en el directorio."
                        : "Actívalo para que los clientes puedan reservarte."}
                  </p>
                </div>
                <Button
                  variant={isPublic ? "outline" : "primary"}
                  size="sm"
                  loading={togglingStatus}
                  disabled={isPublic === null}
                  onClick={handleToggleStatus}
                  leftIcon={isPublic ? <LuEyeOff size={14} /> : <LuEye size={14} />}
                >
                  {isPublic ? "Ocultar" : "Publicar"}
                </Button>
              </div>
              {statusError && (
                <p className="mt-2 text-xs font-medium text-error">{statusError}</p>
              )}
            </div>
          </Card>
        </div>
      </div>

      <ShopGeneralFormModal
        isOpen={generalModalOpen}
        onClose={() => setGeneralModalOpen(false)}
        shop={general}
        onSaved={handleGeneralSaved}
      />

      <ContactFormModal
        isOpen={contactModalOpen}
        onClose={() => setContactModalOpen(false)}
        shopId={selectedShopId}
        contact={editingContact}
        existingNetworks={existingNetworks}
        onSaved={reload}
      />

      {addressModalOpen && (
        <AddressFormModal
          onClose={() => setAddressModalOpen(false)}
          shopId={selectedShopId}
          onSaved={reload}
        />
      )}

      <Modal
        isOpen={Boolean(toDeleteContact)}
        onClose={() => setToDeleteContact(null)}
        title="Eliminar contacto"
        size="sm"
      >
        <div className="space-y-4">
          <p className="text-sm leading-relaxed text-secondary-text">
            ¿Eliminar el contacto de{" "}
            <strong className="text-foreground">
              {toDeleteContact ? socialLabel(toDeleteContact.nombre_red) : ""}
            </strong>
            ? Dejará de mostrarse en tu perfil público.
          </p>

          {contactDeleteError && (
            <div className="rounded-xl border border-error/20 bg-error-tint px-4 py-3 text-sm font-medium text-error">
              {contactDeleteError}
            </div>
          )}

          <div className="flex flex-col-reverse gap-2 border-t border-border/70 pt-4 sm:flex-row sm:justify-end">
            <Button variant="outline" onClick={() => setToDeleteContact(null)}>
              Cancelar
            </Button>
            <Button
              variant="danger"
              loading={deletingContact}
              onClick={handleDeleteContact}
            >
              Sí, eliminar
            </Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}

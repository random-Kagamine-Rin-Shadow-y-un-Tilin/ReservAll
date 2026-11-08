import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import {
  LuCheck,
  LuClock,
  LuListChecks,
  LuPencil,
  LuPlus,
  LuPower,
  LuTag,
  LuUsers,
} from "react-icons/lu";
import { editService, getProfessionals, getServices } from "../api";
import {
  formatDuration,
  formatPrice,
  serviceCategoryLabel,
} from "../constants";
import type { Professional, Service } from "../types";
import { useShop } from "../../shop/hooks/useShop";
import { Badge } from "../../../shared/components/ui/Badge";
import { Button } from "../../../shared/components/ui/Button";
import { Card } from "../../../shared/components/ui/Card";
import { PageHeader } from "../../../shared/components/ui/PageHeader";
import {
  EmptyState,
  ErrorState,
  PageLoader,
} from "../../../shared/components/ui/Feedback";
import { Modal } from "../../../shared/components/Modal";
import { ServiceFormModal } from "../components/ServiceFormModal";

export function ServicesPage() {
  const { selectedShop, selectedShopId, loading: shopLoading } = useShop();
  const [services, setServices] = useState<Service[]>([]);
  const [professionals, setProfessionals] = useState<Professional[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<Service | null>(null);
  const [toDeactivate, setToDeactivate] = useState<Service | null>(null);
  const [deactivating, setDeactivating] = useState(false);
  const [deactivateError, setDeactivateError] = useState<string | null>(null);
  const [togglingId, setTogglingId] = useState<number | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [reloadKey, setReloadKey] = useState(0);

  useEffect(() => {
    if (!selectedShopId) {
      setLoading(false);
      return;
    }

    let active = true;
    setLoading(true);
    setError(null);

    Promise.all([getServices(selectedShopId), getProfessionals(selectedShopId)])
      .then(([servicesData, professionalsData]) => {
        if (!active) return;
        setServices(servicesData);
        setProfessionals(professionalsData);
      })
      .catch((err) => {
        if (!active) return;
        setError(
          err instanceof Error ? err.message : "No pudimos cargar los servicios.",
        );
      })
      .finally(() => {
        if (active) setLoading(false);
      });

    return () => {
      active = false;
    };
  }, [selectedShopId, reloadKey]);

  useEffect(() => {
    if (!notice) return;
    const timer = window.setTimeout(() => setNotice(null), 4000);
    return () => window.clearTimeout(timer);
  }, [notice]);

  async function reload() {
    setReloadKey((key) => key + 1);
  }

  function openCreate() {
    setEditing(null);
    setModalOpen(true);
  }

  function openEdit(service: Service) {
    setEditing(service);
    setModalOpen(true);
  }

  async function activate(service: Service) {
    if (!selectedShopId) return;
    setTogglingId(service.id_servicio);
    setError(null);
    try {
      await editService(selectedShopId, service.id_servicio, {
        estado_servicio: true,
      });
      setNotice(`"${service.nombre}" ya está activo.`);
      await reload();
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "No pudimos activar el servicio.",
      );
    } finally {
      setTogglingId(null);
    }
  }

  async function handleDeactivate() {
    if (!selectedShopId || !toDeactivate) return;
    setDeactivating(true);
    setDeactivateError(null);
    try {
      await editService(selectedShopId, toDeactivate.id_servicio, {
        estado_servicio: false,
      });
      setNotice(`"${toDeactivate.nombre}" quedó inactivo.`);
      setToDeactivate(null);
      await reload();
    } catch (err) {
      setDeactivateError(
        err instanceof Error
          ? err.message
          : "No pudimos desactivar el servicio.",
      );
    } finally {
      setDeactivating(false);
    }
  }

  if (shopLoading || loading) {
    return <PageLoader label="Cargando tu catálogo..." />;
  }

  if (!selectedShop) {
    return (
      <EmptyState
        icon={<LuListChecks />}
        title="Primero registra tu negocio"
        description="Necesitas un negocio para poder crear servicios."
        action={
          <Link to="/negocio/registrar">
            <Button size="sm">Registrar negocio</Button>
          </Link>
        }
      />
    );
  }

  const activeCount = services.filter((service) => service.estado_servicio).length;

  return (
    <div>
      <PageHeader
        eyebrow="Catálogo"
        title="Servicios"
        description="Lo que tus clientes pueden reservar. Agrega servicios con su duración, precio y equipo disponible."
        actions={
          <Button leftIcon={<LuPlus size={16} />} onClick={openCreate}>
            Nuevo servicio
          </Button>
        }
      />

      {error ? (
        <ErrorState message={error} onRetry={reload} />
      ) : (
        <div className="space-y-5">
          <div className="flex flex-wrap items-center gap-2">
            <Badge tone="primary">{services.length} servicios</Badge>
            <Badge tone="success" dot>
              {activeCount} activos
            </Badge>
            <Badge tone="neutral">{professionals.length} profesionales</Badge>
          </div>

          {notice && (
            <div className="flex items-center gap-2 rounded-xl border border-success/20 bg-success-tint px-4 py-3 text-sm font-semibold text-success">
              <LuCheck size={16} />
              {notice}
            </div>
          )}

          {services.length === 0 ? (
            <EmptyState
              icon={<LuListChecks />}
              title="Todavía no tienes servicios"
              description="Crea tu primer servicio para que tus clientes sepan qué ofreces."
              action={
                <Button
                  size="sm"
                  leftIcon={<LuPlus size={15} />}
                  onClick={openCreate}
                >
                  Crear mi primer servicio
                </Button>
              }
            />
          ) : (
            <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
              {services.map((service) => (
                <Card
                  key={service.id_servicio}
                  className="flex flex-col p-5 transition-shadow hover:shadow-lift"
                >
                  <div className="flex items-start justify-between gap-2">
                    <Badge tone="secondary">
                      {serviceCategoryLabel(service.categoria_servicio)}
                    </Badge>
                    <Badge tone={service.estado_servicio ? "success" : "neutral"} dot>
                      {service.estado_servicio ? "Activo" : "Inactivo"}
                    </Badge>
                  </div>

                  <h3 className="mt-3 font-display text-lg font-bold text-foreground">
                    {service.nombre}
                  </h3>
                  <p className="mt-1 line-clamp-2 min-h-10 text-sm leading-relaxed text-secondary-text">
                    {service.descripcion || "Sin descripción."}
                  </p>

                  <div className="mt-4 grid grid-cols-2 gap-2">
                    <div className="rounded-xl bg-surface px-3 py-2">
                      <p className="flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-wide text-secondary-text">
                        <LuClock size={11} />
                        Duración
                      </p>
                      <p className="mt-0.5 text-sm font-semibold text-foreground">
                        {formatDuration(service.duracion_minutos)}
                      </p>
                    </div>
                    <div className="rounded-xl bg-surface px-3 py-2">
                      <p className="flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-wide text-secondary-text">
                        <LuTag size={11} />
                        Precio
                      </p>
                      <p className="mt-0.5 text-sm font-semibold text-foreground">
                        {formatPrice(service.precio)}
                      </p>
                    </div>
                  </div>

                  <div className="mt-4 flex-1">
                    <p className="flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-wide text-secondary-text">
                      <LuUsers size={11} />
                      Profesionales
                    </p>
                    <div className="mt-1.5 flex flex-wrap gap-1.5">
                      {service.profesionales.length > 0 ? (
                        service.profesionales.map((professional) => (
                          <span
                            key={professional.id_profesional}
                            className="rounded-full bg-secondary-tint px-2 py-0.5 text-[10px] font-semibold text-secondary"
                          >
                            {professional.nombre}
                          </span>
                        ))
                      ) : (
                        <span className="text-xs text-secondary-text">
                          Sin asignar
                        </span>
                      )}
                    </div>
                  </div>

                  <div className="mt-4 flex items-center gap-2 border-t border-border/70 pt-3">
                    <Button
                      variant="ghost"
                      size="sm"
                      leftIcon={<LuPencil size={14} />}
                      onClick={() => openEdit(service)}
                    >
                      Editar
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      loading={togglingId === service.id_servicio}
                      className={
                        service.estado_servicio ? "text-error/70" : "text-success"
                      }
                      leftIcon={<LuPower size={14} />}
                      onClick={() =>
                        service.estado_servicio
                          ? setToDeactivate(service)
                          : activate(service)
                      }
                    >
                      {service.estado_servicio ? "Desactivar" : "Activar"}
                    </Button>
                  </div>
                </Card>
              ))}
            </div>
          )}
        </div>
      )}

      {selectedShopId && (
        <ServiceFormModal
          isOpen={modalOpen}
          onClose={() => {
            setModalOpen(false);
            setEditing(null);
          }}
          shopId={selectedShopId}
          professionals={professionals}
          service={editing}
          onSaved={reload}
        />
      )}

      <Modal
        isOpen={Boolean(toDeactivate)}
        onClose={() => {
          if (deactivating) return;
          setToDeactivate(null);
        }}
        title="Desactivar servicio"
        size="sm"
      >
        {toDeactivate && (
          <div className="space-y-4">
            <p className="text-sm leading-relaxed text-secondary-text">
              ¿Desactivar{" "}
              <strong className="text-foreground">{toDeactivate.nombre}</strong>?
              Dejará de aparecer para que tus clientes lo reserven, pero podrás
              reactivarlo cuando quieras.
            </p>

            {deactivateError && (
              <div className="rounded-xl border border-error/20 bg-error-tint px-4 py-3 text-sm font-medium text-error">
                {deactivateError}
              </div>
            )}

            <div className="flex flex-col-reverse gap-2 border-t border-border/70 pt-4 sm:flex-row sm:justify-end">
              <Button
                variant="outline"
                onClick={() => setToDeactivate(null)}
                disabled={deactivating}
              >
                Volver
              </Button>
              <Button
                variant="danger"
                loading={deactivating}
                onClick={handleDeactivate}
              >
                Sí, desactivar
              </Button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}

import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import {
  LuClock,
  LuInfo,
  LuListChecks,
  LuLock,
  LuPencil,
  LuPlus,
  LuTag,
  LuTrash2,
  LuUsers,
} from "react-icons/lu";
import { getProfessionals, getServices } from "../api";
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
import { ServiceFormModal } from "../components/ServiceFormModal";

export function ServicesPage() {
  const { selectedShop, selectedShopId, loading: shopLoading } = useShop();
  const [services, setServices] = useState<Service[]>([]);
  const [professionals, setProfessionals] = useState<Professional[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [modalOpen, setModalOpen] = useState(false);
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

  async function reload() {
    setReloadKey((key) => key + 1);
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
          <Button leftIcon={<LuPlus size={16} />} onClick={() => setModalOpen(true)}>
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

          <div className="flex items-start gap-2.5 rounded-xl border border-highlight/20 bg-highlight-tint/50 px-4 py-3">
            <LuInfo size={17} className="mt-0.5 shrink-0 text-highlight" />
            <p className="text-xs leading-relaxed text-secondary-text">
              Ya puedes crear servicios. La <strong>edición y eliminación</strong> se
              habilitarán en la siguiente fase, cuando el backend termine de implementar
              esas operaciones.
            </p>
          </div>

          {services.length === 0 ? (
            <EmptyState
              icon={<LuListChecks />}
              title="Todavía no tienes servicios"
              description="Crea tu primer servicio para que tus clientes sepan qué ofreces."
              action={
                <Button
                  size="sm"
                  leftIcon={<LuPlus size={15} />}
                  onClick={() => setModalOpen(true)}
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
                      disabled
                      title="Disponible en la siguiente fase"
                      leftIcon={<LuPencil size={14} />}
                    >
                      Editar
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      disabled
                      title="Disponible en la siguiente fase"
                      className="text-error/60"
                      leftIcon={<LuTrash2 size={14} />}
                    >
                      Eliminar
                    </Button>
                    <span className="ml-auto flex items-center gap-1 text-[10px] font-medium text-secondary-text">
                      <LuLock size={10} />
                      Pronto
                    </span>
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
          onClose={() => setModalOpen(false)}
          shopId={selectedShopId}
          professionals={professionals}
          onSaved={reload}
        />
      )}
    </div>
  );
}

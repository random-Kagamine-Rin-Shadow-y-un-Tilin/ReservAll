import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import {
  LuInfo,
  LuPencil,
  LuPlus,
  LuTrash2,
  LuUserPlus,
  LuUsers,
} from "react-icons/lu";
import { deleteProfessional, getProfessionals } from "../api";
import type { Professional } from "../types";
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
import { ProfessionalFormModal } from "../components/ProfessionalFormModal";

const avatarTones = [
  "bg-primary-tint text-primary",
  "bg-secondary-tint text-secondary",
  "bg-highlight-tint text-highlight",
  "bg-surface-muted text-foreground",
];

function initials(name: string): string {
  return name
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part.charAt(0).toUpperCase())
    .join("");
}

export function ProfessionalsPage() {
  const { selectedShop, selectedShopId, loading: shopLoading } = useShop();
  const [professionals, setProfessionals] = useState<Professional[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<Professional | null>(null);
  const [toDelete, setToDelete] = useState<Professional | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [deleteError, setDeleteError] = useState<string | null>(null);
  const [reloadKey, setReloadKey] = useState(0);

  useEffect(() => {
    if (!selectedShopId) {
      setLoading(false);
      return;
    }

    let active = true;
    setLoading(true);
    setError(null);

    getProfessionals(selectedShopId)
      .then((data) => {
        if (active) setProfessionals(data);
      })
      .catch((err) => {
        if (!active) return;
        setError(
          err instanceof Error ? err.message : "No pudimos cargar el equipo.",
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

  function openCreate() {
    setEditing(null);
    setModalOpen(true);
  }

  function openEdit(professional: Professional) {
    setEditing(professional);
    setModalOpen(true);
  }

  async function handleDelete() {
    if (!selectedShopId || !toDelete) return;
    setDeleting(true);
    setDeleteError(null);
    try {
      await deleteProfessional(selectedShopId, toDelete.id_profesional);
      setToDelete(null);
      await reload();
    } catch (err) {
      setDeleteError(
        err instanceof Error
          ? err.message
          : "No pudimos desactivar al profesional.",
      );
    } finally {
      setDeleting(false);
    }
  }

  if (shopLoading || loading) {
    return <PageLoader label="Cargando tu equipo..." />;
  }

  if (!selectedShop) {
    return (
      <EmptyState
        icon={<LuUsers />}
        title="Primero registra tu negocio"
        description="Necesitas un negocio para poder agregar profesionales."
        action={
          <Link to="/negocio/registrar">
            <Button size="sm">Registrar negocio</Button>
          </Link>
        }
      />
    );
  }

  return (
    <div>
      <PageHeader
        eyebrow="Equipo"
        title="Profesionales"
        description="Las personas que atienden tus servicios. Podrás asignarlos al crear cada servicio."
        actions={
          <Button leftIcon={<LuPlus size={16} />} onClick={openCreate}>
            Nuevo profesional
          </Button>
        }
      />

      {error ? (
        <ErrorState message={error} onRetry={reload} />
      ) : (
        <div className="space-y-5">
          <div className="flex flex-wrap items-center gap-2">
            <Badge tone="secondary">{professionals.length} activos</Badge>
            <Badge tone="neutral">Se muestran solo profesionales activos</Badge>
          </div>

          <div className="flex items-start gap-2.5 rounded-xl border border-highlight/20 bg-highlight-tint/50 px-4 py-3">
            <LuInfo size={17} className="mt-0.5 shrink-0 text-highlight" />
            <p className="text-xs leading-relaxed text-secondary-text">
              Al eliminar a un profesional, su cuenta se marca como{" "}
              <strong>inactiva</strong> en lugar de borrarse. Dejará de aparecer en este
              listado y en los servicios nuevos.
            </p>
          </div>

          {professionals.length === 0 ? (
            <EmptyState
              icon={<LuUserPlus />}
              title="Tu equipo está vacío"
              description="Agrega a la primera persona que atiende tus servicios."
              action={
                <Button
                  size="sm"
                  leftIcon={<LuPlus size={15} />}
                  onClick={openCreate}
                >
                  Agregar profesional
                </Button>
              }
            />
          ) : (
            <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
              {professionals.map((professional, index) => (
                <Card
                  key={professional.id_profesional}
                  className="p-5 transition-shadow hover:shadow-lift"
                >
                  <div className="flex items-start justify-between gap-2">
                    <div className="flex items-center gap-3">
                      <span
                        className={`flex size-12 items-center justify-center rounded-2xl font-display text-base font-extrabold ${
                          avatarTones[index % avatarTones.length]
                        }`}
                      >
                        {initials(professional.nombre)}
                      </span>
                      <div className="min-w-0">
                        <h3 className="truncate font-display text-base font-bold text-foreground">
                          {professional.nombre}
                        </h3>
                        <p className="truncate text-xs text-secondary-text">
                          {professional.especialidad || "Sin especialidad"}
                        </p>
                      </div>
                    </div>
                    <Badge tone="success" dot>
                      Activo
                    </Badge>
                  </div>

                  <div className="mt-5 flex items-center gap-1 border-t border-border/70 pt-3">
                    <Button
                      variant="ghost"
                      size="sm"
                      leftIcon={<LuPencil size={14} />}
                      onClick={() => openEdit(professional)}
                    >
                      Editar
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      className="ml-auto text-error/80 hover:bg-error-tint hover:text-error"
                      leftIcon={<LuTrash2 size={14} />}
                      onClick={() => {
                        setDeleteError(null);
                        setToDelete(professional);
                      }}
                    >
                      Desactivar
                    </Button>
                  </div>
                </Card>
              ))}
            </div>
          )}
        </div>
      )}

      {selectedShopId && (
        <ProfessionalFormModal
          isOpen={modalOpen}
          onClose={() => setModalOpen(false)}
          shopId={selectedShopId}
          professional={editing}
          onSaved={reload}
        />
      )}

      <Modal
        isOpen={Boolean(toDelete)}
        onClose={() => setToDelete(null)}
        title="Desactivar profesional"
        size="sm"
      >
        <div className="space-y-4">
          <p className="text-sm leading-relaxed text-secondary-text">
            ¿Seguro que quieres desactivar a{" "}
            <strong className="text-foreground">{toDelete?.nombre}</strong>? Dejará de
            aparecer en el listado y no podrá asignarse a servicios nuevos.
          </p>

          {deleteError && (
            <div className="rounded-xl border border-error/20 bg-error-tint px-4 py-3 text-sm font-medium text-error">
              {deleteError}
            </div>
          )}

          <div className="flex flex-col-reverse gap-2 border-t border-border/70 pt-4 sm:flex-row sm:justify-end">
            <Button variant="outline" onClick={() => setToDelete(null)}>
              Cancelar
            </Button>
            <Button variant="danger" loading={deleting} onClick={handleDelete}>
              Sí, desactivar
            </Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}

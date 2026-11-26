import { useEffect, useState, type FormEvent } from "react";
import { useNavigate } from "react-router-dom";
import {
  LuCircleAlert,
  LuLogOut,
  LuPencil,
  LuPlus,
  LuTags,
  LuTrash2,
} from "react-icons/lu";
import {
  createCategory,
  deleteCategory,
  getCategories,
  updateCategory,
} from "../api";
import type { Category, CategoryUpdatePayload } from "../types";
import { Brand } from "../../../shared/components/layout/Brand";
import { Badge } from "../../../shared/components/ui/Badge";
import { Button } from "../../../shared/components/ui/Button";
import { Card } from "../../../shared/components/ui/Card";
import { Field, Input, Textarea } from "../../../shared/components/ui/Field";
import { EmptyState, ErrorState, PageLoader } from "../../../shared/components/ui/Feedback";
import { Modal } from "../../../shared/components/Modal";
import { useAuth } from "../../auth/hooks/useAuth";

export function CategoriesPage() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [showInactive, setShowInactive] = useState(true);
  const [reloadKey, setReloadKey] = useState(0);

  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<Category | null>(null);
  const [nombre, setNombre] = useState("");
  const [descripcion, setDescripcion] = useState("");
  const [estado, setEstado] = useState(true);
  const [saving, setSaving] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  const [toDelete, setToDelete] = useState<Category | null>(null);
  const [deleting, setDeleting] = useState(false);

  useEffect(() => {
    let active = true;
    setLoading(true);
    setError(null);

    getCategories(showInactive)
      .then((data) => {
        if (active) setCategories(data);
      })
      .catch((err) => {
        if (active) {
          setError(
            err instanceof Error ? err.message : "No pudimos cargar las categorías.",
          );
        }
      })
      .finally(() => {
        if (active) setLoading(false);
      });

    return () => {
      active = false;
    };
  }, [showInactive, reloadKey]);

  function reload() {
    setReloadKey((key) => key + 1);
  }

  function openCreate() {
    setEditing(null);
    setNombre("");
    setDescripcion("");
    setEstado(true);
    setFormError(null);
    setModalOpen(true);
  }

  function openEdit(category: Category) {
    setEditing(category);
    setNombre(category.nombre_categoria);
    setDescripcion(category.descripcion ?? "");
    setEstado(category.estado);
    setFormError(null);
    setModalOpen(true);
  }

  async function handleSave(event: FormEvent) {
    event.preventDefault();
    setFormError(null);
    const nombreLimpio = nombre.trim();
    if (nombreLimpio.length < 2 || nombreLimpio.length > 100) {
      setFormError("El nombre debe tener entre 2 y 100 caracteres.");
      return;
    }
    if (descripcion.length > 500) {
      setFormError("La descripción no puede superar los 500 caracteres.");
      return;
    }

    setSaving(true);
    try {
      if (editing) {
        await updateCategory(editing.id_categoria, {
          nombre_categoria: nombreLimpio,
          descripcion: descripcion.trim() || null,
          estado,
        });
      } else {
        await createCategory({
          nombre_categoria: nombreLimpio,
          descripcion: descripcion.trim() || null,
          estado,
        });
      }
      setNotice(
        editing
          ? "Categoría actualizada correctamente."
          : "Categoría creada correctamente.",
      );
      setModalOpen(false);
      reload();
    } catch (err) {
      setFormError(
        err instanceof Error ? err.message : "No pudimos guardar la categoría.",
      );
    } finally {
      setSaving(false);
    }
  }

  async function handleToggle(category: Category) {
    setNotice(null);
    try {
      const payload: CategoryUpdatePayload = { estado: !category.estado };
      await updateCategory(category.id_categoria, payload);
      setNotice(
        category.estado
          ? "Categoría desactivada. Ya no aparecerá en el catálogo público."
          : "Categoría activada.",
      );
      reload();
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "No pudimos cambiar el estado.",
      );
    }
  }

  async function handleDelete() {
    if (!toDelete) return;
    setDeleting(true);
    setNotice(null);
    try {
      const result = await deleteCategory(toDelete.id_categoria);
      setNotice(result.message);
      setToDelete(null);
      reload();
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "No pudimos eliminar la categoría.",
      );
    } finally {
      setDeleting(false);
    }
  }

  async function handleLogout() {
    await logout();
    navigate("/login", { replace: true });
  }

  return (
    <div className="min-h-screen bg-background">
      <header className="flex h-16 items-center justify-between gap-4 border-b border-border/70 bg-card px-4 sm:px-8">
        <div className="flex items-center gap-4">
          <Brand />
          <span className="hidden text-sm font-semibold text-secondary-text sm:inline">
            Administración
          </span>
        </div>
        <div className="flex items-center gap-3">
          <span className="hidden text-xs text-secondary-text sm:inline">
            {user?.correo}
          </span>
          <Button
            variant="outline"
            size="sm"
            leftIcon={<LuLogOut size={14} />}
            onClick={handleLogout}
          >
            Salir
          </Button>
        </div>
      </header>

      <main className="mx-auto w-full max-w-6xl px-4 py-8 sm:px-8">
        <div className="flex flex-wrap items-end justify-between gap-4">
          <div>
            <p className="text-[11px] font-bold uppercase tracking-[0.18em] text-primary">
              HU_14 · Administración
            </p>
            <h1 className="mt-2 font-display text-3xl font-extrabold text-foreground">
              Categorías
            </h1>
            <p className="mt-2 max-w-2xl text-sm text-secondary-text">
              Clasifica los negocios del catálogo. Al desactivar una categoría, sus
              negocios dejan de mostrarse en el catálogo y el mapa público.
            </p>
          </div>
          <Button leftIcon={<LuPlus size={16} />} onClick={openCreate}>
            Nueva categoría
          </Button>
        </div>

        {notice && (
          <div className="mt-6 rounded-xl border border-success/20 bg-success-tint px-4 py-3 text-sm font-medium text-success">
            {notice}
          </div>
        )}

        {error && (
          <div className="mt-6 flex items-start gap-2 rounded-xl border border-error/20 bg-error-tint px-4 py-3 text-sm font-medium text-error">
            <LuCircleAlert size={16} className="mt-0.5 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        <Card className="mt-6 overflow-hidden">
          <div className="flex items-center justify-between gap-3 border-b border-border/70 px-5 py-4">
            <div className="flex items-center gap-2 text-sm font-semibold text-foreground">
              <LuTags size={16} className="text-primary" />
              Listado de categorías
            </div>
            <label className="flex items-center gap-2 text-xs text-secondary-text">
              <input
                type="checkbox"
                checked={showInactive}
                onChange={(event) => setShowInactive(event.target.checked)}
                className="size-4 accent-[var(--color-primary)]"
              />
              Incluir inactivas
            </label>
          </div>

          {loading ? (
            <div className="p-6">
              <PageLoader label="Cargando categorías..." />
            </div>
          ) : error ? (
            <div className="p-6">
              <ErrorState message={error} onRetry={reload} />
            </div>
          ) : categories.length === 0 ? (
            <div className="p-6">
              <EmptyState
                icon={<LuTags />}
                title="No hay categorías"
                description="Crea la primera categoría para organizar el catálogo."
              />
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead className="bg-surface/60 text-[11px] uppercase tracking-wide text-secondary-text">
                  <tr>
                    <th className="px-5 py-3 font-bold">Nombre</th>
                    <th className="px-5 py-3 font-bold">Descripción</th>
                    <th className="px-5 py-3 font-bold">Negocios</th>
                    <th className="px-5 py-3 font-bold">Estado</th>
                    <th className="px-5 py-3 font-bold text-right">Acciones</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border/70">
                  {categories.map((category) => (
                    <tr key={category.id_categoria}>
                      <td className="px-5 py-4 font-semibold text-foreground">
                        {category.nombre_categoria}
                      </td>
                      <td className="max-w-xs px-5 py-4 text-secondary-text">
                        <span className="line-clamp-2">
                          {category.descripcion || "—"}
                        </span>
                      </td>
                      <td className="px-5 py-4 text-secondary-text">
                        {category.negocios_count}
                      </td>
                      <td className="px-5 py-4">
                        <Badge tone={category.estado ? "success" : "neutral"} dot>
                          {category.estado ? "Activa" : "Inactiva"}
                        </Badge>
                      </td>
                      <td className="px-5 py-4">
                        <div className="flex justify-end gap-1">
                          <Button
                            variant="ghost"
                            size="sm"
                            leftIcon={<LuPencil size={13} />}
                            onClick={() => openEdit(category)}
                          >
                            Editar
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => handleToggle(category)}
                          >
                            {category.estado ? "Desactivar" : "Activar"}
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            className="text-error/80 hover:bg-error-tint hover:text-error"
                            leftIcon={<LuTrash2 size={13} />}
                            onClick={() => {
                              setNotice(null);
                              setToDelete(category);
                            }}
                          >
                            Eliminar
                          </Button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Card>
      </main>

      <Modal
        isOpen={modalOpen}
        onClose={() => setModalOpen(false)}
        title={editing ? "Editar categoría" : "Nueva categoría"}
        size="sm"
      >
        <form onSubmit={handleSave} className="space-y-4">
          <Field label="Nombre" htmlFor="category-name" required>
            <Input
              id="category-name"
              value={nombre}
              onChange={(event) => setNombre(event.target.value)}
              placeholder="Ej. Salud y belleza"
            />
          </Field>
          <Field label="Descripción" htmlFor="category-description">
            <Textarea
              id="category-description"
              value={descripcion}
              onChange={(event) => setDescripcion(event.target.value)}
              placeholder="Descripción opcional"
            />
          </Field>
          <label className="flex items-center gap-2 text-sm text-secondary-text">
            <input
              type="checkbox"
              checked={estado}
              onChange={(event) => setEstado(event.target.checked)}
              className="size-4 accent-[var(--color-primary)]"
            />
            Categoría activa
          </label>

          {formError && (
            <div className="rounded-xl border border-error/20 bg-error-tint px-4 py-3 text-sm font-medium text-error">
              {formError}
            </div>
          )}

          <div className="flex flex-col-reverse gap-2 border-t border-border/70 pt-4 sm:flex-row sm:justify-end">
            <Button
              type="button"
              variant="outline"
              onClick={() => setModalOpen(false)}
            >
              Cancelar
            </Button>
            <Button type="submit" loading={saving}>
              {editing ? "Guardar cambios" : "Crear categoría"}
            </Button>
          </div>
        </form>
      </Modal>

      <Modal
        isOpen={Boolean(toDelete)}
        onClose={() => setToDelete(null)}
        title="Eliminar categoría"
        size="sm"
      >
        <div className="space-y-4">
          <p className="text-sm leading-relaxed text-secondary-text">
            ¿Eliminar <strong className="text-foreground">{toDelete?.nombre_categoria}</strong>?
            {toDelete && toDelete.negocios_count > 0
              ? " Tiene negocios asociados, por lo que quedará desactivada en lugar de eliminarse."
              : " Esta acción no se puede deshacer."}
          </p>
          <div className="flex flex-col-reverse gap-2 border-t border-border/70 pt-4 sm:flex-row sm:justify-end">
            <Button variant="outline" onClick={() => setToDelete(null)}>
              Cancelar
            </Button>
            <Button
              variant="danger"
              loading={deleting}
              onClick={handleDelete}
            >
              Confirmar
            </Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}

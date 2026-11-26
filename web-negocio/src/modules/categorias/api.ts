import { apiRequest, jsonRequest, queryString } from "../../lib/request";
import type {
  Category,
  CategoryDeleteResult,
  CategoryPayload,
  CategoryUpdatePayload,
} from "./types";

// HU_14: las categorías se gestionan solo con una cuenta admin.
export function getCategories(incluirInactivas: boolean): Promise<Category[]> {
  return apiRequest(
    `/categories${queryString({ incluir_inactivas: incluirInactivas })}`,
    {},
    "No pudimos cargar las categorías.",
  );
}

export function createCategory(payload: CategoryPayload): Promise<Category> {
  return jsonRequest(
    "/categories",
    "POST",
    payload,
    "No pudimos crear la categoría.",
  );
}

export function updateCategory(
  categoriaId: number,
  payload: CategoryUpdatePayload,
): Promise<Category> {
  return jsonRequest(
    `/categories/${categoriaId}`,
    "PUT",
    payload,
    "No pudimos actualizar la categoría.",
  );
}

export function deleteCategory(
  categoriaId: number,
): Promise<CategoryDeleteResult> {
  return apiRequest(
    `/categories/${categoriaId}`,
    { method: "DELETE" },
    "No pudimos eliminar la categoría.",
  );
}

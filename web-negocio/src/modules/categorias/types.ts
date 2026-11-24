export interface Category {
  id_categoria: number;
  nombre_categoria: string;
  descripcion: string | null;
  estado: boolean;
  negocios_count: number;
}

export interface CategoryPayload {
  nombre_categoria: string;
  descripcion?: string | null;
  estado?: boolean;
}

export type CategoryUpdatePayload = Partial<CategoryPayload>;

export interface CategoryDeleteResult {
  message: string;
  desactivada: boolean;
}

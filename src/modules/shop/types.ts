export interface RegisterShopPayload{
    nombre: string
    descripcion: string
    imagen_negocio: string | undefined
    categoria_negocio: string
}

export interface Shop{
    id: number
    nombre: string
    descripcion: string
    imagen_negocio: string
    categoria_negocio: string
}
export interface RegisterShopPayload{
    nombre: string
    descripcion: string
    imagen_negocio: string | undefined
    categoria_negocio: number
}

export interface EditShopPayload{
    nombre: string
    descripcion: string
    imagen_negocio: string | undefined
    fk_categoria: number
}

export interface ShopGeneralInfo{
    id: number
    nombre: string
    descripcion: string
    imagen_negocio: string
    categoria_negocio: string
    id_categoria: number
}

//Contact

type IconName =
  | "facebook"
  | "instagram"
  | "whatsapp"
  | "telefono"
  | "tiktok"
  | "x"
  | "sitio_web";

export interface ShopContactInfo{
    id_social?: number
    nombre_red: IconName
    url: string
}

export interface ShopContactRegister{
    nombre_red : string
    url : string
}

export interface ShopContactEdit{
    id_negocio: number
    nombre_red : string
    url: string
}

// Schedule

export interface ShopSheduleInfo{
    id_horario: number
    dia: string
    hora_apertura: string
    hora_cierre : string
    hora_descanso: string | null
}

export interface ShopScheduleRegister{
    dia: string
    hora_apertura: string
    hora_cierre: string
    hora_descanso: string | null
}

//Adress

export interface ShopAddressInfo{
    id_direccion: number
    direccion_calle: string
    ciudad: string
    estado: string
    codigo_postal: string
    pais: string
    latitud: number
    longitud: number
    osm_id: string
    numero_local: string
    numero_interior: string
}

export interface ShopAddressRegister{
    direccion_calle: string
    ciudad: string
    estado: string
    codigo_postal: string
    pais: string
    latitud: number
    longitud: number
    osm_id: string
    numero_local: string
    numero_interior: string
}

//Full profile

export interface ShopFullProfileOut{
    general: ShopGeneralInfo
    contacto: ShopContactInfo[]
    horario: ShopSheduleInfo[]
    direccion: ShopAddressInfo | null
}
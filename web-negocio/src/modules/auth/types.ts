export interface User{
    id: number
    nombre: string
    correo: string
    rol: 'cliente' | 'negocio' | string
}

export interface RegisterPayload{
    nombre: string
    correo: string
    password: string
    confirm_password: string
    rol : 'cliente' | 'negocio' | string
}

export interface LoginPayLoad{
    correo: string
    password: string
}

// HU_05: el id del usuario siempre se toma del token en el backend.
export interface ProfileUpdatePayload{
    nombre?: string
    correo?: string
    password_actual?: string
    password_nueva?: string
    confirm_password?: string
}

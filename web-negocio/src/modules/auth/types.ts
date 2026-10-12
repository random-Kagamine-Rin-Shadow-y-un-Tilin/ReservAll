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
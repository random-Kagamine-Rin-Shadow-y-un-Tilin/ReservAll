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

export interface PasswordResetRequestOut{
    mensaje: string
    expira_en_minutos: number
    // Solo disponible en desarrollo cuando PASSWORD_RESET_RETURN_CODE=true.
    codigo?: string | null
}

export interface PasswordResetConfirmPayload{
    correo: string
    codigo: string
    nueva_password: string
    confirm_password: string
}
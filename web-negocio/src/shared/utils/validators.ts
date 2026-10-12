export function validatePassword(password: string): string | null{
    if (password.length < 8) return 'La contraseña debe tener al menos 8 caracteres.'
    if (!/[A-Z]/.test(password)) return 'Debe incluir al menos una mayuscula.'
    if(!/[a-z]/.test(password)) return 'Debe incluir al menos una minuscula.'
    if(!/[0-9]/.test(password)) return 'Debe incluir al menos un número.'
    return null
}

export function validateEmail(email: string): boolean{
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
}
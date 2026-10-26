import { fetchWithAuth } from "../../lib/api";
import type { User, RegisterPayload, LoginPayLoad } from "./types";

const API_URL = import.meta.env.VITE_API_URL

async function readError(res: Response, fallback: string): Promise<string> {
    try {
        const data = await res.json()
        if (data && typeof data === 'object' && 'detail' in data) {
            const detail = (data as { detail: unknown }).detail
            if (typeof detail === 'string') return detail
        }
        return fallback
    } catch {
        return fallback
    }
}

export async function registerUser(payload: RegisterPayload):Promise<User> {
    const res = await fetchWithAuth(`${API_URL}/auth/register`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify(payload)
    })

    if (!res.ok){
        throw new Error(await readError(res, "Error al registar usuario."))
    }

    return res.json() 
}

export async function loginUser(payload:LoginPayLoad): Promise<User> {
    const res = await fetchWithAuth(`${API_URL}/auth/login`,{
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify(payload),
    })

    if (!res.ok){
        throw new Error(await readError(res, 'Correo o contraseña incorrectos.'))
    }

    return res.json()
}

export async function logOut(): Promise<void> {
    await fetchWithAuth(`${API_URL}/auth/logout`, {method: 'POST'})
}

export async function getCurrentUser():Promise<User | null> {
    try {
        const res = await fetchWithAuth(`${API_URL}/profile/me`)
        if (!res.ok) return null
        return await res.json() as User
    } catch {
        // Sin backend disponible o respuesta no JSON: se trata como sesión cerrada.
        return null
    }
}

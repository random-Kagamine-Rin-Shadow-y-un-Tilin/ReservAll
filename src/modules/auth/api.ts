import { fetchWithAuth } from "../../lib/api";
import type { User, RegisterPayload, LoginPayLoad } from "./types";

const API_URL = import.meta.env.VITE_API_URL

export async function registerUser(payload: RegisterPayload):Promise<User> {
    const res = await fetchWithAuth(`${API_URL}/auth/register`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify(payload)
    })

    if (!res.ok){
        const error = await res.json()
        throw new Error(error.detail || "Error al registar usuario.")
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
        const error = await res.json()
        throw new Error(error.detail || 'Correo o contraseña incorrectos.')
    }

    return res.json()
}

export async function logOut(): Promise<void> {
    await fetchWithAuth(`${API_URL}/auth/logout`, {method: 'POST'})
}

//This is an example
export async function getCurrentUser():Promise<User | null> {
    const res = await fetchWithAuth(`${API_URL}/profile/me`)
    if (!res.ok) return null
    const data = await res.json()
    console.log(data)
    return data
}
import { fetchWithAuth } from "../../lib/api";
import { clearHttpCache } from "../../lib/offlineCache";
import { jsonRequest } from "../../lib/request";
import type {
  PasswordResetConfirmPayload,
  PasswordResetRequestOut,
  ProfileUpdatePayload,
  User,
  RegisterPayload,
  LoginPayLoad,
} from "./types";

const API_URL = import.meta.env.VITE_API_URL
const USER_CACHE_KEY = "reservall:current-user:v1"

function cacheUser(user: User): void {
  try {
    window.localStorage.setItem(USER_CACHE_KEY, JSON.stringify(user))
  } catch {
    // El almacenamiento puede estar bloqueado; la sesión online sigue funcionando.
  }
}

function readCachedUser(): User | null {
  try {
    const raw = window.localStorage.getItem(USER_CACHE_KEY)
    if (!raw) return null
    const parsed = JSON.parse(raw) as Partial<User>
    if (typeof parsed.id !== "number" || typeof parsed.correo !== "string") return null
    return parsed as User
  } catch {
    return null
  }
}

function clearCachedUser(): void {
  try {
    window.localStorage.removeItem(USER_CACHE_KEY)
  } catch {
    // Sin acceso al almacenamiento.
  }
}

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

    const user = await res.json() as User
    cacheUser(user)
    return user
}

export async function logOut(): Promise<void> {
    try {
        await fetchWithAuth(`${API_URL}/auth/logout`, {method: 'POST'})
    } catch {
        // Sin conexión también se cierra la sesión local.
    } finally {
        clearCachedUser()
        clearHttpCache()
    }
}

// HU_03: recuperación de contraseña
export function requestPasswordReset(correo: string): Promise<PasswordResetRequestOut> {
    return jsonRequest(
        '/auth/forgot-password',
        'POST',
        { correo },
        'No pudimos enviar el código de recuperación.',
    )
}

export function confirmPasswordReset(
    payload: PasswordResetConfirmPayload,
): Promise<User> {
    return jsonRequest(
        '/auth/reset-password',
        'POST',
        payload,
        'No pudimos actualizar tu contraseña.',
    )
}

// HU_05: edición del perfil propio.
export async function updateProfile(payload: ProfileUpdatePayload): Promise<User> {
    const user = await jsonRequest<User>(
        '/profile/me',
        'PATCH',
        payload,
        'No pudimos actualizar tu perfil.',
    )
    cacheUser(user)
    return user
}

export async function getCurrentUser():Promise<User | null> {
    try {
        const res = await fetchWithAuth(`${API_URL}/profile/me`)
        if (!res.ok) {
            if (res.status === 401 || res.status === 403) clearCachedUser()
            return null
        }

        const user = await res.json() as User
        cacheUser(user)
        return user
    } catch {
        // Sin conexión: restauramos la última sesión guardada para poder ver
        // la agenda y las reservas offline.
        return readCachedUser()
    }
}

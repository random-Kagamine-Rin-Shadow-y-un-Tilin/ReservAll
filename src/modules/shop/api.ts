import { fetchWithAuth } from "../../lib/api";
import type { Shop, RegisterShopPayload } from "./types";

const API_URL = import.meta.env.VITE_API_URL

export async function registerShop(payload: RegisterShopPayload): Promise<Shop> {
    const res = await fetchWithAuth(`${API_URL}/shop/register-shop`, {
        method: 'POST',
        headers: {'Content-type': 'application/json'},
        body: JSON.stringify(payload)
    })

    if (!res.ok){
        const error = await res.json()
        throw new Error(error.detail || "Error al crear negocio.")
    }

    return res.json()
}

export async function uploadShopImage(file: File): Promise <string> {
    const formData = new FormData()
    formData.append('file', file)

    const res = await fetchWithAuth(`${API_URL}/shop/upload-image`,{
        method: 'POST',
        body: formData,
    })

    if (!res.ok){
        const error = await res.json()
        throw new Error(error.detail || 'Error al subir imagen.')
    }

    const data = await res.json()
    return data.url
}
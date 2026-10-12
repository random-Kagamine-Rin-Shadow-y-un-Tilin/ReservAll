import { fetchWithAuth } from "../../lib/api";
import type { 
    ShopGeneralInfo, RegisterShopPayload, EditShopPayloal, ShopContactInfo, 
    ShopContactRegister, ShopFullProfileOut, ShopScheduleRegister, ShopSheduleInfo, 
    ShopAddressInfo, ShopAddressRegister,
} from "./types";

const API_URL = import.meta.env.VITE_API_URL


//General info actions
export async function getGeneral(shopId:number):Promise<ShopGeneralInfo> {
    const res = await fetchWithAuth(`${API_URL}/shop/get-general/${shopId}`)

    if(!res.ok){
        const error = await res.json()
        throw new Error(error.detail || "Error al cargar información.")
    }

    return res.json()
}


export async function registerShop(payload: RegisterShopPayload): Promise<ShopGeneralInfo> {
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

export async function editShop(payload: EditShopPayloal, shopId: number): 
Promise<ShopGeneralInfo>{
    const res = await fetchWithAuth(`${API_URL}/shop/edit-shop/${shopId}`,{
        method : 'PUT',
        headers: {'Content-type': 'application/json'},
        body: JSON.stringify(payload),
    })

    if(!res.ok){
        const error = await res.json()
        throw new Error(error.detail || "Error al editar negocio.")
    }
    
    return res.json()
}


//Upload image for owner
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

// Get shops for owner
export async function getOwnerShops(): Promise<ShopGeneralInfo[]> {
    const res = await fetchWithAuth(`${API_URL}/shop/my-shops`)

    if(!res.ok){
        const error = await res.json()
        throw new Error(error.detail || 'Error al obtener tus negocios.')
    }

    return res.json()
}

// Get shop by id
export async function getShopForId(idShop: string | undefined): Promise <ShopFullProfileOut> {
    const res = await fetchWithAuth(`${API_URL}/shop/get-shop/${idShop}`)
    
    if(!res.ok){
        const error = await res.json()
        throw new Error(error.detail || "Error al obteher tu negocio.")
    }

    return res.json()
}

// CONTACT ACTIONS
export async function getContactsByShop(shopId:number): Promise<ShopContactInfo[]> {
    const res = await fetchWithAuth(`${API_URL}/shop/get-contacts/${shopId}`)

    if(!res.ok){
        const error = await res.json()
        throw new Error(error.detail || "Error al obteher tus contactos.")
    }

    return res.json()
}


export async function registerContact(
    shop_id : number, 
    data : ShopContactRegister 
):Promise<ShopContactInfo> {
    const res = await fetchWithAuth(`${API_URL}/shop/register-contact/${shop_id}`,{
        method : 'POST',
        headers: {'Content-type': 'application/json'},
        body: JSON.stringify(data),
    });

    if (!res.ok){
        const error = await res.json()
        throw new Error(error.detail || "Error al registrar contacto.")
    }

    return res.json()
}


//SCHEDULE ACTIONS
export async function getScheduleByShop(shopId: number): Promise<ShopSheduleInfo[]> {
    const res = await fetchWithAuth(`${API_URL}/shop/get-schedule/${shopId}`)

    if(!res.ok){
        const error = await res.json()
        throw new Error(error.detail || "Error al obteher tu horario.")
    }

    return res.json()
}


export async function registerSchedule(
    shop_id: number, 
    data: ShopScheduleRegister
): Promise <ShopSheduleInfo> {
    const res = await fetchWithAuth(`${API_URL}/shop/register-schedule/${shop_id}`,{
        method: 'POST',
        headers: {'Content-type': 'application/json'},
        body: JSON.stringify(data)
    })

    if (!res.ok){
        const error = await res.json()
        throw new Error(error.detail || 'Error al registrar horario.')
    }

    return res.json()
}

//ADDRESS ACTIONS
export async function getAddress(shopId: number):Promise<ShopAddressInfo> {
    const res = await fetchWithAuth(`${API_URL}/shop/get-address/${shopId}`)

    if (!res.ok){
        const error = await res.json()
        throw new Error(error.detail || 'Error al obtener direccion')
    }

    return res.json()
}

export async function registerAddress(
    shopId:number, 
    data: ShopAddressRegister
): Promise <ShopAddressInfo> {
    const res = await fetchWithAuth(`${API_URL}/shop/register-address/${shopId}`,{
        method: 'POST',
        headers: {'Content-type': 'application/json'},
        body: JSON.stringify(data)
    })

    if(!res.ok){
        const error = await res.json()
        throw new Error(error.detail || "Error al registrar dirección.")
    }

    return res.json()
}
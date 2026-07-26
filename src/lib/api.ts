const API_URL = import.meta.env.VITE_API_URL
const API_KEY = import.meta.env.VITE_API_KEY

export async function fetchWithAuth(url:string, options: RequestInit = {}): Promise<Response> {

    const res = await fetch(url, {
        ...options,
        credentials: 'include',
        headers: {...options.headers, 'x-api-key': API_KEY},
    })

    if(res.status == 401){
        // Try to refresh the access token
        const refreshRes = await fetch(`${API_URL}/auth/refresh`,{
            method: 'POST',
            credentials: 'include',
            headers: {'x-api-key': API_KEY},
        })

        if (refreshRes.ok){
            // Try again the original request
            return fetch(url, {
                ...options,
                credentials: 'include',
                headers: {...options.headers, 'x-api-key': API_KEY},
            })
        }
        if(window.location.pathname !== '/login'){
            window.location.href = '/login'
        }

        return res
    }
    return res
}
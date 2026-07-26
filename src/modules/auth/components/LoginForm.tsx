import { useState } from "react";
import type { FormEvent } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../hooks/useAuth";

export function LoginForm(){
    const {login} = useAuth()
    const navigate = useNavigate()

    const [correo, setCorreo] = useState('')
    const [password, setPassword] = useState('')
    const [error, setError] = useState<String |null>(null)
    const [loading, setLoading] = useState(false)

    async function handleSubmit(e:FormEvent) {
        e.preventDefault()
        setError(null)
        setLoading(true)

        try{
            await login({correo, password})
            navigate('/')
        } catch (err){
            setError(err instanceof Error ? err.message : 'Error al iniciar sesión.')
        } finally {
            setLoading(false)
        }
    }

    return(
        <form onSubmit={handleSubmit}>
            <h2>Inicias sesión</h2>

            <div>
                <label>Correo</label>
                <input 
                type="email"
                value={correo}
                onChange={(e)=> setCorreo(e.target.value)} 
                />
            </div>

            <div>
                <label>Contraseña</label>
                <input 
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                />
            </div>

            {error && <p>{error}</p>}

            <button type="submit" disabled={loading}>{loading? 'Entrando...': 'Entrar'}</button>
        </form>
    )
}
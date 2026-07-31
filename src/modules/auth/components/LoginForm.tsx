import { useState } from "react";
import type { FormEvent } from "react";
import { useNavigate, Link } from "react-router-dom";
import { useAuth } from "../hooks/useAuth";

import { MdOutlineEmail } from "react-icons/md";
import { RiLockPasswordLine } from "react-icons/ri";

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
        <main className="flex justify-center items-center h-screen">
            <form onSubmit={handleSubmit}
            className="bg-card p-6 flex flex-col justify-center gap-2 rounded-2xl shadow"
            >
                <h2  className="font-medium text-center">Iniciar sesión</h2>

                <div className="flex flex-col gap-2">
                    <label className="font-medium text-xs">Correo</label>
                    <div className="flex items-center gap-2 px-3 py-2 border rounded-md 
                    border-gray-300 focus:border-highlight">
                        <MdOutlineEmail/>
                        <input 
                        type="email"
                        value={correo}
                        onChange={(e)=> setCorreo(e.target.value)} 
                        className="w-full focus:outline-none"
                        placeholder="tu@gmail.com"
                        />
                    </div>
                </div>

                <div className="flex flex-col gap-2">
                    <label className="font-medium text-xs">Contraseña</label>
                    <div className="flex items-center gap-2 px-3 py-2 border rounded-md 
                    border-gray-300 focus:border-highlight">
                        <RiLockPasswordLine/>
                        <input 
                        type="password"
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        className="w-full focus:outline-none"
                        placeholder="● ● ● ● ● ●"
                        />
                    </div>
                </div>

                {error && 
                    <label className="text-error font-medium text-xs"
                    >{error}
                    </label>
                }

                <button type="submit" disabled={loading}
                className="p-2 bg-primary rounded-md text-card hover:bg-[#BF5842]"
                >
                    {loading? 'Entrando...': 'Entrar'}
                </button>

                <div className="flex text-xs justify-center gap-1 font-medium">
                    <label className="text-gray-500">¿Aún no tienes una cuenta?</label>
                    <Link to={'/login'} className="text-secondary">Resgitrate aquí</Link>
                </div>
            </form>
        </main>
    )
}
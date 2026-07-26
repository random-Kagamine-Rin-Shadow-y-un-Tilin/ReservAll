import { useState } from "react";
import type { FormEvent } from "react";
import { useNavigate, Link} from 'react-router-dom';
import { useAuth } from "../hooks/useAuth";
import { validatePassword, validateEmail } from "../../../shared/utils/validators";

export function RegisterForm(){
    const {register} = useAuth()
    const navigate = useNavigate()

    const [name, setName] = useState('')
    const [correo, setCorreo] = useState('')
    const [rol, setRol] = useState('cliente')
    const [password, setPassword] = useState('')
    const [confirmPassword, setConfirmPassword] = useState('')

    const [error, setError] = useState<String | null>(null)
    const [loading, setLoading] = useState(false)
    const [success, setSuccess] = useState(false)

    async function handleSubmit(e:FormEvent) {
        e.preventDefault()
        setError(null)

        if(!name.trim() || !correo.trim || !password.trim || !confirmPassword.trim()){
            setError('Todos los campos son obligatorios.')
            return
        }
        if(!validateEmail(correo)){
            setError('El correo no es valido')
            return
        }
        if(password !== confirmPassword){
            setError('Las contraseñas no coinciden.')
            return
        }
        const errorPassword = validatePassword(password)
        if (errorPassword){
            setError(errorPassword)
            return
        }

        setLoading(true)
        try{
            await register({nombre: name.trim(), correo, password, confirm_password: confirmPassword, rol})
            setSuccess(true)
            setTimeout(()=> navigate('/login'), 1500);
        } catch (err){
            setError(err instanceof Error ? err.message : 'Error al registrar.')
        } finally {
            setLoading(false)
        }
    }

    if (success){
        return (
            <p>Cuenta creada</p>
        )
    }

    return(
        <main className="flex justify-center items-center h-screen">
            <form onSubmit={handleSubmit} 
            className="bg-card p-6 flex flex-col justify-center gap-2 rounded-2xl shadow"
            >
                <h2 className="font-medium text-center">Crear una cuenta</h2>

                <div className="flex flex-col gap-2">
                    <label className="font-medium text-xs">Nombre completo</label>
                    <input 
                    type="text" 
                    value={name}
                    onChange={(e) => setName(e.target.value)} 
                    className="px-3 py-2 border rounded-md border-gray-300 
                    focus:outline-none focus:border-highlight"
                    />
                </div>

                <div className="flex flex-col gap-2">
                    <label className="font-medium text-xs">Correo electrónico</label>
                    <input 
                    type="email"
                    value={correo}
                    onChange={(e)=> setCorreo(e.target.value)}
                    className="px-3 py-2 border rounded-md border-gray-300
                    focus:outline-none focus:border-highlight"
                    />
                </div>

                <div className="flex flex-col gap-2">
                    <label className="font-medium text-xs">Tipo de cliente</label>
                    <select value={rol} onChange={(e)=>{setRol(e.target.value)}}
                        className="px-3 py-2 border rounded-md border-gray-300"
                        >
                        <option value="cliente">Cliente</option>
                        <option value="negocio">Negocio</option>
                    </select>
                </div>

                <div className="flex justify-around gap-2">
                    <div className="flex flex-col gap-2">
                        <label className="font-medium text-xs">Contraseña</label> 
                        <input 
                        type="password" 
                        value={password}
                        onChange={(e)=>setPassword(e.target.value)}
                        className="px-3 py-2 border rounded-md border-gray-300
                        focus:outline-none focus:border-highlight"
                        />
                    </div>

                    <div className="flex flex-col gap-2">
                        <label className="font-medium text-xs">Confirmar contraseña</label>
                        <input 
                        type="password"
                        value={confirmPassword}
                        onChange={(e) => setConfirmPassword(e.target.value)}
                        className="px-3 py-2 border rounded-md border-gray-300
                        focus:outline-none focus:border-highlight"
                        />
                    </div>
                </div>

                {error && <p>{error}</p>}

                <button type="submit" disabled={loading}
                className="p-2 bg-primary rounded-md text-card hover:bg-[#BF5842]"
                >
                    {loading ? 'creando cuenta': 'Resgitrarse'}
                </button>

                <div className="flex text-xs justify-center gap-1 font-medium">
                    <label className="text-gray-500">¿Ya tienes una cuenta?</label>
                    <Link to={'/login'} className="text-secondary">Inicia sesión aquí</Link>
                </div>
            </form>
        </main>
    )
}
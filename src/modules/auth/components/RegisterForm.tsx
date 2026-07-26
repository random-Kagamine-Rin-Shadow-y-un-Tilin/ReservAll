import { useState } from "react";
import type { FormEvent } from "react";
import { useNavigate } from 'react-router-dom';
import { useAuth } from "../hooks/useAuth";
import { validatePassword, validateEmail } from "../../../shared/utils/validators";

export function RegisterForm(){
    const {register} = useAuth()
    const navigate = useNavigate()

    const [name, setName] = useState('')
    const [correo, setCorreo] = useState('')
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
            await register({nombre: name.trim(), correo, password, confirm_password: confirmPassword})
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
        <form onSubmit={handleSubmit}>
            <h2>Crear cuenta</h2>

            <div>
                <label>Nombre completo *</label>
                <input 
                type="text" 
                value={name}
                onChange={(e) => setName(e.target.value)} 
                />
            </div>

            <div>
                <label>Correo electronico</label>
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
                onChange={(e)=>setPassword(e.target.value)}
                />
            </div>

            <div>
                <label>Confirmar contraseña</label>
                <input 
                type="password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                />
            </div>
            {error && <p>{error}</p>}

            <button type="submit" disabled={loading}>
                {loading ? 'creando cuenta': 'Resgitrarse'}
            </button>
        </form>
    )
}
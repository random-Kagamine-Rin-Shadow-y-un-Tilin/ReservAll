import type { FormEvent } from "react";
import { registerSchedule } from "../../../api";
import { useState } from "react"
import { useParams } from "react-router-dom"

//ICONS
import { FaRegClock } from "react-icons/fa6";

export function RegisterScheduleForm(
    {myDays, onSuccess}: {myDays : string[], onSuccess:() => void})
    {

    const days = [
        'lunes',
        'martes',
        'miercoles',
        'jueves',
        'viernes',
        'sabado',
        'domingo',
    ]

    const [day, setDay] = useState<string>('')
    const [openHour, setOpenHour] = useState<string>('')
    const [closeHour, setCloseHour] = useState<string>('')
    const [restHour, setRestHour] = useState<string | null>(null)

    const [loading, setLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)

    const {shopId} = useParams<{shopId: string}>()


    async function handleSubmit(e:FormEvent) {
        e.preventDefault()
        setError(null)

        if(!openHour.trim() || !closeHour.trim()){
            setError('Todos los campos son obligatorios.')
            return
        }

        if(!day){
            setError('Selecciona un dia para continuar.')
            return
        }

        setLoading(true)

        try{
            await registerSchedule(Number(shopId),{
                dia: day,
                hora_apertura: openHour,
                hora_cierre: closeHour,
                hora_descanso: restHour,
            })
            onSuccess()
        } catch (err) {
            setError(err instanceof Error ? err.message : 'Error al registrar horario.')
        } finally {
            setLoading(false)
        }
    }


    return(
        <form 
        className="flex flex-col bg-card p-4 rounded-2xl shadow gap-4 mt-4" 
        onSubmit={handleSubmit}
        >
            <div className="flex gap-2 items-center">
                <FaRegClock className="text-primary text-2xl"/>
                <span className="text-3xl">Registro de Horario</span>
            </div>

            <div className="flex flex-col">
                <label>Día de la semana</label>
                <select value={day} onChange={(e)=> setDay(e.target.value)}
                className="px-3 py-2 bg-card border rounded-md"
                    >
                    <option value="" disabled>Selecciona un día...</option>
                    {days.map((day)=>(
                        !myDays.includes(day) && (
                            <option key={day} value={day}>{day}</option>
                        )
                    ))}
                </select>
            </div>
                
            <div className=" grid grid-cols-2 gap-4">
                <div className="flex flex-col">
                    <label>Hora de apertura</label>
                    <input type="time" onChange={(e)=> setOpenHour(e.target.value)}
                    className="px-3 py-2 bg-card border rounded-md"
                    />
                </div>

                <div className="flex flex-col">
                    <label>Hora de cierre</label>
                    <input type="time" onChange={(e)=> setCloseHour(e.target.value)}
                    className="px-3 py-2 bg-card border rounded-md"
                    />
                </div>

                <div className="flex flex-col">
                    <label>Hora de descanso (Opcional)</label>
                    <input type="time" onChange={(e)=> setRestHour(e.target.value)}
                    className="px-3 py-2 bg-card border rounded-md"
                    />
                </div>
            </div>

            {error && <p>{error}</p>}

            <div className="flex justify-end">
                <button type="submit" 
                disabled={loading}
                className="bg-primary px-4 py-2 rounded-md text-white w-max
                hover:bg-primary/90">
                    {loading? ('registrando...'): ('Guardar horario')}
                </button>
            </div>
        </form>
    )
}
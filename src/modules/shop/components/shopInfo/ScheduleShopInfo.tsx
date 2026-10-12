import type { ShopSheduleInfo } from "../../types"
import { RegisterScheduleForm } from "../forms/register/RegisterScheduleForm"
import { useState, useCallback } from "react"
import { useParams } from "react-router-dom"
import { getScheduleByShop } from "../../api"
import { Modal } from "../../../../shared/components/Modal"

//ICONS
import { LuPlus, LuPencil, LuTrash2 } from "react-icons/lu";

export function ScheduleShopInfo({shop}: {shop: ShopSheduleInfo[]}){
    const { shopId } = useParams<{shopId : string }>()
    const [shopSchedule, setShopSchedule] = useState<ShopSheduleInfo[]>(shop)
    const [registerModalOpen, setRegisterModalOpen] = useState(false)

    const updateSchedule = useCallback(async ()=>{
        try{
            const data = await getScheduleByShop(Number(shopId))
            setShopSchedule(data)
        } catch (err) {
            console.error('Error al cargar horario', err)
        }       
    }, [shopId])

    async function handleSuccess() {
        setRegisterModalOpen(false)
        await updateSchedule()
    }

    const myDays = shop.map((h)=> h.dia)

    return(
        <>
        <div className="flex flex-col mt-4">
            {shopSchedule.length === 0 ?
            (
                <>
                <span className="font-light text-secondary-text">
                    Aún no tienes información sobre tus horarios.
                </span>
                <span className={`text-4xl font-medium`}>
                    Registra tu primer horario.
                </span>

                <RegisterScheduleForm 
                myDays={myDays}
                onSuccess={()=> handleSuccess()}
                />
                </>
            ):(
                <>
                {shopSchedule.length < 7 && (
                    <div className="flex justify-end gap-2">
                        <button
                        type="button"
                        onClick={()=>setRegisterModalOpen(true)}
                        className="bg-primary text-white px-4 py-2 
                        rounded-md mb-4 hover:bg-primary/90 flex gap-2 items-center"
                        >   
                            <LuPlus/>
                            Añadir horario
                        </button>
                    </div>
                )}

                <div className="p-4 bg-card rounded-md shadow">
                    <table 
                    className="w-full [&_th]:text-left [&_td]:text-left 
                    [&_th]:p-2 [&_td]:p-2"
                    >
                        <thead>
                            <tr className="border-b border-secondary-text/40">
                                <th>DÍA DE LA SEMANA</th>
                                <th>HORA DE APERTURA</th>
                                <th>HORA DE CIERRE</th>
                                <th>HORA DE DESCANSO</th>
                                <th>ACCIONES</th>
                            </tr>
                        </thead>
                        <tbody className="[&_tr]:border-b [&_tr]:border-secondary-text/20">
                            {shopSchedule.map((s)=>(
                                <tr key={s.id_horario}>
                                    <td>
                                        {s.dia}
                                    </td>
                                    <td>
                                        <span className="inline-block rounded-4xl 
                                        bg-highlight/20 px-2 py-1">
                                            {s.hora_apertura.slice(0, 5)}
                                        </span>
                                    </td>
                                    <td>
                                        <span className="inline-block rounded-4xl 
                                        bg-highlight/20 px-2 py-1">
                                            {s.hora_cierre.slice(0, 5)}
                                        </span>
                                    </td>
                                    <td> 
                                    {s.hora_descanso? 
                                    (s.hora_descanso.slice(0, 5)):
                                    ('Sin descanso')
                                    }
                                    </td>
                                    <td className="flex justify-start gap-4">
                                        <LuPencil 
                                        className="text-primary hover:text-primary/90
                                        cursor-pointer"
                                        />
                                        <LuTrash2
                                        className="text-error hover:text-error/90
                                        cursor-pointer"
                                        />
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>

                <Modal
                isOpen={registerModalOpen}
                onClose={()=> setRegisterModalOpen(false)}
                >
                    <RegisterScheduleForm 
                    myDays={myDays}
                    onSuccess={()=> handleSuccess()}
                    />
                </Modal>
                </>
            )}
        </div>
        </>
    )
}
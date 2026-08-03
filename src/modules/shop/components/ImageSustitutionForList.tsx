import { getCategoryStyle } from "../utils/caregoryStyle"
import { FaShop } from "react-icons/fa6";

export function ImageSustitutionForList({category} : {category: string}){
    return(
        <div className={`
        min-w-1/5 ${getCategoryStyle(category)} flex flex-col justify-center 
        items-center text-center
        `}>
            <FaShop className="font-medium text-5xl"/>
            <span>Sin imágen</span>
        </div>
    )
}
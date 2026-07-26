import { createContext, useEffect, useState } from "react";
import type { ReactNode } from "react";
import type { User, LoginPayLoad, RegisterPayload } from "../types";
import { loginUser, registerUser, logOut, getCurrentUser } from "../api";

interface AuthContextType{
    user: User | null
    loading : boolean
    login: (payload: LoginPayLoad) => Promise<void>
    register: (payload: RegisterPayload) => Promise<void>
    logout: () => Promise<void>
}

export const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({children}: {children: ReactNode}){
    const [user, setUser] = useState<User | null>(null)
    const [loading, selLoading] = useState(true)

    useEffect(()=>{
        //When you initialite the app, try to recover the session by cookie
        getCurrentUser()
        .then(setUser)
        .finally(()=> selLoading(false))
    }, [])

    async function login(payload:LoginPayLoad) {
        const userLogin = await loginUser(payload)
        setUser(userLogin)
    }

    async function register(payload:RegisterPayload) {
        await registerUser(payload)
    }

    async function logout() {
        await logOut()
        setUser(null)
    }

    return(
        <AuthContext.Provider value={{ user, loading, login, register, logout}}>
            {children}
        </AuthContext.Provider>
    )
}
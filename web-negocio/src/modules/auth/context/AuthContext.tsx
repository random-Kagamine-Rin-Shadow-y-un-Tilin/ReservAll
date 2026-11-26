import { createContext, useEffect, useState } from "react";
import type { ReactNode } from "react";
import type {
    ProfileUpdatePayload,
    User,
    LoginPayLoad,
    RegisterPayload,
} from "../types";
import {
    loginUser,
    registerUser,
    logOut,
    getCurrentUser,
    updateProfile,
} from "../api";

interface AuthContextType{
    user: User | null
    loading : boolean
    login: (payload: LoginPayLoad) => Promise<User>
    register: (payload: RegisterPayload) => Promise<void>
    logout: () => Promise<void>
    updateProfile: (payload: ProfileUpdatePayload) => Promise<User>
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
        return userLogin
    }

    async function register(payload:RegisterPayload) {
        await registerUser(payload)
    }

    async function logout() {
        await logOut()
        setUser(null)
    }

    async function editProfile(payload: ProfileUpdatePayload) {
        const updated = await updateProfile(payload)
        setUser(updated)
        return updated
    }

    return(
        <AuthContext.Provider value={{ user, loading, login, register, logout, updateProfile: editProfile }}>
            {children}
        </AuthContext.Provider>
    )
}
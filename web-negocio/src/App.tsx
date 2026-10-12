import { Outlet } from "react-router-dom"
import { useAuth } from "./modules/auth/hooks/useAuth"
import { Navigate } from "react-router-dom"
import { NavBar } from "./shared/components/NavBar"

export function App() {
  const {user, loading} = useAuth()

  if (loading){
    return <div>cargando...</div>
  }

  if(user === null){
    return <Navigate to='/login' replace/>
  }

  return(
    <div className="flex">
      <NavBar/>
        <main className="p-8 w-full h-screen overflow-y-scroll">
          <Outlet/>
        </main>
    </div>
  )
}

export default App

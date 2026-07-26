import { Outlet } from "react-router-dom"

export function App() {
  return (
    <>
      <header>Este es un header</header>
        <main>
          <Outlet/>
        </main>
      <footer>Este es un footer</footer>
    </>
  )
}

export default App

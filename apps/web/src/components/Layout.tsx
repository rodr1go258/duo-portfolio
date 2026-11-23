import { Link, NavLink, Outlet } from 'react-router-dom';

const links = [
  { to: '/', label: 'Inicio', end: true },
  { to: '/proyectos', label: 'Proyectos' },
  { to: '/equipo', label: 'Equipo' },
  { to: '/contacto', label: 'Contacto' }
];

export function Layout() {
  return (
    <div className="app-shell">
      <header className="topbar">
        <Link to="/" className="brand" data-testid="brand">
          <span className="brand-mark">D&amp;L</span>
          <span>Dúo Portfolio</span>
        </Link>
        <nav aria-label="Navegación principal">
          {links.map((link) => (
            <NavLink
              key={link.to}
              to={link.to}
              end={link.end}
              className={({ isActive }) => (isActive ? 'nav-link active' : 'nav-link')}
            >
              {link.label}
            </NavLink>
          ))}
        </nav>
      </header>

      <main className="content" data-testid="main-content">
        <Outlet />
      </main>

      <footer className="footer">
        <span>Construido por Ana &amp; Luis · React + Node.js + PostgreSQL</span>
        <span data-testid="footer-year">© {new Date().getFullYear()}</span>
      </footer>
    </div>
  );
}

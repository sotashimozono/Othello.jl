import { NavLink, Outlet } from 'react-router-dom';

const NAV_ITEMS = [
  { to: '/', label: 'Game' },
  { to: '/training', label: 'Training' },
  { to: '/tournament', label: 'Tournament' },
];

export function Layout() {
  return (
    <div className="min-h-screen bg-[#0d0f14] text-slate-200 font-['Inter']">
      <nav className="fixed top-0 right-0 z-40 flex gap-1 p-3">
        {NAV_ITEMS.map(({ to, label }) => (
          <NavLink
            key={to}
            to={to}
            end={to === '/'}
            className={({ isActive }) =>
              `px-4 py-2 rounded-lg text-xs font-black uppercase tracking-widest transition-all ${
                isActive
                  ? 'bg-emerald-600 text-white shadow-lg shadow-emerald-500/20'
                  : 'text-slate-500 hover:text-slate-300 hover:bg-white/5'
              }`
            }
          >
            {label}
          </NavLink>
        ))}
      </nav>
      <Outlet />
    </div>
  );
}

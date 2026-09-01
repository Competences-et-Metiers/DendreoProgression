import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../contexts/AuthContext';
import { useTheme } from '../contexts/ThemeContext';
import {
  Users,
  UserCircle,
  UserCog,
  UserX,
  Settings,
  LogOut,
  Menu,
  ChevronLeft,
  BookOpen,
  Shield,
  ClipboardList,
  Moon,
  Sun,
  LayoutList,
  History,
} from 'lucide-react';

const Sidebar = ({ collapsed, onToggle }) => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const location = useLocation();
  const { logout, user } = useAuth();
  const { isDark, toggleTheme } = useTheme();

  // One ordered list; `roles` restricts an entry to those roles (absent = everyone).
  const allMenuItems = [
    {
      id: 'inactive-management',
      label: t('sidebar.inactiveManagement'),
      icon: UserX,
      path: '/inactive-management',
      active: true
    },
    {
      id: 'adf-list',
      label: t('sidebar.dashboard'),
      icon: BookOpen,
      path: '/adf-list',
      active: true
    },
    {
      id: 'participants',
      label: t('sidebar.participants'),
      icon: Users,
      path: '/participants',
      active: true
    },
    {
      id: 'module-management',
      label: t('sidebar.moduleManagement'),
      icon: LayoutList,
      path: '/module-management',
      active: true
    },
    {
      id: 'admin-sync',
      label: 'Admin: Sync',
      icon: Shield,
      path: '/admin/sync',
      active: true,
      roles: ['admin'],
    },
    {
      id: 'interventions',
      label: 'Interventions',
      icon: ClipboardList,
      path: '/interventions',
      active: true,
      roles: ['admin', 'manager'],
    },
    {
      id: 'admin-action-history',
      label: 'Admin: Historique',
      icon: History,
      path: '/admin/action-history',
      active: true,
      roles: ['admin'],
    },
    {
      id: 'admin-users',
      label: t('sidebar.adminUsers'),
      icon: UserCog,
      path: '/admin/users',
      active: true,
      roles: ['admin'],
    },
    {
      id: 'account',
      label: t('sidebar.account'),
      icon: UserCircle,
      path: '/account',
      active: true
    },
    {
      id: 'settings',
      label: t('sidebar.settings'),
      icon: Settings,
      path: '/settings',
      active: true
    }
  ];

  const menuItems = allMenuItems.filter((item) => !item.roles || item.roles.includes(user?.role));

  const isActive = (path) => {
    if (path === '/') {
      return location.pathname === '/' || location.pathname.startsWith('/courses');
    }
    return location.pathname.startsWith(path);
  };

  const handleNavigation = (item) => {
    if (item.active) {
      navigate(item.path);
    }
  };

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <aside
      className={`fixed left-0 top-0 h-full bg-white dark:bg-slate-800 border-r border-gray-200 dark:border-slate-700 transition-all duration-300 z-40 ${
        collapsed ? 'w-16' : 'w-64'
      }`}
    >
      {/* Header */}
      <div className="h-16 flex items-center justify-between px-4 border-b border-gray-200 dark:border-slate-700">
        {!collapsed && (
          <span className="font-semibold text-gray-900 dark:text-white text-lg">MPM</span>
        )}
        <button
          onClick={onToggle}
          className="p-2 rounded-md hover:bg-gray-100 dark:hover:bg-slate-700 text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 transition-colors"
          title={collapsed ? t('sidebar.expand') : t('sidebar.collapse')}
        >
          {collapsed ? <Menu size={20} /> : <ChevronLeft size={20} />}
        </button>
      </div>

      {/* Navigation */}
      <nav className="flex-1 py-4">
        <ul className="space-y-1 px-2">
          {menuItems.map((item) => {
            const Icon = item.icon;
            const active = isActive(item.path);
            const disabled = !item.active;

            return (
              <li key={item.id}>
                <button
                  onClick={() => handleNavigation(item)}
                  disabled={disabled}
                  className={`w-full flex items-center px-3 py-2.5 rounded-lg transition-colors ${
                    active
                      ? 'bg-primary-50 dark:bg-primary-900/30 text-primary-700 dark:text-primary-400 font-medium'
                      : disabled
                      ? 'text-gray-400 dark:text-gray-600 cursor-not-allowed'
                      : 'text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-slate-700'
                  }`}
                  title={collapsed ? item.label : undefined}
                >
                  <Icon size={20} className={`flex-shrink-0 ${active ? 'text-primary-600 dark:text-primary-400' : ''}`} />
                  {!collapsed && (
                    <span className="ml-3 truncate">
                      {item.label}
                      {disabled && (
                        <span className="ml-2 text-xs text-gray-400 dark:text-gray-600">
                          ({t('sidebar.comingSoon')})
                        </span>
                      )}
                    </span>
                  )}
                </button>
              </li>
            );
          })}
        </ul>
      </nav>

      {/* Footer - Theme Toggle + Logout */}
      <div className="absolute bottom-0 left-0 right-0 p-2 border-t border-gray-200 dark:border-slate-700 space-y-1">
        <button
          onClick={toggleTheme}
          className="w-full flex items-center px-3 py-2.5 rounded-lg text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-slate-700 transition-colors"
          title={collapsed ? (isDark ? 'Light mode' : 'Dark mode') : undefined}
        >
          {isDark ? <Sun size={20} className="flex-shrink-0" /> : <Moon size={20} className="flex-shrink-0" />}
          {!collapsed && (
            <span className="ml-3 truncate">{isDark ? t('settings.lightMode') : t('settings.darkMode')} <span className="text-[10px] text-gray-400 dark:text-gray-500">(Beta)</span></span>
          )}
        </button>
        <button
          onClick={handleLogout}
          className="w-full flex items-center px-3 py-2.5 rounded-lg text-gray-700 dark:text-gray-300 hover:bg-red-50 dark:hover:bg-red-900/20 hover:text-red-600 dark:hover:text-red-400 transition-colors"
          title={collapsed ? t('sidebar.logout') : undefined}
        >
          <LogOut size={20} className="flex-shrink-0" />
          {!collapsed && (
            <span className="ml-3 truncate">{t('sidebar.logout')}</span>
          )}
        </button>
      </div>
    </aside>
  );
};

export default Sidebar;

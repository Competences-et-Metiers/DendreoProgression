import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../contexts/AuthContext';
import {
  Users,
  UserCircle,
  UserX,
  Settings,
  LogOut,
  Menu,
  ChevronLeft,
  BookOpen
} from 'lucide-react';

const Sidebar = ({ collapsed, onToggle }) => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const location = useLocation();
  const { logout } = useAuth();

  const menuItems = [
    {
      id: 'dashboard',
      label: t('sidebar.dashboard'),
      icon: BookOpen,
      path: '/',
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
      id: 'inactive-management',
      label: t('sidebar.inactiveManagement'),
      icon: UserX,
      path: '/inactive-management',
      active: true
    },
    {
      id: 'account',
      label: t('sidebar.account'),
      icon: UserCircle,
      path: '/account',
      active: false
    },
    {
      id: 'settings',
      label: t('sidebar.settings'),
      icon: Settings,
      path: '/settings',
      active: false
    }
  ];

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
      className={`fixed left-0 top-0 h-full bg-white border-r border-gray-200 transition-all duration-300 z-40 ${
        collapsed ? 'w-16' : 'w-64'
      }`}
    >
      {/* Header */}
      <div className="h-16 flex items-center justify-between px-4 border-b border-gray-200">
        {!collapsed && (
          <span className="font-semibold text-gray-900 text-lg">Dendreo</span>
        )}
        <button
          onClick={onToggle}
          className="p-2 rounded-md hover:bg-gray-100 text-gray-500 hover:text-gray-700 transition-colors"
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
                      ? 'bg-primary-50 text-primary-700 font-medium'
                      : disabled
                      ? 'text-gray-400 cursor-not-allowed'
                      : 'text-gray-700 hover:bg-gray-100'
                  }`}
                  title={collapsed ? item.label : undefined}
                >
                  <Icon size={20} className={`flex-shrink-0 ${active ? 'text-primary-600' : ''}`} />
                  {!collapsed && (
                    <span className="ml-3 truncate">
                      {item.label}
                      {disabled && (
                        <span className="ml-2 text-xs text-gray-400">
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

      {/* Footer - Logout */}
      <div className="absolute bottom-0 left-0 right-0 p-2 border-t border-gray-200">
        <button
          onClick={handleLogout}
          className="w-full flex items-center px-3 py-2.5 rounded-lg text-gray-700 hover:bg-red-50 hover:text-red-600 transition-colors"
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

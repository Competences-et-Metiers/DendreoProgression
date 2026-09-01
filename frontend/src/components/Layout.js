import React, { useState, useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Sidebar from './Sidebar';

// Longest prefix wins. `key` is an i18n path; `literal` is a hardcoded string.
const TITLE_BY_PREFIX = [
  { prefix: '/admin/action-history', literal: 'Admin: Historique' },
  { prefix: '/admin/users', key: 'sidebar.adminUsers' },
  { prefix: '/admin/sync', literal: 'Admin: Sync' },
  { prefix: '/interventions', literal: 'Interventions' },
  { prefix: '/inactive-management', key: 'sidebar.inactiveManagement' },
  { prefix: '/module-management', key: 'sidebar.moduleManagement' },
  { prefix: '/adf-list', key: 'sidebar.dashboard' },
  { prefix: '/courses', key: 'sidebar.dashboard' },
  { prefix: '/participants', key: 'sidebar.participants' },
  { prefix: '/account', key: 'sidebar.account' },
  { prefix: '/settings', key: 'sidebar.settings' },
];

const Layout = ({ children }) => {
  const location = useLocation();
  const { t } = useTranslation();
  const [sidebarCollapsed, setSidebarCollapsed] = useState(() => {
    const cached = localStorage.getItem('sidebarCollapsed');
    return cached ? JSON.parse(cached) : false;
  });

  useEffect(() => {
    localStorage.setItem('sidebarCollapsed', JSON.stringify(sidebarCollapsed));
  }, [sidebarCollapsed]);

  useEffect(() => {
    const match = TITLE_BY_PREFIX.find(({ prefix }) => location.pathname.startsWith(prefix));
    const label = match ? (match.key ? t(match.key) : match.literal) : null;
    document.title = label ? `${label} – MPM` : 'MPM';
  }, [location.pathname, t]);

  const toggleSidebar = () => {
    setSidebarCollapsed(prev => !prev);
  };

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-slate-900">
      <Sidebar collapsed={sidebarCollapsed} onToggle={toggleSidebar} />
      <main
        className={`transition-all duration-300 ${
          sidebarCollapsed ? 'ml-16' : 'ml-64'
        }`}
      >
        {children}
      </main>
    </div>
  );
};

export default Layout;

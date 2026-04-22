import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClientProvider } from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';
import { queryClient } from './queryClient';
import './i18n'; // Initialize i18n
import { useLanguageEffect } from './hooks/useLanguageEffect';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import { ThemeProvider } from './contexts/ThemeContext';
import Layout from './components/Layout';
import Login from './pages/Login';
import AdfList from './pages/AdfList';
import CourseDetail from './pages/CourseDetail';
import Participants from './pages/Participants';
import ParticipantDetail from './pages/ParticipantDetail';
import Account from './pages/Account';
import InactiveManagement from './pages/InactiveManagement';
import Settings from './pages/Settings';
import AdminSyncDashboard from './pages/AdminSyncDashboard';
import AdminInterventions from './pages/AdminInterventions';
import AdminActionHistory from './pages/AdminActionHistory';
import ModuleManagement from './pages/ModuleManagement';
import { Loader2 } from 'lucide-react';

// Protected route wrapper
const ProtectedRoute = ({ children }) => {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-slate-900">
        <Loader2 className="w-8 h-8 animate-spin text-primary-600" />
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  return children;
};

// Role-gated route wrapper (defaults to admin-only)
const RoleRoute = ({ children, allowedRoles = ['admin'], deniedMessage = 'Admin access required' }) => {
  const { isAuthenticated, user, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-slate-900">
        <Loader2 className="w-8 h-8 animate-spin text-primary-600" />
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  if (!allowedRoles.includes(user?.role)) {
    alert(deniedMessage);
    return <Navigate to="/" replace />;
  }

  return children;
};

// Convenience wrappers
const AdminRoute = ({ children }) => (
  <RoleRoute allowedRoles={['admin']}>{children}</RoleRoute>
);
const ManagerOrAdminRoute = ({ children }) => (
  <RoleRoute allowedRoles={['admin', 'manager']} deniedMessage="Manager or admin access required">
    {children}
  </RoleRoute>
);

// Main app content with routing
const AppContent = () => {
  // Update HTML lang attribute when language changes
  useLanguageEffect();

  return (
    <Router>
      <Routes>
        {/* Public route */}
        <Route path="/login" element={<Login />} />

        {/* Protected routes */}
        <Route
          path="/*"
          element={
            <ProtectedRoute>
              <Layout>
                <Routes>
                  <Route path="/" element={<Navigate to="/inactive-management" replace />} />
                  <Route path="/adf-list" element={<AdfList />} />
                  <Route path="/courses/:courseId" element={<CourseDetail />} />
                  <Route path="/participants" element={<Participants />} />
                  <Route path="/participants/:participantId" element={<ParticipantDetail />} />
                  <Route path="/account" element={<Account />} />
                  <Route path="/inactive-management" element={<InactiveManagement />} />
                  <Route path="/module-management" element={<ModuleManagement />} />
                  <Route path="/settings" element={<Settings />} />
                  <Route
                    path="/admin/sync"
                    element={
                      <AdminRoute>
                        <AdminSyncDashboard />
                      </AdminRoute>
                    }
                  />
                  <Route
                    path="/interventions"
                    element={
                      <ManagerOrAdminRoute>
                        <AdminInterventions />
                      </ManagerOrAdminRoute>
                    }
                  />
                  {/* Legacy path redirect so old bookmarks still work */}
                  <Route path="/admin/interventions" element={<Navigate to="/interventions" replace />} />
                  <Route
                    path="/admin/action-history"
                    element={
                      <AdminRoute>
                        <AdminActionHistory />
                      </AdminRoute>
                    }
                  />
                </Routes>
              </Layout>
            </ProtectedRoute>
          }
        />
      </Routes>
    </Router>
  );
};

function App() {
  return (
    <ThemeProvider>
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <AppContent />
      </AuthProvider>
      {/* React Query DevTools - only shows in development */}
      <ReactQueryDevtools initialIsOpen={false} />
    </QueryClientProvider>
    </ThemeProvider>
  );
}

export default App;

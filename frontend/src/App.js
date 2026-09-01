import React, { lazy, Suspense } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClientProvider } from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';
import { queryClient } from './queryClient';
import './i18n'; // Initialize i18n
import { useLanguageEffect } from './hooks/useLanguageEffect';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import { ThemeProvider } from './contexts/ThemeContext';
import Layout from './components/Layout';
import { Loader2 } from 'lucide-react';

// Pages are code-split so the initial bundle only carries the shell. Previously all
// twelve were imported eagerly, so every visitor downloaded every page (including
// the 2k-line InactiveManagement and the admin dashboards) before first paint.
const Login = lazy(() => import('./pages/Login'));
const AdfList = lazy(() => import('./pages/AdfList'));
const CourseDetail = lazy(() => import('./pages/CourseDetail'));
const Participants = lazy(() => import('./pages/Participants'));
const ParticipantDetail = lazy(() => import('./pages/ParticipantDetail'));
const Account = lazy(() => import('./pages/Account'));
const InactiveManagement = lazy(() => import('./pages/InactiveManagement'));
const Settings = lazy(() => import('./pages/Settings'));
const AdminSyncDashboard = lazy(() => import('./pages/AdminSyncDashboard'));
const AdminInterventions = lazy(() => import('./pages/AdminInterventions'));
const AdminActionHistory = lazy(() => import('./pages/AdminActionHistory'));
const AdminUsers = lazy(() => import('./pages/AdminUsers'));
const ModuleManagement = lazy(() => import('./pages/ModuleManagement'));
const BillingManagement = lazy(() => import('./pages/BillingManagement'));

// Shown while a route chunk is being fetched.
const RouteFallback = () => (
  <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-slate-900">
    <Loader2 className="w-8 h-8 animate-spin text-primary-600" />
  </div>
);

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
const BillingOrAdminRoute = ({ children }) => (
  <RoleRoute allowedRoles={['admin', 'billing']} deniedMessage="Billing or admin access required">
    {children}
  </RoleRoute>
);

// Main app content with routing
const AppContent = () => {
  // Update HTML lang attribute when language changes
  useLanguageEffect();

  return (
    <Router>
      <Suspense fallback={<RouteFallback />}>
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
                    <Route
                      path="/billing"
                      element={
                        <BillingOrAdminRoute>
                          <BillingManagement />
                        </BillingOrAdminRoute>
                      }
                    />
                    <Route
                      path="/admin/users"
                      element={
                        <AdminRoute>
                          <AdminUsers />
                        </AdminRoute>
                      }
                    />
                  </Routes>
                </Layout>
              </ProtectedRoute>
            }
          />
        </Routes>
      </Suspense>
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

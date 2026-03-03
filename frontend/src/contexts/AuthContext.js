import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { authService } from '../services/auth';

const AuthContext = createContext(null);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(() => localStorage.getItem('token'));
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);

  const isAuthenticated = !!token;

  // Fetch current user info on mount if token exists
  useEffect(() => {
    const initAuth = async () => {
      if (token) {
        try {
          const userData = await authService.getCurrentUser();
          setUser(userData);
        } catch (err) {
          // Token is invalid, clear it
          console.error('Failed to fetch user:', err);
          localStorage.removeItem('token');
          setToken(null);
          setUser(null);
        }
      }
      setIsLoading(false);
    };

    initAuth();
  }, [token]);

  const login = useCallback(async (username, password) => {
    setError(null);
    setIsLoading(true);

    try {
      const response = await authService.login(username, password);
      const { access_token } = response;

      // Store token
      localStorage.setItem('token', access_token);
      setToken(access_token);

      // Fetch user info
      const userData = await authService.getCurrentUser();
      setUser(userData);

      return true;
    } catch (err) {
      const message = err.response?.data?.detail || 'Login failed';
      setError(message);
      return false;
    } finally {
      setIsLoading(false);
    }
  }, []);

  const loginWithMicrosoft = useCallback(async (idToken) => {
    setError(null);
    setIsLoading(true);

    try {
      const response = await authService.microsoftLogin(idToken);
      const { access_token } = response;

      localStorage.setItem('token', access_token);
      setToken(access_token);

      const userData = await authService.getCurrentUser();
      setUser(userData);

      return true;
    } catch (err) {
      const message = err.response?.data?.detail || 'Microsoft login failed';
      setError(message);
      return false;
    } finally {
      setIsLoading(false);
    }
  }, []);

  const logout = useCallback(() => {
    localStorage.removeItem('token');
    setToken(null);
    setUser(null);
    setError(null);
  }, []);

  const clearError = useCallback(() => {
    setError(null);
  }, []);

  const value = {
    user,
    token,
    isAuthenticated,
    isLoading,
    error,
    login,
    loginWithMicrosoft,
    logout,
    clearError,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};

export default AuthContext;

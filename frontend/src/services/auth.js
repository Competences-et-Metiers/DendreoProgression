import api from './api';

export const authService = {
  /**
   * Login with username and password
   * @param {string} username
   * @param {string} password
   * @returns {Promise<{access_token: string, token_type: string}>}
   */
  async login(username, password) {
    const response = await api.post('/auth/login', { username, password });
    return response.data;
  },

  /**
   * Get current authenticated user info
   * @returns {Promise<{id: number, username: string, is_active: boolean}>}
   */
  async getCurrentUser() {
    const response = await api.get('/auth/me');
    return response.data;
  },

  /**
   * Logout - clears local storage
   */
  logout() {
    localStorage.removeItem('token');
  },

  /**
   * Check if user is authenticated (has token in localStorage)
   * @returns {boolean}
   */
  isAuthenticated() {
    return !!localStorage.getItem('token');
  },

  /**
   * Get stored token
   * @returns {string|null}
   */
  getToken() {
    return localStorage.getItem('token');
  },
};

export default authService;

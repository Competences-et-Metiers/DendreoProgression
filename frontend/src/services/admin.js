import api from './api';

/**
 * Admin API service for sync management
 */

export const adminService = {
  /**
   * Get API usage statistics (last sync, today, week, month)
   */
  getApiUsage: async () => {
    const response = await api.get('/admin/sync/api-usage');
    return response.data;
  },

  /**
   * Trigger a dry-run sync (no database changes)
   */
  triggerDryRun: async () => {
    const response = await api.post('/admin/sync/dry-run');
    return response.data;
  },

  /**
   * Force an immediate full sync
   */
  forceSync: async () => {
    const response = await api.post('/admin/sync/force');
    return response.data;
  },

  /**
   * Sync a specific ADF by ID
   */
  syncSpecificAdf: async (adfId) => {
    const response = await api.post(`/admin/sync/adf/${adfId}`);
    return response.data;
  },

  /**
   * Get current sync configuration
   */
  getSyncConfig: async () => {
    const response = await api.get('/admin/sync/config');
    return response.data;
  },

  /**
   * Update sync configuration
   */
  updateSyncConfig: async (config) => {
    const response = await api.put('/admin/sync/config', config);
    return response.data;
  },

  /**
   * Get current sync status
   */
  getSyncStatus: async () => {
    const response = await api.get('/admin/sync/status');
    return response.data;
  },

  /**
   * Get sync history
   */
  getSyncHistory: async (limit = 10) => {
    const response = await api.get(`/admin/sync/history?limit=${limit}`);
    return response.data;
  },
};

export default adminService;

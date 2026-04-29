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
  getSyncHistory: async (page = 1, pageSize = 50) => {
    const response = await api.get(`/admin/sync/history?page=${page}&page_size=${pageSize}`);
    return response.data;
  },

  /**
   * Resume sync from where the last one stopped (skipped ADFs)
   */
  resumeSync: async () => {
    const response = await api.post('/admin/sync/resume');
    return response.data;
  },

  /**
   * Cancel/discard the pending list of ADFs skipped due to API limit.
   * After this call the Resume prompt disappears.
   */
  cancelResume: async () => {
    const response = await api.post('/admin/sync/resume/cancel');
    return response.data;
  },

  /**
   * Get live sync log (incremental, byte-offset based)
   */
  getLiveLog: async (offset = 0) => {
    const response = await api.get(`/admin/sync/live-log?offset=${offset}`);
    return response.data;
  },

  /**
   * Stop a currently running sync process
   */
  stopSync: async () => {
    const response = await api.post('/admin/sync/stop');
    return response.data;
  },

  /**
   * Sync module categories from Dendreo
   */
  syncCategories: async () => {
    const response = await api.post('/admin/sync/categories');
    return response.data;
  },

  // ─── Admin Interventions ───

  getInterventions: async (params = {}) => {
    const query = new URLSearchParams();
    if (params.page) query.set('page', params.page);
    if (params.page_size) query.set('page_size', params.page_size);
    if (params.sort_order) query.set('sort_order', params.sort_order);
    if (params.intervention_type) query.set('intervention_type', params.intervention_type);
    if (params.is_active !== undefined && params.is_active !== null) query.set('is_active', params.is_active);
    if (params.user_id) query.set('user_id', params.user_id);
    if (params.search) query.set('search', params.search);
    if (params.date_from) query.set('date_from', params.date_from);
    if (params.date_to) query.set('date_to', params.date_to);
    const response = await api.get(`/admin/interventions?${query.toString()}`);
    return response.data;
  },

  getInterventionStats: async () => {
    const response = await api.get('/admin/interventions/stats');
    return response.data;
  },

  // ─── Admin Action History ───

  getActionHistory: async (params = {}) => {
    const query = new URLSearchParams();
    if (params.page) query.set('page', params.page);
    if (params.page_size) query.set('page_size', params.page_size);
    if (params.sort_order) query.set('sort_order', params.sort_order);
    if (params.action_type) query.set('action_type', params.action_type);
    if (params.status) query.set('status', params.status);
    if (params.user_id) query.set('user_id', params.user_id);
    if (params.search) query.set('search', params.search);
    if (params.date_from) query.set('date_from', params.date_from);
    if (params.date_to) query.set('date_to', params.date_to);
    const response = await api.get(`/admin/action-history?${query.toString()}`);
    return response.data;
  },

  getActionHistoryStats: async () => {
    const response = await api.get('/admin/action-history/stats');
    return response.data;
  },
};

export default adminService;

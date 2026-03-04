import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor - add Authorization header
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor - handle 401 errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Clear token and redirect to login
      localStorage.removeItem('token');
      // Only redirect if not already on login page
      if (window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

// API service functions
export const apiService = {
  // Dashboard stats
  async getDashboardStats() {
    const response = await api.get('/courses/stats');
    return response.data;
  },

  // Courses
  async getAllCourses() {
    const response = await api.get('/courses/courses');
    return response.data;
  },

  async getCourseParticipants(courseId) {
    const response = await api.get(`/courses/courses/${courseId}/participants`);
    return response.data;
  },

  async getCourseTimeStats(courseId) {
    const response = await api.get(`/courses/courses/${courseId}/time-stats`);
    return response.data;
  },

  // Participants
  async getAllParticipants(page = 1, pageSize = 25, searchTerm = '') {
    const skip = (page - 1) * pageSize;
    const params = {
      skip,
      limit: pageSize
    };
    
    // Add search parameters if provided
    if (searchTerm) {
      params.search = searchTerm;
    }
    
    const response = await api.get('/participants/', { params });
    return response.data;
  },

  async getParticipantsCount(searchTerm = '') {
    const params = {};
    
    // Add search parameters if provided
    if (searchTerm) {
      params.search = searchTerm;
    }
    
    const response = await api.get('/participants/count', { params });
    return response.data;
  },

  async getParticipantDetails(participantId) {
    const response = await api.get(`/courses/participants/${participantId}`);
    return response.data;
  },

  // HubSpot
  async getHubspotContact(email) {
    const response = await api.get(`/hubspot/contact/${encodeURIComponent(email)}`);
    return response.data;
  },

  // Interventions
  async createIntervention(data) {
    const response = await api.post('/interventions/', data);
    return response.data;
  },

  async getParticipantTimeline(participantId, idActionFormation = null) {
    const params = {};
    if (idActionFormation) params.id_action_formation = idActionFormation;
    const response = await api.get(`/interventions/timeline/${participantId}`, { params });
    return response.data;
  },

  async cancelIntervention(interventionId) {
    const response = await api.post(`/interventions/${interventionId}/cancel`);
    return response.data;
  },

  // Sync operations
  async syncAll() {
    const response = await api.post('/sync/sync-all');
    return response.data;
  },

  async syncTest() {
    const response = await api.post('/sync/sync-test');
    return response.data;
  },

  async cleanupElearningSync() {
    const response = await api.post('/sync/cleanup-elearning-sync');
    return response.data;
  },

  async getElearningSyncStats() {
    const response = await api.get('/sync/elearning-sync-stats');
    return response.data;
  },

  async getLastSync() {
    const response = await api.get('/sync/last-sync');
    return response.data;
  },
};

export default api; 
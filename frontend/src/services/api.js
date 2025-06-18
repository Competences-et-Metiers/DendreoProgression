import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://192.168.254.24:8000/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

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

  // Participants
  async getAllParticipants() {
    const response = await api.get('/participants/');
    return response.data;
  },

  async getParticipantDetails(participantId) {
    const response = await api.get(`/courses/participants/${participantId}`);
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
};

export default api; 
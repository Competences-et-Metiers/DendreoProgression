import { QueryClient } from '@tanstack/react-query';

// Create a client with optimized defaults for our use case
export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      // Background refetch settings
      staleTime: 5 * 60 * 1000, // 5 minutes - data is considered fresh for 5 minutes
      gcTime: 10 * 60 * 1000, // 10 minutes - cache time (previously cacheTime)
      
      // Network and retry settings
      retry: (failureCount, error) => {
        // Don't retry for 4xx errors (client errors)
        if (error?.response?.status >= 400 && error?.response?.status < 500) {
          return false;
        }
        // Retry up to 2 times for other errors
        return failureCount < 2;
      },
      retryDelay: attemptIndex => Math.min(1000 * 2 ** attemptIndex, 30000),
      
      // Refetch settings
      refetchOnWindowFocus: false, // Don't refetch when window regains focus
      refetchOnReconnect: true, // Refetch when network reconnects
      refetchOnMount: true, // Always refetch when component mounts
      
      // Background refetch
      refetchInterval: false, // Don't auto-refetch by default
      refetchIntervalInBackground: false,
    },
    mutations: {
      // Retry mutations once
      retry: 1,
      retryDelay: 1000,
    },
  },
});

// Query keys for consistent caching
export const queryKeys = {
  // Dashboard
  dashboardStats: ['dashboard', 'stats'],
  
  // Courses
  courses: ['courses'],
  courseDetails: (courseId) => ['courses', courseId],
  courseParticipants: (courseId) => ['courses', courseId, 'participants'],
  
  // Participants
  participants: ['participants'],
  participantDetails: (participantId) => ['participants', participantId],
  
  // Sync
  syncStats: ['sync', 'stats'],

  // Interventions
  interventionTimeline: (participantId, adf) => ['interventions', 'timeline', participantId, adf],

  // HubSpot deals
  hubspotDeals: (email) => ['hubspot', 'deals', email],

  // Saved views
  savedViews: ['savedViews'],

  // Admin interventions
  adminInterventions: (params) => ['admin', 'interventions', params],
  adminInterventionStats: ['admin', 'interventions', 'stats'],
}; 
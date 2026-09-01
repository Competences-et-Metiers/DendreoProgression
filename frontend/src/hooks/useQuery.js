import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiService } from '../services/api';
import { queryKeys } from '../queryClient';

// ADF List hooks
export const useAdfListStats = () => {
  return useQuery({
    queryKey: queryKeys.adfListStats,
    queryFn: apiService.getAdfListStats,
    staleTime: 5 * 60 * 1000, // 5 minutes
    gcTime: 10 * 60 * 1000, // 10 minutes
    refetchOnMount: false, // Don't refetch if data is still fresh
    refetchOnWindowFocus: false,
  });
};

// Course hooks
export const useCourses = () => {
  return useQuery({
    queryKey: queryKeys.courses,
    queryFn: apiService.getAllCourses,
    staleTime: 10 * 60 * 1000, // 10 minutes - courses don't change often
    gcTime: 30 * 60 * 1000, // 30 minutes
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });
};

export const useCourseParticipants = (courseId) => {
  return useQuery({
    queryKey: queryKeys.courseParticipants(courseId),
    queryFn: () => apiService.getCourseParticipants(courseId),
    enabled: !!courseId, // Only run if courseId is provided
    staleTime: 5 * 60 * 1000, // 5 minutes
    gcTime: 15 * 60 * 1000, // 15 minutes
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });
};

// Participant hooks
export const useParticipants = (page = 1, pageSize = 25, searchTerm = '', dealFilter = 'all') => {
  return useQuery({
    queryKey: [...queryKeys.participants, page, pageSize, searchTerm, dealFilter],
    queryFn: () => apiService.getAllParticipants(page, pageSize, searchTerm, dealFilter),
    staleTime: 5 * 60 * 1000, // 5 minutes
    gcTime: 15 * 60 * 1000, // 15 minutes
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });
};

export const useParticipantsCount = (searchTerm = '', dealFilter = 'all') => {
  return useQuery({
    queryKey: [...queryKeys.participants, 'count', searchTerm, dealFilter],
    queryFn: () => apiService.getParticipantsCount(searchTerm, dealFilter),
    staleTime: 5 * 60 * 1000, // 5 minutes
    gcTime: 15 * 60 * 1000, // 15 minutes
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });
};

export const useParticipantDetails = (participantId) => {
  const id = participantId != null ? parseInt(participantId, 10) : null;
  return useQuery({
    queryKey: queryKeys.participantDetails(id),
    queryFn: () => apiService.getParticipantDetails(id),
    enabled: !!id,
    staleTime: 5 * 60 * 1000, // 5 minutes
    gcTime: 15 * 60 * 1000, // 15 minutes
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });
};

// Sync hooks
export const useSyncStats = () => {
  return useQuery({
    queryKey: queryKeys.syncStats,
    queryFn: apiService.getElearningSyncStats,
    staleTime: 2 * 60 * 1000, // 2 minutes
    gcTime: 5 * 60 * 1000, // 5 minutes
    refetchOnMount: true, // Always refresh sync stats
    refetchOnWindowFocus: true,
  });
};

export const useLastSync = () => {
  const query = useQuery({
    queryKey: ['lastSync'],
    queryFn: apiService.getLastSync,
    staleTime: 1 * 60 * 1000, // 1 minute - shorter since this changes frequently
    gcTime: 5 * 60 * 1000, // 5 minutes
    retry: 2,
    refetchOnWindowFocus: true, // Refetch when window gets focus
    refetchOnMount: true, // Always refresh sync info
    // Poll every 5 seconds while a sync is in progress, otherwise refresh once a minute
    // so the next-sync countdown / cooldown calculation stays current.
    refetchInterval: (query) => {
      const data = query.state.data;
      if (data?.in_progress || data?.sync_status === 'in_progress') return 5000;
      return 60000;
    },
  });
  return query;
};

// Intervention hooks
export const useParticipantTimeline = (participantId, idActionFormation, enabled = true) => {
  return useQuery({
    queryKey: queryKeys.interventionTimeline(participantId, idActionFormation),
    queryFn: () => apiService.getParticipantTimeline(participantId, idActionFormation),
    enabled: enabled && !!participantId,
    staleTime: 2 * 60 * 1000, // 2 minutes
    gcTime: 10 * 60 * 1000,
    refetchOnMount: true,
    refetchOnWindowFocus: false,
  });
};

export const useCreateIntervention = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: apiService.createIntervention,
    onSuccess: (data, variables) => {
      // Invalidate timeline for this participant
      queryClient.invalidateQueries({
        queryKey: ['interventions', 'timeline', variables.participant_id],
      });
      // Invalidate inactive participants list to pick up snooze/dismiss changes
      queryClient.invalidateQueries({ queryKey: ['inactiveParticipants'] });
    },
  });
};

export const useCancelIntervention = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: apiService.cancelIntervention,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['interventions'] });
      queryClient.invalidateQueries({ queryKey: ['inactiveParticipants'] });
    },
  });
};

export const useDeleteIntervention = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: apiService.deleteIntervention,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['interventions'] });
      queryClient.invalidateQueries({ queryKey: ['inactiveParticipants'] });
    },
  });
};

export const useDeleteHubspotNote = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ hubspotNoteId, participantId, idActionFormation }) =>
      apiService.deleteHubspotNote(hubspotNoteId, participantId, idActionFormation),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['interventions'] });
    },
  });
};

// HubSpot Deal hooks
export const useHubspotDeals = (email, enabled = false) => {
  return useQuery({
    queryKey: queryKeys.hubspotDeals(email),
    queryFn: () => apiService.getHubspotDeals(email),
    enabled: enabled && !!email,
    staleTime: 5 * 60 * 1000,
    gcTime: 15 * 60 * 1000,
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });
};

export const useLinkDeal = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ participantId, idActionFormation, dealId }) =>
      apiService.linkDeal(participantId, idActionFormation, dealId),
    onMutate: async ({ participantId, idActionFormation, dealId }) => {
      const key = queryKeys.participantDetails(participantId);
      await queryClient.cancelQueries({ queryKey: key });
      const previous = queryClient.getQueryData(key);
      const optimisticDeal = {
        deal_id: dealId,
        deal_url: `https://app-eu1.hubspot.com/contacts/25868618/record/0-3/${dealId}`,
      };
      queryClient.setQueryData(key, (old) => {
        if (!old?.courses) return old;
        return {
          ...old,
          courses: old.courses.map((c) =>
            c.id_action_formation === idActionFormation
              ? { ...c, hubspot_deal: optimisticDeal }
              : c
          ),
        };
      });
      return { previous };
    },
    onError: (_err, variables, context) => {
      if (context?.previous) {
        queryClient.setQueryData(
          queryKeys.participantDetails(variables.participantId),
          context.previous
        );
      }
    },
    onSettled: (_data, _err, variables) => {
      queryClient.invalidateQueries({
        queryKey: queryKeys.participantDetails(variables.participantId),
      });
    },
  });
};

export const useUnlinkDeal = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ participantId, idActionFormation }) =>
      apiService.unlinkDeal(participantId, idActionFormation),
    onMutate: async ({ participantId, idActionFormation }) => {
      const key = queryKeys.participantDetails(participantId);
      await queryClient.cancelQueries({ queryKey: key });
      const previous = queryClient.getQueryData(key);
      queryClient.setQueryData(key, (old) => {
        if (!old?.courses) return old;
        return {
          ...old,
          courses: old.courses.map((c) =>
            c.id_action_formation === idActionFormation
              ? { ...c, hubspot_deal: null }
              : c
          ),
        };
      });
      return { previous };
    },
    onError: (_err, variables, context) => {
      if (context?.previous) {
        queryClient.setQueryData(
          queryKeys.participantDetails(variables.participantId),
          context.previous
        );
      }
    },
    onSettled: (_data, _err, variables) => {
      queryClient.invalidateQueries({
        queryKey: queryKeys.participantDetails(variables.participantId),
      });
    },
  });
};

// Billing hooks
export const useBillingParticipants = (filters = {}) => {
  return useQuery({
    queryKey: queryKeys.billingParticipants(filters),
    queryFn: () => apiService.getBillingParticipants(filters),
    staleTime: 60 * 1000,
    gcTime: 10 * 60 * 1000,
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });
};

export const useSetBillingStatus = (filters = {}) => {
  const queryClient = useQueryClient();
  const key = queryKeys.billingParticipants(filters);

  return useMutation({
    mutationFn: ({ participantId, idActionFormation, facturation }) =>
      apiService.setBillingStatus(participantId, idActionFormation, facturation),
    onMutate: async ({ participantId, idActionFormation, facturation, dealId }) => {
      await queryClient.cancelQueries({ queryKey: key });
      const previous = queryClient.getQueryData(key);
      // The status lives on the deal, and one deal can be linked to several of a
      // participant's enrollments — the server updates them all, so preview that.
      const affects = (p) =>
        dealId
          ? p.deal_id === dealId
          : p.id === participantId && p.id_action_formation === idActionFormation;
      queryClient.setQueryData(key, (old) => {
        if (!old?.participants) return old;
        return {
          ...old,
          participants: old.participants.map((p) =>
            affects(p) ? { ...p, deal_facturation: facturation } : p
          ),
        };
      });
      return { previous };
    },
    // HubSpot is the source of truth: on failure nothing was written there
    // either, so roll the row back to what it was.
    onError: (_err, _variables, context) => {
      if (context?.previous) queryClient.setQueryData(key, context.previous);
    },
    onSettled: (_data, _err, variables) => {
      queryClient.invalidateQueries({
        queryKey: queryKeys.participantDetails(variables.participantId),
      });
    },
  });
};

// Mutation hooks for cache invalidation
export const useSyncMutation = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: apiService.syncAll,
    onSuccess: () => {
      // Invalidate all queries after sync
      queryClient.invalidateQueries({ queryKey: queryKeys.adfListStats });
      queryClient.invalidateQueries({ queryKey: queryKeys.courses });
      queryClient.invalidateQueries({ queryKey: queryKeys.participants });
      queryClient.invalidateQueries({ queryKey: ['lastSync'] });
    },
  });
};

// Helper hook for prefetching
export const usePrefetchQueries = () => {
  const queryClient = useQueryClient();
  
  const prefetchDashboard = () => {
    queryClient.prefetchQuery({
      queryKey: queryKeys.adfListStats,
      queryFn: apiService.getAdfListStats,
      staleTime: 5 * 60 * 1000,
    });
  };
  
  const prefetchCourses = () => {
    queryClient.prefetchQuery({
      queryKey: queryKeys.courses,
      queryFn: apiService.getAllCourses,
      staleTime: 10 * 60 * 1000,
    });
  };
  
  const prefetchParticipants = () => {
    queryClient.prefetchQuery({
      queryKey: queryKeys.participants,
      queryFn: apiService.getAllParticipants,
      staleTime: 5 * 60 * 1000,
    });
  };
  
  const prefetchParticipantDetails = (participantId) => {
    if (participantId) {
      queryClient.prefetchQuery({
        queryKey: queryKeys.participantDetails(participantId),
        queryFn: () => apiService.getParticipantDetails(participantId),
        staleTime: 5 * 60 * 1000,
      });
    }
  };
  
  const prefetchCourseParticipants = (courseId) => {
    if (courseId) {
      queryClient.prefetchQuery({
        queryKey: queryKeys.courseParticipants(courseId),
        queryFn: () => apiService.getCourseParticipants(courseId),
        staleTime: 5 * 60 * 1000,
      });
    }
  };
  
  return {
    prefetchDashboard,
    prefetchCourses,
    prefetchParticipants,
    prefetchParticipantDetails,
    prefetchCourseParticipants,
  };
};

// Cache management hooks
export const useCacheManager = () => {
  const queryClient = useQueryClient();
  
  const invalidateAll = () => {
    queryClient.invalidateQueries();
  };
  
  const invalidateDashboard = () => {
    queryClient.invalidateQueries({ queryKey: queryKeys.adfListStats });
  };
  
  const invalidateCourses = () => {
    queryClient.invalidateQueries({ queryKey: queryKeys.courses });
  };
  
  const invalidateParticipants = () => {
    queryClient.invalidateQueries({ queryKey: queryKeys.participants });
  };
  
  const invalidateParticipantDetails = (participantId) => {
    if (participantId) {
      queryClient.invalidateQueries({ 
        queryKey: queryKeys.participantDetails(participantId) 
      });
    }
  };
  
  const clearCache = () => {
    queryClient.clear();
  };
  
  return {
    invalidateAll,
    invalidateDashboard,
    invalidateCourses,
    invalidateParticipants,
    invalidateParticipantDetails,
    clearCache,
  };
}; 
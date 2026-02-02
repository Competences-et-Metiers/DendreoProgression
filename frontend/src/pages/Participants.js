import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import LoadingSpinner from '../components/LoadingSpinner';
import ProgressBar from '../components/ProgressBar';
import Pagination from '../components/Pagination';
import { useParticipants, useParticipantsCount, usePrefetchQueries } from '../hooks/useQuery';
import {
  Users,
  User,
  BookOpen,
  Target,
  Mail,
  ChevronRight,
  Filter,
  Search,
  RefreshCw,
  ExternalLink,
  ArrowUp,
  ArrowDown
} from 'lucide-react';

const Participants = () => {
  const { t } = useTranslation();
  const [searchTerm, setSearchTerm] = useState('');
  const [debouncedSearchTerm, setDebouncedSearchTerm] = useState('');
  const [sortBy, setSortBy] = useState('progression');
  const [sortDirection, setSortDirection] = useState(() => {
    const cached = localStorage.getItem('participantSortDirection');
    return cached || 'desc';
  });
  const [statusFilters, setStatusFilters] = useState(() => {
    const cached = localStorage.getItem('participantStatusFilters');
    return cached ? JSON.parse(cached) : { active: true, completed: true };
  });
  const [inactivityDays, setInactivityDays] = useState(() => {
    const cached = localStorage.getItem('participantInactivityDays');
    return cached ? parseInt(cached, 10) : 30;
  });
  const [inactivityFilterEnabled, setInactivityFilterEnabled] = useState(() => {
    const cached = localStorage.getItem('participantInactivityFilterEnabled');
    return cached ? JSON.parse(cached) : false;
  });
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(25);
  const searchInputRef = useRef(null);
  const navigate = useNavigate();

  // Cache status filters in localStorage
  useEffect(() => {
    localStorage.setItem('participantStatusFilters', JSON.stringify(statusFilters));
  }, [statusFilters]);

  // Cache inactivity days in localStorage
  useEffect(() => {
    localStorage.setItem('participantInactivityDays', inactivityDays.toString());
  }, [inactivityDays]);

  // Cache inactivity filter enabled state in localStorage
  useEffect(() => {
    localStorage.setItem('participantInactivityFilterEnabled', JSON.stringify(inactivityFilterEnabled));
  }, [inactivityFilterEnabled]);

  // Cache sort direction in localStorage
  useEffect(() => {
    localStorage.setItem('participantSortDirection', sortDirection);
  }, [sortDirection]);
  
  // Use React Query hooks for data fetching with caching
  const { 
    data: participants = [], 
    isLoading: loading, 
    error,
    refetch,
    isFetching
  } = useParticipants(currentPage, pageSize, debouncedSearchTerm);
  
  // Keep previous data visible during refetch to avoid jarring reloads
  const [stableParticipants, setStableParticipants] = useState([]);
  
  // Update stable participants when new data arrives, but keep previous data during loading
  useEffect(() => {
    // Always update stable participants with current data, even if empty
    // This ensures we show empty state when no results are found
    setStableParticipants(participants);
  }, [participants]);
  
  // Use stable participants for display to avoid flickering
  // If we have stable data, use it. Otherwise, use current participants (even if empty)
  const displayParticipants = stableParticipants.length > 0 ? stableParticipants : participants;
  
  const { 
    data: countData,
    isLoading: countLoading
  } = useParticipantsCount(debouncedSearchTerm);
  
  const { prefetchParticipantDetails } = usePrefetchQueries();

  // Handle search submission on Enter key
  const handleSearchSubmit = (e) => {
    if (e.key === 'Enter') {
      setDebouncedSearchTerm(searchTerm);
    }
  };

  // Maintain focus on search input after re-renders
  useEffect(() => {
    if (searchInputRef.current && document.activeElement !== searchInputRef.current) {
      // Only restore focus if the search input was previously focused
      const wasSearchFocused = sessionStorage.getItem('searchInputFocused') === 'true';
      if (wasSearchFocused) {
        searchInputRef.current.focus();
      }
    }
  });

  // Reset to first page when filters change
  useEffect(() => {
    setCurrentPage(1);
  }, [debouncedSearchTerm, statusFilters, inactivityFilterEnabled, inactivityDays, sortBy, sortDirection]);

  // Helper functions for status filter checkboxes
  const allStatusesSelected = statusFilters.active && statusFilters.completed;

  const toggleAllStatuses = () => {
    const newValue = !allStatusesSelected;
    setStatusFilters({ active: newValue, completed: newValue });
  };

  const toggleStatusFilter = (status) => {
    setStatusFilters(prev => ({ ...prev, [status]: !prev[status] }));
  };

  const toggleSortDirection = () => {
    setSortDirection(prev => prev === 'asc' ? 'desc' : 'asc');
  };

  const handlePageChange = (newPage) => {
    setCurrentPage(newPage);
  };

  const handlePageSizeChange = (newPageSize) => {
    setPageSize(newPageSize);
    setCurrentPage(1); // Reset to first page when changing page size
  };

  const handleParticipantClick = (participantId, event) => {
    // Check if Ctrl/Cmd key is pressed or middle mouse button for new tab
    if (event.ctrlKey || event.metaKey || event.button === 1) {
      // Open in new tab
      window.open(`/participants/${participantId}`, '_blank', 'noopener,noreferrer');
    } else {
      // Prefetch participant details for faster loading
      prefetchParticipantDetails(participantId);
      navigate(`/participants/${participantId}`);
    }
  };

  // Helper to get participant's most recent activity from their courses
  const getParticipantLastActivity = (participant) => {
    if (!participant.courses || participant.courses.length === 0) return null;

    const lastActivities = participant.courses
      .map(c => c.last_activity)
      .filter(Boolean)
      .map(date => new Date(date));

    if (lastActivities.length === 0) return null;
    return new Date(Math.max(...lastActivities));
  };

  // Helper to calculate days since last activity
  const getDaysSinceLastActivity = (participant) => {
    const lastActivity = getParticipantLastActivity(participant);
    if (!lastActivity) return Infinity;

    const now = new Date();
    const diffTime = Math.abs(now - lastActivity);
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  };

  // Helper to check if participant has completed all their courses
  const hasCompletedAllCourses = (participant) => {
    const completedCourses = participant.completed_courses || 0;
    const totalCourses = participant.total_courses || 0;
    return totalCourses > 0 && completedCourses === totalCourses;
  };

  const getFilteredAndSortedParticipants = () => {
    let filtered = displayParticipants;

    // Filter by status checkboxes (multi-select)
    filtered = filtered.filter(p => {
      const isActive = p.active_courses > 0;
      const isCompleted = p.completed_courses > 0;

      // If inactivity filter is enabled, show participants inactive for X days
      // BUT exclude those who have completed all their courses (they won't log in anymore)
      if (inactivityFilterEnabled) {
        const isInactiveForDays = getDaysSinceLastActivity(p) >= inactivityDays;
        const completedAll = hasCompletedAllCourses(p);

        // Show if inactive for X days AND not completed all courses
        if (isInactiveForDays && !completedAll) {
          return true;
        }
        return false;
      }

      // Without inactivity filter, just use active/completed filters
      if (isActive && statusFilters.active) return true;
      if (isCompleted && statusFilters.completed) return true;

      return false;
    });

    // Sort participants
    const sortMultiplier = sortDirection === 'asc' ? 1 : -1;

    return filtered.sort((a, b) => {
      let comparison = 0;
      switch (sortBy) {
        case 'name':
          const nameA = `${a.prenom || ''} ${a.nom || ''}`.trim();
          const nameB = `${b.prenom || ''} ${b.nom || ''}`.trim();
          comparison = nameA.localeCompare(nameB, 'fr');
          break;
        case 'progression':
          comparison = (a.overall_progression || 0) - (b.overall_progression || 0);
          break;
        case 'courses':
          comparison = (a.total_courses || 0) - (b.total_courses || 0);
          break;
        case 'email':
          comparison = (a.email || '').localeCompare(b.email || '', 'fr');
          break;
        case 'inactivity':
          comparison = getDaysSinceLastActivity(a) - getDaysSinceLastActivity(b);
          break;
        default:
          comparison = 0;
      }
      return comparison * sortMultiplier;
    });
  };

  const getProgressBadge = (participant) => {
    const completedCourses = participant.completed_courses || 0;
    const activeCourses = participant.active_courses || 0;
    const totalCourses = participant.total_courses || 0;

    if (completedCourses > 0 && completedCourses === totalCourses) {
      return <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
        {t('participants.status.allCompleted')}
      </span>;
    } else if (activeCourses > 0) {
      return <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
        {t('participants.status.active')}
      </span>;
    } else if (totalCourses > 0) {
      return <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
        {t('participants.status.inactive')}
      </span>;
    } else {
      return <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
        {t('participants.status.noCourses')}
      </span>;
    }
  };

  // Only show full loading screen if we have no data at all and are loading for the first time
  // If we have stable data, we can show the page with a loading overlay instead
  if ((loading || countLoading) && stableParticipants.length === 0 && participants.length === 0) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <LoadingSpinner size="large" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="text-red-500 text-xl mb-4">⚠️ {t('common.error')}</div>
          <p className="text-gray-600 mb-4">{error.message || t('errors.failedToLoadParticipants')}</p>
          <button 
            onClick={refetch}
            className="bg-primary-500 text-white px-4 py-2 rounded-lg hover:bg-primary-600 mr-2"
          >
            {t('common.retry')}
          </button>
          <button 
            onClick={() => navigate('/')}
            className="bg-gray-500 text-white px-4 py-2 rounded-lg hover:bg-gray-600"
          >
            {t('navigation.backToDashboard')}
          </button>
        </div>
      </div>
    );
  }

  const filteredParticipants = getFilteredAndSortedParticipants();

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">{t('participants.title')}</h1>
              <p className="text-gray-600 mt-1">{t('participants.subtitle')}</p>
            </div>
            
            {/* Navigation Menu */}
            <div className="flex items-center space-x-4">
              <button
                onClick={refetch}
                disabled={isFetching}
                className="inline-flex items-center px-3 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 disabled:opacity-50"
                title={t('common.refreshData')}
              >
                <RefreshCw size={16} className={`mr-2 ${isFetching ? 'animate-spin' : ''}`} />
                {isFetching ? t('common.refreshing') : t('common.refresh')}
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Participants Section */}
        <div className="bg-white rounded-lg border border-gray-200">
          {/* Participants Header */}
          <div className="px-6 py-4 border-b border-gray-200">
            <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between">
              <div>
                <h2 className="text-lg font-semibold text-gray-900">{t('participants.allParticipants')}</h2>
                                  <p className="text-sm text-gray-600">
                    {t('participants.subtitleWithCount', { filtered: filteredParticipants.length, total: countData?.total || 0 })}
                  </p>
              </div>
              
              {/* Search and Filters */}
              <div className="flex flex-col space-y-4 mt-4 lg:mt-0">
                {/* First row: Search and Sort */}
                <div className="flex flex-col sm:flex-row items-start sm:items-center space-y-2 sm:space-y-0 sm:space-x-4">
                  {/* Search */}
                  <div className="relative">
                    <Search size={16} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
                    <input
                      ref={searchInputRef}
                      type="text"
                      placeholder={t('participants.searchPlaceholder')}
                      value={searchTerm}
                      onChange={(e) => setSearchTerm(e.target.value)}
                      onKeyDown={handleSearchSubmit}
                      onFocus={() => sessionStorage.setItem('searchInputFocused', 'true')}
                      onBlur={() => sessionStorage.removeItem('searchInputFocused')}
                      className="pl-10 pr-4 py-2 border border-gray-300 rounded-md text-sm w-64"
                    />
                  </div>

                  {/* Sort */}
                  <div className="flex items-center space-x-2">
                    <select
                      value={sortBy}
                      onChange={(e) => setSortBy(e.target.value)}
                      className="border border-gray-300 rounded-md px-3 py-2 text-sm"
                    >
                      <option value="name">{t('participants.sort.byName')}</option>
                      <option value="progression">{t('participants.sort.byProgress')}</option>
                      <option value="courses">{t('participants.sort.byCourses')}</option>
                      <option value="email">{t('participants.sort.byEmail')}</option>
                      <option value="inactivity">{t('participants.sort.byInactivity')}</option>
                    </select>
                    <button
                      onClick={toggleSortDirection}
                      className="p-2 border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
                      title={sortDirection === 'asc' ? t('participants.sort.ascending') : t('participants.sort.descending')}
                    >
                      {sortDirection === 'asc' ? (
                        <ArrowUp size={16} className="text-gray-600" />
                      ) : (
                        <ArrowDown size={16} className="text-gray-600" />
                      )}
                    </button>
                  </div>
                </div>

                {/* Second row: Status Filter Checkboxes */}
                <div className="flex flex-wrap items-center gap-4">
                  <div className="flex items-center space-x-2">
                    <Filter size={16} className="text-gray-500" />
                  </div>

                  {/* All Status checkbox */}
                  <label className="flex items-center space-x-2 cursor-pointer select-none">
                    <input
                      type="checkbox"
                      checked={allStatusesSelected && !inactivityFilterEnabled}
                      onChange={() => {
                        toggleAllStatuses();
                        if (inactivityFilterEnabled) setInactivityFilterEnabled(false);
                      }}
                      className="w-4 h-4 text-primary-600 border-gray-300 rounded focus:ring-primary-500"
                    />
                    <span className="text-sm text-gray-700">{t('participants.filters.allStatus')}</span>
                  </label>

                  {/* Active checkbox */}
                  <label className="flex items-center space-x-2 cursor-pointer select-none">
                    <input
                      type="checkbox"
                      checked={statusFilters.active}
                      onChange={() => toggleStatusFilter('active')}
                      className="w-4 h-4 text-primary-600 border-gray-300 rounded focus:ring-primary-500"
                    />
                    <span className="text-sm text-gray-700">{t('participants.filters.active')}</span>
                  </label>

                  {/* Completed checkbox */}
                  <label className="flex items-center space-x-2 cursor-pointer select-none">
                    <input
                      type="checkbox"
                      checked={statusFilters.completed}
                      onChange={() => toggleStatusFilter('completed')}
                      className="w-4 h-4 text-primary-600 border-gray-300 rounded focus:ring-primary-500"
                    />
                    <span className="text-sm text-gray-700">{t('participants.filters.completed')}</span>
                  </label>

                  {/* Inactivity days filter */}
                  <label className="flex items-center space-x-2 cursor-pointer select-none">
                    <input
                      type="checkbox"
                      checked={inactivityFilterEnabled}
                      onChange={() => setInactivityFilterEnabled(!inactivityFilterEnabled)}
                      className="w-4 h-4 text-primary-600 border-gray-300 rounded focus:ring-primary-500"
                    />
                    <span className="text-sm text-gray-700">{t('participants.filters.inactiveForDays')}</span>
                    <input
                      type="number"
                      min="1"
                      value={inactivityDays}
                      onChange={(e) => setInactivityDays(Math.max(1, parseInt(e.target.value, 10) || 1))}
                      className="w-16 px-2 py-1 border border-gray-300 rounded-md text-sm text-center"
                    />
                    <span className="text-sm text-gray-700">{t('participants.filters.days')}</span>
                  </label>
                </div>
              </div>
            </div>
          </div>

                                {/* Participants List */}
           <div className="relative">
             <div className="divide-y divide-gray-200">
               {/* Subtle loading overlay - only covers the list content */}
               {(isFetching || (loading && stableParticipants.length > 0)) && (
                 <div className="absolute inset-0 bg-white bg-opacity-50 z-10 flex items-center justify-center">
                   <div className="flex items-center space-x-2 text-gray-600">
                     <div className="w-4 h-4 border-2 border-gray-300 border-t-primary-500 rounded-full animate-spin"></div>
                     <span className="text-sm">{t('common.updating')}</span>
                   </div>
                 </div>
               )}
               
               {filteredParticipants.length === 0 ? (
                <div className="px-6 py-12 text-center">
                  <Users size={48} className="mx-auto text-gray-400 mb-4" />
                  <p className="text-gray-500">
                    {searchTerm || !allStatusesSelected || inactivityFilterEnabled
                      ? t('errors.noParticipantsMatchingCriteria')
                      : t('common.noParticipantsFound')
                    }
                  </p>
                </div>
              ) : (
                filteredParticipants.map((participant) => (
                <div
                  key={participant.id}
                  onClick={(e) => handleParticipantClick(participant.id, e)}
                  className="px-6 py-4 hover:bg-gray-50 cursor-pointer transition-colors"
                  title={`${participant.prenom || ''} ${participant.nom || ''} (Ctrl+Click or middle-click to open in new tab)`}
                >
                  <div className="flex items-center justify-between">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between mb-2">
                        <div className="flex items-center">
                          <div className="flex-shrink-0">
                            <div className="w-10 h-10 bg-primary-100 rounded-full flex items-center justify-center">
                              <User size={16} className="text-primary-600" />
                            </div>
                          </div>
                          <div className="ml-3">
                            <h3 className="text-sm font-medium text-gray-900">
                              {participant.prenom || ''} {participant.nom || ''}
                              {participant.id_participant && (
                                <button
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    window.open(`https://pro.dendreo.com/competences_et_metiers/participants.php?id_participant=${participant.id_participant}`, '_blank', 'noopener,noreferrer');
                                  }}
                                  className="ml-2 inline-flex items-center px-2 py-1 text-xs font-medium text-gray-700 bg-gray-100 border border-gray-300 rounded-md hover:bg-gray-200 hover:text-gray-900 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-colors"
                                  title={t('common.openDendreoProfile')}
                                >
                                  <ExternalLink size={12} className="mr-1" />
                                  Dendreo
                                </button>
                              )}
                            </h3>
                            <div className="flex items-center text-sm text-gray-600">
                              <Mail size={12} className="mr-1" />
                              {participant.email}
                            </div>
                          </div>
                        </div>
                        <div className="flex items-center space-x-2">
                          {getProgressBadge(participant)}
                          <ChevronRight size={16} className="text-gray-400" />
                        </div>
                      </div>
                      
                      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-3">
                        <div className="flex items-center text-sm text-gray-600">
                          <BookOpen size={14} className="mr-1" />
                          {participant.total_courses || 0} {t('common.totalCourses')}
                        </div>
                        <div className="flex items-center text-sm text-gray-600">
                          <Target size={14} className="mr-1" />
                          {participant.completed_courses || 0} {t('common.completed')}
                        </div>
                        <div className="flex items-center text-sm text-gray-600">
                          <Users size={14} className="mr-1" />
                          {participant.active_courses || 0} {t('common.active')}
                        </div>
                      </div>
                      
                      {/* Progress Bar */}
                      <ProgressBar 
                        percentage={participant.overall_progression || 0} 
                        size="small"
                        className="max-w-md"
                      />
                    </div>
                  </div>
                </div>
              ))
            )}
            </div>
          </div>

          {/* Pagination */}
          <Pagination
            currentPage={currentPage}
            totalPages={Math.ceil((countData?.total || 0) / pageSize)}
            totalItems={countData?.total || 0}
            pageSize={pageSize}
            onPageChange={handlePageChange}
            onPageSizeChange={handlePageSizeChange}
          />
        </div>
      </div>
    </div>
  );
};

export default Participants; 
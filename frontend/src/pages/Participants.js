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
  Search,
  ExternalLink,
  ArrowUp,
  ArrowDown,
  Loader
} from 'lucide-react';
import { apiService } from '../services/api';

// Per-row HubSpot button with own loading/error/cache state
const HubspotButton = ({ email, title }) => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const urlCache = useRef(null);

  const handleClick = async (e) => {
    e.stopPropagation();
    if (!email) return;
    if (urlCache.current) {
      window.open(urlCache.current, '_blank', 'noopener,noreferrer');
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const data = await apiService.getHubspotContact(email);
      if (data?.url) {
        urlCache.current = data.url;
        window.open(data.url, '_blank', 'noopener,noreferrer');
      }
    } catch (err) {
      setError(err.response?.status === 404 ? 'Not found' : 'Error');
      setTimeout(() => setError(null), 3000);
    } finally {
      setLoading(false);
    }
  };

  return (
    <button
      onClick={handleClick}
      disabled={loading}
      className="ml-2 inline-flex items-center px-2 py-1 text-xs font-medium text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-slate-700 border border-gray-300 dark:border-slate-600 rounded-md hover:bg-gray-200 dark:hover:bg-slate-600 hover:text-gray-900 dark:hover:text-white focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-colors disabled:opacity-50"
      title={error || title}
    >
      {loading ? <Loader size={12} className="mr-1 animate-spin" /> : <ExternalLink size={12} className="mr-1" />}
      HubSpot
    </button>
  );
};

const Participants = () => {
  const { t } = useTranslation();
  const [searchTerm, setSearchTerm] = useState('');
  const [debouncedSearchTerm, setDebouncedSearchTerm] = useState('');
  const [sortBy, setSortBy] = useState('progression');
  const [sortDirection, setSortDirection] = useState(() => {
    const cached = localStorage.getItem('participantSortDirection');
    return cached || 'desc';
  });
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(25);
  const searchInputRef = useRef(null);
  const navigate = useNavigate();

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
  // refetch kept for error retry button
  
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

  // Reset to first page when search/sort changes
  useEffect(() => {
    setCurrentPage(1);
  }, [debouncedSearchTerm, sortBy, sortDirection]);

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

  const getFilteredAndSortedParticipants = () => {
    const sortMultiplier = sortDirection === 'asc' ? 1 : -1;

    return [...displayParticipants].sort((a, b) => {
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
        default:
          comparison = 0;
      }
      return comparison * sortMultiplier;
    });
  };

  // Only show full loading screen if we have no data at all and are loading for the first time
  // If we have stable data, we can show the page with a loading overlay instead
  if ((loading || countLoading) && stableParticipants.length === 0 && participants.length === 0) {
    return (
      <LoadingSpinner size="large" />
    );
  }

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="text-red-500 text-xl mb-4">⚠️ {t('common.error')}</div>
          <p className="text-gray-600 dark:text-gray-400 mb-4">{error.message || t('errors.failedToLoadParticipants')}</p>
          <button 
            onClick={refetch}
            className="bg-primary-500 text-white px-4 py-2 rounded-lg hover:bg-primary-600 mr-2"
          >
            {t('common.retry')}
          </button>
          <button 
            onClick={() => navigate('/')}
            className="bg-gray-500 dark:bg-slate-600 text-white px-4 py-2 rounded-lg hover:bg-gray-600 dark:hover:bg-slate-500"
          >
            {t('navigation.backToDashboard')}
          </button>
        </div>
      </div>
    );
  }

  const filteredParticipants = getFilteredAndSortedParticipants();

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-slate-900">
      {/* Header */}
      <div className="bg-white dark:bg-slate-800 border-b border-gray-200 dark:border-slate-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-gray-900 dark:text-white">{t('participants.title')}</h1>
              <p className="text-gray-600 dark:text-gray-400 mt-1">{t('participants.subtitle')}</p>
            </div>
            
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Participants Section */}
        <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700">
          {/* Participants Header */}
          <div className="px-6 py-4 border-b border-gray-200 dark:border-slate-700">
            <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between">
              <div>
                <h2 className="text-lg font-semibold text-gray-900 dark:text-white">{t('participants.allParticipants')}</h2>
                                  <p className="text-sm text-gray-600 dark:text-gray-400">
                    {t('participants.subtitleWithCount', { filtered: filteredParticipants.length, total: countData?.total || 0 })}
                  </p>
              </div>
              
              {/* Search, Sort, and Per Page */}
              <div className="flex flex-col sm:flex-row items-start sm:items-center space-y-2 sm:space-y-0 sm:space-x-4 mt-4 lg:mt-0">
                {/* Search */}
                <div className="relative">
                  <Search size={16} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 dark:text-gray-500" />
                  <input
                    ref={searchInputRef}
                    type="text"
                    placeholder={t('participants.searchPlaceholder')}
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    onKeyDown={handleSearchSubmit}
                    onFocus={() => sessionStorage.setItem('searchInputFocused', 'true')}
                    onBlur={() => sessionStorage.removeItem('searchInputFocused')}
                    className="pl-10 pr-4 py-2 border border-gray-300 dark:border-slate-600 rounded-md text-sm w-64 dark:bg-slate-700 dark:text-white"
                  />
                </div>

                {/* Sort */}
                <div className="flex items-center space-x-2">
                  <select
                    value={sortBy}
                    onChange={(e) => setSortBy(e.target.value)}
                    className="border border-gray-300 dark:border-slate-600 rounded-md px-3 py-2 text-sm dark:bg-slate-700 dark:text-white"
                  >
                    <option value="name">{t('participants.sort.byName')}</option>
                    <option value="progression">{t('participants.sort.byProgress')}</option>
                  </select>
                  <button
                    onClick={toggleSortDirection}
                    className="p-2 border border-gray-300 dark:border-slate-600 rounded-md hover:bg-gray-50 dark:hover:bg-slate-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
                    title={sortDirection === 'asc' ? t('participants.sort.ascending') : t('participants.sort.descending')}
                  >
                    {sortDirection === 'asc' ? (
                      <ArrowUp size={16} className="text-gray-600 dark:text-gray-400" />
                    ) : (
                      <ArrowDown size={16} className="text-gray-600 dark:text-gray-400" />
                    )}
                  </button>
                </div>

                {/* Per Page */}
                <div className="flex items-center space-x-2">
                  <select
                    value={pageSize}
                    onChange={(e) => handlePageSizeChange(parseInt(e.target.value))}
                    className="border border-gray-300 dark:border-slate-600 rounded-md px-3 py-2 text-sm dark:bg-slate-700 dark:text-white"
                  >
                    {[25, 50, 100].map(size => (
                      <option key={size} value={size}>{size}</option>
                    ))}
                  </select>
                  <span className="text-sm text-gray-600 dark:text-gray-400">{t('pagination.perPage')}</span>
                </div>
              </div>
            </div>
          </div>

                                {/* Participants List */}
           <div className="relative">
             <div className="divide-y divide-gray-200 dark:divide-slate-700">
               {/* Subtle loading overlay - only covers the list content */}
               {(isFetching || (loading && stableParticipants.length > 0)) && (
                 <div className="absolute inset-0 bg-white dark:bg-slate-800 bg-opacity-50 dark:bg-opacity-50 z-10 flex items-center justify-center">
                   <div className="flex items-center space-x-2 text-gray-600 dark:text-gray-400">
                     <div className="w-4 h-4 border-2 border-gray-300 dark:border-slate-600 border-t-primary-500 rounded-full animate-spin"></div>
                     <span className="text-sm">{t('common.updating')}</span>
                   </div>
                 </div>
               )}
               
               {filteredParticipants.length === 0 ? (
                <div className="px-6 py-12 text-center">
                  <Users size={48} className="mx-auto text-gray-400 dark:text-gray-500 mb-4" />
                  <p className="text-gray-500 dark:text-gray-400">
                    {searchTerm
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
                  className="px-6 py-4 hover:bg-gray-50 dark:hover:bg-slate-700 cursor-pointer transition-colors"
                  title={`${participant.prenom || ''} ${participant.nom || ''} (Ctrl+Click or middle-click to open in new tab)`}
                >
                  <div className="flex items-center justify-between">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between mb-2">
                        <div className="flex items-center">
                          <div className="flex-shrink-0">
                            <div className="w-10 h-10 bg-primary-100 dark:bg-primary-900/30 rounded-full flex items-center justify-center">
                              <User size={16} className="text-primary-600" />
                            </div>
                          </div>
                          <div className="ml-3">
                            <h3 className="text-sm font-medium text-gray-900 dark:text-white">
                              {participant.prenom || ''} {participant.nom || ''}
                              {participant.id_participant && (
                                <button
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    window.open(`https://pro.dendreo.com/competences_et_metiers/participants.php?id_participant=${participant.id_participant}`, '_blank', 'noopener,noreferrer');
                                  }}
                                  className="ml-2 inline-flex items-center px-2 py-1 text-xs font-medium text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-slate-700 border border-gray-300 dark:border-slate-600 rounded-md hover:bg-gray-200 dark:hover:bg-slate-600 hover:text-gray-900 dark:hover:text-white focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-colors"
                                  title={t('common.openDendreoProfile')}
                                >
                                  <ExternalLink size={12} className="mr-1" />
                                  Dendreo
                                </button>
                              )}
                              {participant.email && (
                                <HubspotButton email={participant.email} title={t('common.openHubspotProfile')} />
                              )}
                            </h3>
                            <div className="flex items-center text-sm text-gray-600 dark:text-gray-400">
                              <Mail size={12} className="mr-1" />
                              {participant.email}
                            </div>
                          </div>
                        </div>
                        <ChevronRight size={16} className="text-gray-400 dark:text-gray-500" />
                      </div>
                      
                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-3">
                        <div className="flex items-center text-sm text-gray-600 dark:text-gray-400">
                          <BookOpen size={14} className="mr-1" />
                          {participant.total_courses || 0} {t('common.totalCourses')}
                        </div>
                        <div className="flex items-center text-sm text-gray-600 dark:text-gray-400">
                          <Target size={14} className="mr-1" />
                          {participant.completed_courses || 0} {t('common.completed')}
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
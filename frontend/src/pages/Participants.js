import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import LoadingSpinner from '../components/LoadingSpinner';
import ProgressBar from '../components/ProgressBar';
import { useParticipants, usePrefetchQueries } from '../hooks/useQuery';
import { 
  Users, 
  User,
  BookOpen, 
  Target, 
  Mail,
  ChevronRight,
  Filter,
  Search,
  ArrowLeft,
  RefreshCw
} from 'lucide-react';

const Participants = () => {
  const { t } = useTranslation();
  const [searchTerm, setSearchTerm] = useState('');
  const [sortBy, setSortBy] = useState('progression');
  const [filterBy, setFilterBy] = useState('all');
  const navigate = useNavigate();
  
  // Use React Query hook for data fetching with caching
  const { 
    data: participants = [], 
    isLoading: loading, 
    error,
    refetch,
    isFetching
  } = useParticipants();
  
  const { prefetchParticipantDetails } = usePrefetchQueries();

  const handleParticipantClick = (participantId) => {
    // Prefetch participant details for faster loading
    prefetchParticipantDetails(participantId);
    navigate(`/participants/${participantId}`);
  };

  const getFilteredAndSortedParticipants = () => {
    let filtered = participants;
    
    // Filter by search term
    if (searchTerm) {
      const search = searchTerm.toLowerCase();
      filtered = filtered.filter(participant => 
        participant.prenom?.toLowerCase().includes(search) ||
        participant.nom?.toLowerCase().includes(search) ||
        participant.email?.toLowerCase().includes(search) ||
        `${participant.prenom} ${participant.nom}`.toLowerCase().includes(search)
      );
    }
    
    // Filter by status
    if (filterBy === 'active') {
      filtered = filtered.filter(p => p.active_courses > 0);
    } else if (filterBy === 'completed') {
      filtered = filtered.filter(p => p.completed_courses > 0);
    } else if (filterBy === 'inactive') {
      filtered = filtered.filter(p => p.active_courses === 0 && p.completed_courses === 0);
    }
    
    // Sort participants
    return filtered.sort((a, b) => {
      switch (sortBy) {
        case 'name':
          const nameA = `${a.prenom || ''} ${a.nom || ''}`.trim();
          const nameB = `${b.prenom || ''} ${b.nom || ''}`.trim();
          return nameA.localeCompare(nameB);
        case 'progression':
          return (b.overall_progression || 0) - (a.overall_progression || 0);
        case 'courses':
          return (b.total_courses || 0) - (a.total_courses || 0);
        case 'email':
          return (a.email || '').localeCompare(b.email || '');
        default:
          return 0;
      }
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

  if (loading) {
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
            <div className="flex items-center">
              <button
                onClick={() => navigate('/')}
                className="mr-4 p-2 text-gray-400 hover:text-gray-600"
              >
                <ArrowLeft size={20} />
              </button>
              <div>
                <h1 className="text-2xl font-bold text-gray-900">{t('participants.title')}</h1>
                <p className="text-gray-600 mt-1">{t('participants.subtitle')}</p>
              </div>
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
              <button
                onClick={() => navigate('/')}
                className="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
              >
                <BookOpen size={16} className="mr-2" />
                {t('navigation.viewCourses')}
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
                  {t('participants.subtitleWithCount', { filtered: filteredParticipants.length, total: participants.length })}
                </p>
              </div>
              
              {/* Search and Filters */}
              <div className="flex flex-col sm:flex-row items-start sm:items-center space-y-2 sm:space-y-0 sm:space-x-4 mt-4 lg:mt-0">
                {/* Search */}
                <div className="relative">
                  <Search size={16} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
                  <input
                    type="text"
                    placeholder={t('participants.searchPlaceholder')}
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="pl-10 pr-4 py-2 border border-gray-300 rounded-md text-sm w-64"
                  />
                </div>
                
                {/* Filter */}
                <div className="flex items-center space-x-2">
                  <Filter size={16} className="text-gray-500" />
                  <select
                    value={filterBy}
                    onChange={(e) => setFilterBy(e.target.value)}
                    className="border border-gray-300 rounded-md px-3 py-2 text-sm"
                  >
                    <option value="all">{t('participants.filters.allStatus')}</option>
                    <option value="active">{t('participants.filters.active')}</option>
                    <option value="completed">{t('participants.filters.completed')}</option>
                    <option value="inactive">{t('participants.filters.inactive')}</option>
                  </select>
                </div>
                
                {/* Sort */}
                <select
                  value={sortBy}
                  onChange={(e) => setSortBy(e.target.value)}
                  className="border border-gray-300 rounded-md px-3 py-2 text-sm"
                >
                  <option value="name">{t('participants.sort.byName')}</option>
                  <option value="progression">{t('participants.sort.byProgress')}</option>
                  <option value="courses">{t('participants.sort.byCourses')}</option>
                  <option value="email">{t('participants.sort.byEmail')}</option>
                </select>
              </div>
            </div>
          </div>

          {/* Participants List */}
          <div className="divide-y divide-gray-200">
            {filteredParticipants.length === 0 ? (
              <div className="px-6 py-12 text-center">
                <Users size={48} className="mx-auto text-gray-400 mb-4" />
                <p className="text-gray-500">
                  {searchTerm || filterBy !== 'all' 
                    ? t('errors.noParticipantsMatchingCriteria')
                    : t('common.noParticipantsFound')
                  }
                </p>
              </div>
            ) : (
              filteredParticipants.map((participant) => (
                <div
                  key={participant.id}
                  onClick={() => handleParticipantClick(participant.id)}
                  className="px-6 py-4 hover:bg-gray-50 cursor-pointer transition-colors"
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
      </div>
    </div>
  );
};

export default Participants; 
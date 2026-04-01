import React, { useState, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import LoadingSpinner from '../components/LoadingSpinner';
import ProgressBar from '../components/ProgressBar';
import { formatTimeSpentInHours, formatTimeSpent } from '../utils/timeUtils';

import { useCourseParticipants } from '../hooks/useQuery';
import { apiService } from '../services/api';
import {
  ArrowLeft,
  Users,
  BookOpen,
  Target,
  Calendar,
  Mail,
  User,
  CheckCircle,
  Clock,
  Filter,
  Search,
  ChevronDown,
  ChevronRight,
  PlayCircle,
  ExternalLink,
  Loader
} from 'lucide-react';

const CourseDetail = () => {
  const { t } = useTranslation();
  const { courseId } = useParams();
  const navigate = useNavigate();
  const [searchTerm, setSearchTerm] = useState('');
  const [sortBy, setSortBy] = useState('progression');
  const [filterBy, setFilterBy] = useState('all');
  const [expandedParticipants, setExpandedParticipants] = useState(new Set());
  const [hubspotLoading, setHubspotLoading] = useState(null); // email of currently loading participant
  const [hubspotError, setHubspotError] = useState(null);
  const hubspotUrlCache = useRef({});

  // Use React Query hook for data fetching with caching
  const { 
    data: courseData, 
    isLoading: loading, 
    error,
    refetch
  } = useCourseParticipants(courseId);

  const getFilteredAndSortedParticipants = () => {
    if (!courseData?.participants) return [];
    
    let filtered = courseData.participants;
    
    // Filter by search term
    if (searchTerm) {
      const search = searchTerm.toLowerCase();
      filtered = filtered.filter(participant => 
        participant.nom.toLowerCase().includes(search) ||
        participant.prenom.toLowerCase().includes(search) ||
        participant.email.toLowerCase().includes(search) ||
        (participant.hubspot_data?.c_id_transaction_hubspot && 
         participant.hubspot_data.c_id_transaction_hubspot.toLowerCase().includes(search))
      );
    }
    
    // Filter by status
    if (filterBy === 'completed') {
      filtered = filtered.filter(p => p.overall_progression >= 100);
    } else if (filterBy === 'in-progress') {
      filtered = filtered.filter(p => p.overall_progression > 0 && p.overall_progression < 100);
    } else if (filterBy === 'not-started') {
      filtered = filtered.filter(p => p.overall_progression === 0);
    } else if (filterBy === 'with-hubspot') {
      filtered = filtered.filter(p => p.hubspot_data?.c_id_transaction_hubspot);
    } else if (filterBy === 'without-hubspot') {
      filtered = filtered.filter(p => !p.hubspot_data?.c_id_transaction_hubspot);
    }
    
    // Sort participants
    return filtered.sort((a, b) => {
      switch (sortBy) {
        case 'progression':
          return b.overall_progression - a.overall_progression;
        case 'name':
          return `${a.nom} ${a.prenom}`.localeCompare(`${b.nom} ${b.prenom}`);
        case 'modules':
          return b.completed_modules - a.completed_modules;
        case 'activity':
          if (!a.last_activity && !b.last_activity) return 0;
          if (!a.last_activity) return 1;
          if (!b.last_activity) return -1;
          return new Date(b.last_activity) - new Date(a.last_activity);
        case 'hubspot':
          const aHasHubspot = a.hubspot_data?.c_id_transaction_hubspot ? 1 : 0;
          const bHasHubspot = b.hubspot_data?.c_id_transaction_hubspot ? 1 : 0;
          return bHasHubspot - aHasHubspot;
        case 'time':
          return (b.total_time_spent || 0) - (a.total_time_spent || 0);
        default:
          return 0;
      }
    });
  };

  const formatDate = (dateString) => {
    if (!dateString) return t('common.never');
    return new Date(dateString).toLocaleDateString();
  };

  const toggleParticipantExpanded = (participantId) => {
    const newExpanded = new Set(expandedParticipants);
    if (newExpanded.has(participantId)) {
      newExpanded.delete(participantId);
    } else {
      newExpanded.add(participantId);
    }
    setExpandedParticipants(newExpanded);
  };

  const handleHubspotClick = async (email) => {
    if (!email) return;
    // Use cached URL if available
    if (hubspotUrlCache.current[email]) {
      window.open(hubspotUrlCache.current[email], '_blank', 'noopener,noreferrer');
      return;
    }
    setHubspotLoading(email);
    setHubspotError(null);
    try {
      const data = await apiService.getHubspotContact(email);
      if (data?.url) {
        hubspotUrlCache.current[email] = data.url;
        window.open(data.url, '_blank', 'noopener,noreferrer');
      }
    } catch (err) {
      const errorKey = err.response?.status === 404 ? 'hubspotNotFound' : 'hubspotError';
      setHubspotError({ email, key: errorKey });
      setTimeout(() => setHubspotError(null), 3000);
    } finally {
      setHubspotLoading(null);
    }
  };

  const getHubSpotDealUrl = (transactionId) => {
    if (!transactionId) return null;
    // Based on the provided URL pattern: https://app-eu1.hubspot.com/contacts/25868618/record/0-3/{deal_id}
    return `https://app-eu1.hubspot.com/contacts/25868618/record/0-3/${transactionId}`;
  };

  const openHubSpotDeal = (transactionId, participantName) => {
    const url = getHubSpotDealUrl(transactionId);
    if (url) {
      window.open(url, '_blank', 'noopener,noreferrer');
    }
  };

  const getProgressBadge = (progression) => {
    if (progression >= 100) {
      return <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-400">
        <CheckCircle size={12} className="mr-1" />
        {t('common.completed')}
      </span>;
    } else if (progression > 0) {
      return <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-400">
        <Clock size={12} className="mr-1" />
        {t('common.inProgress')}
      </span>;
    } else {
      return <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 dark:bg-slate-700 text-gray-800 dark:text-gray-300">
        <Clock size={12} className="mr-1" />
        {t('common.notStarted')}
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
          <p className="text-gray-600 dark:text-gray-400 mb-4">{error.message || t('errors.failedToLoadCourseData')}</p>
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
    <div className="min-h-screen bg-gray-50 dark:bg-slate-900">
      {/* Header */}
      <div className="bg-white dark:bg-slate-800 border-b border-gray-200 dark:border-slate-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center">
              <button
                onClick={(e) => {
                  // Check if Ctrl/Cmd key is pressed or middle mouse button for new tab
                  if (e.ctrlKey || e.metaKey || e.button === 1) {
                    // Open in new tab
                    window.open('/', '_blank', 'noopener,noreferrer');
                  } else {
                    navigate('/');
                  }
                }}
                className="mr-4 p-2 text-gray-400 dark:text-gray-500 hover:text-gray-600 dark:hover:text-gray-300"
                title="Back to Dashboard (Ctrl+Click or middle-click to open in new tab)"
              >
                <ArrowLeft size={20} />
              </button>
              <div>
                <div className="flex items-center">
                  <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                    {courseData?.course?.intitule}
                  </h1>
                  {courseData?.course?.id_action_formation && (
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        window.open(`https://pro.dendreo.com/competences_et_metiers/formations/${courseData.course.id_action_formation}/participants`, '_blank', 'noopener,noreferrer');
                      }}
                      className="ml-3 inline-flex items-center px-3 py-1.5 text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-slate-700 border border-gray-300 dark:border-slate-600 rounded-md hover:bg-gray-200 dark:hover:bg-slate-600 hover:text-gray-900 dark:hover:text-white focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-colors"
                      title={t('common.openDendreoADF')}
                    >
                      <ExternalLink size={14} className="mr-1.5" />
                      Dendreo ADF
                    </button>
                  )}
                </div>
                <p className="text-gray-600 dark:text-gray-400 mt-1">{t('courseDetail.subtitle')}</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Course Summary */}
        {courseData?.summary && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-6 mb-8">
            <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700 p-6">
              <div className="flex items-center">
                <div className="p-3 rounded-full bg-blue-50 dark:bg-blue-900/20 text-blue-600 border border-blue-200 dark:border-blue-800">
                  <Users size={24} />
                </div>
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-600 dark:text-gray-400">{t('courseDetail.summary.totalParticipants')}</p>
                  <p className="text-2xl font-bold text-gray-900 dark:text-white">{courseData.summary.total_participants}</p>
                </div>
              </div>
            </div>
            
            <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700 p-6">
              <div className="flex items-center">
                <div className="p-3 rounded-full bg-green-50 dark:bg-green-900/20 text-green-600 border border-green-200 dark:border-green-800">
                  <CheckCircle size={24} />
                </div>
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-600 dark:text-gray-400">{t('courseDetail.summary.completed')}</p>
                  <p className="text-2xl font-bold text-gray-900 dark:text-white">{courseData.summary.completed_participants}</p>
                </div>
              </div>
            </div>
            
            <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700 p-6">
              <div className="flex items-center">
                <div className="p-3 rounded-full bg-purple-50 dark:bg-purple-900/20 text-purple-600 border border-purple-200 dark:border-purple-800">
                  <Target size={24} />
                </div>
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-600 dark:text-gray-400">{t('courseDetail.summary.averageProgress')}</p>
                  <p className="text-2xl font-bold text-gray-900 dark:text-white">
                    {courseData.summary.average_progression.toFixed(1)}%
                  </p>
                </div>
              </div>
            </div>

            <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700 p-6">
              <div className="flex items-center">
                <div className="p-3 rounded-full bg-orange-50 dark:bg-orange-900/20 text-orange-600 border border-orange-200 dark:border-orange-800">
                  <ExternalLink size={24} />
                </div>
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-600 dark:text-gray-400">{t('courseDetail.summary.hubSpotLinked')}</p>
                  <p className="text-2xl font-bold text-gray-900 dark:text-white">
                    {courseData.participants?.filter(p => p.hubspot_data?.c_id_transaction_hubspot).length || 0}
                  </p>
                </div>
              </div>
            </div>

            {/* Planned Duration vs Actual Time */}
            <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700 p-6">
              <div className="flex items-center">
                <div className="p-3 rounded-full bg-indigo-50 dark:bg-indigo-900/20 text-indigo-600 border border-indigo-200 dark:border-indigo-800">
                  <Clock size={24} />
                </div>
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-600 dark:text-gray-400">{t('courseDetail.summary.plannedDuration')}</p>
                  <p className="text-2xl font-bold text-gray-900 dark:text-white">
                    {courseData.course?.planned_duration_hours !== null && courseData.course?.planned_duration_hours !== undefined
                      ? formatTimeSpentInHours(courseData.course.planned_duration_hours * 3600)
                      : '0h'
                    }
                  </p>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Participants Section */}
        <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700">
          {/* Participants Content */}
            <>
              {/* Participants Header */}
              <div className="px-6 py-4 border-b border-gray-200 dark:border-slate-700">
                <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between">
                  <div>
                    <h2 className="text-lg font-semibold text-gray-900 dark:text-white">{t('courseDetail.participants.title')}</h2>
                    <p className="text-sm text-gray-600 dark:text-gray-400">
                      {t('courseDetail.participants.subtitle', { filtered: filteredParticipants.length, total: courseData?.participants?.length || 0 })}
                    </p>
                  </div>
                  
                  {/* Search and Filters */}
                  <div className="flex flex-col sm:flex-row items-start sm:items-center space-y-2 sm:space-y-0 sm:space-x-4 mt-4 lg:mt-0">
                    {/* Search */}
                    <div className="relative">
                      <Search size={16} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 dark:text-gray-500" />
                      <input
                        type="text"
                        placeholder={t('courseDetail.participants.searchPlaceholder')}
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        className="pl-10 pr-4 py-2 border border-gray-300 dark:border-slate-600 rounded-md text-sm w-64 dark:bg-slate-700 dark:text-white"
                      />
                    </div>
                    
                    {/* Filter */}
                    <div className="flex items-center space-x-2">
                      <Filter size={16} className="text-gray-500 dark:text-gray-400" />
                      <select
                        value={filterBy}
                        onChange={(e) => setFilterBy(e.target.value)}
                        className="border border-gray-300 dark:border-slate-600 rounded-md px-3 py-2 text-sm dark:bg-slate-700 dark:text-white"
                      >
                        <option value="all">{t('courseDetail.participants.filters.allStatus')}</option>
                        <option value="completed">{t('courseDetail.participants.filters.completed')}</option>
                        <option value="in-progress">{t('courseDetail.participants.filters.inProgress')}</option>
                        <option value="not-started">{t('courseDetail.participants.filters.notStarted')}</option>
                        <option value="with-hubspot">{t('courseDetail.participants.filters.withHubSpot')}</option>
                        <option value="without-hubspot">{t('courseDetail.participants.filters.withoutHubSpot')}</option>
                      </select>
                    </div>
                    
                    {/* Sort */}
                    <select
                      value={sortBy}
                      onChange={(e) => setSortBy(e.target.value)}
                      className="border border-gray-300 dark:border-slate-600 rounded-md px-3 py-2 text-sm dark:bg-slate-700 dark:text-white"
                    >
                      <option value="progression">{t('courseDetail.participants.sort.byProgress')}</option>
                      <option value="name">{t('courseDetail.participants.sort.byName')}</option>
                      <option value="modules">{t('courseDetail.participants.sort.byModules')}</option>
                      <option value="time">Time Spent</option>
                      <option value="activity">{t('courseDetail.participants.sort.byActivity')}</option>
                      <option value="hubspot">{t('courseDetail.participants.sort.byHubSpot')}</option>
                    </select>
                  </div>
                </div>
              </div>

              {/* Participants List */}
              <div className="divide-y divide-gray-200 dark:divide-slate-700">
                {filteredParticipants.length === 0 ? (
                  <div className="px-6 py-12 text-center">
                    <Users size={48} className="mx-auto text-gray-400 dark:text-gray-500 mb-4" />
                    <p className="text-gray-500 dark:text-gray-400">
                      {searchTerm || filterBy !== 'all' 
                        ? t('errors.noParticipantsMatchingCriteria')
                        : t('common.noParticipantsInCourse')
                      }
                    </p>
                  </div>
                ) : (
                  filteredParticipants.map((participant) => (
                    <div key={participant.id} className="px-6 py-4 hover:bg-gray-50 dark:hover:bg-slate-700">
                      <div className="flex items-center justify-between">
                        <div className="flex-1 min-w-0">
                          {/* Participant Info */}
                          <div className="flex items-center justify-between mb-2">
                            <div className="flex items-center">
                              <div className="flex-shrink-0">
                                <div className="w-10 h-10 bg-primary-100 dark:bg-primary-900/30 rounded-full flex items-center justify-center">
                                  <User size={16} className="text-primary-600" />
                                </div>
                              </div>
                              <div className="ml-3">
                                <h3 className="text-sm font-medium text-gray-900 dark:text-white">
                                  <span
                                    className="cursor-pointer hover:text-primary-600"
                                    onClick={() => navigate(`/participants/${participant.id}`)}
                                  >
                                    {participant.prenom} {participant.nom}
                                  </span>
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
                                    <button
                                      onClick={(e) => {
                                        e.stopPropagation();
                                        handleHubspotClick(participant.email);
                                      }}
                                      disabled={hubspotLoading === participant.email}
                                      className="ml-2 inline-flex items-center px-2 py-1 text-xs font-medium text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-slate-700 border border-gray-300 dark:border-slate-600 rounded-md hover:bg-gray-200 dark:hover:bg-slate-600 hover:text-gray-900 dark:hover:text-white focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-colors disabled:opacity-50"
                                      title={t('common.openHubspotProfile')}
                                    >
                                      {hubspotLoading === participant.email ? <Loader size={12} className="mr-1 animate-spin" /> : <ExternalLink size={12} className="mr-1" />}
                                      HubSpot
                                    </button>
                                  )}
                                </h3>
                                {hubspotError?.email === participant.email && (
                                  <p className="text-xs text-red-500 mt-0.5">{t(`common.${hubspotError.key}`)}</p>
                                )}
                                <div className="flex items-center text-sm text-gray-600 dark:text-gray-400">
                                  <Mail size={12} className="mr-1" />
                                  {participant.email}
                                </div>
                                {/* HubSpot Transaction Info */}
                                {participant.hubspot_data && participant.hubspot_data.c_id_transaction_hubspot && (
                                  <div className="flex items-center text-sm text-blue-600 mt-1">
                                    <ExternalLink size={12} className="mr-1" />
                                    <button
                                      onClick={(e) => {
                                        e.stopPropagation();
                                        openHubSpotDeal(
                                          participant.hubspot_data.c_id_transaction_hubspot,
                                          `${participant.prenom} ${participant.nom}`
                                        );
                                      }}
                                      className="hover:underline focus:outline-none focus:underline"
                                      title={t('common.openHubSpotDeal')}
                                    >
                                      {t('common.hubSpot')}: {participant.hubspot_data.c_id_transaction_hubspot}
                                    </button>
                                  </div>
                                )}
                                {/* Show if no HubSpot data */}
                                {(!participant.hubspot_data || !participant.hubspot_data.c_id_transaction_hubspot) && (
                                  <div className="flex items-center text-sm text-gray-400 dark:text-gray-500 mt-1">
                                    <span>{t('common.noHubSpotDealLinked')}</span>
                                  </div>
                                )}
                              </div>
                            </div>
                            <div className="flex items-center space-x-2">
                              {getProgressBadge(participant.overall_progression)}
                              {participant.modules && participant.modules.length > 0 && (
                                <button
                                  onClick={() => toggleParticipantExpanded(participant.id)}
                                  className="p-1 text-gray-400 dark:text-gray-500 hover:text-gray-600 dark:hover:text-gray-300 transition-colors"
                                  title={t('common.viewModuleDetails')}
                                >
                                  {expandedParticipants.has(participant.id) ? (
                                    <ChevronDown size={16} />
                                  ) : (
                                    <ChevronRight size={16} />
                                  )}
                                </button>
                              )}
                            </div>
                          </div>
                          
                          {/* Stats Row */}
                          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-3">
                            <div className="flex items-center text-sm text-gray-600 dark:text-gray-400">
                              <BookOpen size={14} className="mr-1" />
                              {participant.completed_modules}/{participant.total_modules} {t('common.modulesCompleted')}
                            </div>
                            <div className="flex items-center text-sm text-gray-600 dark:text-gray-400">
                              <Target size={14} className="mr-1" />
                              {participant.overall_progression.toFixed(1)}% {t('common.progress')}
                            </div>
                            <div className="flex items-center text-sm text-gray-600 dark:text-gray-400">
                              <Clock size={14} className="mr-1" />
                              <span className="font-medium text-blue-600">
                                {formatTimeSpentInHours(participant.total_time_spent || 0)}
                              </span>
                              <span className="text-xs text-gray-400 dark:text-gray-500 ml-1">
                                ({formatTimeSpent(participant.total_time_spent || 0)})
                              </span>
                            </div>
                            <div
                              className="group/source flex items-center text-sm text-gray-600 dark:text-gray-400"
                              title={participant.last_activity_source ? `${t('inactiveManagement.lastActivitySource')}: ${t(`inactiveManagement.activitySource.${participant.last_activity_source}`)}` : ''}
                            >
                              <Calendar size={14} className="mr-1" />
                              {t('common.lastActivity')}: {formatDate(participant.last_activity)}
                              {participant.last_activity_source && (
                                <span className={`opacity-0 group-hover/source:opacity-100 transition-opacity ml-1.5 inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-medium ${
                                  participant.last_activity_source === 'elearning'
                                    ? 'bg-blue-50 dark:bg-blue-900/20 text-blue-600'
                                    : 'bg-violet-50 dark:bg-violet-900/20 text-violet-600'
                                }`}>
                                  {t(`inactiveManagement.activitySource.${participant.last_activity_source}`)}
                                </span>
                              )}
                            </div>
                            <div className="flex items-center text-sm text-gray-600 dark:text-gray-400">
                              <Calendar size={14} className="mr-1" />
                              Ajouté: {formatDate(participant.date_add || participant.created_at)}
                            </div>
                          </div>

                          {/* Progress Bar */}
                          <ProgressBar 
                            percentage={participant.overall_progression} 
                            size="small"
                            className="max-w-md"
                          />
                          
                          {/* Expanded Module Details */}
                          {expandedParticipants.has(participant.id) && participant.modules && (
                            <div className="mt-4 border-t border-gray-200 dark:border-slate-700 pt-4">
                              <h4 className="text-sm font-medium text-gray-900 dark:text-white mb-3 flex items-center">
                                <PlayCircle size={14} className="mr-1" />
                                {t('common.moduleProgressCount', { count: participant.modules.length })}
                              </h4>
                              <div className="space-y-3">
                                {participant.modules.map((module, index) => (
                                  <div key={module.id} className="bg-gray-50 dark:bg-slate-900 rounded-lg p-3">
                                    <div className="flex items-center justify-between mb-2">
                                      <div className="flex items-center">
                                        <span className="inline-flex items-center justify-center w-6 h-6 rounded-full bg-primary-100 dark:bg-primary-900/30 text-primary-600 text-xs font-medium mr-2">
                                          {index + 1}
                                        </span>
                                        <span className="text-sm font-medium text-gray-900 dark:text-white">
                                          {module.intitule || t('common.moduleNumber', { number: module.id_lmp || module.id_lam })}
                                        </span>
                                      </div>
                                      <div className="flex items-center space-x-2">
                                        <span className="text-xs text-gray-500 dark:text-gray-400">
                                          {module.progression.toFixed(1)}%
                                        </span>
                                        {module.progression >= 100 && (
                                          <CheckCircle size={12} className="text-green-500" />
                                        )}
                                      </div>
                                    </div>
                                    <ProgressBar 
                                      percentage={module.progression} 
                                      size="small"
                                      className="mb-2"
                                    />
                                    <div className="grid grid-cols-1 sm:grid-cols-4 gap-2 text-xs text-gray-500 dark:text-gray-400">
                                      <span>{t('common.moduleMode')}: {module.mode_organisation}</span>
                                      {(module.date_debut || module.date_fin) && (
                                        <span className="flex items-center">
                                          <Calendar size={10} className="inline mr-1" />
                                          {formatDate(module.date_debut)} → {formatDate(module.date_fin)}
                                        </span>
                                      )}
                                      <span>
                                        <Clock size={10} className="inline mr-1" />
                                        {formatTimeSpentInHours(module.time_spent || 0)}
                                      </span>
                                      <span>{t('common.moduleLastAccess')}: {formatDate(module.last_access)}</span>
                                    </div>
                                  </div>
                                ))}
                              </div>
                            </div>
                          )}
                        </div>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </>
        </div>
      </div>
    </div>
  );
};

export default CourseDetail; 
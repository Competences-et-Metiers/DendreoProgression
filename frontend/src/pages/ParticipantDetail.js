import React, { useState, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import LoadingSpinner from '../components/LoadingSpinner';
import ProgressBar from '../components/ProgressBar';
import { useParticipantDetails } from '../hooks/useQuery';
import { apiService } from '../services/api';
import * as timeUtils from '../utils/timeUtils';
import DealLinkButton from '../components/DealLinkButton';
import {
  ArrowLeft,
  User,
  BookOpen,
  Target,
  Mail,
  Calendar,
  CheckCircle,
  Clock,
  ChevronRight,
  ChevronDown,
  PlayCircle,
  ExternalLink,
  Loader
} from 'lucide-react';

const ParticipantDetail = () => {
  const { t } = useTranslation();
  const { participantId } = useParams();
  const navigate = useNavigate();
  const [expandedCourses, setExpandedCourses] = useState(new Set());
  const [hubspotLoading, setHubspotLoading] = useState(false);
  const [hubspotError, setHubspotError] = useState(null);
  const hubspotUrlCache = useRef(null);

  // Use React Query hook for data fetching with caching
  const {
    data: participantData,
    isLoading: loading,
    error,
    refetch
  } = useParticipantDetails(participantId);

  const handleCourseClick = (courseId) => {
    navigate(`/courses/${courseId}`);
  };

  const toggleCourseExpanded = (courseId) => {
    const newExpanded = new Set(expandedCourses);
    if (newExpanded.has(courseId)) {
      newExpanded.delete(courseId);
    } else {
      newExpanded.add(courseId);
    }
    setExpandedCourses(newExpanded);
  };

  const handleHubspotClick = async () => {
    if (!participantData?.participant?.email) return;
    // Use cached URL if available
    if (hubspotUrlCache.current) {
      window.open(hubspotUrlCache.current, '_blank', 'noopener,noreferrer');
      return;
    }
    setHubspotLoading(true);
    setHubspotError(null);
    try {
      const data = await apiService.getHubspotContact(participantData.participant.email);
      if (data?.url) {
        hubspotUrlCache.current = data.url;
        window.open(data.url, '_blank', 'noopener,noreferrer');
      }
    } catch (err) {
      const errorKey = err.response?.status === 404 ? 'hubspotNotFound' : 'hubspotError';
      setHubspotError(errorKey);
      setTimeout(() => setHubspotError(null), 3000);
    } finally {
      setHubspotLoading(false);
    }
  };

  const getProgressBadge = (progression) => {
    if (progression >= 100) {
      return <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 dark:bg-green-900/30 text-green-800">
        <CheckCircle size={12} className="mr-1" />
        {t('common.completed')}
      </span>;
    } else if (progression > 0) {
      return <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 dark:bg-blue-900/30 text-blue-800">
        <Clock size={12} className="mr-1" />
        {t('common.inProgress')}
      </span>;
    } else {
      return <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 dark:bg-slate-700 text-gray-800 dark:text-gray-200">
        <Clock size={12} className="mr-1" />
        {t('common.notStarted')}
      </span>;
    }
  };

  const formatDate = (dateString) => {
    if (!dateString) return t('common.never');
    return new Date(dateString).toLocaleDateString();
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
          <p className="text-gray-600 dark:text-gray-400 mb-4">{error.message || t('errors.failedToLoadParticipantData')}</p>
          <button 
            onClick={refetch}
            className="bg-primary-500 text-white px-4 py-2 rounded-lg hover:bg-primary-600 mr-2"
          >
            {t('common.retry')}
          </button>
          <button 
            onClick={() => navigate('/participants')}
            className="bg-gray-500 text-white px-4 py-2 rounded-lg hover:bg-gray-600"
          >
            {t('navigation.backToParticipants')}
          </button>
        </div>
      </div>
    );
  }

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
                    window.open('/participants', '_blank', 'noopener,noreferrer');
                  } else {
                    navigate('/participants');
                  }
                }}
                className="mr-4 p-2 text-gray-400 dark:text-gray-500 hover:text-gray-600 dark:hover:text-gray-300"
                title="Back to Participants (Ctrl+Click or middle-click to open in new tab)"
              >
                <ArrowLeft size={20} />
              </button>
              <div>
                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                  {participantData?.participant?.prenom} {participantData?.participant?.nom}
                  {participantData?.participant?.id_participant && (
                    <button
                      onClick={() => {
                        window.open(`https://pro.dendreo.com/competences_et_metiers/participants.php?id_participant=${participantData.participant.id_participant}`, '_blank', 'noopener,noreferrer');
                      }}
                      className="ml-3 inline-flex items-center px-3 py-1 text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-slate-700 border border-gray-300 dark:border-slate-600 rounded-md hover:bg-gray-200 dark:hover:bg-slate-600 hover:text-gray-900 dark:hover:text-white focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-colors"
                      title={t('common.openDendreoProfile')}
                    >
                      <ExternalLink size={14} className="mr-1" />
                      Dendreo
                    </button>
                  )}
                  {participantData?.participant?.email && (
                    <button
                      onClick={handleHubspotClick}
                      disabled={hubspotLoading}
                      className="ml-2 inline-flex items-center px-3 py-1 text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-slate-700 border border-gray-300 dark:border-slate-600 rounded-md hover:bg-gray-200 dark:hover:bg-slate-600 hover:text-gray-900 dark:hover:text-white focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-colors disabled:opacity-50"
                      title={t('common.openHubspotProfile')}
                    >
                      {hubspotLoading ? <Loader size={14} className="mr-1 animate-spin" /> : <ExternalLink size={14} className="mr-1" />}
                      HubSpot
                    </button>
                  )}
                </h1>
                {hubspotError && (
                  <p className="text-xs text-red-500 mt-1">{t(`common.${hubspotError}`)}</p>
                )}
                <p className="text-gray-600 dark:text-gray-400 mt-1">{t('participantDetail.subtitle')}</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Participant Summary */}
        <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700 mb-8">
          <div className="px-6 py-4 border-b border-gray-200 dark:border-slate-700">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">{t('participantDetail.information')}</h2>
          </div>
          <div className="px-6 py-4">
            <div className="flex items-center mb-4">
              <div className="w-16 h-16 bg-primary-100 dark:bg-primary-900/30 rounded-full flex items-center justify-center mr-4">
                <User size={24} className="text-primary-600" />
              </div>
              <div>
                <h3 className="text-xl font-medium text-gray-900 dark:text-white">
                  {participantData?.participant?.prenom} {participantData?.participant?.nom}
                  {participantData?.participant?.id_participant && (
                    <button
                      onClick={() => {
                        window.open(`https://pro.dendreo.com/competences_et_metiers/participants.php?id_participant=${participantData.participant.id_participant}`, '_blank', 'noopener,noreferrer');
                      }}
                      className="ml-2 inline-flex items-center px-2 py-1 text-xs font-medium text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-slate-700 border border-gray-300 dark:border-slate-600 rounded-md hover:bg-gray-200 dark:hover:bg-slate-600 hover:text-gray-900 dark:hover:text-white focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-colors"
                      title={t('common.openDendreoProfile')}
                    >
                      <ExternalLink size={12} className="mr-1" />
                      Dendreo
                    </button>
                  )}
                  {participantData?.participant?.email && (
                    <button
                      onClick={handleHubspotClick}
                      disabled={hubspotLoading}
                      className="ml-2 inline-flex items-center px-2 py-1 text-xs font-medium text-gray-700 bg-gray-100 border border-gray-300 rounded-md hover:bg-gray-200 hover:text-gray-900 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 transition-colors disabled:opacity-50"
                      title={t('common.openHubspotProfile')}
                    >
                      {hubspotLoading ? <Loader size={12} className="mr-1 animate-spin" /> : <ExternalLink size={12} className="mr-1" />}
                      HubSpot
                    </button>
                  )}
                </h3>
                <div className="flex items-center text-gray-600 dark:text-gray-400 mt-1">
                  <Mail size={16} className="mr-2" />
                  {participantData?.participant?.email}
                </div>
              </div>
            </div>

            {/* Summary Stats */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="bg-gray-50 dark:bg-slate-900 rounded-lg p-4">
                <div className="flex items-center">
                  <div className="p-2 rounded-full bg-blue-100 dark:bg-blue-900/30 text-blue-600">
                    <BookOpen size={20} />
                  </div>
                  <div className="ml-3">
                    <p className="text-sm font-medium text-gray-600 dark:text-gray-400">{t('participantDetail.stats.totalCourses')}</p>
                    <p className="text-xl font-bold text-gray-900 dark:text-white">{participantData?.summary?.total_courses || 0}</p>
                  </div>
                </div>
              </div>

              <div className="bg-gray-50 dark:bg-slate-900 rounded-lg p-4">
                <div className="flex items-center">
                  <div className="p-2 rounded-full bg-green-100 dark:bg-green-900/30 text-green-600">
                    <CheckCircle size={20} />
                  </div>
                  <div className="ml-3">
                    <p className="text-sm font-medium text-gray-600 dark:text-gray-400">{t('participantDetail.stats.completed')}</p>
                    <p className="text-xl font-bold text-gray-900 dark:text-white">{participantData?.summary?.completed_courses || 0}</p>
                  </div>
                </div>
              </div>

              <div className="bg-gray-50 dark:bg-slate-900 rounded-lg p-4">
                <div className="flex items-center">
                  <div className="p-2 rounded-full bg-purple-100 dark:bg-purple-900/30 text-purple-600">
                    <Target size={20} />
                  </div>
                  <div className="ml-3">
                    <p className="text-sm font-medium text-gray-600 dark:text-gray-400">{t('participantDetail.stats.averageProgress')}</p>
                    <p className="text-xl font-bold text-gray-900 dark:text-white">
                      {(participantData?.summary?.average_progression || 0).toFixed(1)}%
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Courses Section */}
        <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700">
          <div className="px-6 py-4 border-b border-gray-200 dark:border-slate-700">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="text-lg font-semibold text-gray-900 dark:text-white">{t('participantDetail.enrolledCourses')}</h2>
                <p className="text-sm text-gray-600 dark:text-gray-400">
                  {t('participantDetail.subtitleWithCount', { count: participantData?.courses?.length || 0 })}
                </p>
              </div>
            </div>
          </div>

          <div className="divide-y divide-gray-200 dark:divide-slate-700">
            {!participantData?.courses || participantData.courses.length === 0 ? (
              <div className="px-6 py-12 text-center">
                <BookOpen size={48} className="mx-auto text-gray-400 dark:text-gray-500 mb-4" />
                <p className="text-gray-500 dark:text-gray-400">{t('common.noCoursesForParticipant')}</p>
              </div>
            ) : (
              participantData.courses.map((course) => (
                <div key={course.course_id} className="px-6 py-4 hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors">
                  <div className="flex items-center justify-between">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between mb-2">
                        <h3 
                          className="text-sm font-medium text-gray-900 dark:text-white cursor-pointer hover:text-primary-600"
                          onClick={() => handleCourseClick(course.course_id)}
                        >
                          {course.course_title || t('common.courseTitle', { id: course.course_id })}
                        </h3>
                        <div className="flex items-center space-x-2">
                          <DealLinkButton
                            participantId={parseInt(participantId)}
                            idActionFormation={course.id_action_formation}
                            email={participantData?.participant?.email}
                            hubspotDeal={course.hubspot_deal}
                          />
                          {getProgressBadge(course.progression)}
                          {course.modules && course.modules.length > 0 && (
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                toggleCourseExpanded(course.course_id);
                              }}
                              className="p-1 text-gray-400 dark:text-gray-500 hover:text-gray-600 dark:hover:text-gray-300 transition-colors"
                              title={t('common.viewModuleDetails')}
                            >
                              {expandedCourses.has(course.course_id) ? (
                                <ChevronDown size={16} />
                              ) : (
                                <ChevronRight size={16} />
                              )}
                            </button>
                          )}
                        </div>
                      </div>
                      
                      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4 mb-3">
                        <div className="flex items-center text-sm text-gray-600 dark:text-gray-400">
                          <Target size={14} className="mr-1" />
                          {(course.progression || 0).toFixed(1)}% {t('common.progress')}
                        </div>
                        <div className="flex items-center text-sm text-gray-600 dark:text-gray-400">
                          <BookOpen size={14} className="mr-1" />
                          {course.completed_modules}/{course.total_modules} {t('common.modulesCompleted')}
                        </div>
                        <div className="flex items-center text-sm text-gray-600 dark:text-gray-400">
                          <Clock size={14} className="mr-1" />
                          {timeUtils.formatTimeSpentInHours(course.total_time_spent || 0)}/{timeUtils.formatTimeSpentInHours((course.planned_duration_hours || 0) * 3600)}
                        </div>
                        <div
                          className="group/source flex items-center text-sm text-gray-600 dark:text-gray-400"
                          title={course.last_activity_source ? `${t('inactiveManagement.lastActivitySource')}: ${t(`inactiveManagement.activitySource.${course.last_activity_source}`)}` : ''}
                        >
                          <Calendar size={14} className="mr-1" />
                          {t('common.lastActivity')}: {formatDate(course.last_activity)}
                          {course.last_activity_source && (
                            <span className={`opacity-0 group-hover/source:opacity-100 transition-opacity ml-1.5 inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-medium ${
                              course.last_activity_source === 'elearning'
                                ? 'bg-blue-50 dark:bg-blue-900/20 text-blue-600'
                                : 'bg-violet-50 dark:bg-violet-900/20 text-violet-600'
                            }`}>
                              {t(`inactiveManagement.activitySource.${course.last_activity_source}`)}
                            </span>
                          )}
                        </div>
                        <div className="flex items-center text-sm text-gray-600 dark:text-gray-400">
                          <Calendar size={14} className="mr-1" />
                          Ajouté: {formatDate(course.date_add || course.created_at)}
                        </div>
                      </div>
                      
                      <ProgressBar 
                        percentage={course.progression || 0} 
                        size="small"
                        className="max-w-md"
                      />

                      {/* Expanded Module Details */}
                      {expandedCourses.has(course.course_id) && course.modules && (
                        <div className="mt-4 border-t border-gray-200 dark:border-slate-700 pt-4">
                          <h4 className="text-sm font-medium text-gray-900 dark:text-white mb-3 flex items-center">
                            <PlayCircle size={14} className="mr-1" />
                            {t('common.moduleProgressCount', { count: course.modules.length })}
                          </h4>
                          <div className="space-y-3">
                            {course.modules.map((module, index) => (
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
                                <div className="flex items-center justify-between text-xs text-gray-500 dark:text-gray-400">
                                  <span>{t('common.moduleMode')}: {module.mode_organisation}</span>
                                  {(module.date_debut || module.date_fin) && (
                                    <span className="flex items-center">
                                      <Calendar size={10} className="inline mr-1" />
                                      {formatDate(module.date_debut)} → {formatDate(module.date_fin)}
                                    </span>
                                  )}
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
        </div>
      </div>
    </div>
  );
};

export default ParticipantDetail; 
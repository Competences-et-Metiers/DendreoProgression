import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useQuery } from '@tanstack/react-query';
import {
  UserX,
  AlertTriangle,
  Clock,
  Calendar,
  Mail,
  BookOpen,
  ChevronDown,
  ChevronRight,
  Settings,
  Filter,
  BarChart3,
  Loader2
} from 'lucide-react';
import api from '../services/api';

const InactiveManagement = () => {
  const { t } = useTranslation();
  const [groupByCourse, setGroupByCourse] = useState(true);
  const [filters, setFilters] = useState({
    inactivityThreshold: 30,
    longInactivityThreshold: 60,
    atRiskThreshold: 21,
    excludeRecentDays: 7,
    minProgression: null,
    maxProgression: null,
    courseId: null
  });
  const [showFilters, setShowFilters] = useState(false);
  const [expandedCourses, setExpandedCourses] = useState(new Set());

  // Fetch inactive participants
  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['inactive-participants', groupByCourse, filters],
    queryFn: async () => {
      const params = new URLSearchParams({
        group_by_course: groupByCourse,
        inactivity_threshold_days: filters.inactivityThreshold,
        long_inactivity_threshold_days: filters.longInactivityThreshold,
        at_risk_threshold_days: filters.atRiskThreshold,
        exclude_recent_enrollments_days: filters.excludeRecentDays
      });

      if (filters.minProgression !== null) {
        params.append('min_progression', filters.minProgression);
      }
      if (filters.maxProgression !== null) {
        params.append('max_progression', filters.maxProgression);
      }
      if (filters.courseId !== null) {
        params.append('course_id', filters.courseId);
      }

      const response = await api.get(`/participants/inactive?${params}`);
      return response.data;
    },
    staleTime: 60000, // Cache for 1 minute
  });

  const toggleCourse = (courseId) => {
    const newExpanded = new Set(expandedCourses);
    if (newExpanded.has(courseId)) {
      newExpanded.delete(courseId);
    } else {
      newExpanded.add(courseId);
    }
    setExpandedCourses(newExpanded);
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'at_risk':
        return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'stalled':
        return 'bg-orange-100 text-orange-800 border-orange-200';
      case 'long_inactive':
        return 'bg-red-100 text-red-800 border-red-200';
      default:
        return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const getStatusIcon = (status) => {
    switch (status) {
      case 'at_risk':
        return <AlertTriangle size={16} className="text-yellow-600" />;
      case 'stalled':
        return <Clock size={16} className="text-orange-600" />;
      case 'long_inactive':
        return <UserX size={16} className="text-red-600" />;
      default:
        return <Clock size={16} className="text-gray-600" />;
    }
  };

  const getStatusLabel = (status) => {
    switch (status) {
      case 'at_risk':
        return t('inactiveManagement.status.atRisk');
      case 'stalled':
        return t('inactiveManagement.status.stalled');
      case 'long_inactive':
        return t('inactiveManagement.status.longInactive');
      default:
        return status;
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center">
              <div className="p-2 bg-orange-100 rounded-lg mr-4">
                <UserX size={24} className="text-orange-600" />
              </div>
              <div>
                <h1 className="text-2xl font-bold text-gray-900">
                  {t('inactiveManagement.title')}
                </h1>
                <p className="text-gray-600 mt-1">
                  {t('inactiveManagement.subtitle')}
                </p>
              </div>
            </div>

            {/* View Toggle */}
            <div className="flex items-center gap-3">
              <button
                onClick={() => setShowFilters(!showFilters)}
                className={`flex items-center gap-2 px-4 py-2 rounded-lg border transition-colors ${
                  showFilters
                    ? 'bg-primary-50 border-primary-200 text-primary-700'
                    : 'bg-white border-gray-300 text-gray-700 hover:bg-gray-50'
                }`}
              >
                <Filter size={18} />
                <span className="font-medium">{t('common.filters')}</span>
              </button>

              <button
                onClick={() => setGroupByCourse(!groupByCourse)}
                className="flex items-center gap-2 px-4 py-2 bg-white border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 transition-colors"
              >
                <BarChart3 size={18} />
                <span className="font-medium">
                  {groupByCourse ? t('inactiveManagement.viewFlat') : t('inactiveManagement.viewGrouped')}
                </span>
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Filters Panel */}
        {showFilters && (
          <div className="bg-white rounded-lg border border-gray-200 p-6 mb-6">
            <div className="flex items-center gap-2 mb-4">
              <Settings size={20} className="text-gray-600" />
              <h3 className="text-lg font-semibold text-gray-900">
                {t('inactiveManagement.filters.title')}
              </h3>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  {t('inactiveManagement.filters.atRiskThreshold')}
                </label>
                <input
                  type="number"
                  value={filters.atRiskThreshold}
                  onChange={(e) => setFilters({ ...filters, atRiskThreshold: parseInt(e.target.value) })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                  min="1"
                  max="365"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  {t('inactiveManagement.filters.stalledThreshold')}
                </label>
                <input
                  type="number"
                  value={filters.inactivityThreshold}
                  onChange={(e) => setFilters({ ...filters, inactivityThreshold: parseInt(e.target.value) })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                  min="1"
                  max="365"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  {t('inactiveManagement.filters.longInactiveThreshold')}
                </label>
                <input
                  type="number"
                  value={filters.longInactivityThreshold}
                  onChange={(e) => setFilters({ ...filters, longInactivityThreshold: parseInt(e.target.value) })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                  min="1"
                  max="365"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  {t('inactiveManagement.filters.excludeRecentDays')}
                </label>
                <input
                  type="number"
                  value={filters.excludeRecentDays}
                  onChange={(e) => setFilters({ ...filters, excludeRecentDays: parseInt(e.target.value) })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                  min="0"
                  max="90"
                />
              </div>
            </div>

            <div className="mt-4 flex justify-end">
              <button
                onClick={() => refetch()}
                className="px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors font-medium"
              >
                {t('common.apply')}
              </button>
            </div>
          </div>
        )}

        {/* Loading State */}
        {isLoading && (
          <div className="flex items-center justify-center py-12">
            <Loader2 className="w-8 h-8 animate-spin text-primary-600" />
          </div>
        )}

        {/* Error State */}
        {error && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
            <p className="text-red-800">
              {t('common.error')}: {error.message}
            </p>
          </div>
        )}

        {/* Statistics Cards */}
        {data && !isLoading && (
          <>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
              <div className="bg-white rounded-lg border border-gray-200 p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-gray-600">{t('inactiveManagement.stats.totalInactive')}</p>
                    <p className="text-3xl font-bold text-gray-900 mt-2">{data.total_inactive}</p>
                  </div>
                  <div className="p-3 bg-gray-100 rounded-lg">
                    <UserX size={24} className="text-gray-600" />
                  </div>
                </div>
              </div>

              <div className="bg-white rounded-lg border border-yellow-200 p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-yellow-700">{t('inactiveManagement.stats.atRisk')}</p>
                    <p className="text-3xl font-bold text-yellow-900 mt-2">{data.at_risk_count}</p>
                  </div>
                  <div className="p-3 bg-yellow-100 rounded-lg">
                    <AlertTriangle size={24} className="text-yellow-600" />
                  </div>
                </div>
              </div>

              <div className="bg-white rounded-lg border border-orange-200 p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-orange-700">{t('inactiveManagement.stats.stalled')}</p>
                    <p className="text-3xl font-bold text-orange-900 mt-2">{data.stalled_count}</p>
                  </div>
                  <div className="p-3 bg-orange-100 rounded-lg">
                    <Clock size={24} className="text-orange-600" />
                  </div>
                </div>
              </div>

              <div className="bg-white rounded-lg border border-red-200 p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-red-700">{t('inactiveManagement.stats.longInactive')}</p>
                    <p className="text-3xl font-bold text-red-900 mt-2">{data.long_inactive_count}</p>
                  </div>
                  <div className="p-3 bg-red-100 rounded-lg">
                    <UserX size={24} className="text-red-600" />
                  </div>
                </div>
              </div>
            </div>

            {/* Grouped by Course View */}
            {groupByCourse && data.by_course && (
              <div className="space-y-4">
                {data.by_course.map((course) => (
                  <div key={course.course_id} className="bg-white rounded-lg border border-gray-200">
                    {/* Course Header */}
                    <button
                      onClick={() => toggleCourse(course.course_id)}
                      className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
                    >
                      <div className="flex items-center gap-4 flex-1">
                        <div className="p-2 bg-primary-100 rounded-lg">
                          <BookOpen size={20} className="text-primary-600" />
                        </div>
                        <div className="text-left flex-1">
                          <h3 className="font-semibold text-gray-900">{course.course_title}</h3>
                          <p className="text-sm text-gray-500 mt-1">
                            {t('inactiveManagement.totalInactive')}: {course.total_inactive}
                          </p>
                        </div>
                        <div className="flex items-center gap-3">
                          <span className="px-3 py-1 bg-yellow-100 text-yellow-800 rounded-full text-sm font-medium">
                            {course.at_risk_count} {t('inactiveManagement.atRisk')}
                          </span>
                          <span className="px-3 py-1 bg-orange-100 text-orange-800 rounded-full text-sm font-medium">
                            {course.stalled_count} {t('inactiveManagement.stalled')}
                          </span>
                          <span className="px-3 py-1 bg-red-100 text-red-800 rounded-full text-sm font-medium">
                            {course.long_inactive_count} {t('inactiveManagement.longInactive')}
                          </span>
                        </div>
                      </div>
                      {expandedCourses.has(course.course_id) ? (
                        <ChevronDown size={20} className="text-gray-400 ml-2" />
                      ) : (
                        <ChevronRight size={20} className="text-gray-400 ml-2" />
                      )}
                    </button>

                    {/* Participants List */}
                    {expandedCourses.has(course.course_id) && (
                      <div className="border-t border-gray-200">
                        <div className="divide-y divide-gray-200">
                          {course.participants.map((participant) => (
                            <div key={participant.id} className="px-6 py-4 hover:bg-gray-50">
                              <div className="flex items-center justify-between">
                                <div className="flex items-center gap-4 flex-1">
                                  <div className={`px-3 py-1 rounded-full text-xs font-medium border flex items-center gap-1 ${getStatusColor(participant.inactivity_status)}`}>
                                    {getStatusIcon(participant.inactivity_status)}
                                    <span>{getStatusLabel(participant.inactivity_status)}</span>
                                  </div>
                                  <div className="flex-1">
                                    <div className="flex items-center gap-2">
                                      <p className="font-medium text-gray-900">
                                        {participant.nom} {participant.prenom}
                                      </p>
                                      <span className="text-sm text-gray-500">
                                        ({participant.current_progression.toFixed(1)}%)
                                      </span>
                                    </div>
                                    <div className="flex items-center gap-4 mt-1 text-sm text-gray-600">
                                      <span className="flex items-center gap-1">
                                        <Mail size={14} />
                                        {participant.email}
                                      </span>
                                      <span className="flex items-center gap-1">
                                        <Clock size={14} />
                                        {participant.days_inactive} {t('common.daysInactive')}
                                      </span>
                                      <span className="flex items-center gap-1">
                                        <Calendar size={14} />
                                        {t('common.enrolled')} {participant.days_since_enrollment} {t('common.daysAgo')}
                                      </span>
                                    </div>
                                  </div>
                                </div>
                              </div>
                            </div>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>
                ))}
              </div>
            )}

            {/* Flat List View */}
            {!groupByCourse && data.participants && (
              <div className="bg-white rounded-lg border border-gray-200">
                <div className="divide-y divide-gray-200">
                  {data.participants.map((participant) => (
                    <div key={`${participant.id}-${participant.course_id}`} className="px-6 py-4 hover:bg-gray-50">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-4 flex-1">
                          <div className={`px-3 py-1 rounded-full text-xs font-medium border flex items-center gap-1 ${getStatusColor(participant.inactivity_status)}`}>
                            {getStatusIcon(participant.inactivity_status)}
                            <span>{getStatusLabel(participant.inactivity_status)}</span>
                          </div>
                          <div className="flex-1">
                            <div className="flex items-center gap-2">
                              <p className="font-medium text-gray-900">
                                {participant.nom} {participant.prenom}
                              </p>
                              <span className="text-sm text-gray-500">
                                • {participant.course_title}
                              </span>
                              <span className="text-sm text-gray-500">
                                ({participant.current_progression.toFixed(1)}%)
                              </span>
                            </div>
                            <div className="flex items-center gap-4 mt-1 text-sm text-gray-600">
                              <span className="flex items-center gap-1">
                                <Mail size={14} />
                                {participant.email}
                              </span>
                              <span className="flex items-center gap-1">
                                <Clock size={14} />
                                {participant.days_inactive} {t('common.daysInactive')}
                              </span>
                              <span className="flex items-center gap-1">
                                <Calendar size={14} />
                                {t('common.enrolled')} {participant.days_since_enrollment} {t('common.daysAgo')}
                              </span>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Empty State */}
            {data.total_inactive === 0 && (
              <div className="bg-white rounded-lg border border-gray-200 p-12 text-center">
                <UserX size={64} className="mx-auto text-gray-400 mb-4" />
                <h2 className="text-xl font-semibold text-gray-900 mb-2">
                  {t('inactiveManagement.noInactive')}
                </h2>
                <p className="text-gray-600 max-w-md mx-auto">
                  {t('inactiveManagement.noInactiveDescription')}
                </p>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
};

export default InactiveManagement;

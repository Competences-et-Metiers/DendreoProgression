import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import LoadingSpinner from '../components/LoadingSpinner';
import StatCard from '../components/StatCard';
import ProgressBar from '../components/ProgressBar';
import CacheStatus from '../components/CacheStatus';
import LanguageSelector from '../components/LanguageSelector';
import { useDashboardStats, useCourses, usePrefetchQueries, useLastSync } from '../hooks/useQuery';
import {
  BookOpen,
  Users,
  Target,
  TrendingUp,
  Calendar,
  RefreshCw,
  ChevronRight,
  Filter,
  Search
} from 'lucide-react';

const Dashboard = () => {
  const { t } = useTranslation();
  const [searchTerm, setSearchTerm] = useState('');
  const [sortBy, setSortBy] = useState('progression');
  const [filterBy, setFilterBy] = useState('all');
  const navigate = useNavigate();

  const {
    data: stats,
    isLoading: statsLoading,
    error: statsError,
    refetch: refetchStats,
    isFetching: statsRefetching
  } = useDashboardStats();

  const {
    data: courses = [],
    isLoading: coursesLoading,
    error: coursesError,
    refetch: refetchCourses,
    isFetching: coursesRefetching
  } = useCourses();

  const {
    data: lastSync,
    isLoading: lastSyncLoading,
    refetch: refetchLastSync,
    isFetching: lastSyncRefetching
  } = useLastSync();

  const { prefetchCourseParticipants } = usePrefetchQueries();

  const loading = statsLoading || coursesLoading;
  const error = statsError || coursesError;
  const isRefetching = statsRefetching || coursesRefetching || lastSyncRefetching;

  const handleRefresh = () => {
    refetchStats();
    refetchCourses();
    refetchLastSync();
  };

  const handleCourseClick = (courseId, event) => {
    if (event.ctrlKey || event.metaKey || event.button === 1) {
      window.open(`/courses/${courseId}`, '_blank', 'noopener,noreferrer');
    } else {
      prefetchCourseParticipants(courseId);
      navigate(`/courses/${courseId}`);
    }
  };

  const getFilteredAndSortedCourses = () => {
    let filtered = courses;

    if (searchTerm) {
      const search = searchTerm.toLowerCase();
      filtered = filtered.filter(course =>
        course.intitule.toLowerCase().includes(search)
      );
    }

    if (filterBy === 'completed') {
      filtered = filtered.filter(course => course.average_progression >= 100);
    } else if (filterBy === 'in-progress') {
      filtered = filtered.filter(course => course.average_progression > 0 && course.average_progression < 100);
    } else if (filterBy === 'not-started') {
      filtered = filtered.filter(course => course.average_progression === 0);
    }

    return filtered.sort((a, b) => {
      switch (sortBy) {
        case 'progression':
          return b.average_progression - a.average_progression;
        case 'participants':
          return b.participant_count - a.participant_count;
        case 'title':
          return a.intitule.localeCompare(b.intitule);
        case 'modules':
          return b.total_modules - a.total_modules;
        default:
          return 0;
      }
    });
  };

  const formatLastSyncDate = (lastSyncData) => {
    if (!lastSyncData || lastSyncData.status === 'no_sync') {
      return 'Never';
    }
    if (!lastSyncData.last_sync_at) {
      return 'Unknown';
    }
    const date = new Date(lastSyncData.last_sync_at);
    return date.toLocaleString();
  };

  const getLastSyncStatus = (lastSyncData) => {
    if (!lastSyncData || lastSyncData.status === 'no_sync') {
      return { status: 'never', color: 'text-gray-500' };
    }
    switch (lastSyncData.sync_status) {
      case 'success':
        return { status: 'success', color: 'text-green-600 dark:text-green-400' };
      case 'error':
        return { status: 'error', color: 'text-red-600 dark:text-red-400' };
      case 'in_progress':
        return { status: 'in progress', color: 'text-blue-600 dark:text-blue-400' };
      default:
        return { status: 'unknown', color: 'text-gray-500 dark:text-gray-400' };
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
          <p className="text-gray-600 dark:text-gray-400 mb-4">{error.message || t('errors.failedToLoadDashboard')}</p>
          <button
            onClick={handleRefresh}
            className="bg-primary-500 text-white px-4 py-2 rounded-lg hover:bg-primary-600"
          >
            {t('common.retry')}
          </button>
        </div>
      </div>
    );
  }

  const filteredCourses = getFilteredAndSortedCourses();

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-slate-900">
      {/* Header */}
      <div className="bg-white dark:bg-slate-800 border-b border-gray-200 dark:border-slate-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-gray-900 dark:text-white">{t('dashboard.title')}</h1>
              <p className="text-gray-600 dark:text-gray-400 mt-1">{t('dashboard.subtitle')}</p>
            </div>

            <div className="flex flex-col items-end space-y-3">
              <div className="text-right">
                <div className="flex items-center space-x-2">
                  <Calendar size={14} className="text-gray-500 dark:text-gray-400" />
                  <span className="text-sm text-gray-600 dark:text-gray-400">
                    {t('dashboard.sync.lastSync')}: <span className="font-medium">{formatLastSyncDate(lastSync)}</span>
                  </span>
                  {lastSync && lastSync.sync_status && (
                    <span className={`text-xs font-medium ${getLastSyncStatus(lastSync).color}`}>
                      ({t(`dashboard.sync.status.${getLastSyncStatus(lastSync).status}`)})
                    </span>
                  )}
                </div>
                {lastSync?.sync_status === 'error' && lastSync?.error_message && (
                  <div className="text-xs text-red-500 dark:text-red-400 mt-1 max-w-md">
                    {t('common.error')}: {lastSync.error_message}
                  </div>
                )}
              </div>

              <div className="flex items-center space-x-4">
                <LanguageSelector />
                <button
                  onClick={handleRefresh}
                  disabled={isRefetching}
                  className="inline-flex items-center px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-md shadow-sm text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-slate-800 hover:bg-gray-50 dark:hover:bg-slate-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 disabled:opacity-50"
                  title={t('common.refreshData')}
                >
                  <RefreshCw size={16} className={`mr-2 ${isRefetching ? 'animate-spin' : ''}`} />
                  {isRefetching ? t('common.refreshing') : t('common.refresh')}
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Stats Grid */}
        {stats && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            <StatCard
              title={t('dashboard.stats.totalCourses')}
              value={stats.total_courses}
              icon={BookOpen}
              color="blue"
            />
            <StatCard
              title={t('dashboard.stats.totalParticipants')}
              value={stats.total_participants}
              icon={Users}
              color="green"
            />
            <StatCard
              title={t('dashboard.stats.averageProgress')}
              value={`${stats.average_progression}%`}
              icon={Target}
              color="purple"
            />
            <StatCard
              title={t('dashboard.stats.completionRate')}
              value={`${stats.completion_rate}%`}
              icon={TrendingUp}
              color="indigo"
            />
          </div>
        )}

        {/* Cache Status - Only show in development */}
        {process.env.NODE_ENV === 'development' && (
          <div className="mb-8">
            <CacheStatus />
          </div>
        )}

        {/* Courses Section */}
        <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700">
          {/* Courses Header */}
          <div className="px-6 py-4 border-b border-gray-200 dark:border-slate-700">
            <div className="flex flex-col space-y-4 lg:flex-row lg:items-center lg:justify-between lg:space-y-0">
              <div>
                <h2 className="text-lg font-semibold text-gray-900 dark:text-white">{t('dashboard.courses.title')}</h2>
                <p className="text-sm text-gray-600 dark:text-gray-400">
                  {t('dashboard.courses.subtitle', { count: filteredCourses.length, total: courses.length })}
                  {searchTerm && ` ${t('common.matchingCriteria')}`}
                </p>
              </div>

              <div className="flex flex-col space-y-2 sm:flex-row sm:items-center sm:space-y-0 sm:space-x-4">
                <div className="relative">
                  <div className="relative">
                    <Search size={16} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
                    <input
                      type="text"
                      placeholder={t('dashboard.courses.searchPlaceholder')}
                      value={searchTerm}
                      onChange={(e) => setSearchTerm(e.target.value)}
                      className="pl-10 pr-4 py-2 border-2 border-blue-300 dark:border-blue-700 rounded-md text-sm w-64 bg-white dark:bg-slate-700 text-gray-900 dark:text-white"
                      style={{ minWidth: '250px' }}
                    />
                  </div>
                  {searchTerm && (
                    <div className="absolute top-full left-0 mt-1 text-xs text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/30 px-2 py-1 rounded">
                      {t('dashboard.courses.searching', { term: searchTerm })}
                    </div>
                  )}
                </div>

                <div className="flex items-center space-x-2">
                  <Filter size={16} className="text-gray-500 dark:text-gray-400" />
                  <select
                    value={filterBy}
                    onChange={(e) => setFilterBy(e.target.value)}
                    className="border border-gray-300 dark:border-slate-600 rounded-md px-3 py-1 text-sm bg-white dark:bg-slate-700 text-gray-900 dark:text-white"
                  >
                    <option value="all">{t('dashboard.courses.filters.allCourses')}</option>
                    <option value="completed">{t('dashboard.courses.filters.completed')}</option>
                    <option value="in-progress">{t('dashboard.courses.filters.inProgress')}</option>
                    <option value="not-started">{t('dashboard.courses.filters.notStarted')}</option>
                  </select>
                </div>

                <select
                  value={sortBy}
                  onChange={(e) => setSortBy(e.target.value)}
                  className="border border-gray-300 dark:border-slate-600 rounded-md px-3 py-1 text-sm bg-white dark:bg-slate-700 text-gray-900 dark:text-white"
                >
                  <option value="progression">{t('dashboard.courses.sort.byProgress')}</option>
                  <option value="participants">{t('dashboard.courses.sort.byParticipants')}</option>
                  <option value="title">{t('dashboard.courses.sort.byTitle')}</option>
                  <option value="modules">{t('dashboard.courses.sort.byModules')}</option>
                </select>
              </div>
            </div>
          </div>

          {/* Courses List */}
          <div className="divide-y divide-gray-200 dark:divide-slate-700">
            {filteredCourses.length === 0 ? (
              <div className="px-6 py-12 text-center">
                <BookOpen size={48} className="mx-auto text-gray-400 dark:text-gray-600 mb-4" />
                <p className="text-gray-500 dark:text-gray-400">
                  {searchTerm || filterBy !== 'all'
                    ? t('errors.noCoursesMatchingCriteria')
                    : t('common.noCoursesFound')
                  }
                </p>
                {searchTerm && (
                  <button
                    onClick={() => setSearchTerm('')}
                    className="mt-2 text-sm text-primary-600 dark:text-primary-400 hover:text-primary-700 dark:hover:text-primary-300"
                  >
                    {t('common.clearSearch')}
                  </button>
                )}
              </div>
            ) : (
              filteredCourses.map((course) => (
                <div
                  key={course.id}
                  onClick={(e) => handleCourseClick(course.id, e)}
                  className="px-6 py-4 hover:bg-gray-50 dark:hover:bg-slate-700/50 cursor-pointer transition-colors"
                  title={`${course.intitule} (Ctrl+Click or middle-click to open in new tab)`}
                >
                  <div className="flex items-center justify-between">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between mb-2">
                        <h3 className="text-sm font-medium text-gray-900 dark:text-white truncate">
                          {course.intitule}
                        </h3>
                        <ChevronRight size={16} className="text-gray-400 dark:text-gray-500 ml-2" />
                      </div>

                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-3">
                        <div className="flex items-center text-sm text-gray-600 dark:text-gray-400">
                          <Users size={14} className="mr-1" />
                          {course.participant_count} {t('common.participants')}
                        </div>
                        <div className="flex items-center text-sm text-gray-600 dark:text-gray-400">
                          <BookOpen size={14} className="mr-1" />
                          {course.total_modules} {t('common.modules')}
                        </div>
                      </div>

                      <ProgressBar
                        percentage={course.average_progression}
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

export default Dashboard;

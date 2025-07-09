import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import LoadingSpinner from '../components/LoadingSpinner';
import StatCard from '../components/StatCard';
import ProgressBar from '../components/ProgressBar';
import CacheStatus from '../components/CacheStatus';
import { useDashboardStats, useCourses, usePrefetchQueries, useLastSync } from '../hooks/useQuery';
import { 
  BookOpen, 
  Users, 
  Target, 
  TrendingUp, 
  Calendar,
  RefreshCw,
  ChevronRight,
  Filter
} from 'lucide-react';

const Dashboard = () => {
  const [sortBy, setSortBy] = useState('progression');
  const [filterBy, setFilterBy] = useState('all');
  const navigate = useNavigate();
  
  // Use React Query hooks for data fetching with caching
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
  
  const { prefetchParticipants, prefetchCourseParticipants } = usePrefetchQueries();
  
  // Combined loading and error states
  const loading = statsLoading || coursesLoading;
  const error = statsError || coursesError;
  const isRefetching = statsRefetching || coursesRefetching || lastSyncRefetching;

  const handleRefresh = () => {
    refetchStats();
    refetchCourses();
    refetchLastSync();
  };

  const handleCourseClick = (courseId) => {
    // Prefetch course participants data for faster loading
    prefetchCourseParticipants(courseId);
    navigate(`/courses/${courseId}`);
  };

  const handleViewParticipants = () => {
    // Prefetch participants data for faster loading
    prefetchParticipants();
    navigate('/participants');
  };

  const getFilteredAndSortedCourses = () => {
    let filtered = courses;
    
    // Filter courses
    if (filterBy === 'completed') {
      filtered = courses.filter(course => course.average_progression >= 100);
    } else if (filterBy === 'in-progress') {
      filtered = courses.filter(course => course.average_progression > 0 && course.average_progression < 100);
    } else if (filterBy === 'not-started') {
      filtered = courses.filter(course => course.average_progression === 0);
    }
    
    // Sort courses
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

  const formatDate = (dateString) => {
    if (!dateString) return 'N/A';
    return new Date(dateString).toLocaleDateString();
  };

  const formatLastSyncDate = (lastSyncData) => {
    if (!lastSyncData || lastSyncData.status === 'no_sync') {
      return 'Never';
    }
    
    if (!lastSyncData.last_sync_at) {
      return 'Unknown';
    }
    
    const date = new Date(lastSyncData.last_sync_at);
    return date.toLocaleString(); // Shows both date and time
  };

  const getLastSyncStatus = (lastSyncData) => {
    if (!lastSyncData || lastSyncData.status === 'no_sync') {
      return { status: 'never', color: 'text-gray-500' };
    }
    
    switch (lastSyncData.sync_status) {
      case 'success':
        return { status: 'success', color: 'text-green-600' };
      case 'error':
        return { status: 'error', color: 'text-red-600' };
      case 'in_progress':
        return { status: 'in progress', color: 'text-blue-600' };
      default:
        return { status: 'unknown', color: 'text-gray-500' };
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
          <div className="text-red-500 text-xl mb-4">⚠️ Error</div>
          <p className="text-gray-600 mb-4">{error.message || 'Failed to load dashboard data'}</p>
          <button 
            onClick={handleRefresh}
            className="bg-primary-500 text-white px-4 py-2 rounded-lg hover:bg-primary-600"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  const filteredCourses = getFilteredAndSortedCourses();

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Dendreo Course Dashboard</h1>
              <p className="text-gray-600 mt-1">Track course progress and participant engagement</p>
            </div>
            
            {/* Last Sync Info and Navigation Menu */}
            <div className="flex flex-col items-end space-y-3">
              {/* Last Sync Information */}
              <div className="text-right">
                <div className="flex items-center space-x-2">
                  <Calendar size={14} className="text-gray-500" />
                  <span className="text-sm text-gray-600">
                    Last sync: <span className="font-medium">{formatLastSyncDate(lastSync)}</span>
                  </span>
                  {lastSync && lastSync.sync_status && (
                    <span className={`text-xs font-medium ${getLastSyncStatus(lastSync).color}`}>
                      ({getLastSyncStatus(lastSync).status})
                    </span>
                  )}
                </div>
                {lastSync?.sync_status === 'error' && lastSync?.error_message && (
                  <div className="text-xs text-red-500 mt-1 max-w-md">
                    Error: {lastSync.error_message}
                  </div>
                )}
              </div>
              
              {/* Navigation Menu */}
              <div className="flex items-center space-x-4">
                <button
                  onClick={handleRefresh}
                  disabled={isRefetching}
                  className="inline-flex items-center px-3 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 disabled:opacity-50"
                  title="Refresh data"
                >
                  <RefreshCw size={16} className={`mr-2 ${isRefetching ? 'animate-spin' : ''}`} />
                  {isRefetching ? 'Refreshing...' : 'Refresh'}
                </button>
                <button
                  onClick={handleViewParticipants}
                  className="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
                >
                  <Users size={16} className="mr-2" />
                  View Participants
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
              title="Total Courses"
              value={stats.total_courses}
              icon={BookOpen}
              color="blue"
            />
            <StatCard
              title="Total Participants"
              value={stats.total_participants}
              icon={Users}
              color="green"
            />
            <StatCard
              title="Average Progress"
              value={`${stats.average_progression}%`}
              icon={Target}
              color="purple"
            />
            <StatCard
              title="Completion Rate"
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
        <div className="bg-white rounded-lg border border-gray-200">
          {/* Courses Header */}
          <div className="px-6 py-4 border-b border-gray-200">
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between">
              <div>
                <h2 className="text-lg font-semibold text-gray-900">Courses</h2>
                <p className="text-sm text-gray-600">Click on a course to view participants</p>
              </div>
              
              {/* Filters and Sort */}
              <div className="flex items-center space-x-4 mt-4 sm:mt-0">
                <div className="flex items-center space-x-2">
                  <Filter size={16} className="text-gray-500" />
                  <select
                    value={filterBy}
                    onChange={(e) => setFilterBy(e.target.value)}
                    className="border border-gray-300 rounded-md px-3 py-1 text-sm"
                  >
                    <option value="all">All Courses</option>
                    <option value="completed">Completed</option>
                    <option value="in-progress">In Progress</option>
                    <option value="not-started">Not Started</option>
                  </select>
                </div>
                
                <select
                  value={sortBy}
                  onChange={(e) => setSortBy(e.target.value)}
                  className="border border-gray-300 rounded-md px-3 py-1 text-sm"
                >
                  <option value="progression">Sort by Progress</option>
                  <option value="participants">Sort by Participants</option>
                  <option value="title">Sort by Title</option>
                  <option value="modules">Sort by Modules</option>
                </select>
              </div>
            </div>
          </div>

          {/* Courses List */}
          <div className="divide-y divide-gray-200">
            {filteredCourses.length === 0 ? (
              <div className="px-6 py-12 text-center">
                <BookOpen size={48} className="mx-auto text-gray-400 mb-4" />
                <p className="text-gray-500">No courses found matching your criteria</p>
              </div>
            ) : (
              filteredCourses.map((course) => (
                <div
                  key={course.id}
                  onClick={() => handleCourseClick(course.id)}
                  className="px-6 py-4 hover:bg-gray-50 cursor-pointer transition-colors"
                >
                  <div className="flex items-center justify-between">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between mb-2">
                        <h3 className="text-sm font-medium text-gray-900 truncate">
                          {course.intitule}
                        </h3>
                        <ChevronRight size={16} className="text-gray-400 ml-2" />
                      </div>
                      
                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-3">
                        <div className="flex items-center text-sm text-gray-600">
                          <Users size={14} className="mr-1" />
                          {course.participant_count} participants
                        </div>
                        <div className="flex items-center text-sm text-gray-600">
                          <BookOpen size={14} className="mr-1" />
                          {course.total_modules} modules
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
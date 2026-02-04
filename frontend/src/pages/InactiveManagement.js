import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
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
  Loader2,
  ArrowUpDown,
  ArrowUp,
  ArrowDown,
  CheckCircle2
} from 'lucide-react';
import api from '../services/api';

const InactiveManagement = () => {
  const { t } = useTranslation();

  // State with localStorage persistence
  const [groupByCourse, setGroupByCourse] = useState(() => {
    const cached = localStorage.getItem('inactiveManagement.groupByCourse');
    return cached ? JSON.parse(cached) : true;
  });

  const [filters, setFilters] = useState(() => {
    const cached = localStorage.getItem('inactiveManagement.filters');
    return cached ? JSON.parse(cached) : {
      inactivityThreshold: 30,
      longInactivityThreshold: 60,
      atRiskThreshold: 21,
      excludeRecentDays: 7,
      minProgression: null,
      maxProgression: null,
      courseId: null
    };
  });

  const [showFilters, setShowFilters] = useState(false);
  const [expandedCourses, setExpandedCourses] = useState(new Set());

  // Sorting state
  const [sortBy, setSortBy] = useState(() => {
    const cached = localStorage.getItem('inactiveManagement.sortBy');
    return cached || 'inactivity';
  });

  const [sortDirection, setSortDirection] = useState(() => {
    const cached = localStorage.getItem('inactiveManagement.sortDirection');
    return cached || 'desc';
  });

  // Status filter state
  const [statusFilter, setStatusFilter] = useState(() => {
    const cached = localStorage.getItem('inactiveManagement.statusFilter');
    return cached ? JSON.parse(cached) : {
      at_risk: true,
      stalled: true,
      long_inactive: true
    };
  });

  // Active users toggle
  const [showActiveOnly, setShowActiveOnly] = useState(() => {
    const cached = localStorage.getItem('inactiveManagement.showActiveOnly');
    return cached ? JSON.parse(cached) : false;
  });

  const [activeDaysThreshold, setActiveDaysThreshold] = useState(() => {
    const cached = localStorage.getItem('inactiveManagement.activeDaysThreshold');
    return cached ? parseInt(cached) : 7;
  });

  // ADF filter state
  const [selectedADFs, setSelectedADFs] = useState(() => {
    const cached = localStorage.getItem('inactiveManagement.selectedADFs');
    return cached ? JSON.parse(cached) : [];
  });

  const [adfSearchTerm, setAdfSearchTerm] = useState('');
  const [showAdfDropdown, setShowAdfDropdown] = useState(false);

  // Persist state to localStorage
  useEffect(() => {
    localStorage.setItem('inactiveManagement.groupByCourse', JSON.stringify(groupByCourse));
  }, [groupByCourse]);

  useEffect(() => {
    localStorage.setItem('inactiveManagement.filters', JSON.stringify(filters));
  }, [filters]);

  useEffect(() => {
    localStorage.setItem('inactiveManagement.sortBy', sortBy);
  }, [sortBy]);

  useEffect(() => {
    localStorage.setItem('inactiveManagement.sortDirection', sortDirection);
  }, [sortDirection]);

  useEffect(() => {
    localStorage.setItem('inactiveManagement.statusFilter', JSON.stringify(statusFilter));
  }, [statusFilter]);

  useEffect(() => {
    localStorage.setItem('inactiveManagement.showActiveOnly', JSON.stringify(showActiveOnly));
  }, [showActiveOnly]);

  useEffect(() => {
    localStorage.setItem('inactiveManagement.activeDaysThreshold', activeDaysThreshold.toString());
  }, [activeDaysThreshold]);

  useEffect(() => {
    localStorage.setItem('inactiveManagement.selectedADFs', JSON.stringify(selectedADFs));
  }, [selectedADFs]);

  // Fetch participants (inactive or all based on active toggle)
  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['participants-view', groupByCourse, filters, showActiveOnly, activeDaysThreshold],
    queryFn: async () => {
      // When showing active users, fetch all participants
      if (showActiveOnly) {
        // Fetch all participants with a reasonable limit
        const response = await api.get('/participants/', {
          params: {
            skip: 0,
            limit: 1000 // Reasonable limit to get participants
          }
        });

        const allParticipants = response.data.participants || [];

        // For flat view, expand each participant into their courses
        let flatParticipants = [];
        if (!groupByCourse) {
          allParticipants.forEach(participant => {
            if (participant.courses && participant.courses.length > 0) {
              // Create one entry per course
              participant.courses.forEach(course => {
                flatParticipants.push({
                  ...participant,
                  course_id: course.course_id,
                  course_title: course.course_title,
                  current_progression: course.progression || 0,
                  inactivity_status: 'active' // Default status for active view
                });
              });
            } else {
              // Participant with no courses
              flatParticipants.push({
                ...participant,
                inactivity_status: 'active'
              });
            }
          });
        }

        // For grouped view, organize by course
        let byCourse = null;
        if (groupByCourse) {
          const coursesMap = new Map();

          allParticipants.forEach(participant => {
            if (participant.courses && participant.courses.length > 0) {
              participant.courses.forEach(course => {
                if (!coursesMap.has(course.course_id)) {
                  coursesMap.set(course.course_id, {
                    course_id: course.course_id,
                    course_title: course.course_title,
                    participants: [],
                    total_inactive: 0,
                    at_risk_count: 0,
                    stalled_count: 0,
                    long_inactive_count: 0
                  });
                }

                coursesMap.get(course.course_id).participants.push({
                  ...participant,
                  course_id: course.course_id,
                  current_progression: course.progression || 0,
                  inactivity_status: 'active'
                });
              });
            }
          });

          byCourse = Array.from(coursesMap.values()).map(course => ({
            ...course,
            total_inactive: course.participants.length
          }));
        }

        // Transform the response to match the expected format
        return {
          participants: flatParticipants,
          total_inactive: allParticipants.length,
          at_risk_count: 0,
          stalled_count: 0,
          long_inactive_count: 0,
          by_course: byCourse
        };
      }

      // Otherwise, fetch inactive participants as before
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
      case 'active':
        return 'bg-green-100 text-green-800 border-green-200';
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
      case 'active':
        return <CheckCircle2 size={16} className="text-green-600" />;
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
      case 'active':
        return t('common.active');
      default:
        return status;
    }
  };

  // Helper to calculate days_inactive from participant's last_activity
  const calculateDaysInactive = (participant) => {
    // If days_inactive is already provided (from inactive endpoint), use it
    if (participant.days_inactive !== undefined) {
      return participant.days_inactive;
    }

    // Otherwise, calculate from courses' last_activity (for all participants endpoint)
    if (!participant.courses || participant.courses.length === 0) return Infinity;

    const lastActivities = participant.courses
      .map(c => c.last_activity)
      .filter(Boolean)
      .map(date => new Date(date));

    if (lastActivities.length === 0) return Infinity;

    const lastActivity = new Date(Math.max(...lastActivities));
    const now = new Date();
    const diffTime = Math.abs(now - lastActivity);
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  };

  // Filter and sort participants
  const filterAndSortParticipants = (participants) => {
    if (!participants) return [];

    let filtered = participants;

    // Apply ADF filter if any ADFs are selected
    if (selectedADFs.length > 0) {
      filtered = filtered.filter(p => selectedADFs.includes(p.id_action_formation));
    }

    // Active users toggle overrides status filters (but not ADF filter)
    if (showActiveOnly) {
      // Only apply the active days threshold, ignore status filters
      filtered = filtered.filter(p => {
        const daysInactive = calculateDaysInactive(p);
        return daysInactive <= activeDaysThreshold;
      });
    } else {
      // Apply status filter only when active toggle is OFF
      filtered = filtered.filter(p => statusFilter[p.inactivity_status]);
    }

    // Sort participants
    const sortMultiplier = sortDirection === 'asc' ? 1 : -1;

    filtered.sort((a, b) => {
      let comparison = 0;

      switch (sortBy) {
        case 'inactivity':
          // Most recent (lower days_inactive) first when desc, oldest when asc
          const daysInactiveA = calculateDaysInactive(a);
          const daysInactiveB = calculateDaysInactive(b);
          comparison = (daysInactiveA - daysInactiveB) * -1;
          break;
        case 'name':
          comparison = `${a.nom} ${a.prenom}`.localeCompare(`${b.nom} ${b.prenom}`);
          break;
        case 'progression':
          const progressionA = a.current_progression || a.overall_progression || 0;
          const progressionB = b.current_progression || b.overall_progression || 0;
          comparison = progressionA - progressionB;
          break;
        case 'status':
          const statusOrder = { 'long_inactive': 3, 'stalled': 2, 'at_risk': 1 };
          comparison = (statusOrder[a.inactivity_status] || 0) - (statusOrder[b.inactivity_status] || 0);
          break;
        default:
          comparison = 0;
      }

      return comparison * sortMultiplier;
    });

    return filtered;
  };

  const toggleSort = (field) => {
    if (sortBy === field) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc');
    } else {
      setSortBy(field);
      setSortDirection('desc');
    }
  };

  const toggleStatusFilter = (status) => {
    setStatusFilter({
      ...statusFilter,
      [status]: !statusFilter[status]
    });
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

        {/* Sorting, Status Filter, and Active Users Controls */}
        <div className="bg-white rounded-lg border border-gray-200 p-6 mb-6">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Sorting */}
            <div>
              <h3 className="text-sm font-semibold text-gray-900 mb-3 flex items-center gap-2">
                <ArrowUpDown size={16} />
                {t('inactiveManagement.sorting.title')}
              </h3>
              <div className="space-y-2">
                <button
                  onClick={() => toggleSort('inactivity')}
                  className={`w-full flex items-center justify-between px-3 py-2 rounded-lg border transition-colors ${
                    sortBy === 'inactivity' ? 'bg-primary-50 border-primary-200 text-primary-700' : 'bg-white border-gray-200 text-gray-700 hover:bg-gray-50'
                  }`}
                >
                  <span className="text-sm font-medium">{t('inactiveManagement.sorting.byInactivity')}</span>
                  {sortBy === 'inactivity' && (
                    sortDirection === 'desc' ? <ArrowDown size={16} /> : <ArrowUp size={16} />
                  )}
                </button>
                <button
                  onClick={() => toggleSort('name')}
                  className={`w-full flex items-center justify-between px-3 py-2 rounded-lg border transition-colors ${
                    sortBy === 'name' ? 'bg-primary-50 border-primary-200 text-primary-700' : 'bg-white border-gray-200 text-gray-700 hover:bg-gray-50'
                  }`}
                >
                  <span className="text-sm font-medium">{t('inactiveManagement.sorting.byName')}</span>
                  {sortBy === 'name' && (
                    sortDirection === 'desc' ? <ArrowDown size={16} /> : <ArrowUp size={16} />
                  )}
                </button>
                <button
                  onClick={() => toggleSort('progression')}
                  className={`w-full flex items-center justify-between px-3 py-2 rounded-lg border transition-colors ${
                    sortBy === 'progression' ? 'bg-primary-50 border-primary-200 text-primary-700' : 'bg-white border-gray-200 text-gray-700 hover:bg-gray-50'
                  }`}
                >
                  <span className="text-sm font-medium">{t('inactiveManagement.sorting.byProgression')}</span>
                  {sortBy === 'progression' && (
                    sortDirection === 'desc' ? <ArrowDown size={16} /> : <ArrowUp size={16} />
                  )}
                </button>
                <button
                  onClick={() => toggleSort('status')}
                  className={`w-full flex items-center justify-between px-3 py-2 rounded-lg border transition-colors ${
                    sortBy === 'status' ? 'bg-primary-50 border-primary-200 text-primary-700' : 'bg-white border-gray-200 text-gray-700 hover:bg-gray-50'
                  }`}
                >
                  <span className="text-sm font-medium">{t('inactiveManagement.sorting.byStatus')}</span>
                  {sortBy === 'status' && (
                    sortDirection === 'desc' ? <ArrowDown size={16} /> : <ArrowUp size={16} />
                  )}
                </button>
              </div>
            </div>

            {/* Status Filter */}
            <div className={showActiveOnly ? 'opacity-50 pointer-events-none' : ''}>
              <h3 className="text-sm font-semibold text-gray-900 mb-3 flex items-center gap-2">
                <Filter size={16} />
                {t('inactiveManagement.statusFilter.title')}
              </h3>
              {showActiveOnly && (
                <p className="text-xs text-gray-500 mb-2 italic">
                  {t('inactiveManagement.statusFilter.disabledWhenActive')}
                </p>
              )}
              <div className="space-y-2">
                <label className="flex items-center gap-2 px-3 py-2 rounded-lg border border-gray-200 hover:bg-gray-50 cursor-pointer transition-colors">
                  <input
                    type="checkbox"
                    checked={statusFilter.at_risk}
                    onChange={() => toggleStatusFilter('at_risk')}
                    disabled={showActiveOnly}
                    className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500"
                  />
                  <AlertTriangle size={14} className="text-yellow-600" />
                  <span className="text-sm font-medium text-gray-700">{t('inactiveManagement.status.atRisk')}</span>
                </label>
                <label className="flex items-center gap-2 px-3 py-2 rounded-lg border border-gray-200 hover:bg-gray-50 cursor-pointer transition-colors">
                  <input
                    type="checkbox"
                    checked={statusFilter.stalled}
                    onChange={() => toggleStatusFilter('stalled')}
                    disabled={showActiveOnly}
                    className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500"
                  />
                  <Clock size={14} className="text-orange-600" />
                  <span className="text-sm font-medium text-gray-700">{t('inactiveManagement.status.stalled')}</span>
                </label>
                <label className="flex items-center gap-2 px-3 py-2 rounded-lg border border-gray-200 hover:bg-gray-50 cursor-pointer transition-colors">
                  <input
                    type="checkbox"
                    checked={statusFilter.long_inactive}
                    onChange={() => toggleStatusFilter('long_inactive')}
                    disabled={showActiveOnly}
                    className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500"
                  />
                  <UserX size={14} className="text-red-600" />
                  <span className="text-sm font-medium text-gray-700">{t('inactiveManagement.status.longInactive')}</span>
                </label>
              </div>
            </div>

            {/* Active Users Toggle */}
            <div>
              <h3 className="text-sm font-semibold text-gray-900 mb-3 flex items-center gap-2">
                <CheckCircle2 size={16} />
                {t('inactiveManagement.activeFilter.title')}
              </h3>
              <label className="flex items-center gap-2 px-3 py-2 rounded-lg border border-gray-200 hover:bg-gray-50 cursor-pointer transition-colors mb-3">
                <input
                  type="checkbox"
                  checked={showActiveOnly}
                  onChange={(e) => setShowActiveOnly(e.target.checked)}
                  className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500"
                />
                <span className="text-sm font-medium text-gray-700">{t('inactiveManagement.activeFilter.showActiveOnly')}</span>
              </label>
              {showActiveOnly && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    {t('inactiveManagement.activeFilter.daysThreshold')}
                  </label>
                  <input
                    type="number"
                    value={activeDaysThreshold}
                    onChange={(e) => setActiveDaysThreshold(parseInt(e.target.value) || 0)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                    min="0"
                    max="365"
                  />
                  <p className="text-xs text-gray-500 mt-1">
                    {t('inactiveManagement.activeFilter.daysThresholdHint')}
                  </p>
                </div>
              )}
            </div>

            {/* ADF Filter */}
            <div>
              <button
                onClick={() => setShowAdfDropdown(!showAdfDropdown)}
                className="w-full flex items-center justify-between px-3 py-2 rounded-lg border border-gray-200 hover:bg-gray-50 transition-colors mb-2"
              >
                <div className="flex items-center gap-2">
                  <BookOpen size={16} className="text-gray-600" />
                  <span className="text-sm font-semibold text-gray-900">Filtrer par formation (ADF)</span>
                  {selectedADFs.length > 0 && (
                    <span className="ml-2 px-2 py-0.5 bg-primary-100 text-primary-700 text-xs font-medium rounded-full">
                      {selectedADFs.length}
                    </span>
                  )}
                </div>
                {showAdfDropdown ? <ChevronDown size={16} /> : <ChevronRight size={16} />}
              </button>

              {/* Collapsible dropdown content */}
              {showAdfDropdown && data && (() => {
                const uniqueADFs = new Set();
                const adfList = [];

                // Extract from flat list or grouped data
                const participants = data.participants || [];
                const courses = data.by_course || [];

                participants.forEach(p => {
                  if (p.id_action_formation && !uniqueADFs.has(p.id_action_formation)) {
                    uniqueADFs.add(p.id_action_formation);
                    adfList.push({
                      id: p.id_action_formation,
                      title: p.course_title
                    });
                  }
                });

                courses.forEach(c => {
                  if (c.id_action_formation && !uniqueADFs.has(c.id_action_formation)) {
                    uniqueADFs.add(c.id_action_formation);
                    adfList.push({
                      id: c.id_action_formation,
                      title: c.course_title
                    });
                  }
                });

                // Filter by search term
                const filteredADFs = adfList.filter(adf =>
                  adf.title.toLowerCase().includes(adfSearchTerm.toLowerCase())
                );

                return (
                  <div className="pl-6 pr-2 space-y-2">
                    {/* Search box */}
                    <input
                      type="text"
                      value={adfSearchTerm}
                      onChange={(e) => setAdfSearchTerm(e.target.value)}
                      placeholder="Rechercher une formation..."
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm"
                    />

                    {/* ADF list with checkboxes */}
                    <div className="max-h-60 overflow-y-auto space-y-2 border border-gray-200 rounded-lg p-2">
                      {filteredADFs.length === 0 ? (
                        <p className="text-sm text-gray-500 text-center py-2">Aucune formation trouvée</p>
                      ) : (
                        <>
                          {/* Select/Deselect all */}
                          <label className="flex items-center gap-2 px-2 py-1.5 rounded hover:bg-gray-50 cursor-pointer transition-colors border-b border-gray-200">
                            <input
                              type="checkbox"
                              checked={selectedADFs.length === adfList.length}
                              onChange={(e) => {
                                if (e.target.checked) {
                                  setSelectedADFs(adfList.map(a => a.id));
                                } else {
                                  setSelectedADFs([]);
                                }
                              }}
                              className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500"
                            />
                            <span className="text-xs font-semibold text-gray-700">
                              {selectedADFs.length === adfList.length ? 'Tout désélectionner' : 'Tout sélectionner'}
                            </span>
                          </label>

                          {filteredADFs.map((adf) => (
                            <label
                              key={adf.id}
                              className="flex items-start gap-2 px-2 py-1.5 rounded hover:bg-gray-50 cursor-pointer transition-colors"
                            >
                              <input
                                type="checkbox"
                                checked={selectedADFs.includes(adf.id)}
                                onChange={(e) => {
                                  if (e.target.checked) {
                                    setSelectedADFs([...selectedADFs, adf.id]);
                                  } else {
                                    setSelectedADFs(selectedADFs.filter(id => id !== adf.id));
                                  }
                                }}
                                className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500 mt-0.5"
                              />
                              <span className="text-xs text-gray-700 leading-tight">{adf.title}</span>
                            </label>
                          ))}
                        </>
                      )}
                    </div>

                    {selectedADFs.length > 0 && (
                      <p className="text-xs text-gray-500 mt-2">
                        {selectedADFs.length} formation{selectedADFs.length > 1 ? 's' : ''} sélectionnée{selectedADFs.length > 1 ? 's' : ''}
                      </p>
                    )}
                  </div>
                );
              })()}
            </div>
          </div>
        </div>

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
                {data.by_course.map((course) => {
                  const filteredParticipants = filterAndSortParticipants(course.participants);
                  if (filteredParticipants.length === 0) return null;

                  return (
                    <div key={course.course_id} className="bg-white rounded-lg border border-gray-200">
                      {/* Course Header */}
                      <div className="px-6 py-4 flex items-center justify-between border-b border-gray-200">
                        <div className="flex items-center gap-4 flex-1">
                          <div className="p-2 bg-primary-100 rounded-lg">
                            <BookOpen size={20} className="text-primary-600" />
                          </div>
                          <div className="text-left flex-1">
                            <Link
                              to={`/courses/${course.course_id}`}
                              className="font-semibold text-gray-900 hover:text-primary-600 transition-colors"
                            >
                              {course.course_title}
                            </Link>
                            <p className="text-sm text-gray-500 mt-1">
                              {t('inactiveManagement.showing')}: {filteredParticipants.length} / {course.total_inactive}
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
                        <button
                          onClick={() => toggleCourse(course.course_id)}
                          className="ml-4 p-1 hover:bg-gray-100 rounded transition-colors"
                        >
                          {expandedCourses.has(course.course_id) ? (
                            <ChevronDown size={20} className="text-gray-400" />
                          ) : (
                            <ChevronRight size={20} className="text-gray-400" />
                          )}
                        </button>
                      </div>

                      {/* Participants List */}
                      {expandedCourses.has(course.course_id) && (
                        <div className="divide-y divide-gray-200">
                          {filteredParticipants.map((participant) => (
                            <div key={participant.id} className="px-6 py-4 hover:bg-gray-50 transition-colors">
                              <div className="flex items-center justify-between">
                                <div className="flex items-center gap-4 flex-1">
                                  <div className={`px-3 py-1 rounded-full text-xs font-medium border flex items-center gap-1 ${getStatusColor(participant.inactivity_status)}`}>
                                    {getStatusIcon(participant.inactivity_status)}
                                    <span>{getStatusLabel(participant.inactivity_status)}</span>
                                  </div>
                                  <div className="flex-1">
                                    <div className="flex items-center gap-2">
                                      <Link
                                        to={`/participants/${participant.id}`}
                                        className="font-medium text-gray-900 hover:text-primary-600 transition-colors"
                                      >
                                        {participant.nom} {participant.prenom}
                                      </Link>
                                      <span className="text-sm text-gray-500">
                                        ({(participant.current_progression || participant.overall_progression || 0).toFixed(1)}%)
                                      </span>
                                    </div>
                                    <div className="flex items-center gap-4 mt-1 text-sm text-gray-600">
                                      <span className="flex items-center gap-1">
                                        <Mail size={14} />
                                        {participant.email}
                                      </span>
                                      <span className="flex items-center gap-1">
                                        <Clock size={14} />
                                        {calculateDaysInactive(participant)} {t('common.daysInactive')}
                                      </span>
                                      {participant.days_since_enrollment && (
                                        <span className="flex items-center gap-1">
                                          <Calendar size={14} />
                                          {t('common.enrolled')} {participant.days_since_enrollment} {t('common.daysAgo')}
                                        </span>
                                      )}
                                      {participant.total_modules > 0 && (
                                        <span className="flex items-center gap-1">
                                          <BookOpen size={14} />
                                          {participant.total_modules} module{participant.total_modules > 1 ? 's' : ''}
                                        </span>
                                      )}
                                      {participant.total_planned_duration_hours > 0 && (
                                        <span className="flex items-center gap-1 text-xs bg-blue-50 text-blue-700 px-2 py-0.5 rounded-full">
                                          <Clock size={12} />
                                          {participant.total_time_spent_hours?.toFixed(0) || 0}h / {participant.total_planned_duration_hours.toFixed(0)}h
                                        </span>
                                      )}
                                    </div>
                                  </div>
                                </div>
                              </div>
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            )}

            {/* Flat List View */}
            {!groupByCourse && data.participants && (
              <div className="bg-white rounded-lg border border-gray-200">
                <div className="divide-y divide-gray-200">
                  {filterAndSortParticipants(data.participants).map((participant) => (
                    <div key={`${participant.id}-${participant.course_id}`} className="px-6 py-4 hover:bg-gray-50 transition-colors">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-4 flex-1">
                          <div className={`px-3 py-1 rounded-full text-xs font-medium border flex items-center gap-1 ${getStatusColor(participant.inactivity_status)}`}>
                            {getStatusIcon(participant.inactivity_status)}
                            <span>{getStatusLabel(participant.inactivity_status)}</span>
                          </div>
                          <div className="flex-1">
                            <div className="flex items-center gap-2">
                              <Link
                                to={`/participants/${participant.id}`}
                                className="font-medium text-gray-900 hover:text-primary-600 transition-colors"
                              >
                                {participant.nom} {participant.prenom}
                              </Link>
                              <span className="text-sm text-gray-500">•</span>
                              {participant.course_title && participant.course_id && (
                                <>
                                  <Link
                                    to={`/courses/${participant.course_id}`}
                                    className="text-sm text-gray-500 hover:text-primary-600 transition-colors"
                                  >
                                    {participant.course_title}
                                  </Link>
                                  <span className="text-sm text-gray-500">•</span>
                                </>
                              )}
                              <span className="text-sm text-gray-500">
                                ({(participant.current_progression || participant.overall_progression || 0).toFixed(1)}%)
                              </span>
                            </div>
                            <div className="flex items-center gap-4 mt-1 text-sm text-gray-600">
                              <span className="flex items-center gap-1">
                                <Mail size={14} />
                                {participant.email}
                              </span>
                              <span className="flex items-center gap-1">
                                <Clock size={14} />
                                {calculateDaysInactive(participant)} {t('common.daysInactive')}
                              </span>
                              {participant.days_since_enrollment && (
                                <span className="flex items-center gap-1">
                                  <Calendar size={14} />
                                  {t('common.enrolled')} {participant.days_since_enrollment} {t('common.daysAgo')}
                                </span>
                              )}
                              {participant.total_modules > 0 && (
                                <span className="flex items-center gap-1">
                                  <BookOpen size={14} />
                                  {participant.total_modules} module{participant.total_modules > 1 ? 's' : ''}
                                </span>
                              )}
                              {participant.total_planned_duration_hours > 0 && (
                                <span className="flex items-center gap-1 text-xs bg-blue-50 text-blue-700 px-2 py-0.5 rounded-full">
                                  <Clock size={12} />
                                  {participant.total_time_spent_hours?.toFixed(0) || 0}h / {participant.total_planned_duration_hours.toFixed(0)}h
                                </span>
                              )}
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

import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import {
  UserX,
  User,
  AlertTriangle,
  Clock,
  BookOpen,
  Calendar,
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
    if (cached) {
      const parsed = JSON.parse(cached);
      // Migrate old filter format
      return {
        atRiskThreshold: parsed.atRiskThreshold || 14,
        inactivityThreshold: parsed.inactivityThreshold || 30,
        excludeRecentDays: parsed.excludeRecentDays || 7,
        minProgression: parsed.minProgression ?? null,
        maxProgression: parsed.maxProgression ?? null,
        courseId: parsed.courseId ?? null
      };
    }
    return {
      atRiskThreshold: 14,
      inactivityThreshold: 30,
      excludeRecentDays: 7,
      minProgression: null,
      maxProgression: null,
      courseId: null
    };
  });

  const [showFilters, setShowFilters] = useState(false);
  const [expandedCourses, setExpandedCourses] = useState(new Set());

  const [sortBy, setSortBy] = useState(() => {
    const cached = localStorage.getItem('inactiveManagement.sortBy');
    return cached || 'inactivity';
  });

  const [sortDirection, setSortDirection] = useState(() => {
    const cached = localStorage.getItem('inactiveManagement.sortDirection');
    return cached || 'desc';
  });

  const [statusFilter, setStatusFilter] = useState(() => {
    const cached = localStorage.getItem('inactiveManagement.statusFilter');
    if (cached) {
      const parsed = JSON.parse(cached);
      // Migrate old format if needed
      if ('stalled' in parsed || 'long_inactive' in parsed) {
        return { active: true, at_risk: true, inactive: true };
      }
      return parsed;
    }
    return { active: true, at_risk: true, inactive: true };
  });

  // ADF filter state
  const [selectedADFs, setSelectedADFs] = useState(() => {
    const cached = localStorage.getItem('inactiveManagement.selectedADFs');
    return cached ? JSON.parse(cached) : [];
  });

  const [adfSearchTerm, setAdfSearchTerm] = useState('');
  const [showAdfDropdown, setShowAdfDropdown] = useState(false);

  // Formateur filter state
  const [selectedFormateurs, setSelectedFormateurs] = useState(() => {
    const cached = localStorage.getItem('inactiveManagement.selectedFormateurs');
    return cached ? JSON.parse(cached) : [];
  });

  const [formateurSearchTerm, setFormateurSearchTerm] = useState('');
  const [showFormateurDropdown, setShowFormateurDropdown] = useState(false);

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
    localStorage.setItem('inactiveManagement.selectedADFs', JSON.stringify(selectedADFs));
  }, [selectedADFs]);

  useEffect(() => {
    localStorage.setItem('inactiveManagement.selectedFormateurs', JSON.stringify(selectedFormateurs));
  }, [selectedFormateurs]);

  // Clean up old localStorage keys from removed active user toggle
  useEffect(() => {
    localStorage.removeItem('inactiveManagement.showActiveOnly');
    localStorage.removeItem('inactiveManagement.activeDaysThreshold');
  }, []);

  // Fetch participants
  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['participants-view', groupByCourse, filters],
    queryFn: async () => {
      const params = new URLSearchParams({
        group_by_course: groupByCourse,
        at_risk_threshold_days: filters.atRiskThreshold,
        inactivity_threshold_days: filters.inactivityThreshold,
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
    staleTime: 60000,
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

  const formatDate = (dateString) => {
    if (!dateString) return t('common.never');
    return new Date(dateString).toLocaleDateString();
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'active':
        return 'bg-green-100 text-green-800 border-green-200';
      case 'at_risk':
        return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'inactive':
        return 'bg-red-100 text-red-800 border-red-200';
      default:
        return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const getStatusIcon = (status) => {
    switch (status) {
      case 'active':
        return <CheckCircle2 size={16} className="text-green-600" />;
      case 'at_risk':
        return <AlertTriangle size={16} className="text-yellow-600" />;
      case 'inactive':
        return <UserX size={16} className="text-red-600" />;
      default:
        return <Clock size={16} className="text-gray-600" />;
    }
  };

  const getStatusLabel = (status) => {
    switch (status) {
      case 'active':
        return t('inactiveManagement.status.active');
      case 'at_risk':
        return t('inactiveManagement.status.atRisk');
      case 'inactive':
        return t('inactiveManagement.status.inactive');
      default:
        return status;
    }
  };

  // Filter and sort participants
  const filterAndSortParticipants = (participants) => {
    if (!participants) return [];

    let filtered = participants;

    // Apply ADF filter
    if (selectedADFs.length > 0) {
      filtered = filtered.filter(p => selectedADFs.includes(p.id_action_formation));
    }

    // Apply Formateur filter
    if (selectedFormateurs.length > 0) {
      filtered = filtered.filter(p => {
        if (!p.formateurs || p.formateurs.length === 0) return false;
        return p.formateurs.some(formateur =>
          selectedFormateurs.includes(formateur.id_formateur)
        );
      });
    }

    // Apply status filter
    filtered = filtered.filter(p => statusFilter[p.inactivity_status]);

    // Sort participants
    const sortMultiplier = sortDirection === 'asc' ? 1 : -1;

    filtered.sort((a, b) => {
      let comparison = 0;

      switch (sortBy) {
        case 'inactivity':
          comparison = ((a.days_inactive || 0) - (b.days_inactive || 0)) * -1;
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
          const statusOrder = { 'inactive': 3, 'at_risk': 2, 'active': 1 };
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

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
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
                  {t('inactiveManagement.filters.inactiveThreshold')}
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

        {/* Sorting, Status Filter, ADF/Formateur Filters */}
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
            <div>
              <h3 className="text-sm font-semibold text-gray-900 mb-3 flex items-center gap-2">
                <Filter size={16} />
                {t('inactiveManagement.statusFilter.title')}
              </h3>
              <div className="space-y-2">
                <label className="flex items-center gap-2 px-3 py-2 rounded-lg border border-gray-200 hover:bg-gray-50 cursor-pointer transition-colors">
                  <input
                    type="checkbox"
                    checked={statusFilter.active}
                    onChange={() => toggleStatusFilter('active')}
                    className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500"
                  />
                  <CheckCircle2 size={14} className="text-green-600" />
                  <span className="text-sm font-medium text-gray-700">{t('inactiveManagement.status.active')}</span>
                </label>
                <label className="flex items-center gap-2 px-3 py-2 rounded-lg border border-gray-200 hover:bg-gray-50 cursor-pointer transition-colors">
                  <input
                    type="checkbox"
                    checked={statusFilter.at_risk}
                    onChange={() => toggleStatusFilter('at_risk')}
                    className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500"
                  />
                  <AlertTriangle size={14} className="text-yellow-600" />
                  <span className="text-sm font-medium text-gray-700">{t('inactiveManagement.status.atRisk')}</span>
                </label>
                <label className="flex items-center gap-2 px-3 py-2 rounded-lg border border-gray-200 hover:bg-gray-50 cursor-pointer transition-colors">
                  <input
                    type="checkbox"
                    checked={statusFilter.inactive}
                    onChange={() => toggleStatusFilter('inactive')}
                    className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500"
                  />
                  <UserX size={14} className="text-red-600" />
                  <span className="text-sm font-medium text-gray-700">{t('inactiveManagement.status.inactive')}</span>
                </label>
              </div>
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

              {showAdfDropdown && data && (() => {
                const uniqueADFs = new Set();
                const adfList = [];

                const participants = data.participants || [];
                const courses = data.by_course || [];

                participants.forEach(p => {
                  if (p.id_action_formation && !uniqueADFs.has(p.id_action_formation)) {
                    uniqueADFs.add(p.id_action_formation);
                    adfList.push({ id: p.id_action_formation, title: p.course_title });
                  }
                });

                courses.forEach(c => {
                  if (c.id_action_formation && !uniqueADFs.has(c.id_action_formation)) {
                    uniqueADFs.add(c.id_action_formation);
                    adfList.push({ id: c.id_action_formation, title: c.course_title });
                  }
                });

                const filteredADFs = adfList.filter(adf =>
                  adf.title.toLowerCase().includes(adfSearchTerm.toLowerCase())
                );

                return (
                  <div className="pl-6 pr-2 space-y-2">
                    <input
                      type="text"
                      value={adfSearchTerm}
                      onChange={(e) => setAdfSearchTerm(e.target.value)}
                      placeholder="Rechercher une formation..."
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm"
                    />
                    <div className="max-h-60 overflow-y-auto space-y-2 border border-gray-200 rounded-lg p-2">
                      {filteredADFs.length === 0 ? (
                        <p className="text-sm text-gray-500 text-center py-2">Aucune formation trouvée</p>
                      ) : (
                        <>
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
                            <label key={adf.id} className="flex items-start gap-2 px-2 py-1.5 rounded hover:bg-gray-50 cursor-pointer transition-colors">
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

            {/* Formateur Filter */}
            <div>
              <button
                onClick={() => setShowFormateurDropdown(!showFormateurDropdown)}
                className="w-full flex items-center justify-between px-3 py-2 rounded-lg border border-gray-200 hover:bg-gray-50 transition-colors mb-2"
              >
                <div className="flex items-center gap-2">
                  <User size={16} className="text-gray-600" />
                  <span className="text-sm font-semibold text-gray-900">Filtrer par formateur</span>
                  {selectedFormateurs.length > 0 && (
                    <span className="ml-2 px-2 py-0.5 bg-primary-100 text-primary-700 text-xs font-medium rounded-full">
                      {selectedFormateurs.length}
                    </span>
                  )}
                </div>
                {showFormateurDropdown ? <ChevronDown size={16} /> : <ChevronRight size={16} />}
              </button>

              {showFormateurDropdown && data && (() => {
                const uniqueFormateurs = new Map();

                const participants = data.participants || [];
                const courses = data.by_course || [];

                participants.forEach(p => {
                  if (p.formateurs && Array.isArray(p.formateurs)) {
                    p.formateurs.forEach(formateur => {
                      if (formateur.id_formateur && !uniqueFormateurs.has(formateur.id_formateur)) {
                        uniqueFormateurs.set(formateur.id_formateur, {
                          id: formateur.id_formateur,
                          nom: formateur.nom || '',
                          prenom: formateur.prenom || '',
                          fullName: `${formateur.prenom || ''} ${formateur.nom || ''}`.trim()
                        });
                      }
                    });
                  }
                });

                courses.forEach(c => {
                  if (c.participants && Array.isArray(c.participants)) {
                    c.participants.forEach(p => {
                      if (p.formateurs && Array.isArray(p.formateurs)) {
                        p.formateurs.forEach(formateur => {
                          if (formateur.id_formateur && !uniqueFormateurs.has(formateur.id_formateur)) {
                            uniqueFormateurs.set(formateur.id_formateur, {
                              id: formateur.id_formateur,
                              nom: formateur.nom || '',
                              prenom: formateur.prenom || '',
                              fullName: `${formateur.prenom || ''} ${formateur.nom || ''}`.trim()
                            });
                          }
                        });
                      }
                    });
                  }
                });

                const formateurList = Array.from(uniqueFormateurs.values());
                const filteredFormateurs = formateurList.filter(formateur =>
                  formateur.fullName.toLowerCase().includes(formateurSearchTerm.toLowerCase())
                );

                return (
                  <div className="pl-6 pr-2 space-y-2">
                    <input
                      type="text"
                      value={formateurSearchTerm}
                      onChange={(e) => setFormateurSearchTerm(e.target.value)}
                      placeholder="Rechercher un formateur..."
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm"
                    />
                    <div className="max-h-60 overflow-y-auto space-y-2 border border-gray-200 rounded-lg p-2">
                      {filteredFormateurs.length === 0 ? (
                        <p className="text-sm text-gray-500 text-center py-2">Aucun formateur trouvé</p>
                      ) : (
                        <>
                          <label className="flex items-center gap-2 px-2 py-1.5 rounded hover:bg-gray-50 cursor-pointer transition-colors border-b border-gray-200">
                            <input
                              type="checkbox"
                              checked={selectedFormateurs.length === formateurList.length}
                              onChange={(e) => {
                                if (e.target.checked) {
                                  setSelectedFormateurs(formateurList.map(f => f.id));
                                } else {
                                  setSelectedFormateurs([]);
                                }
                              }}
                              className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500"
                            />
                            <span className="text-xs font-semibold text-gray-700">
                              {selectedFormateurs.length === formateurList.length ? 'Tout désélectionner' : 'Tout sélectionner'}
                            </span>
                          </label>
                          {filteredFormateurs.map((formateur) => (
                            <label key={formateur.id} className="flex items-start gap-2 px-2 py-1.5 rounded hover:bg-gray-50 cursor-pointer transition-colors">
                              <input
                                type="checkbox"
                                checked={selectedFormateurs.includes(formateur.id)}
                                onChange={(e) => {
                                  if (e.target.checked) {
                                    setSelectedFormateurs([...selectedFormateurs, formateur.id]);
                                  } else {
                                    setSelectedFormateurs(selectedFormateurs.filter(id => id !== formateur.id));
                                  }
                                }}
                                className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500 mt-0.5"
                              />
                              <span className="text-xs text-gray-700 leading-tight">{formateur.fullName || 'Formateur sans nom'}</span>
                            </label>
                          ))}
                        </>
                      )}
                    </div>
                    {selectedFormateurs.length > 0 && (
                      <p className="text-xs text-gray-500 mt-2">
                        {selectedFormateurs.length} formateur{selectedFormateurs.length > 1 ? 's' : ''} sélectionné{selectedFormateurs.length > 1 ? 's' : ''}
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
                    <p className="text-sm text-gray-600">{t('inactiveManagement.stats.total')}</p>
                    <p className="text-3xl font-bold text-gray-900 mt-2">{data.total_participants}</p>
                  </div>
                  <div className="p-3 bg-gray-100 rounded-lg">
                    <User size={24} className="text-gray-600" />
                  </div>
                </div>
              </div>

              <div className="bg-white rounded-lg border border-green-200 p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-green-700">{t('inactiveManagement.stats.active')}</p>
                    <p className="text-3xl font-bold text-green-900 mt-2">{data.active_count}</p>
                  </div>
                  <div className="p-3 bg-green-100 rounded-lg">
                    <CheckCircle2 size={24} className="text-green-600" />
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

              <div className="bg-white rounded-lg border border-red-200 p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-red-700">{t('inactiveManagement.stats.inactive')}</p>
                    <p className="text-3xl font-bold text-red-900 mt-2">{data.inactive_count}</p>
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
                              {t('inactiveManagement.showing')}: {filteredParticipants.length} / {course.total_participants}
                            </p>
                          </div>
                          <div className="flex items-center gap-3">
                            <span className="px-3 py-1 bg-green-100 text-green-800 rounded-full text-sm font-medium">
                              {course.active_count} {t('inactiveManagement.status.active')}
                            </span>
                            <span className="px-3 py-1 bg-yellow-100 text-yellow-800 rounded-full text-sm font-medium">
                              {course.at_risk_count} {t('inactiveManagement.status.atRisk')}
                            </span>
                            <span className="px-3 py-1 bg-red-100 text-red-800 rounded-full text-sm font-medium">
                              {course.inactive_count} {t('inactiveManagement.status.inactive')}
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
                                        <Calendar size={14} />
                                        Ajouté: {formatDate(participant.enrollment_date)}
                                      </span>
                                      <span className="flex items-center gap-1">
                                        <Clock size={14} />
                                        {participant.days_inactive || 0} {t('common.daysInactive')}
                                      </span>
                                      {participant.total_planned_duration_hours > 0 && (
                                        <span className="flex items-center gap-1 text-xs bg-blue-50 text-blue-700 px-2 py-0.5 rounded-full">
                                          <Clock size={12} />
                                          {participant.total_time_spent_hours?.toFixed(0) || 0}h / {participant.total_planned_duration_hours.toFixed(0)}h
                                        </span>
                                      )}
                                      {participant.formateurs && participant.formateurs.length > 0 && (
                                        <span
                                          className="flex items-center gap-1 text-xs bg-purple-50 text-purple-700 px-2 py-0.5 rounded-full cursor-default"
                                          title={participant.formateurs.map(f => `${f.prenom || ''} ${f.nom || ''}`.trim()).join(', ')}
                                        >
                                          <User size={12} />
                                          {participant.formateurs.length} formateur{participant.formateurs.length > 1 ? 's' : ''}
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
                                <Calendar size={14} />
                                Ajouté: {formatDate(participant.enrollment_date)}
                              </span>
                              <span className="flex items-center gap-1">
                                <Clock size={14} />
                                {participant.days_inactive || 0} {t('common.daysInactive')}
                              </span>
                              {participant.total_planned_duration_hours > 0 && (
                                <span className="flex items-center gap-1 text-xs bg-blue-50 text-blue-700 px-2 py-0.5 rounded-full">
                                  <Clock size={12} />
                                  {participant.total_time_spent_hours?.toFixed(0) || 0}h / {participant.total_planned_duration_hours.toFixed(0)}h
                                </span>
                              )}
                              {participant.formateurs && participant.formateurs.length > 0 && (
                                <span
                                  className="flex items-center gap-1 text-xs bg-purple-50 text-purple-700 px-2 py-0.5 rounded-full cursor-default"
                                  title={participant.formateurs.map(f => `${f.prenom || ''} ${f.nom || ''}`.trim()).join(', ')}
                                >
                                  <User size={12} />
                                  {participant.formateurs.length} formateur{participant.formateurs.length > 1 ? 's' : ''}
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
            {data.total_participants === 0 && (
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

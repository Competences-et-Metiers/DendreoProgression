import React, { useState, useEffect, useMemo } from 'react';
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
  CheckCircle2,
  X,
  Download,
  Search
} from 'lucide-react';
import api from '../services/api';
import { generateInactivityReport } from '../utils/pdfExport';

const InactiveManagement = () => {
  const { t, i18n } = useTranslation();

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
        excludeRecentDays: parsed.excludeRecentDays ?? 0,
        minProgression: parsed.minProgression ?? null,
        maxProgression: parsed.maxProgression ?? null,
        courseId: parsed.courseId ?? null
      };
    }
    return {
      atRiskThreshold: 14,
      inactivityThreshold: 30,
      excludeRecentDays: 0,
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

  // Category filter state
  const [selectedCategories, setSelectedCategories] = useState(() => {
    const cached = localStorage.getItem('inactiveManagement.selectedCategories');
    return cached ? JSON.parse(cached) : [];
  });

  const [categorySearchTerm, setCategorySearchTerm] = useState('');
  const [showCategoryDropdown, setShowCategoryDropdown] = useState(false);

  // Global search
  const [searchTerm, setSearchTerm] = useState('');

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

  useEffect(() => {
    localStorage.setItem('inactiveManagement.selectedCategories', JSON.stringify(selectedCategories));
  }, [selectedCategories]);

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

    // Apply Category filter
    if (selectedCategories.length > 0) {
      filtered = filtered.filter(p => p.category_name && selectedCategories.includes(p.category_name));
    }

    // Apply global search
    if (searchTerm.trim()) {
      const term = searchTerm.toLowerCase().trim();
      filtered = filtered.filter(p => {
        const name = `${p.nom || ''} ${p.prenom || ''}`.toLowerCase();
        const courseTitle = (p.course_title || '').toLowerCase();
        const category = (p.category_name || '').toLowerCase();
        return name.includes(term) || courseTitle.includes(term) || category.includes(term);
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

  // Compute stats from client-side filtered data (ADF + formateur filters, ignoring status filter)
  const filteredStats = useMemo(() => {
    if (!data) return { total: 0, active: 0, at_risk: 0, inactive: 0 };

    // Collect all participants from either view mode
    let allParticipants = [];
    if (data.participants) {
      allParticipants = data.participants;
    } else if (data.by_course) {
      data.by_course.forEach(course => {
        if (course.participants) {
          allParticipants = allParticipants.concat(course.participants);
        }
      });
    }

    // Apply ADF filter
    if (selectedADFs.length > 0) {
      allParticipants = allParticipants.filter(p => selectedADFs.includes(p.id_action_formation));
    }

    // Apply formateur filter
    if (selectedFormateurs.length > 0) {
      allParticipants = allParticipants.filter(p => {
        if (!p.formateurs || p.formateurs.length === 0) return false;
        return p.formateurs.some(f => selectedFormateurs.includes(f.id_formateur));
      });
    }

    // Apply category filter
    if (selectedCategories.length > 0) {
      allParticipants = allParticipants.filter(p => p.category_name && selectedCategories.includes(p.category_name));
    }

    // Apply global search
    if (searchTerm.trim()) {
      const term = searchTerm.toLowerCase().trim();
      allParticipants = allParticipants.filter(p => {
        const name = `${p.nom || ''} ${p.prenom || ''}`.toLowerCase();
        const courseTitle = (p.course_title || '').toLowerCase();
        const category = (p.category_name || '').toLowerCase();
        return name.includes(term) || courseTitle.includes(term) || category.includes(term);
      });
    }

    return {
      total: allParticipants.length,
      active: allParticipants.filter(p => p.inactivity_status === 'active').length,
      at_risk: allParticipants.filter(p => p.inactivity_status === 'at_risk').length,
      inactive: allParticipants.filter(p => p.inactivity_status === 'inactive').length,
    };
  }, [data, selectedADFs, selectedFormateurs, selectedCategories, searchTerm]);

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

  const handleDownloadPDF = async () => {
    if (!data) return;

    // Collect all participants regardless of view mode
    let allParticipants = [];
    if (data.participants) {
      allParticipants = data.participants;
    } else if (data.by_course) {
      data.by_course.forEach(course => {
        if (course.participants) {
          allParticipants = allParticipants.concat(course.participants);
        }
      });
    }

    const filteredParticipants = filterAndSortParticipants(allParticipants);

    // Build active filter descriptions
    const activeFilterDescriptions = [];
    if (searchTerm.trim()) {
      activeFilterDescriptions.push(`${t('common.search')}: "${searchTerm.trim()}"`);
    }
    if (selectedADFs.length > 0) {
      activeFilterDescriptions.push(`${selectedADFs.length} ${t('inactiveManagement.pdf.filterADFs')}`);
    }
    if (selectedFormateurs.length > 0) {
      activeFilterDescriptions.push(`${selectedFormateurs.length} ${t('inactiveManagement.pdf.filterFormateurs')}`);
    }
    if (selectedCategories.length > 0) {
      activeFilterDescriptions.push(`${selectedCategories.length} ${t('inactiveManagement.pdf.filterCategories')}`);
    }

    const disabledStatuses = [];
    if (!statusFilter.active) disabledStatuses.push(t('inactiveManagement.status.active'));
    if (!statusFilter.at_risk) disabledStatuses.push(t('inactiveManagement.status.atRisk'));
    if (!statusFilter.inactive) disabledStatuses.push(t('inactiveManagement.status.inactive'));
    if (disabledStatuses.length > 0) {
      activeFilterDescriptions.push(`${t('inactiveManagement.pdf.filterExcluded')}: ${disabledStatuses.join(', ')}`);
    }

    const lang = i18n.language?.startsWith('fr') ? 'fr' : 'en';

    generateInactivityReport({
      participants: filteredParticipants,
      stats: filteredStats,
      activeFilters: activeFilterDescriptions,
      t,
      lang,
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

              <button
                onClick={handleDownloadPDF}
                disabled={!data || isLoading}
                className="flex items-center gap-2 px-4 py-2 bg-white border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <Download size={18} />
                <span className="font-medium">{t('inactiveManagement.downloadPdf')}</span>
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

        {/* Sorting & Filters */}
        <div className="bg-white rounded-lg border border-gray-200 p-4 mb-6 space-y-4">
          {/* Search Bar */}
          <div className="relative">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder={t('inactiveManagement.searchPlaceholder')}
              className="w-full pl-9 pr-8 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm"
            />
            {searchTerm && (
              <button
                onClick={() => setSearchTerm('')}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
              >
                <X size={14} />
              </button>
            )}
          </div>

          {/* Row 1: Sorting + Status Filter */}
          <div className="flex flex-col lg:flex-row gap-4">
            {/* Sorting - horizontal pills */}
            <div className="flex items-center gap-2 flex-wrap">
              <span className="text-sm font-semibold text-gray-600 flex items-center gap-1 mr-1">
                <ArrowUpDown size={14} />
                {t('inactiveManagement.sorting.title')}
              </span>
              {[
                { key: 'inactivity', label: t('inactiveManagement.sorting.byInactivity') },
                { key: 'name', label: t('inactiveManagement.sorting.byName') },
                { key: 'progression', label: t('inactiveManagement.sorting.byProgression') },
                { key: 'status', label: t('inactiveManagement.sorting.byStatus') },
              ].map(({ key, label }) => (
                <button
                  key={key}
                  onClick={() => toggleSort(key)}
                  className={`flex items-center gap-1 px-3 py-1.5 rounded-full border text-xs font-medium transition-colors ${
                    sortBy === key ? 'bg-primary-50 border-primary-200 text-primary-700' : 'bg-white border-gray-200 text-gray-600 hover:bg-gray-50'
                  }`}
                >
                  {label}
                  {sortBy === key && (
                    sortDirection === 'desc' ? <ArrowDown size={12} /> : <ArrowUp size={12} />
                  )}
                </button>
              ))}
            </div>

            {/* Divider */}
            <div className="hidden lg:block w-px bg-gray-200" />

            {/* Status Filter - horizontal pills */}
            <div className="flex items-center gap-2 flex-wrap">
              <span className="text-sm font-semibold text-gray-600 flex items-center gap-1 mr-1">
                <Filter size={14} />
                Statut
              </span>
              <label className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full border text-xs font-medium cursor-pointer transition-colors ${
                statusFilter.active ? 'bg-green-50 border-green-200 text-green-700' : 'bg-white border-gray-200 text-gray-400'
              }`}>
                <input type="checkbox" checked={statusFilter.active} onChange={() => toggleStatusFilter('active')} className="sr-only" />
                <CheckCircle2 size={12} />
                {t('inactiveManagement.status.active')}
              </label>
              <label className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full border text-xs font-medium cursor-pointer transition-colors ${
                statusFilter.at_risk ? 'bg-yellow-50 border-yellow-200 text-yellow-700' : 'bg-white border-gray-200 text-gray-400'
              }`}>
                <input type="checkbox" checked={statusFilter.at_risk} onChange={() => toggleStatusFilter('at_risk')} className="sr-only" />
                <AlertTriangle size={12} />
                {t('inactiveManagement.status.atRisk')}
              </label>
              <label className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full border text-xs font-medium cursor-pointer transition-colors ${
                statusFilter.inactive ? 'bg-red-50 border-red-200 text-red-700' : 'bg-white border-gray-200 text-gray-400'
              }`}>
                <input type="checkbox" checked={statusFilter.inactive} onChange={() => toggleStatusFilter('inactive')} className="sr-only" />
                <UserX size={12} />
                {t('inactiveManagement.status.inactive')}
              </label>
            </div>

            {/* Remove Filters */}
            {(!statusFilter.active || !statusFilter.at_risk || !statusFilter.inactive || selectedADFs.length > 0 || selectedFormateurs.length > 0 || selectedCategories.length > 0 || searchTerm || filters.atRiskThreshold !== 14 || filters.inactivityThreshold !== 30 || filters.excludeRecentDays !== 0) && (
              <>
                <div className="hidden lg:block w-px bg-gray-200" />
                <button
                  onClick={() => {
                    setStatusFilter({ active: true, at_risk: true, inactive: true });
                    setSelectedADFs([]);
                    setSelectedFormateurs([]);
                    setSelectedCategories([]);
                    setSearchTerm('');
                    setFilters(f => ({ ...f, atRiskThreshold: 14, inactivityThreshold: 30, excludeRecentDays: 0 }));
                  }}
                  className="flex items-center gap-1.5 px-3 py-1.5 rounded-full border border-red-200 bg-red-50 text-red-700 text-xs font-medium hover:bg-red-100 transition-colors"
                >
                  <X size={12} />
                  {t('inactiveManagement.removeFilters')}
                </button>
              </>
            )}
          </div>

          {/* Row 2: ADF + Formateur + Category Filters side by side */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 border-t border-gray-100 pt-4">
            {/* ADF Filter */}
            <div>
              <button
                onClick={() => setShowAdfDropdown(!showAdfDropdown)}
                className="w-full flex items-center justify-between px-3 py-2 rounded-lg border border-gray-200 hover:bg-gray-50 transition-colors"
              >
                <div className="flex items-center gap-2">
                  <BookOpen size={16} className="text-gray-600" />
                  <span className="text-sm font-medium text-gray-900">Filtrer par formation (ADF)</span>
                  {selectedADFs.length > 0 && (
                    <span className="px-2 py-0.5 bg-primary-100 text-primary-700 text-xs font-medium rounded-full">
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

                const selectedButHiddenADFs = adfSearchTerm
                  ? adfList.filter(adf => selectedADFs.includes(adf.id) && !adf.title.toLowerCase().includes(adfSearchTerm.toLowerCase()))
                  : [];

                return (
                  <div className="mt-2 space-y-2">
                    <input
                      type="text"
                      value={adfSearchTerm}
                      onChange={(e) => setAdfSearchTerm(e.target.value)}
                      placeholder="Rechercher une formation..."
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm"
                    />
                    {selectedButHiddenADFs.length > 0 && (
                      <div className="space-y-1 border border-primary-200 bg-primary-50/50 rounded-lg p-2">
                        <p className="text-[10px] font-medium text-primary-600 uppercase tracking-wide px-2">Sélectionnées</p>
                        {selectedButHiddenADFs.map((adf) => (
                          <label key={adf.id} className="flex items-start gap-2 px-2 py-1.5 rounded hover:bg-primary-100/50 cursor-pointer transition-colors">
                            <input
                              type="checkbox"
                              checked={true}
                              onChange={() => setSelectedADFs(selectedADFs.filter(id => id !== adf.id))}
                              className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500 mt-0.5"
                            />
                            <span className="text-xs text-primary-700 leading-tight">{adf.title}</span>
                          </label>
                        ))}
                      </div>
                    )}
                    <div className="max-h-48 overflow-y-auto space-y-1 border border-gray-200 rounded-lg p-2">
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
                      <p className="text-xs text-gray-500">
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
                className="w-full flex items-center justify-between px-3 py-2 rounded-lg border border-gray-200 hover:bg-gray-50 transition-colors"
              >
                <div className="flex items-center gap-2">
                  <User size={16} className="text-gray-600" />
                  <span className="text-sm font-medium text-gray-900">Filtrer par formateur</span>
                  {selectedFormateurs.length > 0 && (
                    <span className="px-2 py-0.5 bg-primary-100 text-primary-700 text-xs font-medium rounded-full">
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

                const selectedButHiddenFormateurs = formateurSearchTerm
                  ? formateurList.filter(f => selectedFormateurs.includes(f.id) && !f.fullName.toLowerCase().includes(formateurSearchTerm.toLowerCase()))
                  : [];

                return (
                  <div className="mt-2 space-y-2">
                    <input
                      type="text"
                      value={formateurSearchTerm}
                      onChange={(e) => setFormateurSearchTerm(e.target.value)}
                      placeholder="Rechercher un formateur..."
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm"
                    />
                    {selectedButHiddenFormateurs.length > 0 && (
                      <div className="space-y-1 border border-primary-200 bg-primary-50/50 rounded-lg p-2">
                        <p className="text-[10px] font-medium text-primary-600 uppercase tracking-wide px-2">Sélectionnés</p>
                        {selectedButHiddenFormateurs.map((formateur) => (
                          <label key={formateur.id} className="flex items-start gap-2 px-2 py-1.5 rounded hover:bg-primary-100/50 cursor-pointer transition-colors">
                            <input
                              type="checkbox"
                              checked={true}
                              onChange={() => setSelectedFormateurs(selectedFormateurs.filter(id => id !== formateur.id))}
                              className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500 mt-0.5"
                            />
                            <span className="text-xs text-primary-700 leading-tight">{formateur.fullName || 'Formateur sans nom'}</span>
                          </label>
                        ))}
                      </div>
                    )}
                    <div className="max-h-48 overflow-y-auto space-y-1 border border-gray-200 rounded-lg p-2">
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
                      <p className="text-xs text-gray-500">
                        {selectedFormateurs.length} formateur{selectedFormateurs.length > 1 ? 's' : ''} sélectionné{selectedFormateurs.length > 1 ? 's' : ''}
                      </p>
                    )}
                  </div>
                );
              })()}
            </div>

            {/* Category Filter */}
            <div>
              <button
                onClick={() => setShowCategoryDropdown(!showCategoryDropdown)}
                className="w-full flex items-center justify-between px-3 py-2 rounded-lg border border-gray-200 hover:bg-gray-50 transition-colors"
              >
                <div className="flex items-center gap-2">
                  <Filter size={16} className="text-gray-600" />
                  <span className="text-sm font-medium text-gray-900">{t('inactiveManagement.categoryFilter.title')}</span>
                  {selectedCategories.length > 0 && (
                    <span className="px-2 py-0.5 bg-primary-100 text-primary-700 text-xs font-medium rounded-full">
                      {selectedCategories.length}
                    </span>
                  )}
                </div>
                {showCategoryDropdown ? <ChevronDown size={16} /> : <ChevronRight size={16} />}
              </button>

              {showCategoryDropdown && data && (() => {
                const uniqueCategories = new Map();

                const participants = data.participants || [];
                const courses = data.by_course || [];

                participants.forEach(p => {
                  if (p.category_name && !uniqueCategories.has(p.category_name)) {
                    uniqueCategories.set(p.category_name, {
                      name: p.category_name,
                      color: p.category_color || ''
                    });
                  }
                });

                courses.forEach(c => {
                  if (c.category_name && !uniqueCategories.has(c.category_name)) {
                    uniqueCategories.set(c.category_name, {
                      name: c.category_name,
                      color: c.category_color || ''
                    });
                  }
                  if (c.participants) {
                    c.participants.forEach(p => {
                      if (p.category_name && !uniqueCategories.has(p.category_name)) {
                        uniqueCategories.set(p.category_name, {
                          name: p.category_name,
                          color: p.category_color || ''
                        });
                      }
                    });
                  }
                });

                const categoryList = Array.from(uniqueCategories.values()).sort((a, b) =>
                  a.name.localeCompare(b.name)
                );

                const filteredCategories = categoryList.filter(cat =>
                  cat.name.toLowerCase().includes(categorySearchTerm.toLowerCase())
                );

                const selectedButHiddenCategories = categorySearchTerm
                  ? categoryList.filter(cat => selectedCategories.includes(cat.name) && !cat.name.toLowerCase().includes(categorySearchTerm.toLowerCase()))
                  : [];

                return (
                  <div className="mt-2 space-y-2">
                    <input
                      type="text"
                      value={categorySearchTerm}
                      onChange={(e) => setCategorySearchTerm(e.target.value)}
                      placeholder={t('inactiveManagement.categoryFilter.searchPlaceholder')}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm"
                    />
                    {selectedButHiddenCategories.length > 0 && (
                      <div className="space-y-1 border border-primary-200 bg-primary-50/50 rounded-lg p-2">
                        <p className="text-[10px] font-medium text-primary-600 uppercase tracking-wide px-2">Sélectionnées</p>
                        {selectedButHiddenCategories.map((cat) => (
                          <label key={cat.name} className="flex items-start gap-2 px-2 py-1.5 rounded hover:bg-primary-100/50 cursor-pointer transition-colors">
                            <input
                              type="checkbox"
                              checked={true}
                              onChange={() => setSelectedCategories(selectedCategories.filter(name => name !== cat.name))}
                              className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500 mt-0.5"
                            />
                            <span className="text-xs text-primary-700 leading-tight flex items-center gap-1.5">
                              {cat.color && (
                                <span
                                  className="inline-block w-2.5 h-2.5 rounded-full flex-shrink-0"
                                  style={{ backgroundColor: `#${cat.color}` }}
                                />
                              )}
                              {cat.name}
                            </span>
                          </label>
                        ))}
                      </div>
                    )}
                    <div className="max-h-48 overflow-y-auto space-y-1 border border-gray-200 rounded-lg p-2">
                      {filteredCategories.length === 0 ? (
                        <p className="text-sm text-gray-500 text-center py-2">{t('inactiveManagement.categoryFilter.noResults')}</p>
                      ) : (
                        <>
                          <label className="flex items-center gap-2 px-2 py-1.5 rounded hover:bg-gray-50 cursor-pointer transition-colors border-b border-gray-200">
                            <input
                              type="checkbox"
                              checked={selectedCategories.length === categoryList.length && categoryList.length > 0}
                              onChange={(e) => {
                                if (e.target.checked) {
                                  setSelectedCategories(categoryList.map(c => c.name));
                                } else {
                                  setSelectedCategories([]);
                                }
                              }}
                              className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500"
                            />
                            <span className="text-xs font-semibold text-gray-700">
                              {selectedCategories.length === categoryList.length && categoryList.length > 0 ? t('inactiveManagement.categoryFilter.deselectAll') : t('inactiveManagement.categoryFilter.selectAll')}
                            </span>
                          </label>
                          {filteredCategories.map((cat) => (
                            <label key={cat.name} className="flex items-start gap-2 px-2 py-1.5 rounded hover:bg-gray-50 cursor-pointer transition-colors">
                              <input
                                type="checkbox"
                                checked={selectedCategories.includes(cat.name)}
                                onChange={(e) => {
                                  if (e.target.checked) {
                                    setSelectedCategories([...selectedCategories, cat.name]);
                                  } else {
                                    setSelectedCategories(selectedCategories.filter(name => name !== cat.name));
                                  }
                                }}
                                className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500 mt-0.5"
                              />
                              <span className="text-xs text-gray-700 leading-tight flex items-center gap-1.5">
                                {cat.color && (
                                  <span
                                    className="inline-block w-2.5 h-2.5 rounded-full flex-shrink-0"
                                    style={{ backgroundColor: `#${cat.color}` }}
                                  />
                                )}
                                {cat.name}
                              </span>
                            </label>
                          ))}
                        </>
                      )}
                    </div>
                    {selectedCategories.length > 0 && (
                      <p className="text-xs text-gray-500">
                        {selectedCategories.length} {t('inactiveManagement.categoryFilter.selectedCount')}
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
                    <p className="text-3xl font-bold text-gray-900 mt-2">{filteredStats.total}</p>
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
                    <p className="text-3xl font-bold text-green-900 mt-2">{filteredStats.active}</p>
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
                    <p className="text-3xl font-bold text-yellow-900 mt-2">{filteredStats.at_risk}</p>
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
                    <p className="text-3xl font-bold text-red-900 mt-2">{filteredStats.inactive}</p>
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
                                      <span
                                        className="group/source flex items-center gap-1"
                                        title={participant.last_activity_source ? `${t('inactiveManagement.lastActivitySource')}: ${t(`inactiveManagement.activitySource.${participant.last_activity_source}`)}` : ''}
                                      >
                                        <Clock size={14} />
                                        {participant.days_inactive || 0} {t('common.daysInactive')}
                                        {participant.last_activity_source && (
                                          <span className={`opacity-0 group-hover/source:opacity-100 transition-opacity inline-flex items-center ml-1 px-1.5 py-0.5 rounded text-[10px] font-medium ${
                                            participant.last_activity_source === 'elearning'
                                              ? 'bg-blue-50 text-blue-600'
                                              : 'bg-violet-50 text-violet-600'
                                          }`}>
                                            {t(`inactiveManagement.activitySource.${participant.last_activity_source}`)}
                                          </span>
                                        )}
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
                                      {participant.category_name && (
                                        <span
                                          className="flex items-center gap-1 text-xs px-2 py-0.5 rounded-full cursor-default"
                                          style={{
                                            backgroundColor: participant.category_color ? `#${participant.category_color}20` : '#f3f4f6',
                                            color: participant.category_color ? `#${participant.category_color}` : '#6b7280'
                                          }}
                                        >
                                          {participant.category_color && (
                                            <span
                                              className="inline-block w-2 h-2 rounded-full flex-shrink-0"
                                              style={{ backgroundColor: `#${participant.category_color}` }}
                                            />
                                          )}
                                          {participant.category_name}
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
                              <span
                                className="group/source flex items-center gap-1"
                                title={participant.last_activity_source ? `${t('inactiveManagement.lastActivitySource')}: ${t(`inactiveManagement.activitySource.${participant.last_activity_source}`)}` : ''}
                              >
                                <Clock size={14} />
                                {participant.days_inactive || 0} {t('common.daysInactive')}
                                {participant.last_activity_source && (
                                  <span className={`opacity-0 group-hover/source:opacity-100 transition-opacity inline-flex items-center ml-1 px-1.5 py-0.5 rounded text-[10px] font-medium ${
                                    participant.last_activity_source === 'elearning'
                                      ? 'bg-blue-50 text-blue-600'
                                      : 'bg-violet-50 text-violet-600'
                                  }`}>
                                    {t(`inactiveManagement.activitySource.${participant.last_activity_source}`)}
                                  </span>
                                )}
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
                              {participant.category_name && (
                                <span
                                  className="flex items-center gap-1 text-xs px-2 py-0.5 rounded-full cursor-default"
                                  style={{
                                    backgroundColor: participant.category_color ? `#${participant.category_color}20` : '#f3f4f6',
                                    color: participant.category_color ? `#${participant.category_color}` : '#6b7280'
                                  }}
                                >
                                  {participant.category_color && (
                                    <span
                                      className="inline-block w-2 h-2 rounded-full flex-shrink-0"
                                      style={{ backgroundColor: `#${participant.category_color}` }}
                                    />
                                  )}
                                  {participant.category_name}
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

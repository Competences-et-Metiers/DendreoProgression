import React, { useState, useMemo, useCallback, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import {
  Clock,
  AlertTriangle,
  User,
  Calendar,
  ChevronDown,
  ChevronRight,
  ChevronLeft,
  ChevronsLeft,
  ChevronsRight,
  Target,
  Search,
  BarChart3,
  X,
  BookOpen,
  Filter,
  LayoutList,
  ArrowUpDown,
  ArrowUp,
  ArrowDown,
  MessageSquare,
  CheckCircle2,
  XCircle,
  Download,
} from 'lucide-react';
import { apiService } from '../services/api';
import { queryKeys } from '../queryClient';
import ProgressBar from '../components/ProgressBar';
import LoadingSpinner from '../components/LoadingSpinner';
import InterventionPanel from '../components/InterventionPanel';
import ModulePdfExportModal from '../components/ModulePdfExportModal';
import SavedViewsBar from '../components/SavedViewsBar';

const MODE_LABELS = {
  elearning_async: 'E-Learning',
  elearning_sync: 'Classe(s) Virtuelle(s)',
  mixte: 'Pr\u00e9sentiel + Classe(s) Virtuelle(s)',
};

const MODE_COLORS = {
  elearning_async: 'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400',
  elearning_sync: 'bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-400',
  mixte: 'bg-teal-100 dark:bg-teal-900/30 text-teal-700 dark:text-teal-400',
};

const MODE_FILTER_OPTIONS = [
  { key: 'all', label: 'allTypes' },
  { key: 'elearning_async', label: 'E-Learning' },
  { key: 'elearning_sync', label: 'Classe(s) Virtuelle(s)' },
  { key: 'mixte', label: 'Mixte' },
];

const PAGE_SIZE_OPTIONS = [25, 50, 100, 0];

const ModuleManagement = () => {
  const { t } = useTranslation();

  // Deadline mode toggle
  const [deadlineMode, setDeadlineMode] = useState(() => {
    const cached = sessionStorage.getItem('moduleManagement.deadlineMode');
    return cached ? JSON.parse(cached) : false;
  });

  // Threshold (only used in deadline mode)
  const [threshold, setThreshold] = useState(() => {
    const cached = sessionStorage.getItem('moduleManagement.threshold');
    return cached !== null ? Number(cached) : 95;
  });

  // Search
  const [searchTerm, setSearchTerm] = useState(() => {
    return localStorage.getItem('moduleManagement.searchTerm') || '';
  });

  // View toggle: 'course' (grouped) or 'participant' (flat)
  const [viewMode, setViewMode] = useState(() => {
    const cached = sessionStorage.getItem('moduleManagement.viewMode');
    return cached || 'course';
  });

  // Sorting
  const [sortBy, setSortBy] = useState(() => {
    const cached = localStorage.getItem('moduleManagement.sortBy');
    return cached || 'progression';
  });
  const [sortDirection, setSortDirection] = useState(() => {
    const cached = localStorage.getItem('moduleManagement.sortDirection');
    return cached || 'asc';
  });

  // ADF filter
  const [selectedADFs, setSelectedADFs] = useState(() => {
    const cached = localStorage.getItem('moduleManagement.selectedADFs');
    return cached ? JSON.parse(cached) : [];
  });
  const [showAdfDropdown, setShowAdfDropdown] = useState(false);
  const [adfSearchTerm, setAdfSearchTerm] = useState('');

  // Module (by id_lam) filter
  const [selectedModules, setSelectedModules] = useState(() => {
    const cached = localStorage.getItem('moduleManagement.selectedModules');
    return cached ? JSON.parse(cached) : [];
  });
  const [showModuleDropdown, setShowModuleDropdown] = useState(false);
  const [moduleSearchTerm, setModuleSearchTerm] = useState('');

  // Category filter
  const [selectedCategories, setSelectedCategories] = useState(() => {
    const cached = localStorage.getItem('moduleManagement.selectedCategories');
    return cached ? JSON.parse(cached) : [];
  });
  const [showCategoryDropdown, setShowCategoryDropdown] = useState(false);
  const [categorySearchTerm, setCategorySearchTerm] = useState('');

  // Module type filter
  const [selectedModuleType, setSelectedModuleType] = useState(() => {
    const cached = localStorage.getItem('moduleManagement.selectedModuleType');
    return cached || 'all';
  });

  // Completion status filter (deadline mode): 'all', 'incomplete', 'completed'
  const [completionFilter, setCompletionFilter] = useState('all');

  // Show latest notes (reads from settings page toggle)
  const showLatestNotes = useMemo(() => {
    const cached = localStorage.getItem('inactiveManagement.showLatestNotes');
    return cached ? JSON.parse(cached) : false;
  }, []);

  // Pagination
  const [pageSize, setPageSize] = useState(() => {
    const cached = localStorage.getItem('moduleManagement.pageSize');
    return cached ? JSON.parse(cached) : 50;
  });
  const [currentPage, setCurrentPage] = useState(1);

  // PDF export modal
  const [showExportModal, setShowExportModal] = useState(false);

  // Expanded states
  const [expandedGroups, setExpandedGroups] = useState(new Set());

  // Expanded intervention panels (participant key -> open)
  const [expandedParticipants, setExpandedParticipants] = useState(new Set());
  const toggleParticipantExpand = useCallback((key) => {
    setExpandedParticipants(prev => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key); else next.add(key);
      return next;
    });
  }, []);

  // Persist state
  useEffect(() => { sessionStorage.setItem('moduleManagement.deadlineMode', JSON.stringify(deadlineMode)); }, [deadlineMode]);
  useEffect(() => { localStorage.setItem('moduleManagement.selectedADFs', JSON.stringify(selectedADFs)); }, [selectedADFs]);
  useEffect(() => { localStorage.setItem('moduleManagement.selectedModules', JSON.stringify(selectedModules)); }, [selectedModules]);
  useEffect(() => { localStorage.setItem('moduleManagement.selectedCategories', JSON.stringify(selectedCategories)); }, [selectedCategories]);
  useEffect(() => { localStorage.setItem('moduleManagement.selectedModuleType', selectedModuleType); }, [selectedModuleType]);
  useEffect(() => { localStorage.setItem('moduleManagement.searchTerm', searchTerm); }, [searchTerm]);
  useEffect(() => { localStorage.setItem('moduleManagement.pageSize', JSON.stringify(pageSize)); }, [pageSize]);
  useEffect(() => { localStorage.setItem('moduleManagement.sortBy', sortBy); }, [sortBy]);
  useEffect(() => { localStorage.setItem('moduleManagement.sortDirection', sortDirection); }, [sortDirection]);

  // Reset pagination when filters change
  useEffect(() => {
    setCurrentPage(1);
  }, [selectedADFs, selectedModules, selectedCategories, selectedModuleType, searchTerm, threshold, pageSize, viewMode, deadlineMode, sortBy, sortDirection, completionFilter]);

  const { data, isLoading, error } = useQuery({
    queryKey: queryKeys.moduleData,
    queryFn: () => apiService.getModuleData(),
    staleTime: 5 * 60 * 1000,
  });

  const handleThresholdChange = (value) => {
    const v = Math.max(0, Math.min(100, Number(value)));
    setThreshold(v);
    sessionStorage.setItem('moduleManagement.threshold', v);
  };

  const toggleSort = useCallback((key) => {
    if (sortBy === key) {
      setSortDirection(prev => prev === 'asc' ? 'desc' : 'asc');
    } else {
      setSortBy(key);
      setSortDirection(key === 'name' ? 'asc' : 'asc');
    }
  }, [sortBy]);

  const hasActiveFilters = selectedADFs.length > 0 || selectedModules.length > 0 || selectedCategories.length > 0 || selectedModuleType !== 'all' || searchTerm || completionFilter !== 'all';

  // When these filters are active, all rows share the same value — hide the redundant UI
  const hideTypeCol = selectedModuleType !== 'all';
  const hideCategoryPill = selectedCategories.length > 0;

  const collectCurrentFilters = useCallback(() => ({
    deadlineMode,
    threshold,
    selectedADFs,
    selectedModules,
    selectedCategories,
    selectedModuleType,
    completionFilter,
    searchTerm,
    viewMode,
    sortBy,
    sortDirection,
    pageSize,
  }), [deadlineMode, threshold, selectedADFs, selectedModules, selectedCategories, selectedModuleType, completionFilter, searchTerm, viewMode, sortBy, sortDirection, pageSize]);

  const applyView = useCallback((config) => {
    if (config.deadlineMode !== undefined) setDeadlineMode(config.deadlineMode);
    if (config.threshold !== undefined) {
      setThreshold(config.threshold);
      sessionStorage.setItem('moduleManagement.threshold', config.threshold);
    }
    if (config.selectedADFs) setSelectedADFs(config.selectedADFs);
    if (config.selectedModules) setSelectedModules(config.selectedModules);
    if (config.selectedCategories) setSelectedCategories(config.selectedCategories);
    if (config.selectedModuleType) setSelectedModuleType(config.selectedModuleType);
    if (config.completionFilter) setCompletionFilter(config.completionFilter);
    if (config.searchTerm !== undefined) setSearchTerm(config.searchTerm);
    if (config.viewMode) {
      setViewMode(config.viewMode);
      sessionStorage.setItem('moduleManagement.viewMode', config.viewMode);
    }
    if (config.sortBy) setSortBy(config.sortBy);
    if (config.sortDirection) setSortDirection(config.sortDirection);
    if (config.pageSize !== undefined) setPageSize(config.pageSize);
  }, []);

  const resetAllFilters = useCallback(() => {
    setSelectedADFs([]);
    setSelectedModules([]);
    setSelectedCategories([]);
    setSelectedModuleType('all');
    setCompletionFilter('all');
    setSearchTerm('');
    localStorage.removeItem('moduleManagement.searchTerm');
  }, []);

  const formatDate = (dateString) => {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return date.toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric' });
  };

  // Positive when date_fin is in the future, negative when overdue
  const daysUntilDeadline = (dateString) => {
    if (!dateString) return 0;
    return Math.floor((new Date(dateString) - new Date()) / (1000 * 60 * 60 * 24));
  };

  const deadlineBadgeStyle = (days) => {
    if (days < -30) return 'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400';
    if (days < -7) return 'bg-orange-100 dark:bg-orange-900/30 text-orange-700 dark:text-orange-400';
    if (days < 0) return 'bg-yellow-100 dark:bg-yellow-900/30 text-yellow-700 dark:text-yellow-400';
    return 'bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400';
  };

  const formatDaysLabel = (days) => `${days > 0 ? '+' : ''}${days}j`;

  const toggleGroup = (key) => {
    setExpandedGroups(prev => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  };

  // Extract unique ADFs, modules (by id_lam), and categories
  const { adfList, moduleList, categoryList } = useMemo(() => {
    if (!data?.items) return { adfList: [], moduleList: [], categoryList: [] };
    const adfs = new Map();
    const mods = new Set();
    const cats = new Map();
    for (const item of data.items) {
      if (!adfs.has(item.id_action_formation)) {
        adfs.set(item.id_action_formation, item.course_title);
      }
      // Dedupe modules by title so the same module template appears once in the list,
      // not once per ADF/id_lam. User filters ADF separately if needed.
      if (item.module_intitule) {
        mods.add(item.module_intitule);
      }
      if (item.category_name && !cats.has(item.category_name)) {
        cats.set(item.category_name, item.category_color || '');
      }
    }
    return {
      adfList: Array.from(adfs.entries()).map(([id, title]) => ({ id, title })).sort((a, b) => a.title.localeCompare(b.title)),
      moduleList: Array.from(mods).map(title => ({ id: title, title })).sort((a, b) => a.title.localeCompare(b.title)),
      categoryList: Array.from(cats.entries()).map(([name, color]) => ({ name, color })).sort((a, b) => a.name.localeCompare(b.name)),
    };
  }, [data]);

  // Apply all filters + sorting
  const filteredItems = useMemo(() => {
    if (!data?.items) return [];
    const nowMs = Date.now();
    let items = data.items.filter((item) => {
      // In deadline mode: only show overdue modules + apply completion filter
      if (deadlineMode) {
        if (!item.date_fin || new Date(item.date_fin).getTime() >= nowMs) return false;
        const isComplete = item.progression >= threshold;
        if (completionFilter === 'incomplete' && isComplete) return false;
        if (completionFilter === 'completed' && !isComplete) return false;
      }
      if (selectedADFs.length > 0 && !selectedADFs.includes(item.id_action_formation)) return false;
      if (selectedModules.length > 0 && !selectedModules.includes(item.module_intitule)) return false;
      if (selectedCategories.length > 0 && !selectedCategories.includes(item.category_name)) return false;
      if (selectedModuleType !== 'all' && item.mode_organisation !== selectedModuleType) return false;
      if (searchTerm) {
        const term = searchTerm.toLowerCase();
        const match =
          (item.nom || '').toLowerCase().includes(term) ||
          (item.prenom || '').toLowerCase().includes(term) ||
          (item.email || '').toLowerCase().includes(term) ||
          (item.course_title || '').toLowerCase().includes(term) ||
          (item.module_intitule || '').toLowerCase().includes(term);
        if (!match) return false;
      }
      return true;
    });

    // Sort
    const sortMultiplier = sortDirection === 'desc' ? -1 : 1;
    items.sort((a, b) => {
      let comparison = 0;
      switch (sortBy) {
        case 'progression':
          comparison = a.progression - b.progression;
          break;
        case 'name':
          comparison = `${a.nom} ${a.prenom}`.localeCompare(`${b.nom} ${b.prenom}`);
          break;
        case 'deadline':
          comparison = new Date(a.date_fin || 0) - new Date(b.date_fin || 0);
          break;
        case 'latest_note': {
          const dateA = a.latest_note_date ? new Date(a.latest_note_date).getTime() : 0;
          const dateB = b.latest_note_date ? new Date(b.latest_note_date).getTime() : 0;
          comparison = dateA - dateB;
          break;
        }
        default:
          comparison = 0;
      }
      return comparison * sortMultiplier;
    });

    return items;
  }, [data, threshold, searchTerm, selectedADFs, selectedModules, selectedCategories, selectedModuleType, deadlineMode, completionFilter, sortBy, sortDirection]);

  // Course view: group by ADF+module
  const groupEntries = useMemo(() => {
    if (viewMode !== 'course') return [];
    const groups = {};
    for (const item of filteredItems) {
      const key = `${item.id_action_formation}_${item.id_lam}`;
      if (!groups[key]) {
        groups[key] = {
          id_action_formation: item.id_action_formation,
          course_title: item.course_title,
          module_intitule: item.module_intitule,
          mode_organisation: item.mode_organisation,
          date_debut: item.date_debut,
          date_fin: item.date_fin,
          category_name: item.category_name,
          category_color: item.category_color,
          participants: [],
        };
      }
      groups[key].participants.push(item);
    }
    // Sort groups by earliest date_fin
    const entries = Object.entries(groups);
    if (sortBy === 'deadline') {
      const m = sortDirection === 'desc' ? -1 : 1;
      entries.sort(([, a], [, b]) => (new Date(a.date_fin) - new Date(b.date_fin)) * m);
    } else {
      entries.sort(([, a], [, b]) => new Date(a.date_fin) - new Date(b.date_fin));
    }
    return entries;
  }, [filteredItems, viewMode, sortBy, sortDirection]);

  // Participant view: flat list (already sorted by filteredItems)
  const flatItems = useMemo(() => {
    if (viewMode !== 'participant') return [];
    return filteredItems;
  }, [filteredItems, viewMode]);

  // Human-readable descriptions of active filters for the PDF header
  const activeFilterDescriptions = useMemo(() => {
    const descriptions = [];
    if (deadlineMode) {
      descriptions.push(t('moduleManagement.pdf.filterDeadlineMode'));
      descriptions.push(`${t('moduleManagement.pdf.filterThreshold')}: ${threshold}%`);
      if (completionFilter !== 'all') {
        const label = completionFilter === 'completed' ? t('moduleManagement.completed') : t('moduleManagement.incomplete');
        descriptions.push(`${t('moduleManagement.pdf.filterCompletion')}: ${label}`);
      }
    }
    if (selectedADFs.length > 0) {
      const titles = selectedADFs
        .map(id => adfList.find(a => a.id === id)?.title)
        .filter(Boolean);
      descriptions.push(`${t('moduleManagement.pdf.filterAdf')}: ${titles.join(', ')}`);
    }
    if (selectedModules.length > 0) {
      descriptions.push(`${t('moduleManagement.pdf.filterModule')}: ${selectedModules.join(', ')}`);
    }
    if (selectedCategories.length > 0) {
      descriptions.push(`${t('moduleManagement.pdf.filterCategory')}: ${selectedCategories.join(', ')}`);
    }
    if (selectedModuleType !== 'all') {
      const typeLabel = MODE_LABELS[selectedModuleType] || selectedModuleType;
      descriptions.push(`${t('moduleManagement.pdf.filterType')}: ${typeLabel}`);
    }
    if (searchTerm) {
      descriptions.push(`${t('moduleManagement.pdf.filterSearch')}: "${searchTerm}"`);
    }
    return descriptions;
  }, [deadlineMode, threshold, completionFilter, selectedADFs, selectedModules, selectedCategories, selectedModuleType, searchTerm, adfList, t]);

  // Pagination
  const totalItems = viewMode === 'course' ? groupEntries.length : flatItems.length;
  const effectivePageSize = pageSize === 0 ? totalItems : pageSize;
  const totalPages = Math.max(1, Math.ceil(totalItems / effectivePageSize));
  const safePage = Math.min(currentPage, totalPages);
  const pageStart = (safePage - 1) * effectivePageSize;
  const pageEnd = Math.min(pageStart + effectivePageSize, totalItems);
  const paginatedGroups = groupEntries.slice(pageStart, pageEnd);
  const paginatedFlat = flatItems.slice(pageStart, pageEnd);

  // Completion badge helper for deadline mode
  const CompletionBadge = ({ progression }) => {
    if (!deadlineMode) return null;
    const isComplete = progression >= threshold;
    return (
      <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${
        isComplete
          ? 'bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400'
          : 'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400'
      }`}>
        {isComplete ? <CheckCircle2 size={10} /> : <XCircle size={10} />}
        {isComplete ? t('moduleManagement.completed') : t('moduleManagement.incomplete')}
      </span>
    );
  };

  // Latest note badge with hover tooltip
  const NoteBadge = ({ item }) => {
    if (!showLatestNotes) return null;
    if (item.latest_note_date) {
      const tooltipText = item.latest_note_text
        ? `${item.latest_note_text.substring(0, 200)}${item.latest_note_text.length > 200 ? '...' : ''}`
        : '';
      return (
        <span
          className="flex items-center gap-1 text-xs bg-green-50 dark:bg-green-900/20 text-green-700 dark:text-green-400 px-2 py-0.5 rounded-full cursor-default"
          title={tooltipText}
        >
          <MessageSquare size={12} />
          {t('moduleManagement.latestNote')}: {new Date(item.latest_note_date).toLocaleDateString('fr-FR')}
        </span>
      );
    }
    return (
      <span className="flex items-center gap-1 text-xs bg-gray-50 dark:bg-slate-700 text-gray-400 dark:text-gray-500 px-2 py-0.5 rounded-full cursor-default">
        <MessageSquare size={12} />
        {t('moduleManagement.noNote')}
      </span>
    );
  };

  if (isLoading) return <LoadingSpinner />;

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-slate-900">
      {/* Header */}
      <div className="bg-white dark:bg-slate-800 border-b border-gray-200 dark:border-slate-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center">
              <div className="p-2 bg-primary-100 dark:bg-primary-900/30 rounded-lg mr-4">
                <LayoutList size={24} className="text-primary-600 dark:text-primary-400" />
              </div>
              <div>
                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                  {t('moduleManagement.title')}
                </h1>
                <p className="text-gray-600 dark:text-gray-400 mt-1">
                  {t('moduleManagement.subtitle')}
                </p>
              </div>
            </div>

            <div className="flex items-center gap-2 flex-shrink-0">
              {hasActiveFilters && (
                <button
                  onClick={resetAllFilters}
                  title={t('moduleManagement.resetFilters')}
                  className="flex items-center justify-center h-10 w-10 rounded-lg border border-red-200 dark:border-red-800 bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-900/30 transition-colors"
                >
                  <X size={18} />
                </button>
              )}

              <div className="flex items-center h-10 rounded-lg border border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-800 overflow-hidden">
                <button
                  onClick={() => setDeadlineMode(!deadlineMode)}
                  title={t('moduleManagement.deadlineMode')}
                  className={`flex items-center gap-2 h-full px-3 text-sm font-medium whitespace-nowrap transition-colors ${
                    deadlineMode
                      ? 'bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-400'
                      : 'text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-slate-700'
                  }`}
                >
                  <AlertTriangle size={16} />
                  <span>{t('moduleManagement.deadlineMode')}</span>
                </button>
                <div className="h-6 w-px bg-gray-200 dark:bg-slate-600" />
                <button
                  onClick={() => {
                    const next = viewMode === 'course' ? 'participant' : 'course';
                    setViewMode(next);
                    sessionStorage.setItem('moduleManagement.viewMode', next);
                  }}
                  title={viewMode === 'course' ? t('moduleManagement.viewParticipant') : t('moduleManagement.viewCourse')}
                  className="flex items-center gap-2 h-full px-3 text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-slate-700 whitespace-nowrap transition-colors"
                >
                  <BarChart3 size={16} />
                  <span>
                    {viewMode === 'course' ? t('moduleManagement.viewParticipant') : t('moduleManagement.viewCourse')}
                  </span>
                </button>
              </div>

              <button
                onClick={() => setShowExportModal(true)}
                disabled={filteredItems.length === 0}
                title={t('moduleManagement.export')}
                className="flex items-center gap-2 h-10 px-3 bg-primary-600 hover:bg-primary-700 text-white text-sm font-medium rounded-lg whitespace-nowrap transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <Download size={16} />
                <span>{t('moduleManagement.export')}</span>
              </button>
            </div>
          </div>
        </div>
      </div>

      <ModulePdfExportModal
        isOpen={showExportModal}
        onClose={() => setShowExportModal(false)}
        items={filteredItems}
        activeFilters={activeFilterDescriptions}
      />

      {/* Saved views bar */}
      <div className="bg-white dark:bg-slate-800 border-b border-gray-100 dark:border-slate-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-3">
          <SavedViewsBar page="module" onLoadView={applyView} getCurrentFilters={collectCurrentFilters} />
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Filter Bar - always visible */}
        <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700 p-4 mb-6 space-y-4">
          {/* Row 1: Sorting + Module type pills + threshold (in deadline mode) */}
          <div className="flex flex-col lg:flex-row gap-4">
            {/* Sorting */}
            <div className="flex items-center gap-2 flex-wrap">
              <span className="text-sm font-semibold text-gray-600 dark:text-gray-400 flex items-center gap-1 mr-1">
                <ArrowUpDown size={14} />
                {t('moduleManagement.sortBy')}
              </span>
              {[
                { key: 'progression', label: t('moduleManagement.sortByProgression') },
                { key: 'name', label: t('moduleManagement.sortByName') },
                { key: 'deadline', label: t('moduleManagement.sortByDeadline') },
                ...(showLatestNotes ? [{ key: 'latest_note', label: t('moduleManagement.sortByNote') }] : []),
              ].map(({ key, label }) => (
                <button
                  key={key}
                  onClick={() => toggleSort(key)}
                  className={`flex items-center gap-1 px-3 py-1.5 rounded-full border text-xs font-medium transition-colors ${
                    sortBy === key
                      ? 'bg-primary-50 dark:bg-primary-900/30 border-primary-200 dark:border-primary-800 text-primary-700 dark:text-primary-400'
                      : 'bg-white dark:bg-slate-800 border-gray-200 dark:border-slate-700 text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-slate-700'
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
            <div className="hidden lg:block w-px bg-gray-200 dark:bg-slate-600" />

            {/* Module Type Filter */}
            <div className="flex items-center gap-2 flex-wrap">
              <span className="text-sm font-semibold text-gray-600 dark:text-gray-400 flex items-center gap-1 mr-1">
                <Filter size={14} />
                {t('moduleManagement.filterByType')}
              </span>
              {MODE_FILTER_OPTIONS.map(({ key, label }) => (
                <button
                  key={key}
                  onClick={() => setSelectedModuleType(key)}
                  className={`px-3 py-1.5 rounded-full border text-xs font-medium transition-colors ${
                    selectedModuleType === key
                      ? key === 'elearning_async' ? 'bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-800 text-blue-700 dark:text-blue-400'
                        : key === 'elearning_sync' ? 'bg-purple-50 dark:bg-purple-900/20 border-purple-200 dark:border-purple-800 text-purple-700 dark:text-purple-400'
                        : key === 'mixte' ? 'bg-teal-50 dark:bg-teal-900/20 border-teal-200 dark:border-teal-800 text-teal-700 dark:text-teal-400'
                        : 'bg-primary-50 dark:bg-primary-900/30 border-primary-200 dark:border-primary-800 text-primary-700 dark:text-primary-400'
                      : 'bg-white dark:bg-slate-800 border-gray-200 dark:border-slate-700 text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-slate-700'
                  }`}
                >
                  {key === 'all' ? t('moduleManagement.allTypes') : label}
                </button>
              ))}
            </div>

            {/* Threshold + Completion filter - only shown in deadline mode */}
            {deadlineMode && (
              <>
                <div className="hidden lg:block w-px bg-gray-200 dark:bg-slate-600" />
                <div className="flex items-center gap-2">
                  <span className="text-sm font-semibold text-gray-600 dark:text-gray-400 flex items-center gap-1">
                    <Target size={14} />
                    {t('moduleManagement.thresholdLabel')}
                  </span>
                  <input
                    type="range"
                    min="0"
                    max="100"
                    value={threshold}
                    onChange={(e) => handleThresholdChange(e.target.value)}
                    className="w-32 h-2 bg-gray-200 dark:bg-slate-600 rounded-lg appearance-none cursor-pointer"
                  />
                  <div className="flex items-center gap-1">
                    <input
                      type="number"
                      min="0"
                      max="100"
                      value={threshold}
                      onChange={(e) => handleThresholdChange(e.target.value)}
                      className="w-14 px-2 py-1 border border-gray-300 dark:border-slate-600 rounded text-center text-xs bg-white dark:bg-slate-700 text-gray-900 dark:text-white"
                    />
                    <span className="text-xs text-gray-500 dark:text-gray-400">%</span>
                  </div>
                </div>
                <div className="hidden lg:block w-px bg-gray-200 dark:bg-slate-600" />
                <div className="flex items-center gap-2">
                  {[
                    { key: 'all', label: t('moduleManagement.allTypes'), icon: null, colors: 'bg-primary-50 dark:bg-primary-900/30 border-primary-200 dark:border-primary-800 text-primary-700 dark:text-primary-400' },
                    { key: 'incomplete', label: t('moduleManagement.incomplete'), icon: <XCircle size={12} />, colors: 'bg-red-50 dark:bg-red-900/20 border-red-200 dark:border-red-800 text-red-700 dark:text-red-400' },
                    { key: 'completed', label: t('moduleManagement.completed'), icon: <CheckCircle2 size={12} />, colors: 'bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-800 text-green-700 dark:text-green-400' },
                  ].map(({ key, label, icon, colors }) => (
                    <button
                      key={key}
                      onClick={() => setCompletionFilter(key)}
                      className={`flex items-center gap-1 px-3 py-1.5 rounded-full border text-xs font-medium transition-colors ${
                        completionFilter === key
                          ? colors
                          : 'bg-white dark:bg-slate-800 border-gray-200 dark:border-slate-700 text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-slate-700'
                      }`}
                    >
                      {icon}
                      {label}
                    </button>
                  ))}
                </div>
              </>
            )}
          </div>

          {/* Row 2: ADF + Module + Category Filters side by side */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 border-t border-gray-100 dark:border-slate-700 pt-4">
            {/* ADF Filter */}
            <div>
              <button
                onClick={() => { setShowAdfDropdown(!showAdfDropdown); setShowModuleDropdown(false); setShowCategoryDropdown(false); }}
                className="w-full flex items-center justify-between px-3 py-2 rounded-lg border border-gray-200 dark:border-slate-700 hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors"
              >
                <div className="flex items-center gap-2">
                  <BookOpen size={16} className="text-gray-600 dark:text-gray-400" />
                  <span className="text-sm font-medium text-gray-900 dark:text-white">{t('moduleManagement.filterByAdf')}</span>
                  {selectedADFs.length > 0 && (
                    <span className="px-2 py-0.5 bg-primary-100 dark:bg-primary-900/30 text-primary-700 dark:text-primary-400 text-xs font-medium rounded-full">
                      {selectedADFs.length}
                    </span>
                  )}
                </div>
                {showAdfDropdown ? <ChevronDown size={16} className="text-gray-400 dark:text-gray-300" /> : <ChevronRight size={16} className="text-gray-400 dark:text-gray-300" />}
              </button>

              {showAdfDropdown && (() => {
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
                      placeholder={t('moduleManagement.searchPlaceholder')}
                      className="w-full px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm dark:bg-slate-700 dark:text-white dark:placeholder-gray-500"
                    />
                    {selectedButHiddenADFs.length > 0 && (
                      <div className="space-y-1 border border-primary-200 dark:border-primary-800 bg-primary-50/50 dark:bg-primary-900/20 rounded-lg p-2">
                        <p className="text-[10px] font-medium text-primary-600 uppercase tracking-wide px-2">{t('moduleManagement.selected')}</p>
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
                    <div className="max-h-48 overflow-y-auto space-y-1 border border-gray-200 dark:border-slate-700 rounded-lg p-2">
                      {filteredADFs.length === 0 ? (
                        <p className="text-sm text-gray-500 dark:text-gray-400 text-center py-2">{t('moduleManagement.noResults')}</p>
                      ) : (
                        <>
                          <label className="flex items-center gap-2 px-2 py-1.5 rounded hover:bg-gray-50 dark:hover:bg-slate-700 cursor-pointer transition-colors border-b border-gray-200 dark:border-slate-700">
                            <input
                              type="checkbox"
                              checked={filteredADFs.length > 0 && filteredADFs.every(adf => selectedADFs.includes(adf.id))}
                              onChange={(e) => {
                                if (e.target.checked) {
                                  setSelectedADFs(prev => [...new Set([...prev, ...filteredADFs.map(a => a.id)])]);
                                } else {
                                  const filteredIds = new Set(filteredADFs.map(a => a.id));
                                  setSelectedADFs(prev => prev.filter(id => !filteredIds.has(id)));
                                }
                              }}
                              className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500"
                            />
                            <span className="text-xs font-semibold text-gray-700 dark:text-gray-300">
                              {filteredADFs.length > 0 && filteredADFs.every(adf => selectedADFs.includes(adf.id)) ? t('moduleManagement.deselectAll') : t('moduleManagement.selectAll')}
                            </span>
                          </label>
                          {filteredADFs.map((adf) => (
                            <label key={adf.id} className="flex items-start gap-2 px-2 py-1.5 rounded hover:bg-gray-50 dark:hover:bg-slate-700 cursor-pointer transition-colors">
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
                              <span className="text-xs text-gray-700 dark:text-gray-300 leading-tight">{adf.title}</span>
                            </label>
                          ))}
                        </>
                      )}
                    </div>
                    {selectedADFs.length > 0 && (
                      <p className="text-xs text-gray-500 dark:text-gray-400">
                        {selectedADFs.length} formation{selectedADFs.length > 1 ? 's' : ''} {t('moduleManagement.selected')}
                      </p>
                    )}
                  </div>
                );
              })()}
            </div>

            {/* Module Filter (unique by id_lam) */}
            <div>
              <button
                onClick={() => { setShowModuleDropdown(!showModuleDropdown); setShowAdfDropdown(false); setShowCategoryDropdown(false); }}
                className="w-full flex items-center justify-between px-3 py-2 rounded-lg border border-gray-200 dark:border-slate-700 hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors"
              >
                <div className="flex items-center gap-2">
                  <LayoutList size={16} className="text-gray-600 dark:text-gray-400" />
                  <span className="text-sm font-medium text-gray-900 dark:text-white">{t('moduleManagement.filterByModule', 'Filtrer par module')}</span>
                  {selectedModules.length > 0 && (
                    <span className="px-2 py-0.5 bg-primary-100 dark:bg-primary-900/30 text-primary-700 dark:text-primary-400 text-xs font-medium rounded-full">
                      {selectedModules.length}
                    </span>
                  )}
                </div>
                {showModuleDropdown ? <ChevronDown size={16} className="text-gray-400 dark:text-gray-300" /> : <ChevronRight size={16} className="text-gray-400 dark:text-gray-300" />}
              </button>

              {showModuleDropdown && (() => {
                const filteredModules = moduleList.filter(m =>
                  m.title.toLowerCase().includes(moduleSearchTerm.toLowerCase())
                );
                const selectedButHiddenModules = moduleSearchTerm
                  ? moduleList.filter(m => selectedModules.includes(m.id) && !m.title.toLowerCase().includes(moduleSearchTerm.toLowerCase()))
                  : [];

                return (
                  <div className="mt-2 space-y-2">
                    <input
                      type="text"
                      value={moduleSearchTerm}
                      onChange={(e) => setModuleSearchTerm(e.target.value)}
                      placeholder={t('moduleManagement.searchPlaceholder')}
                      className="w-full px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm dark:bg-slate-700 dark:text-white dark:placeholder-gray-500"
                    />
                    {selectedButHiddenModules.length > 0 && (
                      <div className="space-y-1 border border-primary-200 dark:border-primary-800 bg-primary-50/50 dark:bg-primary-900/20 rounded-lg p-2">
                        <p className="text-[10px] font-medium text-primary-600 uppercase tracking-wide px-2">{t('moduleManagement.selected')}</p>
                        {selectedButHiddenModules.map((m) => (
                          <label key={m.id} className="flex items-start gap-2 px-2 py-1.5 rounded hover:bg-primary-100/50 cursor-pointer transition-colors">
                            <input
                              type="checkbox"
                              checked={true}
                              onChange={() => setSelectedModules(selectedModules.filter(id => id !== m.id))}
                              className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500 mt-0.5"
                            />
                            <span className="text-xs text-primary-700 leading-tight">{m.title}</span>
                          </label>
                        ))}
                      </div>
                    )}
                    <div className="max-h-48 overflow-y-auto space-y-1 border border-gray-200 dark:border-slate-700 rounded-lg p-2">
                      {filteredModules.length === 0 ? (
                        <p className="text-sm text-gray-500 dark:text-gray-400 text-center py-2">{t('moduleManagement.noResults')}</p>
                      ) : (
                        <>
                          <label className="flex items-center gap-2 px-2 py-1.5 rounded hover:bg-gray-50 dark:hover:bg-slate-700 cursor-pointer transition-colors border-b border-gray-200 dark:border-slate-700">
                            <input
                              type="checkbox"
                              checked={filteredModules.length > 0 && filteredModules.every(m => selectedModules.includes(m.id))}
                              onChange={(e) => {
                                if (e.target.checked) {
                                  setSelectedModules(prev => [...new Set([...prev, ...filteredModules.map(m => m.id)])]);
                                } else {
                                  const filteredIds = new Set(filteredModules.map(m => m.id));
                                  setSelectedModules(prev => prev.filter(id => !filteredIds.has(id)));
                                }
                              }}
                              className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500"
                            />
                            <span className="text-xs font-semibold text-gray-700 dark:text-gray-300">
                              {filteredModules.length > 0 && filteredModules.every(m => selectedModules.includes(m.id)) ? t('moduleManagement.deselectAll') : t('moduleManagement.selectAll')}
                            </span>
                          </label>
                          {filteredModules.map((m) => (
                            <label key={m.id} className="flex items-start gap-2 px-2 py-1.5 rounded hover:bg-gray-50 dark:hover:bg-slate-700 cursor-pointer transition-colors">
                              <input
                                type="checkbox"
                                checked={selectedModules.includes(m.id)}
                                onChange={(e) => {
                                  if (e.target.checked) {
                                    setSelectedModules([...selectedModules, m.id]);
                                  } else {
                                    setSelectedModules(selectedModules.filter(id => id !== m.id));
                                  }
                                }}
                                className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500 mt-0.5"
                              />
                              <span className="text-xs text-gray-700 dark:text-gray-300 leading-tight">{m.title}</span>
                            </label>
                          ))}
                        </>
                      )}
                    </div>
                    {selectedModules.length > 0 && (
                      <p className="text-xs text-gray-500 dark:text-gray-400">
                        {selectedModules.length} module{selectedModules.length > 1 ? 's' : ''} {t('moduleManagement.selected')}
                      </p>
                    )}
                  </div>
                );
              })()}
            </div>

            {/* Category Filter */}
            <div>
              <button
                onClick={() => { setShowCategoryDropdown(!showCategoryDropdown); setShowAdfDropdown(false); setShowModuleDropdown(false); }}
                className="w-full flex items-center justify-between px-3 py-2 rounded-lg border border-gray-200 dark:border-slate-700 hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors"
              >
                <div className="flex items-center gap-2">
                  <Filter size={16} className="text-gray-600 dark:text-gray-400" />
                  <span className="text-sm font-medium text-gray-900 dark:text-white">{t('moduleManagement.filterByCategory')}</span>
                  {selectedCategories.length > 0 && (
                    <span className="px-2 py-0.5 bg-primary-100 dark:bg-primary-900/30 text-primary-700 dark:text-primary-400 text-xs font-medium rounded-full">
                      {selectedCategories.length}
                    </span>
                  )}
                </div>
                {showCategoryDropdown ? <ChevronDown size={16} className="text-gray-400 dark:text-gray-300" /> : <ChevronRight size={16} className="text-gray-400 dark:text-gray-300" />}
              </button>

              {showCategoryDropdown && (() => {
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
                      placeholder={t('moduleManagement.searchPlaceholder')}
                      className="w-full px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm dark:bg-slate-700 dark:text-white dark:placeholder-gray-500"
                    />
                    {selectedButHiddenCategories.length > 0 && (
                      <div className="space-y-1 border border-primary-200 dark:border-primary-800 bg-primary-50/50 dark:bg-primary-900/20 rounded-lg p-2">
                        <p className="text-[10px] font-medium text-primary-600 uppercase tracking-wide px-2">{t('moduleManagement.selected')}</p>
                        {selectedButHiddenCategories.map((cat) => (
                          <label key={cat.name} className="flex items-start gap-2 px-2 py-1.5 rounded hover:bg-primary-100/50 cursor-pointer transition-colors">
                            <input
                              type="checkbox"
                              checked={true}
                              onChange={() => setSelectedCategories(selectedCategories.filter(n => n !== cat.name))}
                              className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500 mt-0.5"
                            />
                            {cat.color && <span className="inline-block w-2.5 h-2.5 rounded-full flex-shrink-0 mt-1" style={{ backgroundColor: `#${cat.color}` }} />}
                            <span className="text-xs text-primary-700 leading-tight">{cat.name}</span>
                          </label>
                        ))}
                      </div>
                    )}
                    <div className="max-h-48 overflow-y-auto space-y-1 border border-gray-200 dark:border-slate-700 rounded-lg p-2">
                      {filteredCategories.length === 0 ? (
                        <p className="text-sm text-gray-500 dark:text-gray-400 text-center py-2">{t('moduleManagement.noResults')}</p>
                      ) : (
                        <>
                          <label className="flex items-center gap-2 px-2 py-1.5 rounded hover:bg-gray-50 dark:hover:bg-slate-700 cursor-pointer transition-colors border-b border-gray-200 dark:border-slate-700">
                            <input
                              type="checkbox"
                              checked={filteredCategories.length > 0 && filteredCategories.every(cat => selectedCategories.includes(cat.name))}
                              onChange={(e) => {
                                if (e.target.checked) {
                                  setSelectedCategories(prev => [...new Set([...prev, ...filteredCategories.map(c => c.name)])]);
                                } else {
                                  const filteredNames = new Set(filteredCategories.map(c => c.name));
                                  setSelectedCategories(prev => prev.filter(n => !filteredNames.has(n)));
                                }
                              }}
                              className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500"
                            />
                            <span className="text-xs font-semibold text-gray-700 dark:text-gray-300">
                              {filteredCategories.length > 0 && filteredCategories.every(cat => selectedCategories.includes(cat.name)) ? t('moduleManagement.deselectAll') : t('moduleManagement.selectAll')}
                            </span>
                          </label>
                          {filteredCategories.map((cat) => (
                            <label key={cat.name} className="flex items-start gap-2 px-2 py-1.5 rounded hover:bg-gray-50 dark:hover:bg-slate-700 cursor-pointer transition-colors">
                              <input
                                type="checkbox"
                                checked={selectedCategories.includes(cat.name)}
                                onChange={(e) => {
                                  if (e.target.checked) {
                                    setSelectedCategories([...selectedCategories, cat.name]);
                                  } else {
                                    setSelectedCategories(selectedCategories.filter(n => n !== cat.name));
                                  }
                                }}
                                className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500 mt-0.5"
                              />
                              {cat.color && <span className="inline-block w-2.5 h-2.5 rounded-full flex-shrink-0 mt-1" style={{ backgroundColor: `#${cat.color}` }} />}
                              <span className="text-xs text-gray-700 dark:text-gray-300 leading-tight">{cat.name}</span>
                            </label>
                          ))}
                        </>
                      )}
                    </div>
                    {selectedCategories.length > 0 && (
                      <p className="text-xs text-gray-500 dark:text-gray-400">
                        {selectedCategories.length} {t('moduleManagement.selected')}
                      </p>
                    )}
                  </div>
                );
              })()}
            </div>
          </div>
        </div>

        {/* Search + Stats + Page Size Bar */}
        <div className="flex items-center justify-between mb-6">
          <div className="relative w-80">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder={t('moduleManagement.searchPlaceholder')}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white text-sm focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
            />
          </div>
          <div className="flex items-center gap-4">
            <span className="text-sm text-gray-600 dark:text-gray-400">
              <Target size={14} className="inline mr-1" />
              {t('moduleManagement.results', 'Résultats')}: {totalItems}
              {deadlineMode && ` < ${threshold}%`}
            </span>
            <div className="flex items-center gap-1 border-l border-gray-300 dark:border-slate-600 pl-4">
              {PAGE_SIZE_OPTIONS.map(size => (
                <button
                  key={size}
                  onClick={() => setPageSize(size)}
                  className={`px-2.5 py-1 rounded text-xs font-medium transition-colors ${
                    pageSize === size
                      ? 'bg-primary-100 dark:bg-primary-900/30 text-primary-700 dark:text-primary-400'
                      : 'text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-slate-700'
                  }`}
                >
                  {size === 0 ? 'Tout' : size}
                </button>
              ))}
            </div>
          </div>
        </div>

        {error && (
          <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4 mb-6">
            <p className="text-red-700 dark:text-red-400">Erreur : {error.message}</p>
          </div>
        )}

        {/* Empty State */}
        {filteredItems.length === 0 && !isLoading && !error && (
          <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700 p-12 text-center">
            <AlertTriangle size={48} className="mx-auto text-gray-300 dark:text-slate-600 mb-4" />
            <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
              {t('moduleManagement.emptyTitle')}
            </h3>
            <p className="text-gray-500 dark:text-gray-400">
              {t('moduleManagement.emptyMessage', { threshold })}
            </p>
          </div>
        )}

        {/* ===== COURSE VIEW (grouped by ADF+Module) ===== */}
        {viewMode === 'course' && (
          <div className="space-y-4">
            {paginatedGroups.map(([key, group]) => {
              const isExpanded = expandedGroups.has(key);
              const daysOverdue = daysUntilDeadline(group.date_fin);

              return (
                <div key={key} className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700 overflow-hidden">
                  <button
                    onClick={() => toggleGroup(key)}
                    className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 dark:hover:bg-slate-700/50 transition-colors"
                  >
                    <div className="flex items-center gap-4">
                      {isExpanded ? <ChevronDown size={20} className="text-gray-400" /> : <ChevronRight size={20} className="text-gray-400" />}
                      <div className="text-left">
                        <h3 className="text-sm font-semibold text-gray-900 dark:text-white">
                          {group.module_intitule}
                        </h3>
                        <div className="flex items-center gap-2 mt-0.5">
                          <span className="text-xs text-gray-500 dark:text-gray-400">
                            {group.course_title}
                            {!hideTypeCol && ` - ${MODE_LABELS[group.mode_organisation] || group.mode_organisation}`}
                          </span>
                          {!hideCategoryPill && group.category_name && (
                            <span
                              className="flex items-center gap-1 text-xs px-2 py-0.5 rounded-full"
                              style={{
                                backgroundColor: group.category_color ? `#${group.category_color}20` : '#f3f4f6',
                                color: group.category_color ? `#${group.category_color}` : '#6b7280',
                              }}
                            >
                              {group.category_color && (
                                <span className="inline-block w-2 h-2 rounded-full flex-shrink-0" style={{ backgroundColor: `#${group.category_color}` }} />
                              )}
                              {group.category_name}
                            </span>
                          )}
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center gap-4 flex-shrink-0">
                      <span className="flex items-center text-xs text-gray-500 dark:text-gray-400">
                        <Calendar size={12} className="mr-1" />
                        {formatDate(group.date_debut)} {'\u2192'} {formatDate(group.date_fin)}
                      </span>
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${deadlineBadgeStyle(daysOverdue)}`}>
                        <Clock size={10} className="mr-1" />
                        {formatDaysLabel(daysOverdue)}
                      </span>
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 dark:bg-slate-700 text-gray-700 dark:text-gray-300">
                        <User size={10} className="mr-1" />
                        {group.participants.length}
                      </span>
                    </div>
                  </button>

                  {isExpanded && (
                    <div className="border-t border-gray-200 dark:border-slate-700">
                      <table className="w-full">
                        <thead>
                          <tr className="bg-gray-50 dark:bg-slate-700/50">
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">{t('moduleManagement.participant')}</th>
                            {!hideTypeCol && <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">{t('moduleManagement.type')}</th>}
                            {deadlineMode && <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Status</th>}
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider w-48">{t('moduleManagement.progression')}</th>
                            <th className="w-10" />
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-200 dark:divide-slate-700">
                          {group.participants
                            .sort((a, b) => a.progression - b.progression)
                            .map((item) => {
                              const pKey = `${item.participant_id}-${item.id_action_formation}`;
                              const colSpan = (hideTypeCol ? 3 : 4) + (deadlineMode ? 1 : 0);
                              return (
                              <React.Fragment key={`${item.participant_id}-${item.id_lam}`}>
                              <tr className="hover:bg-gray-50 dark:hover:bg-slate-700/30 transition-colors">
                                <td className="px-6 py-3">
                                  <div className="flex items-center gap-2 flex-wrap">
                                    <Link to={`/participants/${item.participant_id}`} className="text-sm font-medium text-primary-600 dark:text-primary-400 hover:underline">
                                      {item.prenom} {item.nom}
                                    </Link>
                                    <NoteBadge item={item} />
                                  </div>
                                  <p className="text-xs text-gray-500 dark:text-gray-400">{item.email}</p>
                                </td>
                                {!hideTypeCol && (
                                  <td className="px-6 py-3">
                                    <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${MODE_COLORS[item.mode_organisation] || 'bg-gray-100 dark:bg-slate-700 text-gray-700 dark:text-gray-300'}`}>
                                      {MODE_LABELS[item.mode_organisation] || item.mode_organisation}: {item.progression.toFixed(1)}%
                                    </span>
                                  </td>
                                )}
                                {deadlineMode && (
                                  <td className="px-6 py-3">
                                    <CompletionBadge progression={item.progression} />
                                  </td>
                                )}
                                <td className="px-6 py-3">
                                  <ProgressBar percentage={item.progression} size="small" />
                                </td>
                                <td className="px-2 py-3 text-right">
                                  <button
                                    onClick={() => toggleParticipantExpand(pKey)}
                                    className="p-1 hover:bg-gray-200 dark:hover:bg-slate-600 rounded transition-colors"
                                  >
                                    {expandedParticipants.has(pKey)
                                      ? <ChevronDown size={16} className="text-gray-400" />
                                      : <ChevronRight size={16} className="text-gray-400" />
                                    }
                                  </button>
                                </td>
                              </tr>
                              {expandedParticipants.has(pKey) && (
                                <tr>
                                  <td colSpan={colSpan} className="px-6 py-0 bg-gray-50 dark:bg-slate-700/30">
                                    <InterventionPanel participant={{ id: item.participant_id, id_action_formation: item.id_action_formation, nom: item.nom, prenom: item.prenom, email: item.email }} />
                                  </td>
                                </tr>
                              )}
                              </React.Fragment>
                              );
                            })}
                        </tbody>
                      </table>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}

        {/* ===== PARTICIPANT VIEW (flat list) ===== */}
        {viewMode === 'participant' && paginatedFlat.length > 0 && (
          <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700 overflow-hidden">
            <table className="w-full">
              <thead>
                <tr className="bg-gray-50 dark:bg-slate-700/50">
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">{t('moduleManagement.participant')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Formation</th>
                  {!hideTypeCol && <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">{t('moduleManagement.type')}</th>}
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Deadline</th>
                  {deadlineMode && <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Status</th>}
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider w-48">{t('moduleManagement.progression')}</th>
                  <th className="w-10" />
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 dark:divide-slate-700">
                {paginatedFlat.map((item) => {
                  const daysOverdue = daysUntilDeadline(item.date_fin);
                  const pKey = `${item.participant_id}-${item.id_action_formation}`;
                  const flatColSpan = (hideTypeCol ? 5 : 6) + (deadlineMode ? 1 : 0);
                  return (
                    <React.Fragment key={`${item.participant_id}-${item.id_lam}`}>
                    <tr className="hover:bg-gray-50 dark:hover:bg-slate-700/30 transition-colors">
                      <td className="px-6 py-3">
                        <div className="flex items-center gap-2 flex-wrap">
                          <Link to={`/participants/${item.participant_id}`} className="text-sm font-medium text-primary-600 dark:text-primary-400 hover:underline">
                            {item.prenom} {item.nom}
                          </Link>
                          <NoteBadge item={item} />
                        </div>
                        <p className="text-xs text-gray-500 dark:text-gray-400">{item.email}</p>
                      </td>
                      <td className="px-6 py-3">
                        <div className="text-sm text-gray-900 dark:text-white">{item.module_intitule}</div>
                        <div className="flex items-center gap-2 mt-0.5">
                          <span className="text-xs text-gray-500 dark:text-gray-400">{item.course_title}</span>
                          {!hideCategoryPill && item.category_name && (
                            <span
                              className="flex items-center gap-1 text-xs px-1.5 py-0.5 rounded-full"
                              style={{
                                backgroundColor: item.category_color ? `#${item.category_color}20` : '#f3f4f6',
                                color: item.category_color ? `#${item.category_color}` : '#6b7280',
                              }}
                            >
                              {item.category_color && (
                                <span className="inline-block w-2 h-2 rounded-full flex-shrink-0" style={{ backgroundColor: `#${item.category_color}` }} />
                              )}
                              {item.category_name}
                            </span>
                          )}
                        </div>
                      </td>
                      {!hideTypeCol && (
                        <td className="px-6 py-3">
                          <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${MODE_COLORS[item.mode_organisation] || 'bg-gray-100 dark:bg-slate-700 text-gray-700 dark:text-gray-300'}`}>
                            {MODE_LABELS[item.mode_organisation] || item.mode_organisation}: {item.progression.toFixed(1)}%
                          </span>
                        </td>
                      )}
                      <td className="px-6 py-3">
                        <span className="text-xs text-gray-500 dark:text-gray-400">{formatDate(item.date_fin)}</span>
                        <span className={`ml-2 inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${deadlineBadgeStyle(daysOverdue)}`}>
                          {formatDaysLabel(daysOverdue)}
                        </span>
                      </td>
                      {deadlineMode && (
                        <td className="px-6 py-3">
                          <CompletionBadge progression={item.progression} />
                        </td>
                      )}
                      <td className="px-6 py-3">
                        <ProgressBar percentage={item.progression} size="small" />
                      </td>
                      <td className="px-2 py-3 text-right">
                        <button
                          onClick={() => toggleParticipantExpand(pKey)}
                          className="p-1 hover:bg-gray-200 dark:hover:bg-slate-600 rounded transition-colors"
                        >
                          {expandedParticipants.has(pKey)
                            ? <ChevronDown size={16} className="text-gray-400" />
                            : <ChevronRight size={16} className="text-gray-400" />
                          }
                        </button>
                      </td>
                    </tr>
                    {expandedParticipants.has(pKey) && (
                      <tr>
                        <td colSpan={flatColSpan} className="px-6 py-0 bg-gray-50 dark:bg-slate-700/30">
                          <InterventionPanel participant={{ id: item.participant_id, id_action_formation: item.id_action_formation, nom: item.nom, prenom: item.prenom, email: item.email }} />
                        </td>
                      </tr>
                    )}
                    </React.Fragment>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="flex items-center justify-between mt-6">
            <p className="text-sm text-gray-600 dark:text-gray-400">
              {pageStart + 1}-{pageEnd} / {totalItems}
            </p>
            <div className="flex items-center gap-1">
              <button onClick={() => setCurrentPage(1)} disabled={safePage <= 1}
                className="p-2 rounded hover:bg-gray-100 dark:hover:bg-slate-700 disabled:opacity-30 disabled:cursor-not-allowed text-gray-600 dark:text-gray-400">
                <ChevronsLeft size={16} />
              </button>
              <button onClick={() => setCurrentPage(p => Math.max(1, p - 1))} disabled={safePage <= 1}
                className="p-2 rounded hover:bg-gray-100 dark:hover:bg-slate-700 disabled:opacity-30 disabled:cursor-not-allowed text-gray-600 dark:text-gray-400">
                <ChevronLeft size={16} />
              </button>
              <span className="px-3 py-1 text-sm font-medium text-gray-700 dark:text-gray-300">
                {safePage} / {totalPages}
              </span>
              <button onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))} disabled={safePage >= totalPages}
                className="p-2 rounded hover:bg-gray-100 dark:hover:bg-slate-700 disabled:opacity-30 disabled:cursor-not-allowed text-gray-600 dark:text-gray-400">
                <ChevronRight size={16} />
              </button>
              <button onClick={() => setCurrentPage(totalPages)} disabled={safePage >= totalPages}
                className="p-2 rounded hover:bg-gray-100 dark:hover:bg-slate-700 disabled:opacity-30 disabled:cursor-not-allowed text-gray-600 dark:text-gray-400">
                <ChevronsRight size={16} />
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default ModuleManagement;

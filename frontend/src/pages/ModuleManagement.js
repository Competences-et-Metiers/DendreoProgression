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
} from 'lucide-react';
import { apiService } from '../services/api';
import { queryKeys } from '../queryClient';
import ProgressBar from '../components/ProgressBar';
import LoadingSpinner from '../components/LoadingSpinner';

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

  // Threshold
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

  // ADF filter
  const [selectedADFs, setSelectedADFs] = useState(() => {
    const cached = localStorage.getItem('moduleManagement.selectedADFs');
    return cached ? JSON.parse(cached) : [];
  });
  const [showAdfDropdown, setShowAdfDropdown] = useState(false);
  const [adfSearchTerm, setAdfSearchTerm] = useState('');

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

  // Pagination
  const [pageSize, setPageSize] = useState(() => {
    const cached = localStorage.getItem('moduleManagement.pageSize');
    return cached ? JSON.parse(cached) : 50;
  });
  const [currentPage, setCurrentPage] = useState(1);

  // Expanded states
  const [expandedGroups, setExpandedGroups] = useState(new Set());

  // Persist state
  useEffect(() => { localStorage.setItem('moduleManagement.selectedADFs', JSON.stringify(selectedADFs)); }, [selectedADFs]);
  useEffect(() => { localStorage.setItem('moduleManagement.selectedCategories', JSON.stringify(selectedCategories)); }, [selectedCategories]);
  useEffect(() => { localStorage.setItem('moduleManagement.selectedModuleType', selectedModuleType); }, [selectedModuleType]);
  useEffect(() => { localStorage.setItem('moduleManagement.searchTerm', searchTerm); }, [searchTerm]);
  useEffect(() => { localStorage.setItem('moduleManagement.pageSize', JSON.stringify(pageSize)); }, [pageSize]);

  // Reset pagination when filters change
  useEffect(() => {
    setCurrentPage(1);
  }, [selectedADFs, selectedCategories, selectedModuleType, searchTerm, threshold, pageSize, viewMode]);

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

  const handleSearchChange = (value) => {
    setSearchTerm(value);
  };

  const handleViewModeChange = () => {
    const next = viewMode === 'course' ? 'participant' : 'course';
    setViewMode(next);
    sessionStorage.setItem('moduleManagement.viewMode', next);
  };

  const handlePageSizeChange = (size) => {
    setPageSize(size);
  };

  const hasActiveFilters = selectedADFs.length > 0 || selectedCategories.length > 0 || selectedModuleType !== 'all' || searchTerm || threshold !== 95;

  const resetAllFilters = useCallback(() => {
    setSelectedADFs([]);
    setSelectedCategories([]);
    setSelectedModuleType('all');
    setSearchTerm('');
    setThreshold(95);
    sessionStorage.setItem('moduleManagement.threshold', 95);
    localStorage.removeItem('moduleManagement.searchTerm');
  }, []);

  const formatDate = (dateString) => {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return date.toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric' });
  };

  const daysSince = (dateString) => {
    if (!dateString) return 0;
    return Math.floor((new Date() - new Date(dateString)) / (1000 * 60 * 60 * 24));
  };

  const toggleGroup = (key) => {
    setExpandedGroups(prev => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  };

  // Extract unique ADFs and categories
  const { adfList, categoryList } = useMemo(() => {
    if (!data?.items) return { adfList: [], categoryList: [] };
    const adfs = new Map();
    const cats = new Map();
    for (const item of data.items) {
      if (!adfs.has(item.id_action_formation)) {
        adfs.set(item.id_action_formation, item.course_title);
      }
      if (item.category_name && !cats.has(item.category_name)) {
        cats.set(item.category_name, item.category_color || '');
      }
    }
    return {
      adfList: Array.from(adfs.entries()).map(([id, title]) => ({ id, title })).sort((a, b) => a.title.localeCompare(b.title)),
      categoryList: Array.from(cats.entries()).map(([name, color]) => ({ name, color })).sort((a, b) => a.name.localeCompare(b.name)),
    };
  }, [data]);

  // Apply all filters
  const filteredItems = useMemo(() => {
    if (!data?.items) return [];
    return data.items.filter((item) => {
      if (item.progression >= threshold) return false;
      if (selectedADFs.length > 0 && !selectedADFs.includes(item.id_action_formation)) return false;
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
  }, [data, threshold, searchTerm, selectedADFs, selectedCategories, selectedModuleType]);

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
    return Object.entries(groups).sort(([, a], [, b]) => new Date(a.date_fin) - new Date(b.date_fin));
  }, [filteredItems, viewMode]);

  // Participant view: flat list
  const flatItems = useMemo(() => {
    if (viewMode !== 'participant') return [];
    return [...filteredItems].sort((a, b) => a.progression - b.progression);
  }, [filteredItems, viewMode]);

  // Pagination
  const totalItems = viewMode === 'course' ? groupEntries.length : flatItems.length;
  const effectivePageSize = pageSize === 0 ? totalItems : pageSize;
  const totalPages = Math.max(1, Math.ceil(totalItems / effectivePageSize));
  const safePage = Math.min(currentPage, totalPages);
  const pageStart = (safePage - 1) * effectivePageSize;
  const pageEnd = Math.min(pageStart + effectivePageSize, totalItems);
  const paginatedGroups = groupEntries.slice(pageStart, pageEnd);
  const paginatedFlat = flatItems.slice(pageStart, pageEnd);

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

            <div className="flex items-center gap-3">
              {hasActiveFilters && (
                <button
                  onClick={resetAllFilters}
                  className="flex items-center gap-2 px-4 py-2 rounded-lg border border-red-200 dark:border-red-800 bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-900/30 transition-colors"
                >
                  <X size={18} />
                  <span className="font-medium">{t('moduleManagement.resetFilters')}</span>
                </button>
              )}

              <button
                onClick={handleViewModeChange}
                className="flex items-center gap-2 px-4 py-2 bg-white dark:bg-slate-800 border border-gray-300 dark:border-slate-600 rounded-lg text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors"
              >
                <BarChart3 size={18} />
                <span className="font-medium">
                  {viewMode === 'course' ? t('moduleManagement.viewParticipant') : t('moduleManagement.viewCourse')}
                </span>
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Filter Bar - always visible */}
        <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700 p-4 mb-6 space-y-4">
          {/* Row 1: Module type pills + threshold */}
          <div className="flex flex-col lg:flex-row gap-4">
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

            {/* Divider */}
            <div className="hidden lg:block w-px bg-gray-200 dark:bg-slate-600" />

            {/* Threshold */}
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
          </div>

          {/* Row 2: ADF + Category Filters side by side */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 border-t border-gray-100 dark:border-slate-700 pt-4">
            {/* ADF Filter */}
            <div>
              <button
                onClick={() => { setShowAdfDropdown(!showAdfDropdown); setShowCategoryDropdown(false); }}
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
                {showAdfDropdown ? <ChevronDown size={16} /> : <ChevronRight size={16} />}
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

            {/* Category Filter */}
            <div>
              <button
                onClick={() => { setShowCategoryDropdown(!showCategoryDropdown); setShowAdfDropdown(false); }}
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
                {showCategoryDropdown ? <ChevronDown size={16} /> : <ChevronRight size={16} />}
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
              onChange={(e) => handleSearchChange(e.target.value)}
              placeholder={t('moduleManagement.searchPlaceholder')}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white text-sm focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
            />
          </div>
          <div className="flex items-center gap-4">
            <span className="text-sm text-gray-600 dark:text-gray-400">
              <Target size={14} className="inline mr-1" />
              {t('moduleManagement.statsCount', { count: filteredItems.length, threshold })}
            </span>
            <div className="flex items-center gap-1 border-l border-gray-300 dark:border-slate-600 pl-4">
              {PAGE_SIZE_OPTIONS.map(size => (
                <button
                  key={size}
                  onClick={() => handlePageSizeChange(size)}
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
              const daysOverdue = daysSince(group.date_fin);

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
                          {group.course_title}
                        </h3>
                        <div className="flex items-center gap-2 mt-0.5">
                          <span className="text-xs text-gray-500 dark:text-gray-400">
                            {group.module_intitule} - {MODE_LABELS[group.mode_organisation] || group.mode_organisation}
                          </span>
                          {group.category_name && (
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
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        daysOverdue > 30
                          ? 'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400'
                          : daysOverdue > 7
                          ? 'bg-orange-100 dark:bg-orange-900/30 text-orange-700 dark:text-orange-400'
                          : 'bg-yellow-100 dark:bg-yellow-900/30 text-yellow-700 dark:text-yellow-400'
                      }`}>
                        <Clock size={10} className="mr-1" />
                        +{daysOverdue}j
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
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">{t('moduleManagement.type')}</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider w-64">{t('moduleManagement.progression')}</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-200 dark:divide-slate-700">
                          {group.participants
                            .sort((a, b) => a.progression - b.progression)
                            .map((item) => (
                              <tr key={`${item.participant_id}-${item.id_lam}`} className="hover:bg-gray-50 dark:hover:bg-slate-700/30 transition-colors">
                                <td className="px-6 py-3">
                                  <Link to={`/participants/${item.participant_id}`} className="text-sm font-medium text-primary-600 dark:text-primary-400 hover:underline">
                                    {item.prenom} {item.nom}
                                  </Link>
                                  <p className="text-xs text-gray-500 dark:text-gray-400">{item.email}</p>
                                </td>
                                <td className="px-6 py-3">
                                  <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${MODE_COLORS[item.mode_organisation] || 'bg-gray-100 dark:bg-slate-700 text-gray-700 dark:text-gray-300'}`}>
                                    {MODE_LABELS[item.mode_organisation] || item.mode_organisation}: {item.progression.toFixed(1)}%
                                  </span>
                                </td>
                                <td className="px-6 py-3">
                                  <ProgressBar percentage={item.progression} size="small" />
                                </td>
                              </tr>
                            ))}
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
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">{t('moduleManagement.type')}</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Deadline</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider w-48">{t('moduleManagement.progression')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 dark:divide-slate-700">
                {paginatedFlat.map((item) => {
                  const daysOverdue = daysSince(item.date_fin);
                  return (
                    <tr key={`${item.participant_id}-${item.id_lam}`} className="hover:bg-gray-50 dark:hover:bg-slate-700/30 transition-colors">
                      <td className="px-6 py-3">
                        <Link to={`/participants/${item.participant_id}`} className="text-sm font-medium text-primary-600 dark:text-primary-400 hover:underline">
                          {item.prenom} {item.nom}
                        </Link>
                        <p className="text-xs text-gray-500 dark:text-gray-400">{item.email}</p>
                      </td>
                      <td className="px-6 py-3">
                        <div className="text-sm text-gray-900 dark:text-white">{item.course_title}</div>
                        <div className="flex items-center gap-2 mt-0.5">
                          <span className="text-xs text-gray-500 dark:text-gray-400">{item.module_intitule}</span>
                          {item.category_name && (
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
                      <td className="px-6 py-3">
                        <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${MODE_COLORS[item.mode_organisation] || 'bg-gray-100 dark:bg-slate-700 text-gray-700 dark:text-gray-300'}`}>
                          {MODE_LABELS[item.mode_organisation] || item.mode_organisation}: {item.progression.toFixed(1)}%
                        </span>
                      </td>
                      <td className="px-6 py-3">
                        <span className="text-xs text-gray-500 dark:text-gray-400">{formatDate(item.date_fin)}</span>
                        <span className={`ml-2 inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${
                          daysOverdue > 30
                            ? 'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400'
                            : daysOverdue > 7
                            ? 'bg-orange-100 dark:bg-orange-900/30 text-orange-700 dark:text-orange-400'
                            : 'bg-yellow-100 dark:bg-yellow-900/30 text-yellow-700 dark:text-yellow-400'
                        }`}>
                          +{daysOverdue}j
                        </span>
                      </td>
                      <td className="px-6 py-3">
                        <ProgressBar percentage={item.progression} size="small" />
                      </td>
                    </tr>
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

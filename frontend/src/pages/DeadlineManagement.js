import React, { useState, useMemo, useCallback } from 'react';
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
  Settings,
  Search,
  BarChart3,
  X,
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

const PAGE_SIZE_OPTIONS = [25, 50, 100, 0];

const DeadlineManagement = () => {
  // Threshold
  const [threshold, setThreshold] = useState(() => {
    const cached = sessionStorage.getItem('deadlineManagement.threshold');
    return cached !== null ? Number(cached) : 95;
  });
  const [showSettings, setShowSettings] = useState(false);

  // Search
  const [searchTerm, setSearchTerm] = useState(() => {
    return localStorage.getItem('deadlineManagement.searchTerm') || '';
  });

  // View toggle: 'course' (grouped) or 'participant' (flat)
  const [viewMode, setViewMode] = useState(() => {
    const cached = sessionStorage.getItem('deadlineManagement.viewMode');
    return cached || 'course';
  });

  // Filters
  const [selectedADFs, setSelectedADFs] = useState(() => {
    const cached = localStorage.getItem('deadlineManagement.selectedADFs');
    return cached ? JSON.parse(cached) : [];
  });
  const [selectedCategories, setSelectedCategories] = useState(() => {
    const cached = localStorage.getItem('deadlineManagement.selectedCategories');
    return cached ? JSON.parse(cached) : [];
  });

  // Pagination
  const [pageSize, setPageSize] = useState(() => {
    const cached = localStorage.getItem('deadlineManagement.pageSize');
    return cached ? JSON.parse(cached) : 50;
  });
  const [currentPage, setCurrentPage] = useState(1);

  // Expanded states
  const [expandedGroups, setExpandedGroups] = useState(new Set());

  // Filter dropdowns
  const [showADFFilter, setShowADFFilter] = useState(false);
  const [showCategoryFilter, setShowCategoryFilter] = useState(false);
  const [adfSearch, setAdfSearch] = useState('');
  const [categorySearch, setCategorySearch] = useState('');

  const { data, isLoading, error } = useQuery({
    queryKey: queryKeys.deadlineData,
    queryFn: () => apiService.getDeadlineData(),
    staleTime: 5 * 60 * 1000,
  });

  const handleThresholdChange = (value) => {
    const v = Math.max(0, Math.min(100, Number(value)));
    setThreshold(v);
    sessionStorage.setItem('deadlineManagement.threshold', v);
    setCurrentPage(1);
  };

  const handleSearchChange = (value) => {
    setSearchTerm(value);
    localStorage.setItem('deadlineManagement.searchTerm', value);
    setCurrentPage(1);
  };

  const handleViewModeChange = () => {
    const next = viewMode === 'course' ? 'participant' : 'course';
    setViewMode(next);
    sessionStorage.setItem('deadlineManagement.viewMode', next);
    setCurrentPage(1);
  };

  const handlePageSizeChange = (size) => {
    setPageSize(size);
    localStorage.setItem('deadlineManagement.pageSize', JSON.stringify(size));
    setCurrentPage(1);
  };

  const handleADFToggle = useCallback((adfId) => {
    setSelectedADFs(prev => {
      const next = prev.includes(adfId) ? prev.filter(a => a !== adfId) : [...prev, adfId];
      localStorage.setItem('deadlineManagement.selectedADFs', JSON.stringify(next));
      return next;
    });
    setCurrentPage(1);
  }, []);

  const handleCategoryToggle = useCallback((catName) => {
    setSelectedCategories(prev => {
      const next = prev.includes(catName) ? prev.filter(c => c !== catName) : [...prev, catName];
      localStorage.setItem('deadlineManagement.selectedCategories', JSON.stringify(next));
      return next;
    });
    setCurrentPage(1);
  }, []);

  const hasActiveFilters = selectedADFs.length > 0 || selectedCategories.length > 0;

  const resetAllFilters = () => {
    setSelectedADFs([]);
    setSelectedCategories([]);
    localStorage.removeItem('deadlineManagement.selectedADFs');
    localStorage.removeItem('deadlineManagement.selectedCategories');
    setCurrentPage(1);
  };

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
  }, [data, threshold, searchTerm, selectedADFs, selectedCategories]);

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
              <div className="p-2 bg-red-100 dark:bg-red-900/30 rounded-lg mr-4">
                <AlertTriangle size={24} className="text-red-600 dark:text-red-400" />
              </div>
              <div>
                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                  Gestion de Deadline
                </h1>
                <p className="text-gray-600 dark:text-gray-400 mt-1">
                  Modules dont la date de fin est d&eacute;pass&eacute;e avec une progression insuffisante
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
                  <span className="font-medium">Retirer les filtres</span>
                </button>
              )}

              <button
                onClick={() => setShowSettings(!showSettings)}
                className={`flex items-center gap-2 px-4 py-2 rounded-lg border transition-colors ${
                  showSettings
                    ? 'bg-primary-50 dark:bg-primary-900/30 border-primary-200 dark:border-primary-800 text-primary-700 dark:text-primary-400'
                    : 'bg-white dark:bg-slate-800 border-gray-300 dark:border-slate-600 text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-slate-700'
                }`}
              >
                <Settings size={18} />
                <span className="font-medium">Param&egrave;tres</span>
              </button>

              <button
                onClick={handleViewModeChange}
                className="flex items-center gap-2 px-4 py-2 bg-white dark:bg-slate-800 border border-gray-300 dark:border-slate-600 rounded-lg text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors"
              >
                <BarChart3 size={18} />
                <span className="font-medium">
                  {viewMode === 'course' ? 'Vue Participant' : 'Vue Formation'}
                </span>
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Settings Panel */}
        {showSettings && (
          <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700 p-6 mb-6">
            <div className="flex items-center gap-2 mb-4">
              <Settings size={20} className="text-gray-600 dark:text-gray-400" />
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                Filtres &amp; Seuil
              </h3>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {/* Threshold Slider */}
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Seuil de progression
                </label>
                <div className="flex items-center gap-4">
                  <input
                    type="range"
                    min="0"
                    max="100"
                    value={threshold}
                    onChange={(e) => handleThresholdChange(e.target.value)}
                    className="flex-1 h-2 bg-gray-200 dark:bg-slate-600 rounded-lg appearance-none cursor-pointer"
                  />
                  <div className="flex items-center gap-1">
                    <input
                      type="number"
                      min="0"
                      max="100"
                      value={threshold}
                      onChange={(e) => handleThresholdChange(e.target.value)}
                      className="w-16 px-2 py-1 border border-gray-300 dark:border-slate-600 rounded text-center text-sm bg-white dark:bg-slate-700 text-gray-900 dark:text-white"
                    />
                    <span className="text-sm text-gray-500 dark:text-gray-400">%</span>
                  </div>
                </div>
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-2">
                  Afficher les participants avec une progression strictement inf&eacute;rieure &agrave; {threshold}%
                </p>
              </div>

              {/* ADF Filter */}
              <div className="relative">
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Filtrer par ADF
                </label>
                <button
                  onClick={() => { setShowADFFilter(!showADFFilter); setShowCategoryFilter(false); }}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-sm text-left text-gray-900 dark:text-white"
                >
                  {selectedADFs.length === 0 ? 'Toutes les ADF' : `${selectedADFs.length} s\u00e9lectionn\u00e9e(s)`}
                  <ChevronDown size={14} className="float-right mt-0.5 text-gray-400" />
                </button>
                {showADFFilter && (
                  <div className="absolute z-20 mt-1 w-full max-h-64 overflow-y-auto bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-600 rounded-lg shadow-lg">
                    <div className="p-2 border-b border-gray-100 dark:border-slate-700">
                      <input
                        type="text"
                        value={adfSearch}
                        onChange={(e) => setAdfSearch(e.target.value)}
                        placeholder="Rechercher..."
                        className="w-full px-2 py-1 text-xs border border-gray-200 dark:border-slate-600 rounded bg-white dark:bg-slate-700 text-gray-900 dark:text-white"
                      />
                    </div>
                    {adfList
                      .filter(a => !adfSearch || a.title.toLowerCase().includes(adfSearch.toLowerCase()))
                      .map(adf => (
                        <label key={adf.id} className="flex items-center gap-2 px-3 py-2 hover:bg-gray-50 dark:hover:bg-slate-700 cursor-pointer text-xs">
                          <input
                            type="checkbox"
                            checked={selectedADFs.includes(adf.id)}
                            onChange={() => handleADFToggle(adf.id)}
                            className="w-3.5 h-3.5 rounded"
                          />
                          <span className="text-gray-700 dark:text-gray-300 truncate">{adf.title}</span>
                        </label>
                      ))}
                  </div>
                )}
              </div>

              {/* Category Filter */}
              <div className="relative">
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Filtrer par cat&eacute;gorie
                </label>
                <button
                  onClick={() => { setShowCategoryFilter(!showCategoryFilter); setShowADFFilter(false); }}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-sm text-left text-gray-900 dark:text-white"
                >
                  {selectedCategories.length === 0 ? 'Toutes les cat\u00e9gories' : `${selectedCategories.length} s\u00e9lectionn\u00e9e(s)`}
                  <ChevronDown size={14} className="float-right mt-0.5 text-gray-400" />
                </button>
                {showCategoryFilter && (
                  <div className="absolute z-20 mt-1 w-full max-h-64 overflow-y-auto bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-600 rounded-lg shadow-lg">
                    <div className="p-2 border-b border-gray-100 dark:border-slate-700">
                      <input
                        type="text"
                        value={categorySearch}
                        onChange={(e) => setCategorySearch(e.target.value)}
                        placeholder="Rechercher..."
                        className="w-full px-2 py-1 text-xs border border-gray-200 dark:border-slate-600 rounded bg-white dark:bg-slate-700 text-gray-900 dark:text-white"
                      />
                    </div>
                    {categoryList
                      .filter(c => !categorySearch || c.name.toLowerCase().includes(categorySearch.toLowerCase()))
                      .map(cat => (
                        <label key={cat.name} className="flex items-center gap-2 px-3 py-2 hover:bg-gray-50 dark:hover:bg-slate-700 cursor-pointer text-xs">
                          <input
                            type="checkbox"
                            checked={selectedCategories.includes(cat.name)}
                            onChange={() => handleCategoryToggle(cat.name)}
                            className="w-3.5 h-3.5 rounded"
                          />
                          {cat.color && (
                            <span className="inline-block w-2.5 h-2.5 rounded-full flex-shrink-0" style={{ backgroundColor: `#${cat.color}` }} />
                          )}
                          <span className="text-gray-700 dark:text-gray-300 truncate">{cat.name}</span>
                        </label>
                      ))}
                  </div>
                )}
              </div>
            </div>
          </div>
        )}

        {/* Search + Stats + Page Size Bar */}
        <div className="flex items-center justify-between mb-6">
          <div className="relative w-80">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => handleSearchChange(e.target.value)}
              placeholder="Rechercher par nom, email ou formation..."
              className="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white text-sm focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
            />
          </div>
          <div className="flex items-center gap-4">
            <span className="text-sm text-gray-600 dark:text-gray-400">
              <Target size={14} className="inline mr-1" />
              {filteredItems.length} module(s) sous {threshold}%
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
              Aucun retard d&eacute;tect&eacute;
            </h3>
            <p className="text-gray-500 dark:text-gray-400">
              Tous les participants ont une progression sup&eacute;rieure ou &eacute;gale &agrave; {threshold}% pour les modules dont la date de fin est d&eacute;pass&eacute;e.
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
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Participant</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Type</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider w-64">Progression</th>
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
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Participant</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Formation</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Type</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Deadline</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider w-48">Progression</th>
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

export default DeadlineManagement;

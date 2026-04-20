import React, { useState, useMemo, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import {
  ClipboardList,
  Search,
  ArrowUpDown,
  ArrowUp,
  ArrowDown,
  Filter,
  Loader2,
  Phone,
  AlarmClock,
  Mail,
  MessageSquare,
  Ban,
  ChevronLeft,
  ChevronRight,
  Download,
  CheckCircle2,
  XCircle,
  Calendar,
  User,
  X,
} from 'lucide-react';
import { adminService } from '../services/admin';
import { queryKeys } from '../queryClient';

const TYPE_CONFIG = {
  call:    { icon: Phone,         label: 'Appels',  iconClass: 'text-blue-600',   pillClass: 'bg-blue-50 dark:bg-blue-900/20 text-blue-700 dark:text-blue-400 border-blue-200 dark:border-blue-800',     selectedCard: 'border-blue-300 ring-1 ring-blue-200',   filterPill: 'bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-800 text-blue-700 dark:text-blue-400' },
  snooze:  { icon: AlarmClock,    label: 'Reports',  iconClass: 'text-amber-600',  pillClass: 'bg-amber-50 dark:bg-amber-900/20 text-amber-700 dark:text-amber-400 border-amber-200 dark:border-amber-800',   selectedCard: 'border-amber-300 ring-1 ring-amber-200', filterPill: 'bg-amber-50 dark:bg-amber-900/20 border-amber-200 dark:border-amber-800 text-amber-700 dark:text-amber-400' },
  note:    { icon: MessageSquare, label: 'Notes',    iconClass: 'text-green-600',  pillClass: 'bg-green-50 dark:bg-green-900/20 text-green-700 dark:text-green-400 border-green-200 dark:border-green-800',   selectedCard: 'border-green-300 ring-1 ring-green-200', filterPill: 'bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-800 text-green-700 dark:text-green-400' },
  email:   { icon: Mail,          label: 'Emails',   iconClass: 'text-purple-600', pillClass: 'bg-purple-50 dark:bg-purple-900/20 text-purple-700 dark:text-purple-400 border-purple-200 dark:border-purple-800', selectedCard: 'border-purple-300 ring-1 ring-purple-200', filterPill: 'bg-purple-50 dark:bg-purple-900/20 border-purple-200 dark:border-purple-800 text-purple-700 dark:text-purple-400' },
  dismiss: { icon: Ban,           label: 'Écartés',  iconClass: 'text-red-600',    pillClass: 'bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-400 border-red-200 dark:border-red-800',         selectedCard: 'border-red-300 ring-1 ring-red-200',     filterPill: 'bg-red-50 dark:bg-red-900/20 border-red-200 dark:border-red-800 text-red-700 dark:text-red-400' },
};

const AdminInterventions = () => {
  const { t } = useTranslation();

  // Filter state
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(50);
  const [sortOrder, setSortOrder] = useState('desc');
  const [typeFilter, setTypeFilter] = useState(null);
  const [activeFilter, setActiveFilter] = useState(null);
  const [userFilter, setUserFilter] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [searchInput, setSearchInput] = useState('');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');

  // Build query params
  const queryParams = useMemo(() => ({
    page,
    page_size: pageSize,
    sort_order: sortOrder,
    intervention_type: typeFilter,
    is_active: activeFilter,
    user_id: userFilter,
    search: searchTerm || undefined,
    date_from: dateFrom || undefined,
    date_to: dateTo || undefined,
  }), [page, pageSize, sortOrder, typeFilter, activeFilter, userFilter, searchTerm, dateFrom, dateTo]);

  // Queries
  const { data, isLoading, isFetching } = useQuery({
    queryKey: queryKeys.adminInterventions(queryParams),
    queryFn: () => adminService.getInterventions(queryParams),
    staleTime: 30 * 1000,
    keepPreviousData: true,
  });

  const { data: stats } = useQuery({
    queryKey: queryKeys.adminInterventionStats,
    queryFn: adminService.getInterventionStats,
    staleTime: 60 * 1000,
  });

  const items = data?.items || [];
  const total = data?.total || 0;
  const totalPages = data?.total_pages || 1;

  // Handlers
  const handleSearch = useCallback((e) => {
    e.preventDefault();
    setSearchTerm(searchInput);
    setPage(1);
  }, [searchInput]);

  const clearSearch = useCallback(() => {
    setSearchInput('');
    setSearchTerm('');
    setPage(1);
  }, []);

  const toggleSort = useCallback(() => {
    setSortOrder(prev => prev === 'desc' ? 'asc' : 'desc');
    setPage(1);
  }, []);

  const setTypeFilterAndReset = useCallback((type) => {
    setTypeFilter(prev => prev === type ? null : type);
    setPage(1);
  }, []);

  const setActiveFilterAndReset = useCallback((val) => {
    setActiveFilter(prev => prev === val ? null : val);
    setPage(1);
  }, []);

  const setUserFilterAndReset = useCallback((id) => {
    setUserFilter(prev => prev === id ? null : id);
    setPage(1);
  }, []);

  const resetFilters = useCallback(() => {
    setTypeFilter(null);
    setActiveFilter(null);
    setUserFilter(null);
    setSearchInput('');
    setSearchTerm('');
    setDateFrom('');
    setDateTo('');
    setPage(1);
  }, []);

  const hasFilters = typeFilter || activeFilter !== null || userFilter || searchTerm || dateFrom || dateTo;

  // CSV export
  const handleExport = useCallback(async () => {
    try {
      const allData = await adminService.getInterventions({
        ...queryParams,
        page: 1,
        page_size: 10000,
      });
      const rows = [
        ['Date', 'Type', 'Participant', 'Staff', 'Status', 'Details'].join(','),
        ...allData.items.map(iv => [
          iv.created_at ? new Date(iv.created_at).toLocaleString('fr-FR') : '',
          iv.intervention_type,
          `"${(iv.participant_name || '').replace(/"/g, '""')}"`,
          `"${(iv.user_display_name || '').replace(/"/g, '""')}"`,
          iv.is_active ? 'Effectué' : 'Annulé',
          `"${getDetailText(iv).replace(/"/g, '""')}"`,
        ].join(','))
      ];
      const blob = new Blob([rows.join('\n')], { type: 'text/csv;charset=utf-8;' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `interventions_${new Date().toISOString().slice(0, 10)}.csv`;
      a.click();
      URL.revokeObjectURL(url);
    } catch (e) {
      console.error('Export failed:', e);
    }
  }, [queryParams]);

  // Helper: extract readable detail text
  const getDetailText = (iv) => {
    if (!iv.details) return '';
    if (iv.intervention_type === 'note') return iv.details.text || '';
    if (iv.intervention_type === 'snooze') return iv.details.reason || `${iv.details.snooze_days}j`;
    if (iv.intervention_type === 'email') return iv.details.recipient || '';
    if (iv.intervention_type === 'dismiss') return iv.details.reason || '';
    return '';
  };

  return (
    <>
      {/* Page Header */}
      <div className="bg-white dark:bg-slate-800 border-b border-gray-200 dark:border-slate-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center">
              <div className="p-2 bg-primary-100 dark:bg-primary-900/30 rounded-lg mr-4">
                <ClipboardList size={24} className="text-primary-600" />
              </div>
              <div>
                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                  {t('adminInterventions.title')}
                </h1>
                <p className="text-gray-600 dark:text-gray-400 mt-1">
                  {t('adminInterventions.subtitle')}
                </p>
              </div>
            </div>
            <div className="flex items-center gap-3">
              {hasFilters && (
                <button
                  onClick={resetFilters}
                  className="flex items-center gap-2 px-4 py-2 rounded-lg border border-red-200 dark:border-red-800 bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-400 hover:bg-red-100 transition-colors"
                >
                  <X size={18} />
                  <span className="font-medium">{t('adminInterventions.resetFilters')}</span>
                </button>
              )}
              <button
                onClick={handleExport}
                className="flex items-center gap-2 px-4 py-2 bg-white dark:bg-slate-800 border border-gray-300 dark:border-slate-600 rounded-lg text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors"
              >
                <Download size={18} />
                <span className="font-medium">CSV</span>
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-6">
        {/* Stats cards */}
        {stats && (
          <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-7 gap-4">
            <div className="bg-white dark:bg-slate-800 rounded-xl border border-gray-200 dark:border-slate-700 p-5 shadow-sm">
              <div className="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Total</div>
              <div className="text-3xl font-bold text-gray-900 dark:text-white mt-2">{stats.total}</div>
            </div>
            {Object.entries(TYPE_CONFIG).map(([type, cfg]) => {
              const Icon = cfg.icon;
              const count = stats.by_type?.[type] || 0;
              return (
                <button
                  key={type}
                  onClick={() => setTypeFilterAndReset(type)}
                  className={`bg-white dark:bg-slate-800 rounded-xl border p-5 text-left transition-all shadow-sm ${
                    typeFilter === type ? cfg.selectedCard : 'border-gray-200 dark:border-slate-700 hover:border-gray-300 dark:hover:border-slate-600 hover:shadow'
                  }`}
                >
                  <div className="flex items-center gap-1.5">
                    <Icon size={14} className={cfg.iconClass} />
                    <span className="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">{cfg.label}</span>
                  </div>
                  <div className="text-3xl font-bold text-gray-900 dark:text-white mt-2">{count}</div>
                </button>
              );
            })}
            <div className="bg-amber-50 dark:bg-amber-900/20 rounded-xl border border-amber-200 dark:border-amber-800 p-5 shadow-sm">
              <div className="text-xs font-medium text-amber-600 uppercase tracking-wider">{t('adminInterventions.stats.activeSnoozes')}</div>
              <div className="text-3xl font-bold text-amber-700 dark:text-amber-400 mt-2">{stats.active_snoozes || 0}</div>
            </div>
          </div>
        )}

        {/* Search bar */}
        <div className="bg-white dark:bg-slate-800 rounded-xl border border-gray-200 dark:border-slate-700 shadow-sm overflow-hidden">
          <div className="p-4">
            <form onSubmit={handleSearch} className="relative">
              <Search size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 dark:text-gray-500" />
              <input
                type="text"
                value={searchInput}
                onChange={(e) => setSearchInput(e.target.value)}
                placeholder={t('adminInterventions.searchPlaceholder')}
                className="w-full pl-11 pr-10 py-2.5 border border-gray-200 dark:border-slate-600 rounded-lg text-sm dark:bg-slate-700 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
              />
              {searchInput && (
                <button type="button" onClick={clearSearch} className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 dark:text-gray-500 hover:text-gray-600 dark:hover:text-gray-300">
                  <X size={16} />
                </button>
              )}
            </form>
          </div>

          {/* Filter rows */}
          <div className="px-4 pb-4 space-y-3">
            {/* Row 1: Sort + Type + Status */}
            <div className="flex items-center gap-2 flex-wrap">
              <button
                onClick={toggleSort}
                className="flex items-center gap-1.5 px-3 py-1.5 rounded-full border border-primary-200 dark:border-primary-800 bg-primary-50 dark:bg-primary-900/30 text-primary-700 dark:text-primary-400 text-xs font-medium transition-colors hover:bg-primary-100"
              >
                <ArrowUpDown size={12} />
                {sortOrder === 'desc' ? t('adminInterventions.newestFirst') : t('adminInterventions.oldestFirst')}
                {sortOrder === 'desc' ? <ArrowDown size={10} /> : <ArrowUp size={10} />}
              </button>

              <div className="w-px h-5 bg-gray-200 dark:bg-slate-600 mx-1" />

              <span className="text-xs font-semibold text-gray-500 dark:text-gray-400 flex items-center gap-1 mr-1">
                <Filter size={12} />
                Type
              </span>
              {Object.entries(TYPE_CONFIG).map(([type, cfg]) => {
                const Icon = cfg.icon;
                const isSelected = typeFilter === type;
                return (
                  <button
                    key={type}
                    onClick={() => setTypeFilterAndReset(type)}
                    className={`flex items-center gap-1 px-3 py-1.5 rounded-full border text-xs font-medium transition-colors ${
                      isSelected
                        ? cfg.filterPill
                        : 'bg-white dark:bg-slate-800 border-gray-200 dark:border-slate-700 text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-slate-700'
                    }`}
                  >
                    <Icon size={12} />
                    {cfg.label}
                  </button>
                );
              })}

              <div className="w-px h-5 bg-gray-200 dark:bg-slate-600 mx-1" />

              <button
                onClick={() => setActiveFilterAndReset(true)}
                className={`flex items-center gap-1 px-3 py-1.5 rounded-full border text-xs font-medium transition-colors ${
                  activeFilter === true ? 'bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-800 text-green-700 dark:text-green-400' : 'bg-white dark:bg-slate-800 border-gray-200 dark:border-slate-700 text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-slate-700'
                }`}
              >
                <CheckCircle2 size={12} />
                {t('adminInterventions.active')}
              </button>
              <button
                onClick={() => setActiveFilterAndReset(false)}
                className={`flex items-center gap-1 px-3 py-1.5 rounded-full border text-xs font-medium transition-colors ${
                  activeFilter === false ? 'bg-gray-100 dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-700 dark:text-gray-300' : 'bg-white dark:bg-slate-800 border-gray-200 dark:border-slate-700 text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-slate-700'
                }`}
              >
                <XCircle size={12} />
                {t('adminInterventions.cancelled')}
              </button>
            </div>

            {/* Row 2: Date range + Staff */}
            <div className="flex items-center gap-2 flex-wrap">
              <div className="flex items-center gap-2">
                <Calendar size={14} className="text-gray-400 dark:text-gray-500" />
                <input
                  type="date"
                  value={dateFrom}
                  onChange={(e) => { setDateFrom(e.target.value); setPage(1); }}
                  className="px-2.5 py-1.5 border border-gray-200 dark:border-slate-600 rounded-lg text-xs dark:bg-slate-700 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                />
                <span className="text-gray-300 dark:text-gray-600 text-xs">—</span>
                <input
                  type="date"
                  value={dateTo}
                  onChange={(e) => { setDateTo(e.target.value); setPage(1); }}
                  className="px-2.5 py-1.5 border border-gray-200 dark:border-slate-600 rounded-lg text-xs dark:bg-slate-700 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                />
              </div>

              {stats?.staff?.length > 0 && (
                <>
                  <div className="w-px h-5 bg-gray-200 dark:bg-slate-600 mx-1" />
                  <span className="text-xs font-semibold text-gray-500 dark:text-gray-400 flex items-center gap-1 mr-1">
                    <User size={12} />
                    {t('adminInterventions.staff')}
                  </span>
                  <select
                    value={userFilter ?? ''}
                    onChange={(e) => {
                      const val = e.target.value;
                      setUserFilter(val === '' ? null : Number(val));
                      setPage(1);
                    }}
                    className="px-3 py-1.5 rounded-full border text-xs font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-primary-500 bg-white dark:bg-slate-800 border-gray-200 dark:border-slate-700 text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-slate-700"
                  >
                    <option value="">{t('adminInterventions.allStaff', 'Tous')}</option>
                    {stats.staff.map(s => (
                      <option key={s.id} value={s.id}>
                        {s.display_name} ({s.count})
                      </option>
                    ))}
                  </select>
                </>
              )}
            </div>
          </div>
        </div>

        {/* Results bar */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <span className="text-sm font-medium text-gray-700 dark:text-gray-300">
              {total} {t('adminInterventions.results')}
              {isFetching && !isLoading && <Loader2 size={14} className="inline ml-2 animate-spin text-primary-500" />}
            </span>
            <div className="flex items-center gap-1">
              {[25, 50, 100].map(size => (
                <button
                  key={size}
                  onClick={() => { setPageSize(size); setPage(1); }}
                  className={`px-2.5 py-1 rounded-md text-xs font-medium transition-colors ${
                    pageSize === size
                      ? 'bg-primary-600 text-white'
                      : 'bg-gray-100 dark:bg-slate-700 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-slate-600'
                  }`}
                >
                  {size}
                </button>
              ))}
              <span className="text-xs text-gray-400 dark:text-gray-500 ml-1">/ page</span>
            </div>
          </div>
          {totalPages > 1 && (
            <div className="flex items-center gap-1.5">
              <button
                onClick={() => setPage(p => Math.max(1, p - 1))}
                disabled={page <= 1}
                className="p-1.5 rounded-lg border border-gray-200 dark:border-slate-700 hover:bg-gray-50 dark:hover:bg-slate-700 disabled:opacity-30 disabled:cursor-not-allowed transition-colors dark:text-gray-300"
              >
                <ChevronLeft size={16} />
              </button>
              <span className="text-sm text-gray-600 dark:text-gray-400 min-w-[60px] text-center">
                {page} / {totalPages}
              </span>
              <button
                onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                disabled={page >= totalPages}
                className="p-1.5 rounded-lg border border-gray-200 dark:border-slate-700 hover:bg-gray-50 dark:hover:bg-slate-700 disabled:opacity-30 disabled:cursor-not-allowed transition-colors dark:text-gray-300"
              >
                <ChevronRight size={16} />
              </button>
            </div>
          )}
        </div>

        {/* Table */}
        <div className="bg-white dark:bg-slate-800 rounded-xl border border-gray-200 dark:border-slate-700 shadow-sm overflow-hidden">
          {isLoading ? (
            <div className="flex items-center justify-center py-24">
              <Loader2 size={28} className="animate-spin text-primary-600" />
            </div>
          ) : items.length === 0 ? (
            <div className="text-center py-24 text-gray-400 dark:text-gray-500">
              <ClipboardList size={40} className="mx-auto mb-3 opacity-40" />
              <p className="text-sm">{t('adminInterventions.noResults')}</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-gray-200 dark:border-slate-700 bg-gray-50/80 dark:bg-slate-900/50">
                    <th className="text-left px-5 py-3.5 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">{t('adminInterventions.table.date')}</th>
                    <th className="text-left px-5 py-3.5 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Type</th>
                    <th className="text-left px-5 py-3.5 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">{t('adminInterventions.table.participant')}</th>
                    <th className="text-left px-5 py-3.5 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">{t('adminInterventions.table.staff')}</th>
                    <th className="text-left px-5 py-3.5 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">{t('adminInterventions.table.status')}</th>
                    <th className="text-left px-5 py-3.5 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">{t('adminInterventions.table.details')}</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100 dark:divide-slate-700">
                  {items.map(iv => {
                    const cfg = TYPE_CONFIG[iv.intervention_type] || {};
                    const Icon = cfg.icon || MessageSquare;
                    return (
                      <tr key={iv.id} className={`transition-colors hover:bg-gray-50/50 dark:hover:bg-slate-700/50 ${!iv.is_active ? 'opacity-40' : ''}`}>
                        <td className="px-5 py-3.5 whitespace-nowrap text-gray-500 dark:text-gray-400 tabular-nums">
                          {iv.created_at ? new Date(iv.created_at).toLocaleDateString('fr-FR', {
                            day: '2-digit', month: '2-digit', year: 'numeric',
                            hour: '2-digit', minute: '2-digit'
                          }) : '—'}
                        </td>
                        <td className="px-5 py-3.5">
                          <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium border ${cfg.pillClass || 'bg-gray-50 dark:bg-slate-900 text-gray-600 dark:text-gray-400 border-gray-200 dark:border-slate-700'}`}>
                            <Icon size={12} />
                            {cfg.label || iv.intervention_type}
                          </span>
                        </td>
                        <td className="px-5 py-3.5">
                          {iv.participant_id ? (
                            <Link
                              to={`/participants/${iv.participant_id}`}
                              className="font-medium text-gray-900 dark:text-white hover:text-primary-600 transition-colors"
                            >
                              {iv.participant_name || `#${iv.participant_id}`}
                            </Link>
                          ) : '—'}
                        </td>
                        <td className="px-5 py-3.5 text-gray-600 dark:text-gray-400">
                          {iv.user_display_name || '—'}
                        </td>
                        <td className="px-5 py-3.5">
                          {iv.is_active ? (
                            <span className="inline-flex items-center gap-1 text-xs font-medium text-green-700 dark:text-green-400">
                              <CheckCircle2 size={12} />
                              {t('adminInterventions.active')}
                            </span>
                          ) : (
                            <span className="inline-flex items-center gap-1 text-xs font-medium text-gray-400 dark:text-gray-500">
                              <XCircle size={12} />
                              {t('adminInterventions.cancelled')}
                            </span>
                          )}
                          {iv.intervention_type === 'snooze' && iv.snooze_until && (
                            <div className="text-[10px] text-gray-400 dark:text-gray-500 mt-0.5">
                              → {new Date(iv.snooze_until).toLocaleDateString('fr-FR')}
                            </div>
                          )}
                        </td>
                        <td className="px-5 py-3.5 text-gray-500 dark:text-gray-400 max-w-xs truncate">
                          {getDetailText(iv)}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </>
  );
};

export default AdminInterventions;

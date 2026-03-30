import React, { useState, useMemo, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import {
  Shield,
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
  call:    { icon: Phone,         label: 'Appels',  iconClass: 'text-blue-600',   pillClass: 'bg-blue-50 text-blue-700 border-blue-200',     selectedCard: 'border-blue-300 ring-1 ring-blue-200',   filterPill: 'bg-blue-50 border-blue-200 text-blue-700' },
  snooze:  { icon: AlarmClock,    label: 'Reports',  iconClass: 'text-amber-600',  pillClass: 'bg-amber-50 text-amber-700 border-amber-200',   selectedCard: 'border-amber-300 ring-1 ring-amber-200', filterPill: 'bg-amber-50 border-amber-200 text-amber-700' },
  note:    { icon: MessageSquare, label: 'Notes',    iconClass: 'text-green-600',  pillClass: 'bg-green-50 text-green-700 border-green-200',   selectedCard: 'border-green-300 ring-1 ring-green-200', filterPill: 'bg-green-50 border-green-200 text-green-700' },
  email:   { icon: Mail,          label: 'Emails',   iconClass: 'text-purple-600', pillClass: 'bg-purple-50 text-purple-700 border-purple-200', selectedCard: 'border-purple-300 ring-1 ring-purple-200', filterPill: 'bg-purple-50 border-purple-200 text-purple-700' },
  dismiss: { icon: Ban,           label: 'Écartés',  iconClass: 'text-red-600',    pillClass: 'bg-red-50 text-red-700 border-red-200',         selectedCard: 'border-red-300 ring-1 ring-red-200',     filterPill: 'bg-red-50 border-red-200 text-red-700' },
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
          iv.is_active ? 'Active' : 'Cancelled',
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
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
            <Shield className="text-primary-600" size={24} />
            {t('adminInterventions.title')}
          </h1>
          <p className="text-sm text-gray-500 mt-1">{t('adminInterventions.subtitle')}</p>
        </div>
        <button
          onClick={handleExport}
          className="flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-lg border border-gray-200 bg-white text-gray-700 hover:bg-gray-50 transition-colors"
        >
          <Download size={16} />
          CSV
        </button>
      </div>

      {/* Stats cards */}
      {stats && (
        <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-3">
          <div className="bg-white rounded-xl border border-gray-200 p-4">
            <div className="text-xs text-gray-500 uppercase tracking-wide">{t('adminInterventions.stats.total')}</div>
            <div className="text-2xl font-bold text-gray-900 mt-1">{stats.total}</div>
          </div>
          {Object.entries(TYPE_CONFIG).map(([type, cfg]) => {
            const Icon = cfg.icon;
            const count = stats.by_type?.[type] || 0;
            return (
              <button
                key={type}
                onClick={() => setTypeFilterAndReset(type)}
                className={`bg-white rounded-xl border p-4 text-left transition-colors ${
                  typeFilter === type ? cfg.selectedCard : 'border-gray-200 hover:border-gray-300'
                }`}
              >
                <div className="flex items-center gap-1.5">
                  <Icon size={12} className={cfg.iconClass} />
                  <span className="text-xs text-gray-500 uppercase tracking-wide">{cfg.label}</span>
                </div>
                <div className="text-2xl font-bold text-gray-900 mt-1">{count}</div>
              </button>
            );
          })}
          <div className="bg-white rounded-xl border border-amber-200 p-4">
            <div className="text-xs text-amber-600 uppercase tracking-wide">{t('adminInterventions.stats.activeSnoozes')}</div>
            <div className="text-2xl font-bold text-amber-700 mt-1">{stats.active_snoozes || 0}</div>
          </div>
        </div>
      )}

      {/* Filters */}
      <div className="bg-white rounded-xl border border-gray-200 shadow-sm p-4 space-y-4">
        {/* Search + date range */}
        <div className="flex flex-col lg:flex-row gap-3">
          <form onSubmit={handleSearch} className="flex-1 relative">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              value={searchInput}
              onChange={(e) => setSearchInput(e.target.value)}
              placeholder={t('adminInterventions.searchPlaceholder')}
              className="w-full pl-10 pr-10 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
            />
            {searchInput && (
              <button type="button" onClick={clearSearch} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
                <X size={14} />
              </button>
            )}
          </form>
          <div className="flex items-center gap-2">
            <Calendar size={14} className="text-gray-400" />
            <input
              type="date"
              value={dateFrom}
              onChange={(e) => { setDateFrom(e.target.value); setPage(1); }}
              className="px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
            />
            <span className="text-gray-400 text-sm">—</span>
            <input
              type="date"
              value={dateTo}
              onChange={(e) => { setDateTo(e.target.value); setPage(1); }}
              className="px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
            />
          </div>
        </div>

        {/* Type + status + staff filters */}
        <div className="flex flex-col lg:flex-row gap-4">
          {/* Sort */}
          <button
            onClick={toggleSort}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-full border border-gray-200 text-xs font-medium bg-white text-gray-600 hover:bg-gray-50 transition-colors"
          >
            <ArrowUpDown size={12} />
            {sortOrder === 'desc' ? t('adminInterventions.newestFirst') : t('adminInterventions.oldestFirst')}
            {sortOrder === 'desc' ? <ArrowDown size={10} /> : <ArrowUp size={10} />}
          </button>

          <div className="hidden lg:block w-px bg-gray-200" />

          {/* Type pills */}
          <div className="flex items-center gap-2 flex-wrap">
            <span className="text-xs font-semibold text-gray-500 flex items-center gap-1">
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
                      : 'bg-white border-gray-200 text-gray-600 hover:bg-gray-50'
                  }`}
                >
                  <Icon size={12} />
                  {cfg.label}
                </button>
              );
            })}
          </div>

          <div className="hidden lg:block w-px bg-gray-200" />

          {/* Active/cancelled pills */}
          <div className="flex items-center gap-2">
            <button
              onClick={() => setActiveFilterAndReset(true)}
              className={`flex items-center gap-1 px-3 py-1.5 rounded-full border text-xs font-medium transition-colors ${
                activeFilter === true ? 'bg-green-50 border-green-200 text-green-700' : 'bg-white border-gray-200 text-gray-600 hover:bg-gray-50'
              }`}
            >
              <CheckCircle2 size={12} />
              {t('adminInterventions.active')}
            </button>
            <button
              onClick={() => setActiveFilterAndReset(false)}
              className={`flex items-center gap-1 px-3 py-1.5 rounded-full border text-xs font-medium transition-colors ${
                activeFilter === false ? 'bg-gray-100 border-gray-300 text-gray-700' : 'bg-white border-gray-200 text-gray-600 hover:bg-gray-50'
              }`}
            >
              <XCircle size={12} />
              {t('adminInterventions.cancelled')}
            </button>
          </div>
        </div>

        {/* Staff filter */}
        {stats?.staff?.length > 0 && (
          <div className="flex items-center gap-2 flex-wrap border-t border-gray-100 pt-3">
            <span className="text-xs font-semibold text-gray-500 flex items-center gap-1">
              <User size={12} />
              {t('adminInterventions.staff')}
            </span>
            {stats.staff.map(s => (
              <button
                key={s.id}
                onClick={() => setUserFilterAndReset(s.id)}
                className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full border text-xs font-medium transition-colors ${
                  userFilter === s.id ? 'bg-primary-50 border-primary-200 text-primary-700' : 'bg-white border-gray-200 text-gray-600 hover:bg-gray-50'
                }`}
              >
                {s.display_name}
                <span className="text-[10px] opacity-60">({s.count})</span>
              </button>
            ))}
          </div>
        )}

        {/* Reset */}
        {hasFilters && (
          <div className="flex items-center">
            <button onClick={resetFilters} className="text-xs text-primary-600 hover:text-primary-700 font-medium flex items-center gap-1">
              <X size={12} />
              {t('adminInterventions.resetFilters')}
            </button>
          </div>
        )}
      </div>

      {/* Results count + pagination controls */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <span className="text-sm text-gray-600">
            {total} {t('adminInterventions.results')}
            {isFetching && !isLoading && <Loader2 size={14} className="inline ml-2 animate-spin" />}
          </span>
          <div className="flex items-center gap-1.5">
            {[25, 50, 100].map(size => (
              <button
                key={size}
                onClick={() => { setPageSize(size); setPage(1); }}
                className={`px-2.5 py-1 rounded text-xs font-medium transition-colors ${
                  pageSize === size ? 'bg-primary-100 text-primary-700' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
              >
                {size}
              </button>
            ))}
            <span className="text-xs text-gray-400">/ page</span>
          </div>
        </div>
        {totalPages > 1 && (
          <div className="flex items-center gap-2">
            <button
              onClick={() => setPage(p => Math.max(1, p - 1))}
              disabled={page <= 1}
              className="p-1.5 rounded-lg border border-gray-200 hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed"
            >
              <ChevronLeft size={16} />
            </button>
            <span className="text-sm text-gray-600">
              {page} / {totalPages}
            </span>
            <button
              onClick={() => setPage(p => Math.min(totalPages, p + 1))}
              disabled={page >= totalPages}
              className="p-1.5 rounded-lg border border-gray-200 hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed"
            >
              <ChevronRight size={16} />
            </button>
          </div>
        )}
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
        {isLoading ? (
          <div className="flex items-center justify-center py-20">
            <Loader2 size={24} className="animate-spin text-primary-600" />
          </div>
        ) : items.length === 0 ? (
          <div className="text-center py-20 text-gray-500">
            {t('adminInterventions.noResults')}
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="text-left px-4 py-3 font-semibold text-gray-600">{t('adminInterventions.table.date')}</th>
                  <th className="text-left px-4 py-3 font-semibold text-gray-600">Type</th>
                  <th className="text-left px-4 py-3 font-semibold text-gray-600">{t('adminInterventions.table.participant')}</th>
                  <th className="text-left px-4 py-3 font-semibold text-gray-600">{t('adminInterventions.table.staff')}</th>
                  <th className="text-left px-4 py-3 font-semibold text-gray-600">{t('adminInterventions.table.status')}</th>
                  <th className="text-left px-4 py-3 font-semibold text-gray-600">{t('adminInterventions.table.details')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {items.map(iv => {
                  const cfg = TYPE_CONFIG[iv.intervention_type] || {};
                  const Icon = cfg.icon || MessageSquare;
                  return (
                    <tr key={iv.id} className={`hover:bg-gray-50 transition-colors ${!iv.is_active ? 'opacity-50' : ''}`}>
                      <td className="px-4 py-3 whitespace-nowrap text-gray-600">
                        {iv.created_at ? new Date(iv.created_at).toLocaleDateString('fr-FR', {
                          day: '2-digit', month: '2-digit', year: 'numeric',
                          hour: '2-digit', minute: '2-digit'
                        }) : '—'}
                      </td>
                      <td className="px-4 py-3">
                        <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium border ${cfg.pillClass}`}>
                          <Icon size={12} />
                          {cfg.label || iv.intervention_type}
                        </span>
                      </td>
                      <td className="px-4 py-3">
                        {iv.participant_id ? (
                          <Link
                            to={`/participants/${iv.participant_id}`}
                            className="text-gray-900 hover:text-primary-600 font-medium transition-colors"
                          >
                            {iv.participant_name || `#${iv.participant_id}`}
                          </Link>
                        ) : '—'}
                      </td>
                      <td className="px-4 py-3 text-gray-600">
                        {iv.user_display_name || '—'}
                      </td>
                      <td className="px-4 py-3">
                        {iv.is_active ? (
                          <span className="inline-flex items-center gap-1 text-xs text-green-700">
                            <CheckCircle2 size={12} />
                            {t('adminInterventions.active')}
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 text-xs text-gray-500">
                            <XCircle size={12} />
                            {t('adminInterventions.cancelled')}
                          </span>
                        )}
                        {iv.intervention_type === 'snooze' && iv.snooze_until && (
                          <div className="text-[10px] text-gray-400 mt-0.5">
                            → {new Date(iv.snooze_until).toLocaleDateString('fr-FR')}
                          </div>
                        )}
                      </td>
                      <td className="px-4 py-3 text-gray-600 max-w-xs truncate">
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
  );
};

export default AdminInterventions;

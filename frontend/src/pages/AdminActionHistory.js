import React, { useState, useMemo, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import {
  History,
  Search,
  ArrowUpDown,
  ArrowUp,
  ArrowDown,
  Filter,
  Loader2,
  Link2,
  Unlink,
  ChevronLeft,
  ChevronRight,
  CheckCircle2,
  XCircle,
  AlertTriangle,
  Ban,
  User,
  X,
  ExternalLink,
  Cpu,
} from 'lucide-react';
import { adminService } from '../services/admin';
import { queryKeys } from '../queryClient';

const ACTION_CONFIG = {
  link_deal: {
    icon: Link2,
    label: 'Lier deal',
    iconClass: 'text-green-600',
    pillClass: 'bg-green-50 dark:bg-green-900/20 text-green-700 dark:text-green-400 border-green-200 dark:border-green-800',
    selectedCard: 'border-green-300 ring-1 ring-green-200',
  },
  unlink_deal: {
    icon: Unlink,
    label: 'Délier deal',
    iconClass: 'text-red-600',
    pillClass: 'bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-400 border-red-200 dark:border-red-800',
    selectedCard: 'border-red-300 ring-1 ring-red-200',
  },
};

const STATUS_CONFIG = {
  success:  { icon: CheckCircle2,   label: 'Succès',   pillClass: 'bg-green-50 dark:bg-green-900/20 text-green-700 dark:text-green-400 border-green-200 dark:border-green-800' },
  partial:  { icon: AlertTriangle,  label: 'Partiel',  pillClass: 'bg-amber-50 dark:bg-amber-900/20 text-amber-700 dark:text-amber-400 border-amber-200 dark:border-amber-800' },
  error:    { icon: XCircle,        label: 'Échec',    pillClass: 'bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-400 border-red-200 dark:border-red-800' },
  blocked:  { icon: Ban,            label: 'Bloqué',   pillClass: 'bg-gray-100 dark:bg-slate-700 text-gray-600 dark:text-gray-400 border-gray-300 dark:border-slate-600' },
};

const AdminActionHistory = () => {
  const { t } = useTranslation();

  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(50);
  const [sortOrder, setSortOrder] = useState('desc');
  const [typeFilter, setTypeFilter] = useState(null);
  const [statusFilter, setStatusFilter] = useState(null);
  const [userFilter, setUserFilter] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [searchInput, setSearchInput] = useState('');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');

  const queryParams = useMemo(() => ({
    page,
    page_size: pageSize,
    sort_order: sortOrder,
    action_type: typeFilter,
    status: statusFilter,
    user_id: userFilter,
    search: searchTerm || undefined,
    date_from: dateFrom || undefined,
    date_to: dateTo || undefined,
  }), [page, pageSize, sortOrder, typeFilter, statusFilter, userFilter, searchTerm, dateFrom, dateTo]);

  const { data, isLoading, isFetching } = useQuery({
    queryKey: queryKeys.adminActionHistory(queryParams),
    queryFn: () => adminService.getActionHistory(queryParams),
    staleTime: 30 * 1000,
    keepPreviousData: true,
  });

  const { data: stats } = useQuery({
    queryKey: queryKeys.adminActionHistoryStats,
    queryFn: adminService.getActionHistoryStats,
    staleTime: 60 * 1000,
  });

  const items = data?.items || [];
  const total = data?.total || 0;
  const totalPages = data?.total_pages || 1;

  const toggleSort = useCallback(() => {
    setSortOrder(prev => prev === 'desc' ? 'asc' : 'desc');
    setPage(1);
  }, []);
  const setTypeFilterAndReset = useCallback((t) => {
    setTypeFilter(prev => prev === t ? null : t);
    setPage(1);
  }, []);
  const setStatusFilterAndReset = useCallback((s) => {
    setStatusFilter(prev => prev === s ? null : s);
    setPage(1);
  }, []);

  const handleSearch = (e) => {
    e.preventDefault();
    setSearchTerm(searchInput);
    setPage(1);
  };
  const clearSearch = () => { setSearchInput(''); setSearchTerm(''); setPage(1); };

  const resetFilters = () => {
    setTypeFilter(null); setStatusFilter(null); setUserFilter(null);
    setSearchInput(''); setSearchTerm(''); setDateFrom(''); setDateTo('');
    setPage(1);
  };
  const hasFilters = typeFilter || statusFilter || userFilter || searchTerm || dateFrom || dateTo;

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-slate-900">
      {/* Header */}
      <div className="bg-white dark:bg-slate-800 border-b border-gray-200 dark:border-slate-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center">
              <div className="p-2 bg-primary-100 dark:bg-primary-900/30 rounded-lg mr-4">
                <History size={24} className="text-primary-600 dark:text-primary-400" />
              </div>
              <div>
                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Historique des actions</h1>
                <p className="text-gray-600 dark:text-gray-400 mt-1">Actions manuelles et liens HubSpot/Dendreo</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-6">
        {/* Stats cards */}
        {stats && (
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4">
            <div className="bg-white dark:bg-slate-800 rounded-xl border border-gray-200 dark:border-slate-700 p-5 shadow-sm">
              <div className="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Total</div>
              <div className="text-3xl font-bold text-gray-900 dark:text-white mt-2">{stats.total}</div>
            </div>
            {Object.entries(ACTION_CONFIG).map(([type, cfg]) => {
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
            <div className="bg-red-50 dark:bg-red-900/20 rounded-xl border border-red-200 dark:border-red-800 p-5 shadow-sm">
              <div className="text-xs font-medium text-red-600 uppercase tracking-wider">Échecs / Bloqués</div>
              <div className="text-3xl font-bold text-red-700 dark:text-red-400 mt-2">{(stats.by_status?.error || 0) + (stats.by_status?.blocked || 0)}</div>
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
                placeholder="Rechercher par nom de participant..."
                className="w-full pl-11 pr-10 py-2.5 border border-gray-200 dark:border-slate-600 rounded-lg text-sm dark:bg-slate-700 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
              />
              {searchInput && (
                <button type="button" onClick={clearSearch} className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 dark:text-gray-500 hover:text-gray-600 dark:hover:text-gray-300">
                  <X size={16} />
                </button>
              )}
            </form>
          </div>

          <div className="px-4 pb-4 space-y-3">
            {/* Sort + Type + Status pills */}
            <div className="flex items-center gap-2 flex-wrap">
              <button
                onClick={toggleSort}
                className="flex items-center gap-1.5 px-3 py-1.5 rounded-full border border-primary-200 dark:border-primary-800 bg-primary-50 dark:bg-primary-900/30 text-primary-700 dark:text-primary-400 text-xs font-medium transition-colors hover:bg-primary-100"
              >
                <ArrowUpDown size={12} />
                {sortOrder === 'desc' ? 'Plus récent' : 'Plus ancien'}
                {sortOrder === 'desc' ? <ArrowDown size={10} /> : <ArrowUp size={10} />}
              </button>

              <div className="w-px h-5 bg-gray-200 dark:bg-slate-600 mx-1" />

              <span className="text-xs font-semibold text-gray-500 dark:text-gray-400 flex items-center gap-1 mr-1">
                <Filter size={12} />
                Type
              </span>
              {Object.entries(ACTION_CONFIG).map(([type, cfg]) => {
                const Icon = cfg.icon;
                const isSelected = typeFilter === type;
                return (
                  <button
                    key={type}
                    onClick={() => setTypeFilterAndReset(type)}
                    className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full border text-xs font-medium transition-colors ${isSelected ? cfg.pillClass : 'bg-white dark:bg-slate-800 border-gray-200 dark:border-slate-700 text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-slate-700'}`}
                  >
                    <Icon size={12} />
                    {cfg.label}
                  </button>
                );
              })}

              <div className="w-px h-5 bg-gray-200 dark:bg-slate-600 mx-1" />

              <span className="text-xs font-semibold text-gray-500 dark:text-gray-400 flex items-center gap-1 mr-1">Statut</span>
              {Object.entries(STATUS_CONFIG).map(([s, cfg]) => {
                const Icon = cfg.icon;
                const isSelected = statusFilter === s;
                return (
                  <button
                    key={s}
                    onClick={() => setStatusFilterAndReset(s)}
                    className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full border text-xs font-medium transition-colors ${isSelected ? cfg.pillClass : 'bg-white dark:bg-slate-800 border-gray-200 dark:border-slate-700 text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-slate-700'}`}
                  >
                    <Icon size={12} />
                    {cfg.label}
                  </button>
                );
              })}
            </div>

            {/* Date range + staff + reset */}
            <div className="flex items-center gap-2 flex-wrap">
              <span className="text-xs font-semibold text-gray-500 dark:text-gray-400">Du</span>
              <input
                type="date"
                value={dateFrom}
                onChange={(e) => { setDateFrom(e.target.value); setPage(1); }}
                className="px-2.5 py-1.5 border border-gray-200 dark:border-slate-600 rounded-lg text-xs dark:bg-slate-700 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
              />
              <span className="text-xs font-semibold text-gray-500 dark:text-gray-400">au</span>
              <input
                type="date"
                value={dateTo}
                onChange={(e) => { setDateTo(e.target.value); setPage(1); }}
                className="px-2.5 py-1.5 border border-gray-200 dark:border-slate-600 rounded-lg text-xs dark:bg-slate-700 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
              />

              {stats?.staff?.length > 0 && (
                <>
                  <div className="w-px h-5 bg-gray-200 dark:bg-slate-600 mx-1" />
                  <span className="text-xs font-semibold text-gray-500 dark:text-gray-400 flex items-center gap-1 mr-1">
                    <User size={12} />
                    Source
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
                    <option value="">Tous</option>
                    {stats.staff.map(s => (
                      <option key={s.id} value={s.id}>
                        {s.display_name} ({s.count})
                      </option>
                    ))}
                  </select>
                </>
              )}

              {hasFilters && (
                <button
                  onClick={resetFilters}
                  className="ml-auto flex items-center gap-1 px-3 py-1.5 rounded-full border border-red-200 dark:border-red-800 bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-400 text-xs font-medium hover:bg-red-100"
                >
                  <X size={12} />
                  Réinitialiser
                </button>
              )}
            </div>
          </div>
        </div>

        {/* Results bar */}
        <div className="flex items-center justify-between">
          <span className="text-sm font-medium text-gray-700 dark:text-gray-300">
            {total} résultat(s)
            {isFetching && !isLoading && <Loader2 size={14} className="inline ml-2 animate-spin text-primary-500" />}
          </span>
          <div className="flex items-center gap-1">
            {[25, 50, 100].map(size => (
              <button
                key={size}
                onClick={() => { setPageSize(size); setPage(1); }}
                className={`px-2.5 py-1 rounded-md text-xs font-medium transition-colors ${
                  pageSize === size ? 'bg-primary-600 text-white' : 'bg-gray-100 dark:bg-slate-700 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-slate-600'
                }`}
              >
                {size}
              </button>
            ))}
          </div>
          {totalPages > 1 && (
            <div className="flex items-center gap-1.5">
              <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page <= 1} className="p-1.5 rounded-lg border border-gray-200 dark:border-slate-700 hover:bg-gray-50 dark:hover:bg-slate-700 disabled:opacity-30 dark:text-gray-300">
                <ChevronLeft size={16} />
              </button>
              <span className="text-sm text-gray-600 dark:text-gray-400 min-w-[60px] text-center">{page} / {totalPages}</span>
              <button onClick={() => setPage(p => Math.min(totalPages, p + 1))} disabled={page >= totalPages} className="p-1.5 rounded-lg border border-gray-200 dark:border-slate-700 hover:bg-gray-50 dark:hover:bg-slate-700 disabled:opacity-30 dark:text-gray-300">
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
              <History size={40} className="mx-auto mb-3 opacity-40" />
              <p className="text-sm">Aucune action trouvée</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-gray-200 dark:border-slate-700 bg-gray-50/80 dark:bg-slate-900/50">
                    <th className="text-left px-5 py-3.5 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Date</th>
                    <th className="text-left px-5 py-3.5 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Catégorie</th>
                    <th className="text-left px-5 py-3.5 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Action</th>
                    <th className="text-left px-5 py-3.5 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Participant</th>
                    <th className="text-left px-5 py-3.5 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Source</th>
                    <th className="text-left px-5 py-3.5 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Statut</th>
                    <th className="text-left px-5 py-3.5 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">API (D/H)</th>
                    <th className="text-left px-5 py-3.5 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Deal</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100 dark:divide-slate-700">
                  {items.map(row => {
                    const typeCfg = ACTION_CONFIG[row.action_type] || {};
                    const TypeIcon = typeCfg.icon || History;
                    const statusCfg = STATUS_CONFIG[row.status] || {};
                    const StatusIcon = statusCfg.icon || AlertTriangle;
                    const isSystem = !row.user_id;
                    return (
                      <tr key={row.id} className="transition-colors hover:bg-gray-50/50 dark:hover:bg-slate-700/50">
                        <td className="px-5 py-3.5 whitespace-nowrap text-gray-500 dark:text-gray-400 tabular-nums">
                          {row.created_at ? new Date(row.created_at).toLocaleDateString('fr-FR', {
                            day: '2-digit', month: '2-digit', year: 'numeric',
                            hour: '2-digit', minute: '2-digit'
                          }) : '—'}
                        </td>
                        <td className="px-5 py-3.5">
                          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium border bg-purple-50 dark:bg-purple-900/20 text-purple-700 dark:text-purple-400 border-purple-200 dark:border-purple-800">
                            Manip
                          </span>
                        </td>
                        <td className="px-5 py-3.5">
                          <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium border ${typeCfg.pillClass || 'bg-gray-50 dark:bg-slate-900 text-gray-600 dark:text-gray-400 border-gray-200 dark:border-slate-700'}`}>
                            <TypeIcon size={12} />
                            {typeCfg.label || row.action_type}
                          </span>
                        </td>
                        <td className="px-5 py-3.5">
                          {row.participant_id ? (
                            <Link to={`/participants/${row.participant_id}`} className="font-medium text-gray-900 dark:text-white hover:text-primary-600 transition-colors">
                              {row.participant_name || `#${row.participant_id}`}
                            </Link>
                          ) : '—'}
                        </td>
                        <td className="px-5 py-3.5 text-gray-600 dark:text-gray-400">
                          <span className="inline-flex items-center gap-1.5">
                            {isSystem ? <Cpu size={12} className="text-gray-400" /> : <User size={12} className="text-gray-400" />}
                            {row.source}
                          </span>
                        </td>
                        <td className="px-5 py-3.5">
                          <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium border ${statusCfg.pillClass || 'bg-gray-50 dark:bg-slate-900 text-gray-600 dark:text-gray-400 border-gray-200 dark:border-slate-700'}`} title={row.error_message || ''}>
                            <StatusIcon size={12} />
                            {statusCfg.label || row.status}
                          </span>
                        </td>
                        <td className="px-5 py-3.5 text-gray-600 dark:text-gray-400 tabular-nums text-xs">
                          {row.api_calls_count || 0} / {row.hubspot_api_calls_count || 0}
                        </td>
                        <td className="px-5 py-3.5">
                          {row.deal_id ? (
                            <a
                              href={`https://app-eu1.hubspot.com/contacts/25868618/record/0-3/${row.deal_id}`}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="inline-flex items-center gap-1 text-xs text-primary-600 dark:text-primary-400 hover:underline"
                            >
                              <ExternalLink size={11} />
                              {row.deal_id}
                            </a>
                          ) : '—'}
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
    </div>
  );
};

export default AdminActionHistory;

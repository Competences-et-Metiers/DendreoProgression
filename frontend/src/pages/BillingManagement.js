import React, { useState, useMemo, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import {
  Receipt,
  Search,
  Loader2,
  ExternalLink,
  Clock,
  AlertCircle,
  RefreshCw,
  X,
  Filter,
  ChevronDown,
  ChevronRight,
  BookOpen,
  User,
  Tag,
  Landmark,
} from 'lucide-react';
import { useBillingParticipants, useSetBillingStatus } from '../hooks/useQuery';
import {
  FACTURATION_VALUES,
  NO_DEAL,
  getFacturationTone,
  matchesBillingFilters,
} from '../utils/billing';
import MultiSelectFilter from '../components/MultiSelectFilter';
import Pagination from '../components/Pagination';
import ProgressBar from '../components/ProgressBar';

const EDOF_HOURS_KEY = 'billingManagement.edofHours';
const PAGE_SIZE_KEY = 'billingManagement.pageSize';

const formatEUR = (value) => {
  if (value === null || value === undefined) return '—';
  return new Intl.NumberFormat('fr-FR', {
    style: 'currency',
    currency: 'EUR',
    maximumFractionDigits: 0,
  }).format(value);
};

const formatHours = (hours) => `${(hours || 0).toFixed(1)}h`;

// Ratio of time actually spent to the EDOF expected duration the user typed in.
// Green once the participant has covered the expected time, red while well short.
const edofRatioTone = (ratio) => {
  if (ratio >= 100) return 'bg-green-50 dark:bg-green-900/20 text-green-700 dark:text-green-400 border-green-200 dark:border-green-800';
  if (ratio >= 80) return 'bg-amber-50 dark:bg-amber-900/20 text-amber-700 dark:text-amber-400 border-amber-200 dark:border-amber-800';
  return 'bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-400 border-red-200 dark:border-red-800';
};

// Filter selections survive a reload, like the Inactive Management ones.
const usePersistedList = (name) => {
  const key = `billingManagement.${name}`;
  const [value, setValue] = useState(() => {
    try {
      const cached = JSON.parse(localStorage.getItem(key));
      return Array.isArray(cached) ? cached : [];
    } catch {
      return [];
    }
  });
  useEffect(() => {
    localStorage.setItem(key, JSON.stringify(value));
  }, [key, value]);
  return [value, setValue];
};

const BillingManagement = () => {
  const { t } = useTranslation();

  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [showFilters, setShowFilters] = useState(false);
  const [selectedCourses, setSelectedCourses] = usePersistedList('selectedCourses');
  const [selectedFormateurs, setSelectedFormateurs] = usePersistedList('selectedFormateurs');
  const [selectedCategories, setSelectedCategories] = usePersistedList('selectedCategories');
  const [selectedFinancements, setSelectedFinancements] = usePersistedList('selectedFinancements');
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(() => {
    const saved = parseInt(localStorage.getItem(PAGE_SIZE_KEY), 10);
    return Number.isFinite(saved) && saved > 0 ? saved : 25;
  });
  // View-only comparator: EDOF's expected duration is not in any API and changes
  // on EDOF's side, so it is typed here and applies to every visible row rather
  // than being stored per course where it would silently go stale.
  const [edofHours, setEdofHours] = useState(() => localStorage.getItem(EDOF_HOURS_KEY) || '');
  const [rowError, setRowError] = useState(null);

  const { data, isLoading, isFetching, refetch } = useBillingParticipants();
  const setBillingStatus = useSetBillingStatus();

  useEffect(() => {
    localStorage.setItem(EDOF_HOURS_KEY, edofHours);
  }, [edofHours]);

  useEffect(() => {
    localStorage.setItem(PAGE_SIZE_KEY, String(pageSize));
  }, [pageSize]);

  const rows = useMemo(() => data?.participants || [], [data]);

  // Filter options are derived from the loaded rows, so they only ever offer
  // values that can actually match something.
  const courseOptions = useMemo(() => {
    const seen = new Map();
    rows.forEach((r) => {
      if (r.id_action_formation && !seen.has(r.id_action_formation)) {
        seen.set(r.id_action_formation, r.course_title || r.id_action_formation);
      }
    });
    return [...seen.entries()]
      .map(([value, label]) => ({ value, label }))
      .sort((a, b) => a.label.localeCompare(b.label));
  }, [rows]);

  const formateurOptions = useMemo(() => {
    const seen = new Map();
    rows.forEach((r) => {
      (r.formateurs || []).forEach((f) => {
        if (f.id_formateur && !seen.has(f.id_formateur)) {
          seen.set(f.id_formateur, {
            value: f.id_formateur,
            label: `${f.prenom || ''} ${f.nom || ''}`.trim() || t('billing.unnamedFormateur'),
          });
        }
      });
    });
    return [...seen.values()].sort((a, b) => a.label.localeCompare(b.label));
  }, [rows, t]);

  const categoryOptions = useMemo(() => {
    const seen = new Map();
    rows.forEach((r) => {
      if (r.category_name && !seen.has(r.category_name)) {
        seen.set(r.category_name, {
          value: r.category_name,
          label: r.category_name,
          color: r.category_color || '',
        });
      }
    });
    return [...seen.values()].sort((a, b) => a.label.localeCompare(b.label));
  }, [rows]);

  const financementOptions = useMemo(() => {
    const seen = new Set();
    rows.forEach((r) => {
      if (r.deal_type_financement) seen.add(r.deal_type_financement);
    });
    return [...seen].sort().map((value) => ({ value, label: value }));
  }, [rows]);

  const filtered = useMemo(
    () =>
      rows.filter((r) =>
        matchesBillingFilters(r, {
          courses: selectedCourses,
          formateurs: selectedFormateurs,
          categories: selectedCategories,
          financements: selectedFinancements,
          status: statusFilter,
          search,
        })
      ),
    [
      rows,
      search,
      statusFilter,
      selectedCourses,
      selectedFormateurs,
      selectedCategories,
      selectedFinancements,
    ]
  );

  const activeFilterCount =
    selectedCourses.length +
    selectedFormateurs.length +
    selectedCategories.length +
    selectedFinancements.length;

  const resetFilters = () => {
    setSelectedCourses([]);
    setSelectedFormateurs([]);
    setSelectedCategories([]);
    setSelectedFinancements([]);
    setStatusFilter('');
    setSearch('');
  };

  // Reset to the first page whenever the filters change the result set.
  useEffect(() => {
    setPage(1);
  }, [search, statusFilter, selectedCourses, selectedFormateurs, selectedCategories, selectedFinancements]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / pageSize));
  // A refetch can shrink the list under the current page; without this the user
  // lands on an empty page with no pagination control to get back.
  const currentPage = Math.min(page, totalPages);
  const visible = useMemo(
    () => filtered.slice((currentPage - 1) * pageSize, currentPage * pageSize),
    [filtered, currentPage, pageSize]
  );

  const edofHoursNum = parseFloat(edofHours);
  const hasEdofHours = Number.isFinite(edofHoursNum) && edofHoursNum > 0;

  const handleStatusChange = (row, facturation) => {
    setRowError(null);
    setBillingStatus.mutate(
      {
        participantId: row.id,
        idActionFormation: row.id_action_formation,
        facturation,
        dealId: row.deal_id,
      },
      {
        onError: (err) =>
          setRowError({
            key: `${row.id}-${row.id_action_formation}`,
            message: err?.response?.data?.detail || t('billing.updateError'),
          }),
      }
    );
  };

  const pendingKey = setBillingStatus.isPending
    ? `${setBillingStatus.variables?.participantId}-${setBillingStatus.variables?.idActionFormation}`
    : null;

  return (
    <div className="p-6 space-y-4">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900 dark:text-white flex items-center gap-2">
            <Receipt size={24} className="text-primary-600" />
            {t('billing.title')}
          </h1>
          <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">{t('billing.subtitle')}</p>
        </div>
        <button
          onClick={() => refetch()}
          disabled={isFetching}
          className="inline-flex items-center gap-2 px-3 py-2 text-sm rounded-lg border border-gray-300 dark:border-slate-600 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-slate-700 disabled:opacity-50"
        >
          <RefreshCw size={14} className={isFetching ? 'animate-spin' : ''} />
          {t('billing.refresh')}
        </button>
      </div>

      {/* Toolbar stays in view while scrolling: the EDOF hours field applies to
          every row below it. */}
      <div className="sticky top-0 z-20 -mx-6 px-6 py-3 bg-gray-50/95 dark:bg-slate-900/95 backdrop-blur border-b border-gray-200 dark:border-slate-700">
        <div className="flex flex-wrap items-center gap-3">
          <div className="relative">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder={t('billing.searchPlaceholder')}
              className="pl-9 pr-3 py-2 w-56 text-sm rounded-lg border border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-gray-900 dark:text-white"
            />
          </div>

          <button
            onClick={() => setShowFilters(!showFilters)}
            className={`inline-flex items-center gap-2 px-3 py-2 text-sm rounded-lg border transition-colors ${
              activeFilterCount > 0
                ? 'border-primary-300 dark:border-primary-700 bg-primary-50 dark:bg-primary-900/20 text-primary-700 dark:text-primary-400'
                : 'border-gray-300 dark:border-slate-600 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-slate-700'
            }`}
          >
            <Filter size={14} />
            {t('billing.filters')}
            {activeFilterCount > 0 && (
              <span className="px-1.5 py-0.5 rounded-full bg-primary-100 dark:bg-primary-900/40 text-xs font-medium">
                {activeFilterCount}
              </span>
            )}
            {showFilters ? <ChevronDown size={14} /> : <ChevronRight size={14} />}
          </button>

          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="py-2 px-3 text-sm rounded-lg border border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-gray-900 dark:text-white"
          >
            <option value="">{t('billing.allStatuses')}</option>
            {FACTURATION_VALUES.map((v) => (
              <option key={v} value={v}>{v}</option>
            ))}
            <option value={NO_DEAL}>{t('billing.noDealFilter')}</option>
          </select>

          <div
            className="flex items-center gap-2 ml-auto px-3 py-1.5 rounded-lg border border-primary-200 dark:border-primary-800 bg-primary-50 dark:bg-primary-900/20"
            title={t('billing.edofHoursHint')}
          >
            <Clock size={14} className="text-primary-600 dark:text-primary-400" />
            <label htmlFor="edof-hours" className="text-sm text-gray-700 dark:text-gray-300">
              {t('billing.edofHours')}
            </label>
            <input
              id="edof-hours"
              type="number"
              min="0"
              step="0.5"
              value={edofHours}
              onChange={(e) => setEdofHours(e.target.value)}
              placeholder="—"
              className="w-20 px-2 py-1 text-sm rounded border border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-gray-900 dark:text-white"
            />
            {edofHours && (
              <button
                onClick={() => setEdofHours('')}
                title={t('billing.clearEdofHours')}
                className="p-0.5 rounded text-gray-400 hover:text-gray-600 dark:hover:text-gray-200"
              >
                <X size={14} />
              </button>
            )}
          </div>
        </div>
        {showFilters && (
          <div className="mt-3 grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-3">
            <MultiSelectFilter
              label={t('billing.filterByCourse')}
              icon={BookOpen}
              options={courseOptions}
              selected={selectedCourses}
              onChange={setSelectedCourses}
              searchPlaceholder={t('billing.searchCourse')}
              emptyText={t('billing.noCourseFound')}
              summary={(n) => t('billing.coursesSelected', { count: n })}
            />
            <MultiSelectFilter
              label={t('billing.filterByFormateur')}
              icon={User}
              options={formateurOptions}
              selected={selectedFormateurs}
              onChange={setSelectedFormateurs}
              searchPlaceholder={t('billing.searchFormateur')}
              emptyText={t('billing.noFormateurFound')}
              summary={(n) => t('billing.formateursSelected', { count: n })}
            />
            <MultiSelectFilter
              label={t('billing.filterByCategory')}
              icon={Tag}
              options={categoryOptions}
              selected={selectedCategories}
              onChange={setSelectedCategories}
              searchPlaceholder={t('billing.searchCategory')}
              emptyText={t('billing.noCategoryFound')}
              summary={(n) => t('billing.categoriesSelected', { count: n })}
            />
            <MultiSelectFilter
              label={t('billing.filterByFinancement')}
              icon={Landmark}
              options={financementOptions}
              selected={selectedFinancements}
              onChange={setSelectedFinancements}
              searchPlaceholder={t('billing.searchFinancement')}
              emptyText={t('billing.noFinancementFound')}
              summary={(n) => t('billing.financementsSelected', { count: n })}
            />
          </div>
        )}

        <div className="mt-2 flex items-center gap-3">
          <p className="text-xs text-gray-500 dark:text-gray-400">
            {t('billing.resultCount', { shown: filtered.length, total: rows.length })}
          </p>
          {(activeFilterCount > 0 || statusFilter || search) && (
            <button
              onClick={resetFilters}
              className="text-xs text-primary-600 dark:text-primary-400 hover:underline"
            >
              {t('billing.resetFilters')}
            </button>
          )}
        </div>
      </div>

      {isLoading ? (
        <div className="py-20 flex justify-center">
          <Loader2 className="w-6 h-6 animate-spin text-primary-600" />
        </div>
      ) : (
        <>
          <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700 divide-y divide-gray-200 dark:divide-slate-700">
            {visible.length === 0 && (
              <div className="py-16 text-center text-gray-500 dark:text-gray-400">
                {t('billing.noRows')}
              </div>
            )}

            {visible.map((row) => {
              const rowKey = `${row.id}-${row.id_action_formation}`;
              const busy = pendingKey === rowKey;
              const ratio = hasEdofHours
                ? ((row.total_time_spent_hours || 0) / edofHoursNum) * 100
                : null;

              return (
                <div key={rowKey} className="px-4 py-3 hover:bg-gray-50 dark:hover:bg-slate-700/50">
                  <div className="flex flex-wrap items-center gap-x-4 gap-y-2">
                    <div className="min-w-[200px] flex-1">
                      <Link
                        to={`/participants/${row.id}`}
                        className="font-medium text-gray-900 dark:text-white hover:text-primary-600"
                      >
                        {row.prenom} {row.nom}
                      </Link>
                      <div className="text-xs text-gray-500 dark:text-gray-400 truncate">
                        {row.course_title || row.id_action_formation}
                      </div>
                    </div>

                    {/* Billing status */}
                    <div className="flex items-center gap-2">
                      <select
                        value={row.deal_facturation || ''}
                        disabled={!row.deal_id || busy}
                        onChange={(e) => handleStatusChange(row, e.target.value)}
                        title={row.deal_id ? t('billing.setStatus') : t('billing.noDealLinked')}
                        className={`text-xs font-medium rounded border px-2 py-1 disabled:cursor-not-allowed ${getFacturationTone(row.deal_facturation)}`}
                      >
                        <option value="" disabled>
                          {row.deal_id ? t('billing.noStatus') : t('billing.noDealLinked')}
                        </option>
                        {FACTURATION_VALUES.map((v) => (
                          <option key={v} value={v}>{v}</option>
                        ))}
                      </select>
                      {busy && <Loader2 size={14} className="animate-spin text-primary-600" />}
                      {row.deal_url && (
                        <a
                          href={row.deal_url}
                          target="_blank"
                          rel="noopener noreferrer"
                          title={t('billing.openDeal')}
                          className="p-1 rounded text-gray-400 hover:text-orange-500"
                        >
                          <ExternalLink size={14} />
                        </a>
                      )}
                    </div>

                    {/* Deal financials */}
                    <div className="flex items-center gap-3 text-xs text-gray-600 dark:text-gray-400">
                      <span title={t('hubspotDeal.amount')}>{formatEUR(row.deal_amount)}</span>
                      <span className="text-gray-300 dark:text-slate-600">|</span>
                      <span title={t('hubspotDeal.montantPec')}>
                        {t('hubspotDeal.montantPec')} {formatEUR(row.deal_montant_pec)}
                      </span>
                      <span title={t('hubspotDeal.montantRac')}>
                        {t('hubspotDeal.montantRac')} {formatEUR(row.deal_montant_rac)}
                      </span>
                      {row.deal_type_financement && (
                        <span className="px-1.5 py-0.5 rounded bg-gray-100 dark:bg-slate-700">
                          {row.deal_type_financement}
                        </span>
                      )}
                    </div>

                    {/* Time spent, Dendreo progression, EDOF ratio */}
                    <div className="flex items-center gap-3 text-xs text-gray-600 dark:text-gray-400 min-w-[240px]">
                      <span title={t('billing.timeSpentHint')}>
                        {formatHours(row.total_time_spent_hours)} / {formatHours(row.total_planned_duration_hours)}
                      </span>
                      <div className="w-20">
                        <ProgressBar percentage={row.current_progression || 0} size="small" />
                      </div>
                      <span
                        className={`px-1.5 py-0.5 rounded border font-medium ${
                          ratio === null
                            ? 'bg-gray-50 dark:bg-slate-800 text-gray-400 border-gray-200 dark:border-slate-700'
                            : edofRatioTone(ratio)
                        }`}
                        title={
                          ratio === null
                            ? t('billing.edofHoursHint')
                            : t('billing.edofRatioHint', { hours: edofHoursNum })
                        }
                      >
                        EDOF {ratio === null ? '—' : `${ratio.toFixed(0)}%`}
                      </span>
                    </div>
                  </div>

                  {rowError?.key === rowKey && (
                    <div className="mt-2 flex items-center gap-1.5 text-xs text-red-600 dark:text-red-400">
                      <AlertCircle size={12} />
                      {rowError.message}
                    </div>
                  )}
                </div>
              );
            })}
          </div>

          {filtered.length > 0 && (
            <Pagination
              currentPage={currentPage}
              totalPages={totalPages}
              pageSize={pageSize}
              totalItems={filtered.length}
              onPageChange={setPage}
              onPageSizeChange={(size) => {
                setPageSize(size);
                setPage(1);
              }}
            />
          )}
        </>
      )}
    </div>
  );
};

export default BillingManagement;

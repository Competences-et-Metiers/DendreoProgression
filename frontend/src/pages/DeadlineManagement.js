import React, { useState, useMemo } from 'react';
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
  Target,
  Settings,
  Search,
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

const DeadlineManagement = () => {
  const { t } = useTranslation();
  const [threshold, setThreshold] = useState(() => {
    const cached = sessionStorage.getItem('deadlineManagement.threshold');
    return cached !== null ? Number(cached) : 95;
  });
  const [showSettings, setShowSettings] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [expandedADFs, setExpandedADFs] = useState(new Set());

  const { data, isLoading, error } = useQuery({
    queryKey: queryKeys.deadlineData,
    queryFn: () => apiService.getDeadlineData(),
    staleTime: 5 * 60 * 1000,
  });

  const handleThresholdChange = (value) => {
    const v = Math.max(0, Math.min(100, Number(value)));
    setThreshold(v);
    sessionStorage.setItem('deadlineManagement.threshold', v);
  };

  const formatDate = (dateString) => {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return date.toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric' });
  };

  const daysSince = (dateString) => {
    if (!dateString) return 0;
    const d = new Date(dateString);
    const now = new Date();
    return Math.floor((now - d) / (1000 * 60 * 60 * 24));
  };

  // Filter items below threshold, then group by ADF
  const { grouped, totalFiltered } = useMemo(() => {
    if (!data?.items) return { grouped: {}, totalFiltered: 0 };

    const filtered = data.items.filter((item) => {
      if (item.progression >= threshold) return false;
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

    const groups = {};
    for (const item of filtered) {
      const key = `${item.id_action_formation}_${item.id_lam}`;
      if (!groups[key]) {
        groups[key] = {
          id_action_formation: item.id_action_formation,
          course_title: item.course_title,
          module_intitule: item.module_intitule,
          mode_organisation: item.mode_organisation,
          date_debut: item.date_debut,
          date_fin: item.date_fin,
          participants: [],
        };
      }
      groups[key].participants.push(item);
    }

    return { grouped: groups, totalFiltered: filtered.length };
  }, [data, threshold, searchTerm]);

  const groupEntries = useMemo(() => {
    return Object.entries(grouped).sort(
      ([, a], [, b]) => new Date(a.date_fin) - new Date(b.date_fin)
    );
  }, [grouped]);

  const toggleADF = (key) => {
    setExpandedADFs((prev) => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  };

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
                  {t('deadlineManagement.title')}
                </h1>
                <p className="text-gray-600 dark:text-gray-400 mt-1">
                  {t('deadlineManagement.subtitle')}
                </p>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <button
                onClick={() => setShowSettings(!showSettings)}
                className={`flex items-center gap-2 px-4 py-2 rounded-lg border transition-colors ${
                  showSettings
                    ? 'bg-primary-50 dark:bg-primary-900/30 border-primary-200 dark:border-primary-800 text-primary-700 dark:text-primary-400'
                    : 'bg-white dark:bg-slate-800 border-gray-300 dark:border-slate-600 text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-slate-700'
                }`}
              >
                <Settings size={18} />
                <span className="font-medium">{t('deadlineManagement.settings')}</span>
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
                {t('deadlineManagement.settingsTitle')}
              </h3>
            </div>
            <div className="max-w-md">
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                {t('deadlineManagement.thresholdLabel')}
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
                {t('deadlineManagement.thresholdHelp', { threshold })}
              </p>
            </div>
          </div>
        )}

        {/* Search + Stats Bar */}
        <div className="flex items-center justify-between mb-6">
          <div className="relative w-80">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder={t('deadlineManagement.searchPlaceholder')}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-gray-900 dark:text-white text-sm focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
            />
          </div>
          <div className="flex items-center gap-4">
            <span className="text-sm text-gray-600 dark:text-gray-400">
              <Target size={14} className="inline mr-1" />
              {t('deadlineManagement.statsCount', { count: totalFiltered, threshold })}
            </span>
          </div>
        </div>

        {error && (
          <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4 mb-6">
            <p className="text-red-700 dark:text-red-400">{t('common.error')}: {error.message}</p>
          </div>
        )}

        {/* Empty State */}
        {totalFiltered === 0 && !isLoading && !error && (
          <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700 p-12 text-center">
            <AlertTriangle size={48} className="mx-auto text-gray-300 dark:text-slate-600 mb-4" />
            <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
              {t('deadlineManagement.emptyTitle')}
            </h3>
            <p className="text-gray-500 dark:text-gray-400">
              {t('deadlineManagement.emptyMessage', { threshold })}
            </p>
          </div>
        )}

        {/* Grouped by ADF+Module */}
        <div className="space-y-4">
          {groupEntries.map(([key, group]) => {
            const isExpanded = expandedADFs.has(key);
            const daysOverdue = daysSince(group.date_fin);

            return (
              <div
                key={key}
                className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700 overflow-hidden"
              >
                {/* Group Header */}
                <button
                  onClick={() => toggleADF(key)}
                  className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 dark:hover:bg-slate-700/50 transition-colors"
                >
                  <div className="flex items-center gap-4">
                    {isExpanded ? (
                      <ChevronDown size={20} className="text-gray-400" />
                    ) : (
                      <ChevronRight size={20} className="text-gray-400" />
                    )}
                    <div className="text-left">
                      <h3 className="text-sm font-semibold text-gray-900 dark:text-white">
                        {group.course_title}
                      </h3>
                      <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                        {group.module_intitule} - {MODE_LABELS[group.mode_organisation] || group.mode_organisation}
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center gap-4">
                    <span className="flex items-center text-xs text-gray-500 dark:text-gray-400">
                      <Calendar size={12} className="mr-1" />
                      {formatDate(group.date_debut)} {'\u2192'} {formatDate(group.date_fin)}
                    </span>
                    <span
                      className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        daysOverdue > 30
                          ? 'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400'
                          : daysOverdue > 7
                          ? 'bg-orange-100 dark:bg-orange-900/30 text-orange-700 dark:text-orange-400'
                          : 'bg-yellow-100 dark:bg-yellow-900/30 text-yellow-700 dark:text-yellow-400'
                      }`}
                    >
                      <Clock size={10} className="mr-1" />
                      +{daysOverdue}j
                    </span>
                    <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 dark:bg-slate-700 text-gray-700 dark:text-gray-300">
                      <User size={10} className="mr-1" />
                      {group.participants.length}
                    </span>
                  </div>
                </button>

                {/* Participant List */}
                {isExpanded && (
                  <div className="border-t border-gray-200 dark:border-slate-700">
                    <table className="w-full">
                      <thead>
                        <tr className="bg-gray-50 dark:bg-slate-700/50">
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                            {t('deadlineManagement.participant')}
                          </th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                            {t('deadlineManagement.type')}
                          </th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider w-64">
                            {t('deadlineManagement.progression')}
                          </th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-gray-200 dark:divide-slate-700">
                        {group.participants
                          .sort((a, b) => a.progression - b.progression)
                          .map((item) => (
                            <tr
                              key={`${item.participant_id}-${item.id_lam}`}
                              className="hover:bg-gray-50 dark:hover:bg-slate-700/30 transition-colors"
                            >
                              <td className="px-6 py-3">
                                <Link
                                  to={`/participants/${item.participant_id}`}
                                  className="text-sm font-medium text-primary-600 dark:text-primary-400 hover:underline"
                                >
                                  {item.prenom} {item.nom}
                                </Link>
                                <p className="text-xs text-gray-500 dark:text-gray-400">{item.email}</p>
                              </td>
                              <td className="px-6 py-3">
                                <span
                                  className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${
                                    item.mode_organisation === 'elearning_async'
                                      ? 'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400'
                                      : item.mode_organisation === 'elearning_sync'
                                      ? 'bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-400'
                                      : 'bg-teal-100 dark:bg-teal-900/30 text-teal-700 dark:text-teal-400'
                                  }`}
                                >
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
      </div>
    </div>
  );
};

export default DeadlineManagement;

import React, { useState, useEffect, useRef, useCallback } from 'react';
import { adminService } from '../services/admin';
import {
  Shield,
  Activity,
  Zap,
  Play,
  FlaskConical,
  Target,
  Settings,
  History,
  Clock,
  CheckCircle2,
  XCircle,
  Loader2,
  RefreshCw,
  Save,
  CalendarDays,
  Terminal,
  FastForward,
  StopCircle,
  FolderSync,
  AlertTriangle,
  X,
  ChevronRight,
  ChevronLeft,
} from 'lucide-react';

// Confirmation Modal Component
const ConfirmModal = ({ isOpen, title, message, variant = 'primary', confirmLabel = 'Confirm', onConfirm, onCancel }) => {
  if (!isOpen) return null;

  const variantStyles = {
    primary: { button: 'bg-primary-600 hover:bg-primary-700', icon: <Zap size={24} className="text-primary-600" /> },
    danger: { button: 'bg-red-600 hover:bg-red-700', icon: <XCircle size={24} className="text-red-600" /> },
    warning: { button: 'bg-amber-600 hover:bg-amber-700', icon: <Activity size={24} className="text-amber-600" /> },
    info: { button: 'bg-indigo-600 hover:bg-indigo-700', icon: <Target size={24} className="text-indigo-600" /> },
    teal: { button: 'bg-teal-600 hover:bg-teal-700', icon: <FolderSync size={24} className="text-teal-600" /> },
  };
  const style = variantStyles[variant] || variantStyles.primary;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="fixed inset-0 bg-black/50" onClick={onCancel} />
      <div className="relative bg-white dark:bg-slate-800 rounded-xl shadow-xl border border-gray-200 dark:border-slate-700 max-w-md w-full mx-4 p-6">
        <div className="flex items-start gap-4">
          <div className="flex-shrink-0 p-2 bg-gray-50 dark:bg-slate-900 rounded-lg">{style.icon}</div>
          <div className="flex-1 min-w-0">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white">{title}</h3>
            <p className="mt-2 text-sm text-gray-600 dark:text-gray-400 whitespace-pre-line">{message}</p>
          </div>
        </div>
        <div className="flex justify-end gap-3 mt-6">
          <button
            onClick={onCancel}
            className="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-slate-800 border border-gray-300 dark:border-slate-600 rounded-lg hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors"
          >
            Cancel
          </button>
          <button
            onClick={onConfirm}
            className={`px-4 py-2 text-sm font-medium text-white rounded-lg transition-colors ${style.button}`}
          >
            {confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
};

const AdminSyncDashboard = () => {
  const [apiUsage, setApiUsage] = useState(null);
  const [syncStatus, setSyncStatus] = useState(null);
  const [syncConfig, setSyncConfig] = useState(null);
  const [syncHistory, setSyncHistory] = useState([]);
  const [historyPage, setHistoryPage] = useState(1);
  const [historyPageSize, setHistoryPageSize] = useState(50);
  const [historyTotal, setHistoryTotal] = useState(0);
  const [historyTotalPages, setHistoryTotalPages] = useState(1);
  const [loading, setLoading] = useState(true);
  const [actionOutput, setActionOutput] = useState(null);
  const [adfId, setAdfId] = useState('');

  // Confirmation modal state
  const [confirmModal, setConfirmModal] = useState({ isOpen: false, title: '', message: '', variant: 'primary', confirmLabel: 'Confirm', onConfirm: () => {} });
  const [cooldownHours, setCooldownHours] = useState(12.0);
  const [scheduleDays, setScheduleDays] = useState('0,1,2,3,4');
  const [scheduleTime, setScheduleTime] = useState('08:00');
  const [dendreoApiLimit, setDendreoApiLimit] = useState('');
  const [hubspotApiLimit, setHubspotApiLimit] = useState('');
  const [dendreoDailyLimit, setDendreoDailyLimit] = useState('');
  const [dendreoWeeklyLimit, setDendreoWeeklyLimit] = useState('');
  const [dendreoMonthlyLimit, setDendreoMonthlyLimit] = useState('');
  const [hubspotDailyLimit, setHubspotDailyLimit] = useState('');
  const [hubspotWeeklyLimit, setHubspotWeeklyLimit] = useState('');
  const [hubspotMonthlyLimit, setHubspotMonthlyLimit] = useState('');

  // Sync detail modal
  const [selectedSync, setSelectedSync] = useState(null);

  // Live log state
  const [liveLog, setLiveLog] = useState('');
  const [isPollingLog, setIsPollingLog] = useState(false);
  const [apiCounters, setApiCounters] = useState({ dendreo: 0, hubspot: 0 });
  const pollingRef = useRef(null);
  const logEndRef = useRef(null);
  const logOffsetRef = useRef(0);

  const scrollToLogBottom = () => {
    if (logEndRef.current) {
      logEndRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  };

  const stopPolling = useCallback(() => {
    if (pollingRef.current) {
      clearInterval(pollingRef.current);
      pollingRef.current = null;
    }
    setIsPollingLog(false);
  }, []);

  const pollLog = useCallback(async () => {
    try {
      const data = await adminService.getLiveLog(logOffsetRef.current);
      if (data.content) {
        setLiveLog(prev => prev + data.content);
        logOffsetRef.current = data.offset;
        setTimeout(scrollToLogBottom, 50);
      }
      if (data.api_counters) {
        setApiCounters(data.api_counters);
      }
      if (!data.is_running) {
        stopPolling();
        loadDashboardData();
        // Update actionOutput with final sync result
        if (data.final_status === 'error') {
          setActionOutput({ status: 'error', message: data.final_message || 'Sync failed.' });
        } else if (data.final_status === 'warning') {
          setActionOutput({ status: 'warning', message: data.final_message || 'Sync completed with warnings.' });
        } else if (data.final_status) {
          setActionOutput({ status: 'success', message: data.final_message || 'Sync completed successfully.' });
        }
      }
    } catch (err) {
      console.error('Log poll error:', err);
    }
  }, [stopPolling]);

  const startPolling = useCallback((resetLog = true) => {
    if (pollingRef.current) return;
    if (resetLog) {
      setLiveLog('');
      logOffsetRef.current = 0;
      setApiCounters({ dendreo: 0, hubspot: 0 });
    }
    setIsPollingLog(true);
    pollLog();
    pollingRef.current = setInterval(pollLog, 2000);
  }, [pollLog]);

  // Clean up polling on unmount
  useEffect(() => {
    return () => {
      if (pollingRef.current) clearInterval(pollingRef.current);
    };
  }, []);

  const loadDashboardData = async (isInitial = false) => {
    try {
      if (isInitial) setLoading(true);
      const [usage, status, config, history] = await Promise.all([
        adminService.getApiUsage(),
        adminService.getSyncStatus(),
        adminService.getSyncConfig(),
        adminService.getSyncHistory(historyPage, historyPageSize),
      ]);

      setApiUsage(usage);
      setSyncStatus(status);
      setSyncConfig(config);
      setCooldownHours(config.cooldown_hours);
      setScheduleDays(config.schedule_days || '0,1,2,3,4');
      setScheduleTime(config.schedule_time || '08:00');
      setDendreoApiLimit(config.dendreo_api_limit || '');
      setHubspotApiLimit(config.hubspot_api_limit || '');
      setDendreoDailyLimit(config.dendreo_daily_limit || '');
      setDendreoWeeklyLimit(config.dendreo_weekly_limit || '');
      setDendreoMonthlyLimit(config.dendreo_monthly_limit || '');
      setHubspotDailyLimit(config.hubspot_daily_limit || '');
      setHubspotWeeklyLimit(config.hubspot_weekly_limit || '');
      setHubspotMonthlyLimit(config.hubspot_monthly_limit || '');
      setSyncHistory(history.items || []);
      setHistoryTotal(history.total || 0);
      setHistoryTotalPages(history.total_pages || 1);
    } catch (error) {
      console.error('Failed to load dashboard data:', error);
    } finally {
      if (isInitial) setLoading(false);
    }
  };

  useEffect(() => {
    const init = async () => {
      await loadDashboardData(true);
    };
    init();
    const interval = setInterval(() => loadDashboardData(false), 30000);
    return () => clearInterval(interval);
  }, []);

  // Refetch history when page or page size changes
  useEffect(() => {
    const fetchHistory = async () => {
      try {
        const history = await adminService.getSyncHistory(historyPage, historyPageSize);
        setSyncHistory(history.items || []);
        setHistoryTotal(history.total || 0);
        setHistoryTotalPages(history.total_pages || 1);
      } catch (e) {
        console.error('Failed to load sync history:', e);
      }
    };
    fetchHistory();
  }, [historyPage, historyPageSize]);

  // Start polling if sync is already running on page load
  useEffect(() => {
    if (syncStatus?.is_running && !pollingRef.current) {
      startPolling(true);
    }
  }, [syncStatus?.is_running, startPolling]);

  const showConfirm = (title, message, variant, confirmLabel, onConfirm) => {
    setConfirmModal({ isOpen: true, title, message, variant, confirmLabel, onConfirm });
  };
  const closeConfirm = () => setConfirmModal(prev => ({ ...prev, isOpen: false }));

  const handleDryRun = () => {
    showConfirm('Dry Run Sync', 'Run a dry-run sync? This will test the sync without making changes.', 'primary', 'Run Dry Run', async () => {
      closeConfirm();
      setActionOutput(null);
      try {
        const result = await adminService.triggerDryRun();
        setActionOutput(result);
        if (result.status === 'started') startPolling(true);
      } catch (error) {
        const msg = error.response?.data?.detail || error.message;
        setActionOutput({ status: 'error', message: msg });
      }
    });
  };

  const handleForceSync = () => {
    showConfirm('Force Full Sync', 'Force a full sync now? This will make API calls to Dendreo and HubSpot immediately.', 'warning', 'Force Sync', async () => {
      closeConfirm();
      setActionOutput(null);
      try {
        const result = await adminService.forceSync();
        setActionOutput(result);
        if (result.status === 'started') startPolling(true);
      } catch (error) {
        const msg = error.response?.data?.detail || error.message;
        setActionOutput({ status: 'error', message: msg });
      }
    });
  };

  const handleSyncAdf = () => {
    if (!adfId.trim()) return;
    showConfirm('Sync Single ADF', `Sync ADF ${adfId}?\n\nThis will fetch the ADF from Dendreo and update its data. If the ADF is not in an active etape (5, 6 or 7), its status will be updated but no participant data will be synced.`, 'info', 'Sync ADF', async () => {
      closeConfirm();
      setActionOutput(null);
      try {
        const result = await adminService.syncSpecificAdf(adfId);
        setActionOutput(result);
        if (result.status === 'started') startPolling(true);
      } catch (error) {
        const msg = error.response?.data?.detail || error.message;
        setActionOutput({ status: 'error', message: msg });
      }
    });
  };

  const handleResumeSync = () => {
    showConfirm('Resume Sync', `Resume sync for ${syncStatus?.skipped_adf_count} remaining ADFs that were skipped due to API limits?`, 'warning', 'Resume Sync', async () => {
      closeConfirm();
      setActionOutput(null);
      try {
        const result = await adminService.resumeSync();
        setActionOutput(result);
        if (result.status === 'started') startPolling(true);
      } catch (error) {
        const msg = error.response?.data?.detail || error.message;
        setActionOutput({ status: 'error', message: msg });
      }
    });
  };

  const handleSyncCategories = () => {
    showConfirm('Sync Categories', 'Sync module categories from Dendreo?\n\nThis is a lightweight operation (1 API call).', 'teal', 'Sync Categories', async () => {
      closeConfirm();
      setActionOutput(null);
      try {
        const result = await adminService.syncCategories();
        setActionOutput(result);
      } catch (error) {
        const msg = error.response?.data?.detail || error.message;
        setActionOutput({ status: 'error', message: msg });
      }
    });
  };

  const handleStopSync = () => {
    showConfirm('Stop Sync', 'Are you sure you want to stop the running sync?\n\nThis will terminate the process immediately. The sync record will be marked as an error.', 'danger', 'Stop Sync', async () => {
      closeConfirm();
      setActionOutput(null);
      try {
        const result = await adminService.stopSync();
        setActionOutput(result);
      } catch (error) {
        const msg = error.response?.data?.detail || error.message;
        setActionOutput({ status: 'error', message: msg });
      }
    });
  };

  const handleToggleCron = () => {
    const newState = !syncConfig.cron_enabled;
    showConfirm(
      newState ? 'Enable Scheduled Syncs' : 'Disable Scheduled Syncs',
      newState ? 'Enable scheduled cron syncs? Syncs will run automatically on the configured schedule.' : 'Disable scheduled cron syncs? Only manual syncs will be available.',
      newState ? 'primary' : 'danger',
      newState ? 'Enable' : 'Disable',
      async () => {
        closeConfirm();
        try {
          await adminService.updateSyncConfig({ cron_enabled: newState });
          await loadDashboardData();
        } catch (error) {
          console.error('Failed to update config:', error);
        }
      }
    );
  };

  const DAY_LABELS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  const toggleDay = (dayIndex) => {
    const days = scheduleDays.split(',').filter(d => d.trim());
    const dayStr = String(dayIndex);
    if (days.includes(dayStr)) {
      if (days.length <= 1) return; // Must have at least one day
      setScheduleDays(days.filter(d => d !== dayStr).sort((a, b) => a - b).join(','));
    } else {
      setScheduleDays([...days, dayStr].sort((a, b) => a - b).join(','));
    }
  };

  const handleSaveSchedule = async () => {
    if (cooldownHours < 0) return;
    try {
      await adminService.updateSyncConfig({
        schedule_days: scheduleDays,
        schedule_time: scheduleTime,
        cooldown_hours: parseFloat(cooldownHours),
        dendreo_api_limit: dendreoApiLimit ? parseInt(dendreoApiLimit, 10) : 0,
        hubspot_api_limit: hubspotApiLimit ? parseInt(hubspotApiLimit, 10) : 0,
        dendreo_daily_limit: dendreoDailyLimit ? parseInt(dendreoDailyLimit, 10) : 0,
        dendreo_weekly_limit: dendreoWeeklyLimit ? parseInt(dendreoWeeklyLimit, 10) : 0,
        dendreo_monthly_limit: dendreoMonthlyLimit ? parseInt(dendreoMonthlyLimit, 10) : 0,
        hubspot_daily_limit: hubspotDailyLimit ? parseInt(hubspotDailyLimit, 10) : 0,
        hubspot_weekly_limit: hubspotWeeklyLimit ? parseInt(hubspotWeeklyLimit, 10) : 0,
        hubspot_monthly_limit: hubspotMonthlyLimit ? parseInt(hubspotMonthlyLimit, 10) : 0,
      });
      await loadDashboardData();
    } catch (error) {
      console.error('Failed to update schedule config:', error);
    }
  };

  const formatDateTime = (dateStr) => {
    if (!dateStr) return 'Never';
    return new Date(dateStr).toLocaleString();
  };

  const formatDuration = (seconds) => {
    if (!seconds) return 'N/A';
    if (seconds < 60) return `${seconds.toFixed(1)}s`;
    return `${(seconds / 60).toFixed(1)}min`;
  };

  const getStatusStyle = (status) => {
    switch (status) {
      case 'success':
        return 'bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-400 border-green-200 dark:border-green-800';
      case 'error':
        return 'bg-red-100 dark:bg-red-900/30 text-red-800 dark:text-red-400 border-red-200 dark:border-red-800';
      case 'in_progress':
        return 'bg-yellow-100 dark:bg-yellow-900/30 text-yellow-800 dark:text-yellow-400 border-yellow-200 dark:border-yellow-800';
      default:
        return 'bg-gray-100 dark:bg-slate-700 text-gray-800 dark:text-gray-300 border-gray-200 dark:border-slate-700';
    }
  };

  const formatSyncType = (syncType) => {
    switch (syncType) {
      case 'sync_all': return 'Full Sync';
      case 'sync_adf': return 'Single ADF';
      default: return syncType;
    }
  };

  const getStatusIcon = (status) => {
    switch (status) {
      case 'success':
        return <CheckCircle2 size={14} className="text-green-600" />;
      case 'error':
        return <XCircle size={14} className="text-red-600" />;
      case 'in_progress':
        return <Loader2 size={14} className="text-yellow-600 animate-spin" />;
      default:
        return <Clock size={14} className="text-gray-600 dark:text-gray-400" />;
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-slate-900">
        <div className="bg-white dark:bg-slate-800 border-b border-gray-200 dark:border-slate-700">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
            <div className="flex items-center">
              <div className="p-2 bg-indigo-100 dark:bg-indigo-900/30 rounded-lg mr-4">
                <Shield size={24} className="text-indigo-600" />
              </div>
              <div>
                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Sync Management</h1>
                <p className="text-gray-600 dark:text-gray-400 mt-1">Admin dashboard</p>
              </div>
            </div>
          </div>
        </div>
        <div className="flex items-center justify-center py-12">
          <Loader2 className="w-8 h-8 animate-spin text-primary-600" />
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-slate-900">
      {/* Header */}
      <div className="bg-white dark:bg-slate-800 border-b border-gray-200 dark:border-slate-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center">
              <div className="p-2 bg-indigo-100 dark:bg-indigo-900/30 rounded-lg mr-4">
                <Shield size={24} className="text-indigo-600" />
              </div>
              <div>
                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Sync Management</h1>
                <p className="text-gray-600 dark:text-gray-400 mt-1">Monitor API usage and control synchronization</p>
              </div>
            </div>
            <button
              onClick={loadDashboardData}
              className="flex items-center gap-2 px-4 py-2 bg-white dark:bg-slate-800 border border-gray-300 dark:border-slate-600 rounded-lg text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors"
            >
              <RefreshCw size={18} />
              <span className="font-medium">Refresh</span>
            </button>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">

        {/* API Usage Stats */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
          <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700 p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600 dark:text-gray-400">Last Sync</p>
                <p className="text-3xl font-bold text-gray-900 dark:text-white mt-2">{apiUsage?.last_sync?.api_calls || 0}</p>
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                  {formatDuration(apiUsage?.last_sync?.duration_seconds)}
                </p>
              </div>
              <div className="p-3 bg-gray-100 dark:bg-slate-700 rounded-lg">
                <Activity size={24} className="text-gray-600 dark:text-gray-400" />
              </div>
            </div>
          </div>

          <div className="bg-white dark:bg-slate-800 rounded-lg border border-blue-200 dark:border-blue-800 p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-blue-700 dark:text-blue-400">Today</p>
                <p className="text-3xl font-bold text-blue-900 dark:text-blue-100 mt-2">{apiUsage?.today?.api_calls || 0}</p>
                <div className="text-xs mt-1 space-y-0.5">
                  <p className="text-blue-600">
                    D: {apiUsage?.today?.dendreo_calls || 0}{apiUsage?.today?.dendreo_limit ? ` / ${apiUsage.today.dendreo_limit}` : ''}
                    {' '} H: {apiUsage?.today?.hubspot_calls || 0}{apiUsage?.today?.hubspot_limit ? ` / ${apiUsage.today.hubspot_limit}` : ''}
                  </p>
                  <p className="text-blue-500">{apiUsage?.today?.sync_count || 0} syncs</p>
                </div>
              </div>
              <div className="p-3 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <Zap size={24} className="text-blue-600" />
              </div>
            </div>
          </div>

          <div className="bg-white dark:bg-slate-800 rounded-lg border border-purple-200 dark:border-purple-800 p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-purple-700 dark:text-purple-400">This Week</p>
                <p className="text-3xl font-bold text-purple-900 dark:text-purple-100 mt-2">{apiUsage?.this_week?.api_calls || 0}</p>
                <div className="text-xs mt-1 space-y-0.5">
                  <p className="text-purple-600">
                    D: {apiUsage?.this_week?.dendreo_calls || 0}{apiUsage?.this_week?.dendreo_limit ? ` / ${apiUsage.this_week.dendreo_limit}` : ''}
                    {' '} H: {apiUsage?.this_week?.hubspot_calls || 0}{apiUsage?.this_week?.hubspot_limit ? ` / ${apiUsage.this_week.hubspot_limit}` : ''}
                  </p>
                  <p className="text-purple-500">{apiUsage?.this_week?.sync_count || 0} syncs</p>
                </div>
              </div>
              <div className="p-3 bg-purple-100 dark:bg-purple-900/30 rounded-lg">
                <Activity size={24} className="text-purple-600" />
              </div>
            </div>
          </div>

          <div className="bg-white dark:bg-slate-800 rounded-lg border border-indigo-200 dark:border-indigo-800 p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-indigo-700 dark:text-indigo-400">This Month</p>
                <p className="text-3xl font-bold text-indigo-900 dark:text-indigo-100 mt-2">{apiUsage?.this_month?.api_calls || 0}</p>
                <div className="text-xs mt-1 space-y-0.5">
                  <p className="text-indigo-600">
                    D: {apiUsage?.this_month?.dendreo_calls || 0}{apiUsage?.this_month?.dendreo_limit ? ` / ${apiUsage.this_month.dendreo_limit}` : ''}
                    {' '} H: {apiUsage?.this_month?.hubspot_calls || 0}{apiUsage?.this_month?.hubspot_limit ? ` / ${apiUsage.this_month.hubspot_limit}` : ''}
                  </p>
                  <p className="text-indigo-500">{apiUsage?.this_month?.sync_count || 0} syncs</p>
                </div>
              </div>
              <div className="p-3 bg-indigo-100 dark:bg-indigo-900/30 rounded-lg">
                <Activity size={24} className="text-indigo-600" />
              </div>
            </div>
          </div>
        </div>

        {/* Status + Config Row */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
          {/* Current Status */}
          <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700 p-6">
            <div className="flex items-center gap-2 mb-4">
              <Zap size={20} className="text-gray-600 dark:text-gray-400" />
              <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Current Status</h2>
            </div>
            <div className="flex items-center gap-4 mb-4">
              <span className={`inline-flex items-center gap-2 px-4 py-2 rounded-full text-sm font-semibold ${
                syncStatus?.is_running
                  ? 'bg-yellow-100 dark:bg-yellow-900/30 text-yellow-800 dark:text-yellow-400 border border-yellow-200 dark:border-yellow-800'
                  : 'bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-400 border border-green-200 dark:border-green-800'
              }`}>
                {syncStatus?.is_running ? (
                  <><Loader2 size={16} className="animate-spin" /> Sync Running</>
                ) : (
                  <><CheckCircle2 size={16} /> Idle</>
                )}
              </span>
            </div>
            {syncStatus?.last_sync && (
              <div className="space-y-2 text-sm text-gray-600 dark:text-gray-400">
                <div className="flex items-center justify-between">
                  <span>Last Sync</span>
                  <span className="font-medium text-gray-900 dark:text-white">{formatDateTime(syncStatus.last_sync.last_sync_at)}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span>Status</span>
                  <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium border ${getStatusStyle(syncStatus.last_sync.status)}`}>
                    {getStatusIcon(syncStatus.last_sync.status)}
                    {syncStatus.last_sync.status}
                  </span>
                </div>
                <div className="flex items-center justify-between">
                  <span>API Calls</span>
                  <span className="font-medium text-gray-900 dark:text-white">{syncStatus.last_sync.api_calls_count}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span>Duration</span>
                  <span className="font-medium text-gray-900 dark:text-white">{formatDuration(syncStatus.last_sync.duration_seconds)}</span>
                </div>
              </div>
            )}
          </div>

          {/* Configuration */}
          <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700 p-6">
            <div className="flex items-center gap-2 mb-4">
              <Settings size={20} className="text-gray-600 dark:text-gray-400" />
              <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Configuration</h2>
            </div>
            <div className="space-y-5">
              {/* Enable/Disable Toggle */}
              <div>
                <label className="flex items-center gap-3 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={syncConfig?.cron_enabled || false}
                    onChange={handleToggleCron}
                    className="w-5 h-5 text-primary-600 rounded focus:ring-2 focus:ring-primary-500"
                  />
                  <span className="font-medium text-gray-900 dark:text-white">Enable Scheduled Syncs</span>
                </label>
                <p className="text-sm text-gray-500 dark:text-gray-400 mt-1 ml-8">
                  {syncConfig?.cron_enabled
                    ? 'Syncs will run on the schedule below'
                    : 'Scheduled syncs are disabled (manual only)'}
                </p>
              </div>

              {/* Schedule Days */}
              <div>
                <label className="flex items-center gap-1.5 text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  <CalendarDays size={14} />
                  Schedule Days
                </label>
                <div className="flex flex-wrap gap-2">
                  {DAY_LABELS.map((label, idx) => {
                    const isActive = scheduleDays.split(',').map(d => d.trim()).includes(String(idx));
                    return (
                      <button
                        key={idx}
                        onClick={() => toggleDay(idx)}
                        className={`px-3 py-1.5 rounded-lg text-sm font-medium border transition-colors ${
                          isActive
                            ? 'bg-primary-600 text-white border-primary-600'
                            : 'bg-white dark:bg-slate-700 text-gray-600 dark:text-gray-400 border-gray-300 dark:border-slate-600 hover:bg-gray-50 dark:hover:bg-slate-700'
                        }`}
                      >
                        {label}
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* Schedule Time */}
              <div>
                <label className="flex items-center gap-1.5 text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  <Clock size={14} />
                  Schedule Time (Europe/Paris)
                </label>
                <input
                  type="time"
                  value={scheduleTime}
                  onChange={(e) => setScheduleTime(e.target.value)}
                  className="w-32 px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm dark:bg-slate-700 dark:text-white"
                />
              </div>

              {/* Cooldown Hours */}
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Cooldown Hours
                </label>
                <input
                  type="number"
                  min="0"
                  step="0.5"
                  value={cooldownHours}
                  onChange={(e) => setCooldownHours(e.target.value)}
                  className="w-24 px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm dark:bg-slate-700 dark:text-white"
                />
                <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
                  Scheduled sync is skipped if the last successful sync (including force sync) was less than {cooldownHours}h ago
                </p>
              </div>

              {/* API Limits */}
              <div className="border-t border-gray-200 dark:border-slate-700 pt-4">
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">
                  API Call Limits
                </label>

                {/* Per-Sync Limits */}
                <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-2">Per Sync</p>
                <div className="grid grid-cols-2 gap-4 mb-3">
                  <div>
                    <label className="block text-xs text-gray-500 dark:text-gray-400 mb-1">Dendreo</label>
                    <input
                      type="number"
                      min="0"
                      step="10"
                      placeholder="Unlimited"
                      value={dendreoApiLimit}
                      onChange={(e) => setDendreoApiLimit(e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm dark:bg-slate-700 dark:text-white"
                    />
                  </div>
                  <div>
                    <label className="block text-xs text-gray-500 dark:text-gray-400 mb-1">HubSpot</label>
                    <input
                      type="number"
                      min="0"
                      step="10"
                      placeholder="Unlimited"
                      value={hubspotApiLimit}
                      onChange={(e) => setHubspotApiLimit(e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm dark:bg-slate-700 dark:text-white"
                    />
                  </div>
                </div>

                {/* Period Limits */}
                <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-2 mt-4">Daily</p>
                <div className="grid grid-cols-2 gap-4 mb-3">
                  <div>
                    <label className="block text-xs text-gray-500 dark:text-gray-400 mb-1">Dendreo</label>
                    <input
                      type="number"
                      min="0"
                      step="100"
                      placeholder="Unlimited"
                      value={dendreoDailyLimit}
                      onChange={(e) => setDendreoDailyLimit(e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm dark:bg-slate-700 dark:text-white"
                    />
                  </div>
                  <div>
                    <label className="block text-xs text-gray-500 dark:text-gray-400 mb-1">HubSpot</label>
                    <input
                      type="number"
                      min="0"
                      step="100"
                      placeholder="Unlimited"
                      value={hubspotDailyLimit}
                      onChange={(e) => setHubspotDailyLimit(e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm dark:bg-slate-700 dark:text-white"
                    />
                  </div>
                </div>

                <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-2">Weekly</p>
                <div className="grid grid-cols-2 gap-4 mb-3">
                  <div>
                    <label className="block text-xs text-gray-500 dark:text-gray-400 mb-1">Dendreo</label>
                    <input
                      type="number"
                      min="0"
                      step="100"
                      placeholder="Unlimited"
                      value={dendreoWeeklyLimit}
                      onChange={(e) => setDendreoWeeklyLimit(e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm dark:bg-slate-700 dark:text-white"
                    />
                  </div>
                  <div>
                    <label className="block text-xs text-gray-500 dark:text-gray-400 mb-1">HubSpot</label>
                    <input
                      type="number"
                      min="0"
                      step="100"
                      placeholder="Unlimited"
                      value={hubspotWeeklyLimit}
                      onChange={(e) => setHubspotWeeklyLimit(e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm dark:bg-slate-700 dark:text-white"
                    />
                  </div>
                </div>

                <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-2">Monthly</p>
                <div className="grid grid-cols-2 gap-4 mb-3">
                  <div>
                    <label className="block text-xs text-gray-500 dark:text-gray-400 mb-1">Dendreo</label>
                    <input
                      type="number"
                      min="0"
                      step="500"
                      placeholder="Unlimited"
                      value={dendreoMonthlyLimit}
                      onChange={(e) => setDendreoMonthlyLimit(e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm dark:bg-slate-700 dark:text-white"
                    />
                  </div>
                  <div>
                    <label className="block text-xs text-gray-500 dark:text-gray-400 mb-1">HubSpot</label>
                    <input
                      type="number"
                      min="0"
                      step="500"
                      placeholder="Unlimited"
                      value={hubspotMonthlyLimit}
                      onChange={(e) => setHubspotMonthlyLimit(e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm dark:bg-slate-700 dark:text-white"
                    />
                  </div>
                </div>

                <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
                  0 or empty = unlimited. Per-sync limits skip remaining ADFs. Period limits block new syncs from starting.
                </p>
              </div>

              {/* Save Button */}
              <button
                onClick={handleSaveSchedule}
                className="flex items-center gap-1.5 px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors text-sm font-medium"
              >
                <Save size={14} />
                Save Configuration
              </button>
            </div>
          </div>
        </div>

        {/* Sync Actions */}
        <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700 p-6 mb-6">
          <div className="flex items-center gap-2 mb-4">
            <Play size={20} className="text-gray-600 dark:text-gray-400" />
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Sync Actions</h2>
          </div>
          <div className="flex flex-wrap items-center gap-3">
            <button
              onClick={handleDryRun}
              disabled={isPollingLog}
              className="flex items-center gap-2 px-4 py-2 bg-gray-100 dark:bg-slate-700 text-gray-700 dark:text-gray-300 border border-gray-300 dark:border-slate-600 rounded-lg hover:bg-gray-200 dark:hover:bg-slate-700 transition-colors font-medium disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <FlaskConical size={18} />
              Dry Run
            </button>
            <button
              onClick={handleForceSync}
              disabled={isPollingLog}
              className="flex items-center gap-2 px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors font-medium disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <Zap size={18} />
              Force Sync
            </button>
            {isPollingLog && (
              <button
                onClick={handleStopSync}
                className="flex items-center gap-2 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors font-medium"
              >
                <StopCircle size={18} />
                Stop Sync
              </button>
            )}
            {syncStatus?.skipped_adf_count > 0 && (
              <button
                onClick={handleResumeSync}
                disabled={isPollingLog}
                className="flex items-center gap-2 px-4 py-2 bg-amber-600 text-white rounded-lg hover:bg-amber-700 transition-colors font-medium disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <FastForward size={18} />
                Resume ({syncStatus.skipped_adf_count} ADFs)
              </button>
            )}
            <div className="flex items-center gap-2">
              <input
                type="text"
                placeholder="ADF ID"
                value={adfId}
                onChange={(e) => setAdfId(e.target.value)}
                disabled={isPollingLog}
                className="w-28 px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm dark:bg-slate-700 dark:text-white"
              />
              <button
                onClick={handleSyncAdf}
                disabled={isPollingLog || !adfId.trim()}
                className="flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors font-medium disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <Target size={18} />
                Sync ADF
              </button>
            </div>
            <button
              onClick={handleSyncCategories}
              disabled={isPollingLog}
              className="flex items-center gap-2 px-4 py-2 bg-teal-600 text-white rounded-lg hover:bg-teal-700 transition-colors font-medium disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <FolderSync size={18} />
              Sync Categories
            </button>
          </div>

          {actionOutput && (
            <div className={`mt-4 p-3 rounded-lg border ${
              actionOutput.status === 'started'
                ? 'bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-800'
                : actionOutput.status === 'error'
                ? 'bg-red-50 dark:bg-red-900/20 border-red-200 dark:border-red-800'
                : actionOutput.status === 'warning'
                ? 'bg-amber-50 dark:bg-amber-900/20 border-amber-200 dark:border-amber-800'
                : 'bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-800'
            }`}>
              <div className="flex items-center gap-2">
                {actionOutput.status === 'started' ? (
                  <Loader2 size={16} className="text-blue-600 animate-spin" />
                ) : actionOutput.status === 'error' ? (
                  <XCircle size={16} className="text-red-600" />
                ) : actionOutput.status === 'warning' ? (
                  <AlertTriangle size={16} className="text-amber-600" />
                ) : (
                  <CheckCircle2 size={16} className="text-green-600" />
                )}
                <span className="text-sm font-medium">{actionOutput.message}</span>
              </div>
            </div>
          )}
        </div>

        {/* Live Sync Log */}
        {(isPollingLog || liveLog) && (
          <div className="bg-gray-900 rounded-lg border border-gray-700 mb-6">
            <div className="px-4 py-3 border-b border-gray-700 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Terminal size={16} className="text-green-400" />
                <span className="text-sm font-medium text-gray-200">Sync Log</span>
                {isPollingLog && (
                  <>
                    <span className="flex items-center gap-1 px-2 py-0.5 bg-green-900 text-green-300 rounded-full text-xs font-medium">
                      <span className="w-1.5 h-1.5 bg-green-400 rounded-full animate-pulse" />
                      Live
                    </span>
                    <span className="text-xs text-gray-400 ml-2">
                      Dendreo: <span className="text-blue-400 font-mono">{apiCounters.dendreo}</span>
                      {' | '}
                      HubSpot: <span className="text-orange-400 font-mono">{apiCounters.hubspot}</span>
                    </span>
                  </>
                )}
              </div>
              {!isPollingLog && liveLog && (
                <button
                  onClick={() => { setLiveLog(''); logOffsetRef.current = 0; }}
                  className="text-xs text-gray-400 hover:text-gray-200 transition-colors"
                >
                  Clear
                </button>
              )}
            </div>
            <pre className="p-4 text-xs text-gray-300 overflow-x-auto max-h-96 overflow-y-auto leading-relaxed font-mono whitespace-pre-wrap">
              {liveLog || 'Waiting for output...'}
              <div ref={logEndRef} />
            </pre>
          </div>
        )}

        {/* Sync History */}
        <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700">
          <div className="px-6 py-4 border-b border-gray-200 dark:border-slate-700">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <History size={20} className="text-gray-600 dark:text-gray-400" />
                <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Sync History</h2>
                <span className="text-xs text-gray-500 dark:text-gray-400">({historyTotal})</span>
              </div>
              <div className="flex items-center gap-3">
                <div className="flex items-center gap-1">
                  {[25, 50, 100].map(size => (
                    <button
                      key={size}
                      onClick={() => { setHistoryPageSize(size); setHistoryPage(1); }}
                      className={`px-2.5 py-1 rounded text-xs font-medium transition-colors ${
                        historyPageSize === size
                          ? 'bg-primary-600 text-white'
                          : 'bg-gray-100 dark:bg-slate-700 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-slate-600'
                      }`}
                    >
                      {size}
                    </button>
                  ))}
                </div>
                {historyTotalPages > 1 && (
                  <div className="flex items-center gap-1.5">
                    <button
                      onClick={() => setHistoryPage(p => Math.max(1, p - 1))}
                      disabled={historyPage <= 1}
                      className="p-1.5 rounded border border-gray-200 dark:border-slate-700 hover:bg-gray-50 dark:hover:bg-slate-700 disabled:opacity-30 transition-colors text-gray-600 dark:text-gray-400"
                    >
                      <ChevronLeft size={14} />
                    </button>
                    <span className="text-xs text-gray-600 dark:text-gray-400 min-w-[50px] text-center">
                      {historyPage} / {historyTotalPages}
                    </span>
                    <button
                      onClick={() => setHistoryPage(p => Math.min(historyTotalPages, p + 1))}
                      disabled={historyPage >= historyTotalPages}
                      className="p-1.5 rounded border border-gray-200 dark:border-slate-700 hover:bg-gray-50 dark:hover:bg-slate-700 disabled:opacity-30 transition-colors text-gray-600 dark:text-gray-400"
                    >
                      <ChevronRight size={14} />
                    </button>
                  </div>
                )}
              </div>
            </div>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="bg-gray-50 dark:bg-slate-900">
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 dark:text-gray-400 uppercase tracking-wider">Timestamp</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 dark:text-gray-400 uppercase tracking-wider">Type</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 dark:text-gray-400 uppercase tracking-wider">Status</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 dark:text-gray-400 uppercase tracking-wider">Summary</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 dark:text-gray-400 uppercase tracking-wider">API Calls (D/H)</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 dark:text-gray-400 uppercase tracking-wider">Duration</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 dark:text-gray-400 uppercase tracking-wider"></th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 dark:divide-slate-700">
                {syncHistory.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="px-6 py-8 text-center text-sm text-gray-500 dark:text-gray-400">
                      No sync history available
                    </td>
                  </tr>
                ) : (
                  syncHistory.map((sync) => (
                    <tr key={sync.id} className="hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors cursor-pointer" onClick={() => setSelectedSync(sync)}>
                      <td className="px-6 py-3 text-sm text-gray-700 dark:text-gray-300">{formatDateTime(sync.last_sync_at)}</td>
                      <td className="px-6 py-3 text-sm text-gray-700 dark:text-gray-300">{formatSyncType(sync.sync_type)}</td>
                      <td className="px-6 py-3">
                        <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium border ${getStatusStyle(sync.status)}`}>
                          {getStatusIcon(sync.status)}
                          {sync.status}
                        </span>
                      </td>
                      <td className="px-6 py-3 text-xs text-gray-500 dark:text-gray-400">
                        {sync.stats ? (
                          <span className="flex flex-wrap gap-x-2 gap-y-0.5">
                            {(sync.stats.courses_created > 0 || sync.stats.courses_updated > 0 || sync.stats.courses_removed > 0) && (
                              <span>ADFs: <span className="text-green-600">+{sync.stats.courses_created || 0}</span> <span className="text-blue-600">~{sync.stats.courses_updated || 0}</span> <span className="text-red-600">-{sync.stats.courses_removed || 0}</span></span>
                            )}
                            {(sync.stats.participants_created > 0 || sync.stats.participants_updated > 0) && (
                              <span>P: <span className="text-green-600">+{sync.stats.participants_created || 0}</span> <span className="text-blue-600">~{sync.stats.participants_updated || 0}</span></span>
                            )}
                            {sync.stats.adfs_status_updated > 0 && (
                              <span className="text-amber-600">⚡{sync.stats.adfs_status_updated} status</span>
                            )}
                          </span>
                        ) : (
                          <span className="italic">—</span>
                        )}
                      </td>
                      <td className="px-6 py-3 text-sm text-gray-700 dark:text-gray-300">
                        {sync.api_calls_count}{sync.hubspot_api_calls_count > 0 ? ` / ${sync.hubspot_api_calls_count}` : ''}
                      </td>
                      <td className="px-6 py-3 text-sm text-gray-700 dark:text-gray-300">{formatDuration(sync.duration_seconds)}</td>
                      <td className="px-6 py-3 text-sm text-gray-700 dark:text-gray-300">
                        <ChevronRight size={16} className="text-gray-400 dark:text-gray-500" />
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* Sync Detail Modal */}
      {selectedSync && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          <div className="fixed inset-0 bg-black/50" onClick={() => setSelectedSync(null)} />
          <div className="relative bg-white dark:bg-slate-800 rounded-xl shadow-xl border border-gray-200 dark:border-slate-700 max-w-lg w-full mx-4 max-h-[80vh] overflow-y-auto">
            <div className="sticky top-0 bg-white dark:bg-slate-800 border-b border-gray-200 dark:border-slate-700 px-6 py-4 rounded-t-xl flex items-center justify-between">
              <div>
                <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Sync Summary</h3>
                <p className="text-sm text-gray-500 dark:text-gray-400 mt-0.5">{formatDateTime(selectedSync.last_sync_at)} &mdash; {formatSyncType(selectedSync.sync_type)}</p>
              </div>
              <button onClick={() => setSelectedSync(null)} className="p-1 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-700 transition-colors">
                <X size={20} className="text-gray-500 dark:text-gray-400" />
              </button>
            </div>
            <div className="px-6 py-4 space-y-4">
              {/* Status & Duration */}
              <div className="flex items-center gap-4">
                <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium border ${getStatusStyle(selectedSync.status)}`}>
                  {getStatusIcon(selectedSync.status)}
                  {selectedSync.status}
                </span>
                <span className="text-sm text-gray-600 dark:text-gray-400">Duration: <span className="font-medium text-gray-900 dark:text-white">{formatDuration(selectedSync.duration_seconds)}</span></span>
              </div>

              {/* Error message */}
              {selectedSync.error_message && (
                <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3 text-sm text-red-700 dark:text-red-400">
                  {selectedSync.error_message}
                </div>
              )}

              {/* API Calls */}
              <div className="bg-gray-50 dark:bg-slate-900 rounded-lg p-3">
                <h4 className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase mb-2">API Calls</h4>
                <div className="grid grid-cols-2 gap-2 text-sm text-gray-700 dark:text-gray-300">
                  <div>Dendreo: <span className="font-medium text-gray-900 dark:text-white">{selectedSync.api_calls_count}</span></div>
                  <div>HubSpot: <span className="font-medium text-gray-900 dark:text-white">{selectedSync.hubspot_api_calls_count || 0}</span></div>
                </div>
              </div>

              {/* Stats */}
              {selectedSync.stats && (
                <>
                  {/* ADFs (Courses) */}
                  <div className="bg-gray-50 dark:bg-slate-900 rounded-lg p-3">
                    <h4 className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase mb-2">ADFs (Courses)</h4>
                    <div className="grid grid-cols-3 gap-2 text-sm">
                      <div className="text-center p-2 bg-white dark:bg-slate-800 rounded border dark:border-slate-700">
                        <div className="text-green-600 font-semibold">{selectedSync.stats.courses_created || 0}</div>
                        <div className="text-xs text-gray-500 dark:text-gray-400">Created</div>
                      </div>
                      <div className="text-center p-2 bg-white dark:bg-slate-800 rounded border dark:border-slate-700">
                        <div className="text-blue-600 font-semibold">{selectedSync.stats.courses_updated || 0}</div>
                        <div className="text-xs text-gray-500 dark:text-gray-400">Updated</div>
                      </div>
                      <div className="text-center p-2 bg-white dark:bg-slate-800 rounded border dark:border-slate-700">
                        <div className="text-red-600 font-semibold">{selectedSync.stats.courses_removed || 0}</div>
                        <div className="text-xs text-gray-500 dark:text-gray-400">Removed</div>
                      </div>
                    </div>
                  </div>

                  {/* Participants */}
                  <div className="bg-gray-50 dark:bg-slate-900 rounded-lg p-3">
                    <h4 className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase mb-2">Participants</h4>
                    <div className="grid grid-cols-3 gap-2 text-sm">
                      <div className="text-center p-2 bg-white dark:bg-slate-800 rounded border dark:border-slate-700">
                        <div className="text-green-600 font-semibold">{selectedSync.stats.participants_created || 0}</div>
                        <div className="text-xs text-gray-500 dark:text-gray-400">Created</div>
                      </div>
                      <div className="text-center p-2 bg-white dark:bg-slate-800 rounded border dark:border-slate-700">
                        <div className="text-blue-600 font-semibold">{selectedSync.stats.participants_updated || 0}</div>
                        <div className="text-xs text-gray-500 dark:text-gray-400">Updated</div>
                      </div>
                      <div className="text-center p-2 bg-white dark:bg-slate-800 rounded border dark:border-slate-700">
                        <div className="text-red-600 font-semibold">{selectedSync.stats.participants_removed || 0}</div>
                        <div className="text-xs text-gray-500 dark:text-gray-400">Removed</div>
                      </div>
                    </div>
                  </div>

                  {/* Enrollments */}
                  <div className="bg-gray-50 dark:bg-slate-900 rounded-lg p-3">
                    <h4 className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase mb-2">Enrollments</h4>
                    <div className="grid grid-cols-3 gap-2 text-sm">
                      <div className="text-center p-2 bg-white dark:bg-slate-800 rounded border dark:border-slate-700">
                        <div className="text-green-600 font-semibold">{selectedSync.stats.participant_courses_created || 0}</div>
                        <div className="text-xs text-gray-500 dark:text-gray-400">Created</div>
                      </div>
                      <div className="text-center p-2 bg-white dark:bg-slate-800 rounded border dark:border-slate-700">
                        <div className="text-blue-600 font-semibold">{selectedSync.stats.participant_courses_updated || 0}</div>
                        <div className="text-xs text-gray-500 dark:text-gray-400">Updated</div>
                      </div>
                      <div className="text-center p-2 bg-white dark:bg-slate-800 rounded border dark:border-slate-700">
                        <div className="text-red-600 font-semibold">{selectedSync.stats.participant_courses_removed || 0}</div>
                        <div className="text-xs text-gray-500 dark:text-gray-400">Removed</div>
                      </div>
                    </div>
                  </div>

                  {/* Modules */}
                  <div className="bg-gray-50 dark:bg-slate-900 rounded-lg p-3">
                    <h4 className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase mb-2">Modules</h4>
                    <div className="grid grid-cols-3 gap-2 text-sm">
                      <div className="text-center p-2 bg-white dark:bg-slate-800 rounded border dark:border-slate-700">
                        <div className="text-green-600 font-semibold">{selectedSync.stats.modules_created || 0}</div>
                        <div className="text-xs text-gray-500 dark:text-gray-400">Created</div>
                      </div>
                      <div className="text-center p-2 bg-white dark:bg-slate-800 rounded border dark:border-slate-700">
                        <div className="text-blue-600 font-semibold">{selectedSync.stats.modules_updated || 0}</div>
                        <div className="text-xs text-gray-500 dark:text-gray-400">Updated</div>
                      </div>
                      <div className="text-center p-2 bg-white dark:bg-slate-800 rounded border dark:border-slate-700">
                        <div className="text-red-600 font-semibold">{selectedSync.stats.modules_removed || 0}</div>
                        <div className="text-xs text-gray-500 dark:text-gray-400">Removed</div>
                      </div>
                    </div>
                  </div>

                  {/* Creneaux */}
                  {(selectedSync.stats.creneaux_created > 0 || selectedSync.stats.creneaux_updated > 0) && (
                    <div className="bg-gray-50 dark:bg-slate-900 rounded-lg p-3">
                      <h4 className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase mb-2">Liverooms</h4>
                      <div className="grid grid-cols-2 gap-2 text-sm">
                        <div className="text-center p-2 bg-white dark:bg-slate-800 rounded border dark:border-slate-700">
                          <div className="text-green-600 font-semibold">{selectedSync.stats.creneaux_created || 0}</div>
                          <div className="text-xs text-gray-500 dark:text-gray-400">Slots Created</div>
                        </div>
                        <div className="text-center p-2 bg-white dark:bg-slate-800 rounded border dark:border-slate-700">
                          <div className="text-blue-600 font-semibold">{selectedSync.stats.creneau_participants_created || 0}</div>
                          <div className="text-xs text-gray-500 dark:text-gray-400">Attendees Created</div>
                        </div>
                      </div>
                    </div>
                  )}

                  {/* HubSpot */}
                  {selectedSync.stats.hubspot_updates_total > 0 && (
                    <div className="bg-gray-50 dark:bg-slate-900 rounded-lg p-3">
                      <h4 className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase mb-2">HubSpot</h4>
                      <div className="grid grid-cols-3 gap-2 text-sm">
                        <div className="text-center p-2 bg-white dark:bg-slate-800 rounded border dark:border-slate-700">
                          <div className="font-semibold">{selectedSync.stats.hubspot_updates_total || 0}</div>
                          <div className="text-xs text-gray-500 dark:text-gray-400">Total</div>
                        </div>
                        <div className="text-center p-2 bg-white dark:bg-slate-800 rounded border dark:border-slate-700">
                          <div className="text-green-600 font-semibold">{selectedSync.stats.hubspot_updates_successful || 0}</div>
                          <div className="text-xs text-gray-500 dark:text-gray-400">Successful</div>
                        </div>
                        <div className="text-center p-2 bg-white dark:bg-slate-800 rounded border dark:border-slate-700">
                          <div className="text-red-600 font-semibold">{selectedSync.stats.hubspot_updates_failed || 0}</div>
                          <div className="text-xs text-gray-500 dark:text-gray-400">Failed</div>
                        </div>
                      </div>
                      {selectedSync.stats.hubspot_data_created > 0 && (
                        <div className="mt-2 text-xs text-gray-500 dark:text-gray-400">New HubSpot records: {selectedSync.stats.hubspot_data_created}</div>
                      )}
                    </div>
                  )}

                  {/* Categories */}
                  {selectedSync.stats.categories_synced > 0 && (
                    <div className="text-sm text-gray-600 dark:text-gray-400">Categories synced: <span className="font-medium">{selectedSync.stats.categories_synced}</span></div>
                  )}

                  {/* Skipped ADFs */}
                  {selectedSync.stats.adfs_skipped_api_limit > 0 && (
                    <div className="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg p-3 text-sm text-amber-700 dark:text-amber-400">
                      {selectedSync.stats.adfs_skipped_api_limit} ADF(s) skipped due to API limit
                    </div>
                  )}

                  {/* ADF Status Changes */}
                  {selectedSync.stats.adfs_status_updated > 0 && (
                    <div className="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg p-3">
                      <h4 className="text-xs font-semibold text-amber-700 dark:text-amber-400 uppercase mb-2">
                        ADF Status Updated ({selectedSync.stats.adfs_status_updated})
                      </h4>
                      {selectedSync.stats.adfs_left_tracker && selectedSync.stats.adfs_left_tracker.length > 0 && (
                        <div className="space-y-1.5">
                          {selectedSync.stats.adfs_left_tracker.map((adf, idx) => (
                            <div key={idx} className="flex items-center justify-between text-xs bg-white dark:bg-slate-800 rounded border border-amber-100 dark:border-amber-800 px-2 py-1.5">
                              <span className="text-gray-700 dark:text-gray-300 truncate mr-2" title={adf.intitule}>
                                <span className="font-mono text-gray-400 dark:text-gray-500">#{adf.id_adf}</span> {adf.intitule}
                              </span>
                              <span className="text-amber-600 font-medium whitespace-nowrap">
                                {adf.old_status} → {adf.new_status}
                              </span>
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                  )}
                </>
              )}

              {!selectedSync.stats && (
                <p className="text-sm text-gray-500 dark:text-gray-400 italic">No detailed stats available for this sync.</p>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Confirmation Modal */}
      <ConfirmModal
        isOpen={confirmModal.isOpen}
        title={confirmModal.title}
        message={confirmModal.message}
        variant={confirmModal.variant}
        confirmLabel={confirmModal.confirmLabel}
        onConfirm={confirmModal.onConfirm}
        onCancel={closeConfirm}
      />
    </div>
  );
};

export default AdminSyncDashboard;

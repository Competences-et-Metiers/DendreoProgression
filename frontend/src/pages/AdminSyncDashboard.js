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
} from 'lucide-react';

const AdminSyncDashboard = () => {
  const [apiUsage, setApiUsage] = useState(null);
  const [syncStatus, setSyncStatus] = useState(null);
  const [syncConfig, setSyncConfig] = useState(null);
  const [syncHistory, setSyncHistory] = useState([]);
  const [loading, setLoading] = useState(true);
  const [actionOutput, setActionOutput] = useState(null);
  const [adfId, setAdfId] = useState('');
  const [cooldownHours, setCooldownHours] = useState(12.0);
  const [scheduleDays, setScheduleDays] = useState('0,1,2,3,4');
  const [scheduleTime, setScheduleTime] = useState('08:00');
  const [dendreoApiLimit, setDendreoApiLimit] = useState('');
  const [hubspotApiLimit, setHubspotApiLimit] = useState('');

  // Live log state
  const [liveLog, setLiveLog] = useState('');
  const [isPollingLog, setIsPollingLog] = useState(false);
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
      if (!data.is_running) {
        stopPolling();
        loadDashboardData();
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
        adminService.getSyncHistory(10),
      ]);

      setApiUsage(usage);
      setSyncStatus(status);
      setSyncConfig(config);
      setCooldownHours(config.cooldown_hours);
      setScheduleDays(config.schedule_days || '0,1,2,3,4');
      setScheduleTime(config.schedule_time || '08:00');
      setDendreoApiLimit(config.dendreo_api_limit || '');
      setHubspotApiLimit(config.hubspot_api_limit || '');
      setSyncHistory(history);
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

  // Start polling if sync is already running on page load
  useEffect(() => {
    if (syncStatus?.is_running && !pollingRef.current) {
      startPolling(true);
    }
  }, [syncStatus?.is_running, startPolling]);

  const handleDryRun = async () => {
    if (!window.confirm('Run a dry-run sync? This will test the sync without making changes.')) return;
    setActionOutput(null);
    try {
      const result = await adminService.triggerDryRun();
      setActionOutput(result);
      if (result.status === 'started') {
        startPolling(true);
      }
    } catch (error) {
      const msg = error.response?.data?.detail || error.message;
      setActionOutput({ status: 'error', message: msg });
    }
  };

  const handleForceSync = async () => {
    if (!window.confirm('Force a full sync NOW? This will make API calls immediately.')) return;
    setActionOutput(null);
    try {
      const result = await adminService.forceSync();
      setActionOutput(result);
      if (result.status === 'started') {
        startPolling(true);
      }
    } catch (error) {
      const msg = error.response?.data?.detail || error.message;
      setActionOutput({ status: 'error', message: msg });
    }
  };

  const handleSyncAdf = async () => {
    if (!adfId.trim()) return;
    if (!window.confirm(`Sync ADF ${adfId}?`)) return;
    setActionOutput(null);
    try {
      const result = await adminService.syncSpecificAdf(adfId);
      setActionOutput(result);
      if (result.status === 'started') {
        startPolling(true);
      }
    } catch (error) {
      const msg = error.response?.data?.detail || error.message;
      setActionOutput({ status: 'error', message: msg });
    }
  };

  const handleResumeSync = async () => {
    if (!window.confirm(`Resume sync for ${syncStatus?.skipped_adf_count} remaining ADFs?`)) return;
    setActionOutput(null);
    try {
      const result = await adminService.resumeSync();
      setActionOutput(result);
      if (result.status === 'started') {
        startPolling(true);
      }
    } catch (error) {
      const msg = error.response?.data?.detail || error.message;
      setActionOutput({ status: 'error', message: msg });
    }
  };

  const handleToggleCron = async () => {
    const newState = !syncConfig.cron_enabled;
    if (!window.confirm(`${newState ? 'ENABLE' : 'DISABLE'} scheduled cron syncs?`)) return;
    try {
      await adminService.updateSyncConfig({ cron_enabled: newState });
      await loadDashboardData();
    } catch (error) {
      console.error('Failed to update config:', error);
    }
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
        return 'bg-green-100 text-green-800 border-green-200';
      case 'error':
        return 'bg-red-100 text-red-800 border-red-200';
      case 'in_progress':
        return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      default:
        return 'bg-gray-100 text-gray-800 border-gray-200';
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
        return <Clock size={14} className="text-gray-600" />;
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50">
        <div className="bg-white border-b border-gray-200">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
            <div className="flex items-center">
              <div className="p-2 bg-indigo-100 rounded-lg mr-4">
                <Shield size={24} className="text-indigo-600" />
              </div>
              <div>
                <h1 className="text-2xl font-bold text-gray-900">Sync Management</h1>
                <p className="text-gray-600 mt-1">Admin dashboard</p>
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
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center">
              <div className="p-2 bg-indigo-100 rounded-lg mr-4">
                <Shield size={24} className="text-indigo-600" />
              </div>
              <div>
                <h1 className="text-2xl font-bold text-gray-900">Sync Management</h1>
                <p className="text-gray-600 mt-1">Monitor API usage and control synchronization</p>
              </div>
            </div>
            <button
              onClick={loadDashboardData}
              className="flex items-center gap-2 px-4 py-2 bg-white border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 transition-colors"
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
          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Last Sync</p>
                <p className="text-3xl font-bold text-gray-900 mt-2">{apiUsage?.last_sync?.api_calls || 0}</p>
                <p className="text-xs text-gray-500 mt-1">
                  {formatDuration(apiUsage?.last_sync?.duration_seconds)}
                </p>
              </div>
              <div className="p-3 bg-gray-100 rounded-lg">
                <Activity size={24} className="text-gray-600" />
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg border border-blue-200 p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-blue-700">Today</p>
                <p className="text-3xl font-bold text-blue-900 mt-2">{apiUsage?.today?.api_calls || 0}</p>
                <p className="text-xs text-blue-600 mt-1">{apiUsage?.today?.sync_count || 0} syncs</p>
              </div>
              <div className="p-3 bg-blue-100 rounded-lg">
                <Zap size={24} className="text-blue-600" />
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg border border-purple-200 p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-purple-700">This Week</p>
                <p className="text-3xl font-bold text-purple-900 mt-2">{apiUsage?.this_week?.api_calls || 0}</p>
                <p className="text-xs text-purple-600 mt-1">{apiUsage?.this_week?.sync_count || 0} syncs</p>
              </div>
              <div className="p-3 bg-purple-100 rounded-lg">
                <Activity size={24} className="text-purple-600" />
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg border border-indigo-200 p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-indigo-700">This Month</p>
                <p className="text-3xl font-bold text-indigo-900 mt-2">{apiUsage?.this_month?.api_calls || 0}</p>
                <p className="text-xs text-indigo-600 mt-1">{apiUsage?.this_month?.sync_count || 0} syncs</p>
              </div>
              <div className="p-3 bg-indigo-100 rounded-lg">
                <Activity size={24} className="text-indigo-600" />
              </div>
            </div>
          </div>
        </div>

        {/* Status + Config Row */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
          {/* Current Status */}
          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <div className="flex items-center gap-2 mb-4">
              <Zap size={20} className="text-gray-600" />
              <h2 className="text-lg font-semibold text-gray-900">Current Status</h2>
            </div>
            <div className="flex items-center gap-4 mb-4">
              <span className={`inline-flex items-center gap-2 px-4 py-2 rounded-full text-sm font-semibold ${
                syncStatus?.is_running
                  ? 'bg-yellow-100 text-yellow-800 border border-yellow-200'
                  : 'bg-green-100 text-green-800 border border-green-200'
              }`}>
                {syncStatus?.is_running ? (
                  <><Loader2 size={16} className="animate-spin" /> Sync Running</>
                ) : (
                  <><CheckCircle2 size={16} /> Idle</>
                )}
              </span>
            </div>
            {syncStatus?.last_sync && (
              <div className="space-y-2 text-sm text-gray-600">
                <div className="flex items-center justify-between">
                  <span>Last Sync</span>
                  <span className="font-medium text-gray-900">{formatDateTime(syncStatus.last_sync.last_sync_at)}</span>
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
                  <span className="font-medium text-gray-900">{syncStatus.last_sync.api_calls_count}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span>Duration</span>
                  <span className="font-medium text-gray-900">{formatDuration(syncStatus.last_sync.duration_seconds)}</span>
                </div>
              </div>
            )}
          </div>

          {/* Configuration */}
          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <div className="flex items-center gap-2 mb-4">
              <Settings size={20} className="text-gray-600" />
              <h2 className="text-lg font-semibold text-gray-900">Configuration</h2>
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
                  <span className="font-medium text-gray-900">Enable Scheduled Syncs</span>
                </label>
                <p className="text-sm text-gray-500 mt-1 ml-8">
                  {syncConfig?.cron_enabled
                    ? 'Syncs will run on the schedule below'
                    : 'Scheduled syncs are disabled (manual only)'}
                </p>
              </div>

              {/* Schedule Days */}
              <div>
                <label className="flex items-center gap-1.5 text-sm font-medium text-gray-700 mb-2">
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
                            : 'bg-white text-gray-600 border-gray-300 hover:bg-gray-50'
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
                <label className="flex items-center gap-1.5 text-sm font-medium text-gray-700 mb-2">
                  <Clock size={14} />
                  Schedule Time (Europe/Paris)
                </label>
                <input
                  type="time"
                  value={scheduleTime}
                  onChange={(e) => setScheduleTime(e.target.value)}
                  className="w-32 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm"
                />
              </div>

              {/* Cooldown Hours */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Cooldown Hours
                </label>
                <input
                  type="number"
                  min="0"
                  step="0.5"
                  value={cooldownHours}
                  onChange={(e) => setCooldownHours(e.target.value)}
                  className="w-24 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm"
                />
                <p className="text-sm text-gray-500 mt-1">
                  Scheduled sync is skipped if the last successful sync (including force sync) was less than {cooldownHours}h ago
                </p>
              </div>

              {/* API Limits */}
              <div className="border-t border-gray-200 pt-4">
                <label className="block text-sm font-medium text-gray-700 mb-3">
                  API Call Limits per Sync
                </label>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs text-gray-500 mb-1">Dendreo API</label>
                    <input
                      type="number"
                      min="0"
                      step="10"
                      placeholder="Unlimited"
                      value={dendreoApiLimit}
                      onChange={(e) => setDendreoApiLimit(e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm"
                    />
                  </div>
                  <div>
                    <label className="block text-xs text-gray-500 mb-1">HubSpot API</label>
                    <input
                      type="number"
                      min="0"
                      step="10"
                      placeholder="Unlimited"
                      value={hubspotApiLimit}
                      onChange={(e) => setHubspotApiLimit(e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm"
                    />
                  </div>
                </div>
                <p className="text-sm text-gray-500 mt-1">
                  Max API calls per sync run. 0 or empty = unlimited. Remaining ADFs are skipped when the limit is reached.
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
        <div className="bg-white rounded-lg border border-gray-200 p-6 mb-6">
          <div className="flex items-center gap-2 mb-4">
            <Play size={20} className="text-gray-600" />
            <h2 className="text-lg font-semibold text-gray-900">Sync Actions</h2>
          </div>
          <div className="flex flex-wrap items-center gap-3">
            <button
              onClick={handleDryRun}
              disabled={isPollingLog}
              className="flex items-center gap-2 px-4 py-2 bg-gray-100 text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-200 transition-colors font-medium disabled:opacity-50 disabled:cursor-not-allowed"
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
                className="w-28 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm"
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
          </div>

          {actionOutput && (
            <div className={`mt-4 p-3 rounded-lg border ${
              actionOutput.status === 'started'
                ? 'bg-blue-50 border-blue-200'
                : actionOutput.status === 'error'
                ? 'bg-red-50 border-red-200'
                : 'bg-green-50 border-green-200'
            }`}>
              <div className="flex items-center gap-2">
                {actionOutput.status === 'started' ? (
                  <Loader2 size={16} className="text-blue-600 animate-spin" />
                ) : actionOutput.status === 'error' ? (
                  <XCircle size={16} className="text-red-600" />
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
                  <span className="flex items-center gap-1 px-2 py-0.5 bg-green-900 text-green-300 rounded-full text-xs font-medium">
                    <span className="w-1.5 h-1.5 bg-green-400 rounded-full animate-pulse" />
                    Live
                  </span>
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
        <div className="bg-white rounded-lg border border-gray-200">
          <div className="px-6 py-4 border-b border-gray-200">
            <div className="flex items-center gap-2">
              <History size={20} className="text-gray-600" />
              <h2 className="text-lg font-semibold text-gray-900">Recent Sync History</h2>
            </div>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="bg-gray-50">
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">Timestamp</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">Type</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">Status</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">API Calls</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">Duration</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">Error</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {syncHistory.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="px-6 py-8 text-center text-sm text-gray-500">
                      No sync history available
                    </td>
                  </tr>
                ) : (
                  syncHistory.map((sync) => (
                    <tr key={sync.id} className="hover:bg-gray-50 transition-colors">
                      <td className="px-6 py-3 text-sm text-gray-700">{formatDateTime(sync.last_sync_at)}</td>
                      <td className="px-6 py-3 text-sm text-gray-700">{sync.sync_type}</td>
                      <td className="px-6 py-3">
                        <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium border ${getStatusStyle(sync.status)}`}>
                          {getStatusIcon(sync.status)}
                          {sync.status}
                        </span>
                      </td>
                      <td className="px-6 py-3 text-sm text-gray-700">{sync.api_calls_count}</td>
                      <td className="px-6 py-3 text-sm text-gray-700">{formatDuration(sync.duration_seconds)}</td>
                      <td className="px-6 py-3 text-sm text-red-600 max-w-[200px] truncate">{sync.error_message || '-'}</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AdminSyncDashboard;

import React, { useState, useCallback, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Phone,
  AlarmClock,
  Mail,
  MessageSquare,
  Ban,
  FileText,
  X,
  Send,
  Loader2,
  Undo2,
  Clock,
  ChevronDown,
  ChevronUp,
  Check,
} from 'lucide-react';
import { useParticipantTimeline, useCreateIntervention, useCancelIntervention } from '../hooks/useQuery';
import { apiService } from '../services/api';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api';

const getProxyRecordingUrl = (originalUrl) => {
  if (!originalUrl) return null;
  const token = localStorage.getItem('token');
  return `${API_BASE_URL}/interventions/proxy-recording?url=${encodeURIComponent(originalUrl)}&token=${encodeURIComponent(token || '')}`;
};

// Filter definitions — maps filter key to matcher function
const FILTER_MATCHERS = {
  all: () => true,
  calls: (e) => e.source === 'hubspot_call' || (e.source === 'local' && e.intervention_type === 'call'),
  snooze: (e) => e.source === 'local' && e.intervention_type === 'snooze',
  notes: (e) => e.source === 'hubspot_note' || (e.source === 'local' && e.intervention_type === 'note'),
  email: (e) => e.source === 'local' && e.intervention_type === 'email',
  dismiss: (e) => e.source === 'local' && e.intervention_type === 'dismiss',
};

const InterventionPanel = ({ participant }) => {
  const { t } = useTranslation();

  // Timeline data — only fetches when panel is rendered (i.e. expanded)
  const { data: timeline, isLoading: timelineLoading, refetch: refetchTimeline } = useParticipantTimeline(
    participant.id,
    participant.id_action_formation,
    true
  );

  const createIntervention = useCreateIntervention();
  const cancelIntervention = useCancelIntervention();

  // UI state
  const [showSnoozeForm, setShowSnoozeForm] = useState(false);
  const [showNoteInput, setShowNoteInput] = useState(false);
  const [showDismissConfirm, setShowDismissConfirm] = useState(false);
  const [showCallConfirm, setShowCallConfirm] = useState(false);
  const [showEmailConfirm, setShowEmailConfirm] = useState(false);
  const [snoozeDays, setSnoozeDays] = useState(14);
  const [snoozeReason, setSnoozeReason] = useState('');
  const [noteText, setNoteText] = useState('');
  const [hubspotLoading, setHubspotLoading] = useState(false);
  const [showAllEntries, setShowAllEntries] = useState(false);
  const [timelineFilter, setTimelineFilter] = useState('all');

  const basePayload = {
    participant_id: participant.id,
    participant_course_id: participant.course_id || null,
    id_action_formation: participant.id_action_formation,
  };

  // --- Action handlers ---

  const handleCall = useCallback(async () => {
    if (!participant.email) return;
    setHubspotLoading(true);
    try {
      const data = await apiService.getHubspotContact(participant.email);
      if (data?.id) {
        const url = data.properties?.hs_object_id
          ? `https://app.hubspot.com/contacts/${data.properties.hs_object_id}`
          : null;
        const contactUrl = url || `https://app.hubspot.com/contacts`;
        window.open(contactUrl, '_blank', 'noopener,noreferrer');
        // Show confirmation + switch to calls filter
        setShowCallConfirm(true);
        setTimelineFilter('calls');
      }
    } catch (err) {
      // Silently fail — HubSpot might not have this contact
    } finally {
      setHubspotLoading(false);
    }
  }, [participant.email]);

  const handleCallConfirmYes = useCallback(() => {
    // Ringover logs the call in HubSpot — just refetch timeline to pick it up
    refetchTimeline();
    setShowCallConfirm(false);
  }, [refetchTimeline]);

  const handleCallConfirmNo = useCallback(() => {
    setShowCallConfirm(false);
  }, []);

  const handleSnooze = useCallback(() => {
    createIntervention.mutate(
      {
        ...basePayload,
        intervention_type: 'snooze',
        details: { snooze_days: snoozeDays, reason: snoozeReason },
      },
      {
        onSuccess: () => {
          setShowSnoozeForm(false);
          setSnoozeDays(14);
          setSnoozeReason('');
        },
      }
    );
  }, [snoozeDays, snoozeReason, participant.id, participant.id_action_formation]);

  const handleEmail = useCallback(() => {
    if (!participant.email) return;
    window.open(`mailto:${participant.email}`, '_self');
    // Show confirmation + switch to email filter
    setShowEmailConfirm(true);
    setTimelineFilter('email');
  }, [participant.email]);

  const handleEmailConfirmYes = useCallback(() => {
    createIntervention.mutate(
      {
        ...basePayload,
        intervention_type: 'email',
        details: { recipient: participant.email },
      },
      {
        onSuccess: () => setShowEmailConfirm(false),
      }
    );
  }, [participant.email, participant.id, participant.id_action_formation]);

  const handleEmailConfirmNo = useCallback(() => {
    setShowEmailConfirm(false);
  }, []);

  const handleNote = useCallback(() => {
    if (!noteText.trim()) return;
    createIntervention.mutate(
      {
        ...basePayload,
        intervention_type: 'note',
        details: { text: noteText.trim() },
      },
      {
        onSuccess: () => {
          setShowNoteInput(false);
          setNoteText('');
        },
      }
    );
  }, [noteText, participant.id, participant.id_action_formation]);

  const handleDismiss = useCallback(() => {
    createIntervention.mutate(
      {
        ...basePayload,
        intervention_type: 'dismiss',
        details: { reason: 'Dismissed from inactive list' },
      },
      {
        onSuccess: () => setShowDismissConfirm(false),
      }
    );
  }, [participant.id, participant.id_action_formation]);

  const handleCancelIntervention = useCallback((interventionId) => {
    cancelIntervention.mutate(interventionId);
  }, []);

  // --- Action button click with filter auto-select ---

  const handleSnoozeToggle = useCallback(() => {
    const opening = !showSnoozeForm;
    setShowSnoozeForm(opening);
    if (opening) setTimelineFilter('snooze');
  }, [showSnoozeForm]);

  const handleNoteToggle = useCallback(() => {
    const opening = !showNoteInput;
    setShowNoteInput(opening);
    if (opening) setTimelineFilter('notes');
  }, [showNoteInput]);

  const handleDismissToggle = useCallback(() => {
    const opening = !showDismissConfirm;
    setShowDismissConfirm(opening);
    if (opening) setTimelineFilter('dismiss');
  }, [showDismissConfirm]);

  // --- Helpers ---

  const formatTimestamp = (ts) => {
    if (!ts) return '';
    const date = new Date(ts);
    return date.toLocaleDateString('fr-FR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const stripHtml = (html) => {
    if (!html) return '';
    return html
      .replace(/<br\s*\/?>/gi, '\n')
      .replace(/<\/p>/gi, '\n')
      .replace(/<\/div>/gi, '\n')
      .replace(/<\/li>/gi, '\n')
      .replace(/<[^>]*>/g, '')
      .replace(/&nbsp;/g, ' ')
      .replace(/&amp;/g, '&')
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>')
      .replace(/&quot;/g, '"')
      .replace(/&#39;/g, "'")
      .replace(/\n{3,}/g, '\n\n')
      .trim();
  };

  const formatCallDuration = (seconds) => {
    if (!seconds) return '';
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return mins > 0 ? `${mins}m${secs > 0 ? ` ${secs}s` : ''}` : `${secs}s`;
  };

  const getEntryIcon = (entry) => {
    if (entry.source === 'hubspot_note') return <FileText size={14} className="text-orange-500" />;
    if (entry.source === 'hubspot_call') return <Phone size={14} className="text-blue-500" />;
    switch (entry.intervention_type) {
      case 'snooze': return <AlarmClock size={14} className="text-amber-500" />;
      case 'note': return <MessageSquare size={14} className="text-green-600" />;
      case 'email': return <Mail size={14} className="text-purple-500" />;
      case 'call': return <Phone size={14} className="text-blue-500" />;
      case 'dismiss': return <Ban size={14} className="text-red-500" />;
      default: return <Clock size={14} className="text-gray-400" />;
    }
  };

  const getEntryLabel = (entry) => {
    if (entry.source === 'hubspot_note') return t('inactiveManagement.interventions.sources.hubspot_note');
    if (entry.source === 'hubspot_call') return t('inactiveManagement.interventions.sources.hubspot_call');
    return t(`inactiveManagement.interventions.${entry.intervention_type}`) || entry.intervention_type;
  };

  const getEntryBody = (entry) => {
    if (entry.source === 'local') {
      if (entry.intervention_type === 'snooze' && entry.details) {
        const days = entry.details.snooze_days || 0;
        const reason = entry.details.reason || '';
        return `${days} ${t('common.daysInactive')}${reason ? ` — ${reason}` : ''}`;
      }
      if (entry.intervention_type === 'note' && entry.details?.text) {
        return entry.details.text;
      }
      if (entry.intervention_type === 'dismiss' && entry.details?.reason) {
        return entry.details.reason;
      }
      return null;
    }
    return stripHtml(entry.body) || null;
  };

  // --- Filtered entries ---

  const entries = timeline?.entries || [];
  const filteredEntries = useMemo(() => {
    const matcher = FILTER_MATCHERS[timelineFilter] || FILTER_MATCHERS.all;
    return entries.filter(matcher);
  }, [entries, timelineFilter]);
  const visibleEntries = showAllEntries ? filteredEntries : filteredEntries.slice(0, 5);
  const hasMore = filteredEntries.length > 5;

  // Count entries per filter for badges
  const filterCounts = useMemo(() => {
    const counts = {};
    for (const key of Object.keys(FILTER_MATCHERS)) {
      if (key === 'all') continue;
      counts[key] = entries.filter(FILTER_MATCHERS[key]).length;
    }
    return counts;
  }, [entries]);

  // Filter chip definitions
  const filterChips = [
    { key: 'all', label: t('inactiveManagement.interventions.filters.all') },
    { key: 'calls', label: t('inactiveManagement.interventions.filters.calls'), icon: <Phone size={10} /> },
    { key: 'snooze', label: t('inactiveManagement.interventions.filters.snooze'), icon: <AlarmClock size={10} /> },
    { key: 'notes', label: t('inactiveManagement.interventions.filters.notes'), icon: <MessageSquare size={10} /> },
    { key: 'email', label: t('inactiveManagement.interventions.filters.email'), icon: <Mail size={10} /> },
    { key: 'dismiss', label: t('inactiveManagement.interventions.filters.dismiss'), icon: <Ban size={10} /> },
  ];

  return (
    <div className="bg-gray-50 border-t border-gray-200 px-6 py-4">
      {/* Action Buttons */}
      <div className="flex items-center gap-2 mb-4">
        <button
          onClick={handleCall}
          disabled={!participant.email || hubspotLoading}
          className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-md bg-blue-50 text-blue-700 hover:bg-blue-100 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
          title={t('inactiveManagement.interventions.callTooltip')}
        >
          {hubspotLoading ? <Loader2 size={13} className="animate-spin" /> : <Phone size={13} />}
          {t('inactiveManagement.interventions.call')}
        </button>

        <button
          onClick={handleSnoozeToggle}
          className={`inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-md transition-colors ${
            showSnoozeForm ? 'bg-amber-200 text-amber-800' : 'bg-amber-50 text-amber-700 hover:bg-amber-100'
          }`}
          title={t('inactiveManagement.interventions.snoozeTooltip')}
        >
          <AlarmClock size={13} />
          {t('inactiveManagement.interventions.snooze')}
        </button>

        <button
          onClick={handleEmail}
          disabled={!participant.email}
          className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-md bg-purple-50 text-purple-700 hover:bg-purple-100 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
          title={t('inactiveManagement.interventions.emailTooltip')}
        >
          <Mail size={13} />
          {t('inactiveManagement.interventions.email')}
        </button>

        <button
          onClick={handleNoteToggle}
          className={`inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-md transition-colors ${
            showNoteInput ? 'bg-green-200 text-green-800' : 'bg-green-50 text-green-700 hover:bg-green-100'
          }`}
        >
          <MessageSquare size={13} />
          {t('inactiveManagement.interventions.note')}
        </button>

        <button
          onClick={handleDismissToggle}
          className={`inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-md transition-colors ${
            showDismissConfirm ? 'bg-red-200 text-red-800' : 'bg-red-50 text-red-700 hover:bg-red-100'
          }`}
          title={t('inactiveManagement.interventions.dismissTooltip')}
        >
          <Ban size={13} />
          {t('inactiveManagement.interventions.dismiss')}
        </button>
      </div>

      {/* Call Confirmation */}
      {showCallConfirm && (
        <div className="mb-4 p-3 bg-blue-50 border border-blue-200 rounded-lg">
          <p className="text-xs text-blue-700 mb-2">
            {t('inactiveManagement.interventions.callConfirmMessage')}
          </p>
          <div className="flex items-center gap-2">
            <button
              onClick={handleCallConfirmYes}
              className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium rounded bg-blue-600 text-white hover:bg-blue-700 transition-colors"
            >
              <Check size={12} />
              {t('common.yes')}
            </button>
            <button
              onClick={handleCallConfirmNo}
              className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium rounded bg-gray-200 text-gray-600 hover:bg-gray-300 transition-colors"
            >
              <X size={12} />
              {t('common.no')}
            </button>
          </div>
        </div>
      )}

      {/* Email Confirmation */}
      {showEmailConfirm && (
        <div className="mb-4 p-3 bg-purple-50 border border-purple-200 rounded-lg">
          <p className="text-xs text-purple-700 mb-2">
            {t('inactiveManagement.interventions.emailConfirmMessage')}
          </p>
          <div className="flex items-center gap-2">
            <button
              onClick={handleEmailConfirmYes}
              disabled={createIntervention.isPending}
              className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium rounded bg-purple-600 text-white hover:bg-purple-700 disabled:opacity-50 transition-colors"
            >
              {createIntervention.isPending ? <Loader2 size={12} className="animate-spin" /> : <Check size={12} />}
              {t('common.yes')}
            </button>
            <button
              onClick={handleEmailConfirmNo}
              className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium rounded bg-gray-200 text-gray-600 hover:bg-gray-300 transition-colors"
            >
              <X size={12} />
              {t('common.no')}
            </button>
          </div>
        </div>
      )}

      {/* Snooze Form */}
      {showSnoozeForm && (
        <div className="mb-4 p-3 bg-amber-50 border border-amber-200 rounded-lg">
          <div className="flex items-center gap-3 mb-2">
            <label className="text-xs font-medium text-amber-800">
              {t('inactiveManagement.interventions.snoozeDays')}
            </label>
            <input
              type="number"
              min={1}
              max={90}
              value={snoozeDays}
              onChange={(e) => setSnoozeDays(Math.max(1, Math.min(90, parseInt(e.target.value) || 1)))}
              className="w-16 px-2 py-1 text-xs border border-amber-300 rounded focus:ring-1 focus:ring-amber-400 focus:border-amber-400"
            />
          </div>
          <textarea
            value={snoozeReason}
            onChange={(e) => setSnoozeReason(e.target.value)}
            placeholder={t('inactiveManagement.interventions.snoozePlaceholder')}
            className="w-full px-3 py-2 text-xs border border-amber-300 rounded resize-none focus:ring-1 focus:ring-amber-400 focus:border-amber-400"
            rows={2}
          />
          <div className="flex items-center gap-2 mt-2">
            <button
              onClick={handleSnooze}
              disabled={createIntervention.isPending}
              className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium rounded bg-amber-600 text-white hover:bg-amber-700 disabled:opacity-50 transition-colors"
            >
              {createIntervention.isPending ? <Loader2 size={12} className="animate-spin" /> : <AlarmClock size={12} />}
              {t('inactiveManagement.interventions.snoozeConfirm')}
            </button>
            <button
              onClick={() => setShowSnoozeForm(false)}
              className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium rounded bg-gray-200 text-gray-600 hover:bg-gray-300 transition-colors"
            >
              <X size={12} />
            </button>
          </div>
        </div>
      )}

      {/* Note Input */}
      {showNoteInput && (
        <div className="mb-4 p-3 bg-green-50 border border-green-200 rounded-lg">
          <textarea
            value={noteText}
            onChange={(e) => setNoteText(e.target.value)}
            placeholder={t('inactiveManagement.interventions.notePlaceholder')}
            className="w-full px-3 py-2 text-xs border border-green-300 rounded resize-none focus:ring-1 focus:ring-green-400 focus:border-green-400"
            rows={2}
            autoFocus
          />
          <div className="flex items-center gap-2 mt-2">
            <button
              onClick={handleNote}
              disabled={!noteText.trim() || createIntervention.isPending}
              className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium rounded bg-green-600 text-white hover:bg-green-700 disabled:opacity-50 transition-colors"
            >
              {createIntervention.isPending ? <Loader2 size={12} className="animate-spin" /> : <Send size={12} />}
              {t('inactiveManagement.interventions.noteSubmit')}
            </button>
            <button
              onClick={() => { setShowNoteInput(false); setNoteText(''); }}
              className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium rounded bg-gray-200 text-gray-600 hover:bg-gray-300 transition-colors"
            >
              <X size={12} />
            </button>
          </div>
        </div>
      )}

      {/* Dismiss Confirmation */}
      {showDismissConfirm && (
        <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg">
          <p className="text-xs text-red-700 mb-2">
            {t('inactiveManagement.interventions.dismissWarning')}
          </p>
          <div className="flex items-center gap-2">
            <button
              onClick={handleDismiss}
              disabled={createIntervention.isPending}
              className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium rounded bg-red-600 text-white hover:bg-red-700 disabled:opacity-50 transition-colors"
            >
              {createIntervention.isPending ? <Loader2 size={12} className="animate-spin" /> : <Ban size={12} />}
              {t('inactiveManagement.interventions.dismissConfirm')}
            </button>
            <button
              onClick={() => setShowDismissConfirm(false)}
              className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium rounded bg-gray-200 text-gray-600 hover:bg-gray-300 transition-colors"
            >
              <X size={12} />
            </button>
          </div>
        </div>
      )}

      {/* Timeline */}
      <div className="border-t border-gray-200 pt-3">
        <div className="flex items-center justify-between mb-2">
          <h4 className="text-xs font-semibold text-gray-500 uppercase tracking-wide">
            {t('inactiveManagement.interventions.timeline')}
          </h4>
        </div>

        {/* Filter chips */}
        <div className="flex items-center gap-1.5 mb-3 flex-wrap">
          {filterChips.map(({ key, label, icon }) => {
            const isActive = timelineFilter === key;
            const count = key === 'all' ? entries.length : (filterCounts[key] || 0);
            if (key !== 'all' && count === 0) return null;
            return (
              <button
                key={key}
                onClick={() => { setTimelineFilter(key); setShowAllEntries(false); }}
                className={`inline-flex items-center gap-1 px-2 py-1 text-[10px] font-medium rounded-full transition-colors ${
                  isActive
                    ? 'bg-gray-700 text-white'
                    : 'bg-gray-100 text-gray-500 hover:bg-gray-200'
                }`}
              >
                {icon}
                {label}
                <span className={`ml-0.5 ${isActive ? 'text-gray-300' : 'text-gray-400'}`}>
                  {count}
                </span>
              </button>
            );
          })}
        </div>

        {timelineLoading ? (
          <div className="flex items-center justify-center py-4">
            <Loader2 size={16} className="animate-spin text-gray-400" />
          </div>
        ) : filteredEntries.length === 0 ? (
          <p className="text-xs text-gray-400 py-2">
            {t('inactiveManagement.interventions.noEntries')}
          </p>
        ) : (
          <>
            <div className="space-y-0">
              {visibleEntries.map((entry, idx) => (
                <div
                  key={`${entry.source}-${entry.hubspot_id || entry.intervention_id || idx}`}
                  className={`flex gap-2.5 py-2 ${idx < visibleEntries.length - 1 ? 'border-b border-gray-100' : ''} ${
                    entry.is_active === false ? 'opacity-40' : ''
                  }`}
                >
                  {/* Icon */}
                  <div className="flex-shrink-0 mt-0.5">{getEntryIcon(entry)}</div>

                  {/* Content */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 text-xs">
                      <span className="font-medium text-gray-700">
                        {getEntryLabel(entry)}
                      </span>
                      {entry.user_display_name && (
                        <span className="text-gray-400">
                          {entry.user_display_name}
                        </span>
                      )}
                      {entry.hubspot_owner_name && (
                        <span className="text-gray-400">
                          {entry.hubspot_owner_name}
                        </span>
                      )}
                      <span className="text-gray-300 text-[10px]">
                        {formatTimestamp(entry.timestamp)}
                      </span>
                    </div>

                    {/* Body */}
                    {getEntryBody(entry) && (
                      <p className="text-xs text-gray-600 mt-0.5 line-clamp-3 whitespace-pre-line">
                        {getEntryBody(entry)}
                      </p>
                    )}

                    {/* Call recording player */}
                    {entry.call_recording_url && (
                      <div className="mt-1.5 flex items-center gap-2">
                        <audio
                          controls
                          preload="metadata"
                          className="h-8 max-w-xs"
                          style={{ minWidth: '200px' }}
                          src={getProxyRecordingUrl(entry.call_recording_url)}
                        />
                        {entry.call_duration && (
                          <span className="text-[10px] text-gray-400">
                            {formatCallDuration(entry.call_duration)}
                          </span>
                        )}
                      </div>
                    )}

                    {/* Call duration (when no recording) */}
                    {!entry.call_recording_url && entry.call_duration && (
                      <span className="text-[10px] text-gray-400">
                        {formatCallDuration(entry.call_duration)}
                      </span>
                    )}
                  </div>

                  {/* Cancel button for active snoozes/dismissals */}
                  {entry.source === 'local' &&
                    entry.is_active &&
                    (entry.intervention_type === 'snooze' || entry.intervention_type === 'dismiss') && (
                      <button
                        onClick={() => handleCancelIntervention(entry.intervention_id)}
                        disabled={cancelIntervention.isPending}
                        className="flex-shrink-0 p-1 text-gray-400 hover:text-red-500 transition-colors"
                        title={
                          entry.intervention_type === 'snooze'
                            ? t('inactiveManagement.interventions.cancelSnooze')
                            : t('inactiveManagement.interventions.reverseDismiss')
                        }
                      >
                        <Undo2 size={12} />
                      </button>
                    )}
                </div>
              ))}
            </div>

            {/* Show more / less */}
            {hasMore && (
              <button
                onClick={() => setShowAllEntries(!showAllEntries)}
                className="flex items-center gap-1 mt-2 text-[10px] text-gray-400 hover:text-gray-600 transition-colors"
              >
                {showAllEntries ? (
                  <>
                    <ChevronUp size={10} />
                    {filteredEntries.length - 5} de moins
                  </>
                ) : (
                  <>
                    <ChevronDown size={10} />
                    {filteredEntries.length - 5} de plus
                  </>
                )}
              </button>
            )}
          </>
        )}
      </div>
    </div>
  );
};

export default InterventionPanel;

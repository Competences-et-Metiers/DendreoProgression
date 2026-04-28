import React, { useState, useEffect, useMemo, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import {
  UserX,
  User,
  Clock,
  BookOpen,
  Calendar,
  CalendarClock,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  Settings,
  Filter,
  BarChart3,
  Loader2,
  ArrowUpDown,
  ArrowUp,
  ArrowDown,
  CheckCircle2,
  X,
  Download,
  Search,
  AlarmClock,
  Ban,
  MessageSquare,
} from 'lucide-react';
import api from '../services/api';
import { useLastSync } from '../hooks/useQuery';
import { generateInactivityReport } from '../utils/pdfExport';
import { formatTimeSpentInHours, formatHoursMinutes } from '../utils/timeUtils';
import InterventionPanel from '../components/InterventionPanel';
import SavedViewsBar from '../components/SavedViewsBar';

const InactiveManagement = () => {
  const { t, i18n } = useTranslation();
  const { data: lastSync } = useLastSync();

  // State with sessionStorage persistence
  const [groupByCourse, setGroupByCourse] = useState(() => {
    const cached = sessionStorage.getItem('inactiveManagement.groupByCourse');
    return cached !== null ? JSON.parse(cached) : false;
  });

  const [filters, setFilters] = useState(() => {
    const cached = sessionStorage.getItem('inactiveManagement.filters');
    if (cached) {
      const parsed = JSON.parse(cached);
      // Migrate old filter format
      return {
        inactivityThreshold: parsed.inactivityThreshold || 30,
        excludeRecentDays: parsed.excludeRecentDays ?? 0,
        minProgression: parsed.minProgression ?? null,
        maxProgression: parsed.maxProgression ?? null,
        courseId: parsed.courseId ?? null
      };
    }
    return {
      inactivityThreshold: 30,
      excludeRecentDays: 0,
      minProgression: null,
      maxProgression: null,
      courseId: null
    };
  });

  const [showFilters, setShowFilters] = useState(false);
  const [expandedCourses, setExpandedCourses] = useState(new Set());

  const [sortBy, setSortBy] = useState(() => {
    const cached = localStorage.getItem('inactiveManagement.sortBy');
    return cached || 'inactivity';
  });

  const [sortDirection, setSortDirection] = useState(() => {
    const cached = localStorage.getItem('inactiveManagement.sortDirection');
    return cached || 'desc';
  });

  const [statusFilter, setStatusFilter] = useState(() => {
    const cached = localStorage.getItem('inactiveManagement.statusFilter');
    if (cached) {
      const parsed = JSON.parse(cached);
      // Migrate old format if needed
      if ('stalled' in parsed || 'long_inactive' in parsed) {
        return { active: true, inactive: true, never_started: true, snoozed: false, dismissed: false };
      }
      // Migrate: add never_started if missing
      if (!('never_started' in parsed)) {
        parsed.never_started = true;
      }
      // Migrate: add snoozed/dismissed if missing
      if (!('snoozed' in parsed)) parsed.snoozed = false;
      if (!('dismissed' in parsed)) parsed.dismissed = false;
      return parsed;
    }
    return { active: true, inactive: true, never_started: true, snoozed: false, dismissed: false };
  });

  // ADF filter state
  const [selectedADFs, setSelectedADFs] = useState(() => {
    const cached = localStorage.getItem('inactiveManagement.selectedADFs');
    return cached ? JSON.parse(cached) : [];
  });

  const [adfSearchTerm, setAdfSearchTerm] = useState('');
  const [showAdfDropdown, setShowAdfDropdown] = useState(false);

  // Formateur filter state
  const [selectedFormateurs, setSelectedFormateurs] = useState(() => {
    const cached = localStorage.getItem('inactiveManagement.selectedFormateurs');
    return cached ? JSON.parse(cached) : [];
  });

  const [formateurSearchTerm, setFormateurSearchTerm] = useState('');
  const [showFormateurDropdown, setShowFormateurDropdown] = useState(false);

  // Category filter state
  const [selectedCategories, setSelectedCategories] = useState(() => {
    const cached = localStorage.getItem('inactiveManagement.selectedCategories');
    return cached ? JSON.parse(cached) : [];
  });

  const [categorySearchTerm, setCategorySearchTerm] = useState('');
  const [showCategoryDropdown, setShowCategoryDropdown] = useState(false);

  // Progression range slider (client-side filter)
  const [progressionRange, setProgressionRange] = useState(() => {
    const cached = localStorage.getItem('inactiveManagement.progressionRange');
    return cached ? JSON.parse(cached) : [0, 100];
  });

  // CV planifié = Actif toggle
  const [cvPlannedIsActive, setCvPlannedIsActive] = useState(() => {
    const cached = localStorage.getItem('inactiveManagement.cvPlannedIsActive');
    return cached ? JSON.parse(cached) : false;
  });

  // Show/hide intervention counters (snoozed/dismissed stat cards) — toggled from Settings page
  const showInterventionCounters = useMemo(() => {
    const cached = localStorage.getItem('inactiveManagement.showInterventionCounters');
    return cached ? JSON.parse(cached) : false;
  }, []);

  // Show latest notes on participant cards — toggled from Settings page (default on)
  const showLatestNotes = useMemo(() => {
    const cached = localStorage.getItem('inactiveManagement.showLatestNotes');
    return cached === null ? true : JSON.parse(cached);
  }, []);

  // Note filters: independent toggles that combine
  const [noteFilterWithNote, setNoteFilterWithNote] = useState(false);
  const [noteFilterWithoutNote, setNoteFilterWithoutNote] = useState(false);
  const [noteFilterOlderThan, setNoteFilterOlderThan] = useState(false);
  const [noteOlderThanDays, setNoteOlderThanDays] = useState(7);
  const [noteOlderThanInput, setNoteOlderThanInput] = useState('7');

  // Intervention expand state
  const [expandedParticipants, setExpandedParticipants] = useState(new Set());

  const toggleParticipantExpand = useCallback((participantKey) => {
    setExpandedParticipants(prev => {
      const next = new Set(prev);
      if (next.has(participantKey)) {
        next.delete(participantKey);
      } else {
        next.add(participantKey);
      }
      return next;
    });
  }, []);

  // Global search
  const [searchTerm, setSearchTerm] = useState(() => {
    return localStorage.getItem('inactiveManagement.searchTerm') || '';
  });

  // Pagination
  const PAGE_SIZE_OPTIONS = [25, 50, 100, 0]; // 0 = all
  const [pageSize, setPageSize] = useState(() => {
    const cached = localStorage.getItem('inactiveManagement.pageSize');
    return cached ? JSON.parse(cached) : 50;
  });
  const [currentPage, setCurrentPage] = useState(1);

  // Persist state to localStorage
  useEffect(() => {
    localStorage.setItem('inactiveManagement.groupByCourse', JSON.stringify(groupByCourse));
  }, [groupByCourse]);

  useEffect(() => {
    localStorage.setItem('inactiveManagement.filters', JSON.stringify(filters));
  }, [filters]);

  useEffect(() => {
    localStorage.setItem('inactiveManagement.sortBy', sortBy);
  }, [sortBy]);

  useEffect(() => {
    localStorage.setItem('inactiveManagement.sortDirection', sortDirection);
  }, [sortDirection]);

  useEffect(() => {
    localStorage.setItem('inactiveManagement.statusFilter', JSON.stringify(statusFilter));
  }, [statusFilter]);

  useEffect(() => {
    localStorage.setItem('inactiveManagement.selectedADFs', JSON.stringify(selectedADFs));
  }, [selectedADFs]);

  useEffect(() => {
    localStorage.setItem('inactiveManagement.selectedFormateurs', JSON.stringify(selectedFormateurs));
  }, [selectedFormateurs]);

  useEffect(() => {
    localStorage.setItem('inactiveManagement.selectedCategories', JSON.stringify(selectedCategories));
  }, [selectedCategories]);

  useEffect(() => {
    localStorage.setItem('inactiveManagement.progressionRange', JSON.stringify(progressionRange));
  }, [progressionRange]);

  useEffect(() => {
    localStorage.setItem('inactiveManagement.cvPlannedIsActive', JSON.stringify(cvPlannedIsActive));
  }, [cvPlannedIsActive]);

  useEffect(() => {
    localStorage.setItem('inactiveManagement.searchTerm', searchTerm);
  }, [searchTerm]);

  useEffect(() => {
    localStorage.setItem('inactiveManagement.pageSize', JSON.stringify(pageSize));
  }, [pageSize]);

  // Reset pagination when filters change
  useEffect(() => {
    setCurrentPage(1);
  }, [selectedADFs, selectedFormateurs, selectedCategories, searchTerm, statusFilter, sortBy, sortDirection, groupByCourse, pageSize, progressionRange, cvPlannedIsActive]);

  // Clean up old localStorage keys from removed active user toggle
  useEffect(() => {
    localStorage.removeItem('inactiveManagement.showActiveOnly');
    localStorage.removeItem('inactiveManagement.activeDaysThreshold');
  }, []);

  // Fetch participants
  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['participants-view', groupByCourse, filters],
    queryFn: async () => {
      const params = new URLSearchParams({
        group_by_course: groupByCourse,
        inactivity_threshold_days: filters.inactivityThreshold,
        exclude_recent_enrollments_days: filters.excludeRecentDays
      });

      if (filters.minProgression !== null) {
        params.append('min_progression', filters.minProgression);
      }
      if (filters.maxProgression !== null) {
        params.append('max_progression', filters.maxProgression);
      }
      if (filters.courseId !== null) {
        params.append('course_id', filters.courseId);
      }

      const response = await api.get(`/participants/inactive?${params}`);
      return response.data;
    },
    staleTime: 60000,
  });

  const toggleCourse = useCallback((courseId) => {
    setExpandedCourses(prev => {
      const newExpanded = new Set(prev);
      if (newExpanded.has(courseId)) {
        newExpanded.delete(courseId);
      } else {
        newExpanded.add(courseId);
      }
      return newExpanded;
    });
  }, []);

  const formatDate = (dateString) => {
    if (!dateString) return t('common.never');
    return new Date(dateString).toLocaleDateString();
  };

  const getDisplayStatus = (participant) => {
    if (participant.is_dismissed) return 'dismissed';
    if (participant.has_active_snooze) return 'snoozed';
    return participant.inactivity_status;
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'active':
        return 'bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-400 border-green-200 dark:border-green-800';
      case 'inactive':
        return 'bg-red-100 dark:bg-red-900/30 text-red-800 dark:text-red-400 border-red-200 dark:border-red-800';
      case 'never_started':
        return 'bg-purple-100 dark:bg-purple-900/30 text-purple-800 dark:text-purple-400 border-purple-200 dark:border-purple-800';
      case 'snoozed':
        return 'bg-amber-100 dark:bg-amber-900/30 text-amber-800 dark:text-amber-400 border-amber-200 dark:border-amber-800';
      case 'dismissed':
        return 'bg-gray-200 dark:bg-slate-600 text-gray-700 dark:text-gray-300 border-gray-300 dark:border-slate-600';
      default:
        return 'bg-gray-100 dark:bg-slate-700 text-gray-800 dark:text-gray-200 border-gray-200 dark:border-slate-700';
    }
  };

  const getStatusIcon = (status) => {
    switch (status) {
      case 'active':
        return <CheckCircle2 size={16} className="text-green-600 dark:text-green-400" />;
      case 'inactive':
        return <UserX size={16} className="text-red-600 dark:text-red-400" />;
      case 'never_started':
        return <Clock size={16} className="text-purple-600 dark:text-purple-400" />;
      case 'snoozed':
        return <AlarmClock size={16} className="text-amber-600 dark:text-amber-400" />;
      case 'dismissed':
        return <Ban size={16} className="text-gray-600 dark:text-gray-400" />;
      default:
        return <Clock size={16} className="text-gray-600 dark:text-gray-400" />;
    }
  };

  const getStatusLabel = (status) => {
    switch (status) {
      case 'active':
        return t('inactiveManagement.status.active');
      case 'inactive':
        return t('inactiveManagement.status.inactive');
      case 'never_started':
        return t('inactiveManagement.status.neverStarted');
      case 'snoozed':
        return t('inactiveManagement.status.snoozed');
      case 'dismissed':
        return t('inactiveManagement.status.dismissed');
      default:
        return status;
    }
  };

  // Consolidated filtering: single useMemo produces stats, flat list, and grouped list
  const { filteredStats, filteredParticipantsFlat, filteredCourseGroups } = useMemo(() => {
    const emptyResult = {
      filteredStats: { total: 0, active: 0, inactive: 0, never_started: 0, snoozed: 0, dismissed: 0 },
      filteredParticipantsFlat: [],
      filteredCourseGroups: [],
    };
    if (!data) return emptyResult;

    // Base filters: ADF, formateur, category, search (no status, no sort)
    const applyBaseFilters = (participants) => {
      if (!participants) return [];
      let filtered = participants;
      if (selectedADFs.length > 0) {
        filtered = filtered.filter(p => selectedADFs.includes(p.id_action_formation));
      }
      if (selectedFormateurs.length > 0) {
        filtered = filtered.filter(p =>
          p.formateurs?.some(f => selectedFormateurs.includes(f.id_formateur))
        );
      }
      if (selectedCategories.length > 0) {
        filtered = filtered.filter(p => p.category_name && selectedCategories.includes(p.category_name));
      }
      if (searchTerm.trim()) {
        const term = searchTerm.toLowerCase().trim();
        filtered = filtered.filter(p => {
          const name = `${p.nom || ''} ${p.prenom || ''}`.toLowerCase();
          const courseTitle = (p.course_title || '').toLowerCase();
          const category = (p.category_name || '').toLowerCase();
          return name.includes(term) || courseTitle.includes(term) || category.includes(term);
        });
      }
      if (progressionRange[0] > 0 || progressionRange[1] < 100) {
        filtered = filtered.filter(p => {
          const prog = p.current_progression || p.overall_progression || 0;
          return prog >= progressionRange[0] && prog <= progressionRange[1];
        });
      }
      // Snooze/dismiss visibility (driven by status filter pills)
      if (!statusFilter.snoozed) {
        filtered = filtered.filter(p => !p.has_active_snooze);
      }
      if (!statusFilter.dismissed) {
        filtered = filtered.filter(p => !p.is_dismissed);
      }
      // Note filters (only when showLatestNotes is enabled)
      if (showLatestNotes) {
        const now = new Date();
        if (noteFilterWithNote && !noteFilterOlderThan) {
          filtered = filtered.filter(p => !!p.latest_note_date);
        }
        if (noteFilterWithoutNote) {
          filtered = filtered.filter(p => !p.latest_note_date);
        }
        if (noteFilterOlderThan) {
          filtered = filtered.filter(p => {
            if (!p.latest_note_date) return true;
            const daysSince = Math.floor((now - new Date(p.latest_note_date)) / (1000 * 60 * 60 * 24));
            return daysSince > noteOlderThanDays;
          });
        }
        // "with_note" + "older_than" combined = has a note AND it's older than X days
        if (noteFilterWithNote && noteFilterOlderThan) {
          filtered = filtered.filter(p => !!p.latest_note_date);
        }
      }
      return filtered;
    };

    // Status filter + sort
    const applySortAndStatus = (participants) => {
      const withStatus = participants.filter(p =>
        statusFilter[p.inactivity_status] ||
        (statusFilter.snoozed && p.has_active_snooze) ||
        (statusFilter.dismissed && p.is_dismissed)
      );
      const sortMultiplier = sortDirection === 'asc' ? 1 : -1;
      withStatus.sort((a, b) => {
        let comparison = 0;
        switch (sortBy) {
          case 'inactivity':
            comparison = ((a.days_inactive || 0) - (b.days_inactive || 0)) * -1;
            break;
          case 'name':
            comparison = `${a.nom} ${a.prenom}`.localeCompare(`${b.nom} ${b.prenom}`);
            break;
          case 'progression': {
            const progA = a.current_progression || a.overall_progression || 0;
            const progB = b.current_progression || b.overall_progression || 0;
            comparison = progA - progB;
            break;
          }
          case 'status': {
            const order = { never_started: 3, inactive: 2, active: 1 };
            comparison = (order[a.inactivity_status] || 0) - (order[b.inactivity_status] || 0);
            break;
          }
          case 'intervention': {
            // Sort by intervention status: dismissed first, then snoozed, then others
            const interventionOrder = (p) => p.is_dismissed ? 2 : p.has_active_snooze ? 1 : 0;
            comparison = interventionOrder(a) - interventionOrder(b);
            break;
          }
          case 'date_add': {
            const addA = a.enrollment_date ? new Date(a.enrollment_date).getTime() : 0;
            const addB = b.enrollment_date ? new Date(b.enrollment_date).getTime() : 0;
            comparison = addA - addB;
            break;
          }
          case 'latest_note': {
            // No note = sort last (Infinity), otherwise by date descending
            const dateA = a.latest_note_date ? new Date(a.latest_note_date).getTime() : 0;
            const dateB = b.latest_note_date ? new Date(b.latest_note_date).getTime() : 0;
            comparison = dateA - dateB;
            break;
          }
          default:
            comparison = 0;
        }
        return comparison * sortMultiplier;
      });
      return withStatus;
    };

    // Collect all participants into flat list
    let allParticipants = [];
    if (data.participants) {
      allParticipants = data.participants;
    } else if (data.by_course) {
      for (const course of data.by_course) {
        if (course.participants) allParticipants = allParticipants.concat(course.participants);
      }
    }

    // CV planifié = Actif: override status for participants with upcoming sessions
    if (cvPlannedIsActive) {
      allParticipants = allParticipants.map(p =>
        p.upcoming_sessions_count > 0
          ? { ...p, inactivity_status: 'active', inactivity_reason: 'CV planifiée' }
          : p
      );
    }

    // Base filter once for stats + flat view
    const baseFiltered = applyBaseFilters(allParticipants);

    // Stats: only count participants whose status filter is active
    const stats = { total: 0, active: 0, inactive: 0, never_started: 0, snoozed: 0, dismissed: 0 };
    for (const p of baseFiltered) {
      let key;
      if (p.is_dismissed) {
        key = 'dismissed';
      } else if (p.has_active_snooze) {
        key = 'snoozed';
      } else {
        key = p.inactivity_status;
      }
      if (key in stats && statusFilter[key]) {
        stats[key]++;
        stats.total++;
      }
    }

    // Flat view: apply status + sort to already-filtered list
    const flat = data.participants ? applySortAndStatus(baseFiltered) : [];

    // Grouped view: base filter per course, then status + sort
    const applyCvOverride = (participants) =>
      cvPlannedIsActive
        ? participants.map(p => p.upcoming_sessions_count > 0 ? { ...p, inactivity_status: 'active', inactivity_reason: 'CV planifiée' } : p)
        : participants;

    const groups = data.by_course
      ? data.by_course
          .map(course => ({
            ...course,
            filteredParticipants: applySortAndStatus(applyBaseFilters(applyCvOverride(course.participants)))
          }))
          .filter(course => course.filteredParticipants.length > 0)
      : [];

    return { filteredStats: stats, filteredParticipantsFlat: flat, filteredCourseGroups: groups };
  }, [data, selectedADFs, selectedFormateurs, selectedCategories, searchTerm, statusFilter, sortBy, sortDirection, progressionRange, cvPlannedIsActive, showLatestNotes, noteFilterWithNote, noteFilterWithoutNote, noteFilterOlderThan, noteOlderThanDays]);

  // Pagination: slice data for current page (pageSize 0 = show all)
  const totalItems = groupByCourse ? filteredCourseGroups.length : filteredParticipantsFlat.length;
  const effectivePageSize = pageSize === 0 ? totalItems : pageSize;
  const totalPages = Math.max(1, Math.ceil(totalItems / effectivePageSize));
  const safePage = Math.min(currentPage, totalPages);
  const pageStart = (safePage - 1) * effectivePageSize;
  const pageEnd = Math.min(pageStart + effectivePageSize, totalItems);
  const paginatedFlat = filteredParticipantsFlat.slice(pageStart, pageEnd);
  const paginatedGroups = filteredCourseGroups.slice(pageStart, pageEnd);

  const toggleSort = useCallback((field) => {
    setSortBy(prev => {
      if (prev === field) {
        setSortDirection(d => d === 'asc' ? 'desc' : 'asc');
        return prev;
      }
      setSortDirection('desc');
      return field;
    });
  }, []);

  const toggleStatusFilter = useCallback((status) => {
    setStatusFilter(prev => ({
      ...prev,
      [status]: !prev[status]
    }));
  }, []);

  // Memoized dropdown data - extracted from render to avoid recomputing on every state change
  const adfList = useMemo(() => {
    if (!data) return [];
    const uniqueADFs = new Set();
    const list = [];
    (data.participants || []).forEach(p => {
      if (p.id_action_formation && !uniqueADFs.has(p.id_action_formation)) {
        uniqueADFs.add(p.id_action_formation);
        list.push({ id: p.id_action_formation, title: p.course_title });
      }
    });
    (data.by_course || []).forEach(c => {
      if (c.id_action_formation && !uniqueADFs.has(c.id_action_formation)) {
        uniqueADFs.add(c.id_action_formation);
        list.push({ id: c.id_action_formation, title: c.course_title });
      }
    });
    return list.sort((a, b) => (a.title || '').localeCompare(b.title || ''));
  }, [data]);

  const formateurList = useMemo(() => {
    if (!data) return [];
    const uniqueFormateurs = new Map();
    const processFormateurs = (formateurs) => {
      if (!formateurs || !Array.isArray(formateurs)) return;
      formateurs.forEach(f => {
        if (f.id_formateur && !uniqueFormateurs.has(f.id_formateur)) {
          uniqueFormateurs.set(f.id_formateur, {
            id: f.id_formateur,
            nom: f.nom || '',
            prenom: f.prenom || '',
            fullName: `${f.prenom || ''} ${f.nom || ''}`.trim()
          });
        }
      });
    };
    (data.participants || []).forEach(p => processFormateurs(p.formateurs));
    (data.by_course || []).forEach(c => {
      (c.participants || []).forEach(p => processFormateurs(p.formateurs));
    });
    return Array.from(uniqueFormateurs.values()).sort((a, b) => (a.prenom || '').localeCompare(b.prenom || ''));
  }, [data]);

  const categoryList = useMemo(() => {
    if (!data) return [];
    const uniqueCategories = new Map();
    const addCategory = (name, color) => {
      if (name && !uniqueCategories.has(name)) {
        uniqueCategories.set(name, { name, color: color || '' });
      }
    };
    (data.participants || []).forEach(p => addCategory(p.category_name, p.category_color));
    (data.by_course || []).forEach(c => {
      addCategory(c.category_name, c.category_color);
      (c.participants || []).forEach(p => addCategory(p.category_name, p.category_color));
    });
    return Array.from(uniqueCategories.values()).sort((a, b) => a.name.localeCompare(b.name));
  }, [data]);

  const hasActiveFilters = !statusFilter.active || !statusFilter.inactive || !statusFilter.never_started || statusFilter.snoozed || statusFilter.dismissed || selectedADFs.length > 0 || selectedFormateurs.length > 0 || selectedCategories.length > 0 || searchTerm || filters.inactivityThreshold !== 30 || filters.excludeRecentDays !== 0 || progressionRange[0] > 0 || progressionRange[1] < 100 || cvPlannedIsActive || noteFilterWithNote || noteFilterWithoutNote || noteFilterOlderThan;

  const resetAllFilters = useCallback(() => {
    setStatusFilter({ active: true, inactive: true, never_started: true, snoozed: false, dismissed: false });
    setSelectedADFs([]);
    setSelectedFormateurs([]);
    setSelectedCategories([]);
    setSearchTerm('');
    setCvPlannedIsActive(false);
    setProgressionRange([0, 100]);
    setFilters(f => ({ ...f, inactivityThreshold: 30, excludeRecentDays: 0 }));
    setNoteFilterWithNote(false);
    setNoteFilterWithoutNote(false);
    setNoteFilterOlderThan(false);
    setNoteOlderThanDays(7);
    setNoteOlderThanInput('7');
  }, []);

  const collectCurrentFilters = useCallback(() => ({
    filters: {
      inactivityThreshold: filters.inactivityThreshold,
      excludeRecentDays: filters.excludeRecentDays,
    },
    statusFilter,
    selectedADFs,
    selectedFormateurs,
    selectedCategories,
    progressionRange,
    cvPlannedIsActive,
    sortBy,
    sortDirection,
    groupByCourse,
  }), [filters, statusFilter, selectedADFs, selectedFormateurs, selectedCategories, progressionRange, cvPlannedIsActive, sortBy, sortDirection, groupByCourse]);

  const applyView = useCallback((config) => {
    if (config.filters) setFilters(f => ({ ...f, ...config.filters }));
    if (config.statusFilter) setStatusFilter(config.statusFilter);
    if (config.selectedADFs) setSelectedADFs(config.selectedADFs);
    if (config.selectedFormateurs) setSelectedFormateurs(config.selectedFormateurs);
    if (config.selectedCategories) setSelectedCategories(config.selectedCategories);
    if (config.progressionRange) setProgressionRange(config.progressionRange);
    if (config.cvPlannedIsActive !== undefined) setCvPlannedIsActive(config.cvPlannedIsActive);
    if (config.sortBy) setSortBy(config.sortBy);
    if (config.sortDirection) setSortDirection(config.sortDirection);
    if (config.groupByCourse !== undefined) setGroupByCourse(config.groupByCourse);
  }, []);

  const handleDownloadPDF = async () => {
    if (!data) return;

    // Use pre-computed filtered data from the consolidated useMemo
    let filteredParticipants;
    if (groupByCourse) {
      filteredParticipants = filteredCourseGroups.flatMap(c => c.filteredParticipants);
    } else {
      filteredParticipants = filteredParticipantsFlat;
    }

    // Build active filter descriptions
    const activeFilterDescriptions = [];
    if (searchTerm.trim()) {
      activeFilterDescriptions.push(`${t('common.search')}: "${searchTerm.trim()}"`);
    }
    if (selectedFormateurs.length > 0) {
      const formateurNames = selectedFormateurs
        .map(id => formateurList.find(f => f.id === id))
        .filter(Boolean)
        .map(f => f.fullName);
      activeFilterDescriptions.push(`${t('inactiveManagement.pdf.filterFormateurs')}: ${formateurNames.join(', ')}`);
    }
    if (selectedCategories.length > 0) {
      activeFilterDescriptions.push(`${t('inactiveManagement.pdf.filterCategories')}: ${selectedCategories.join(', ')}`);
    }

    const disabledStatuses = [];
    if (!statusFilter.active) disabledStatuses.push(t('inactiveManagement.status.active'));
    if (!statusFilter.inactive) disabledStatuses.push(t('inactiveManagement.status.inactive'));
    if (!statusFilter.never_started) disabledStatuses.push(t('inactiveManagement.status.neverStarted'));
    if (statusFilter.snoozed) disabledStatuses.push(t('inactiveManagement.status.snoozed'));
    if (statusFilter.dismissed) disabledStatuses.push(t('inactiveManagement.status.dismissed'));
    if (disabledStatuses.length > 0) {
      activeFilterDescriptions.push(`${t('inactiveManagement.pdf.filterExcluded')}: ${disabledStatuses.join(', ')}`);
    }

    const lang = i18n.language?.startsWith('fr') ? 'fr' : 'en';

    generateInactivityReport({
      participants: filteredParticipants,
      stats: filteredStats,
      activeFilters: activeFilterDescriptions,
      t,
      lang,
    });
  };

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-slate-900">
      {/* Header */}
      <div className="bg-white dark:bg-slate-800 border-b border-gray-200 dark:border-slate-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center">
              <div className="p-2 bg-orange-100 dark:bg-orange-900/30 rounded-lg mr-4">
                <UserX size={24} className="text-orange-600 dark:text-orange-400" />
              </div>
              <div>
                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                  {t('inactiveManagement.title')}
                </h1>
                <p className="text-gray-600 dark:text-gray-400 mt-1">
                  {t('inactiveManagement.subtitle')}
                </p>
                {lastSync && lastSync.last_sync_at && (
                  <div className="flex items-center mt-1 text-xs text-gray-500 dark:text-gray-400">
                    <Calendar size={12} className="mr-1" />
                    {t('inactiveManagement.lastSync')}: {new Date(lastSync.last_sync_at).toLocaleString()}
                    {lastSync.sync_status && (
                      <span className={`ml-1 font-medium ${
                        lastSync.sync_status === 'success' ? 'text-green-600 dark:text-green-400' :
                        lastSync.sync_status === 'error' ? 'text-red-600 dark:text-red-400' :
                        'text-gray-500 dark:text-gray-400'
                      }`}>
                        ({t(`adfList.sync.status.${lastSync.sync_status === 'success' ? 'success' : lastSync.sync_status === 'error' ? 'error' : 'unknown'}`)})
                      </span>
                    )}
                  </div>
                )}
              </div>
            </div>

            {/* View Toggle */}
            <div className="flex items-center gap-3">
              {hasActiveFilters && (
                <button
                  onClick={resetAllFilters}
                  className="flex items-center gap-2 px-4 py-2 rounded-lg border border-red-200 dark:border-red-800 bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-900/30 transition-colors"
                >
                  <X size={18} />
                  <span className="font-medium">{t('inactiveManagement.removeFilters')}</span>
                </button>
              )}

              <button
                onClick={() => setShowFilters(!showFilters)}
                className={`flex items-center gap-2 px-4 py-2 rounded-lg border transition-colors ${
                  showFilters
                    ? 'bg-primary-50 dark:bg-primary-900/30 border-primary-200 dark:border-primary-800 text-primary-700 dark:text-primary-400'
                    : 'bg-white dark:bg-slate-800 border-gray-300 dark:border-slate-600 text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-slate-700'
                }`}
              >
                <Settings size={18} />
                <span className="font-medium">{t('inactiveManagement.modifyThreshold')}</span>
              </button>

              <button
                onClick={() => setGroupByCourse(!groupByCourse)}
                className="flex items-center gap-2 px-4 py-2 bg-white dark:bg-slate-800 border border-gray-300 dark:border-slate-600 rounded-lg text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors"
              >
                <BarChart3 size={18} />
                <span className="font-medium">
                  {groupByCourse ? t('inactiveManagement.viewFlat') : t('inactiveManagement.viewGrouped')}
                </span>
              </button>

              <button
                onClick={handleDownloadPDF}
                disabled={!data || isLoading}
                className="flex items-center gap-2 px-4 py-2 bg-white dark:bg-slate-800 border border-gray-300 dark:border-slate-600 rounded-lg text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <Download size={18} />
                <span className="font-medium">{t('inactiveManagement.downloadPdf')}</span>
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Saved Views */}
      <div className="bg-white dark:bg-slate-800 border-b border-gray-100 dark:border-slate-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-3">
          <SavedViewsBar page="inactive" onLoadView={applyView} getCurrentFilters={collectCurrentFilters} />
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Filters Panel */}
        {showFilters && (
          <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700 p-6 mb-6">
            <div className="flex items-center gap-2 mb-4">
              <Settings size={20} className="text-gray-600 dark:text-gray-400" />
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                {t('inactiveManagement.filters.title')}
              </h3>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  {t('inactiveManagement.filters.inactiveThreshold')}
                </label>
                <input
                  type="number"
                  value={filters.inactivityThreshold}
                  onChange={(e) => setFilters({ ...filters, inactivityThreshold: parseInt(e.target.value) })}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent dark:bg-slate-700 dark:text-white"
                  min="1"
                  max="365"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  {t('inactiveManagement.filters.excludeRecentDays')}
                </label>
                <input
                  type="number"
                  value={filters.excludeRecentDays}
                  onChange={(e) => setFilters({ ...filters, excludeRecentDays: parseInt(e.target.value) })}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent dark:bg-slate-700 dark:text-white"
                  min="0"
                  max="90"
                />
              </div>
            </div>

            <div className="mt-4 flex justify-end">
              <button
                onClick={() => refetch()}
                className="px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors font-medium"
              >
                {t('common.apply')}
              </button>
            </div>
          </div>
        )}

        {/* Sorting & Filters */}
        <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700 p-4 mb-6 space-y-4">
          {/* Search Bar */}
          <div className="relative">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 dark:text-gray-500" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder={t('inactiveManagement.searchPlaceholder')}
              className="w-full pl-9 pr-8 py-2 border border-gray-200 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm dark:bg-slate-700 dark:text-white dark:placeholder-gray-500"
            />
            {searchTerm && (
              <button
                onClick={() => setSearchTerm('')}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 dark:text-gray-500 hover:text-gray-600 dark:hover:text-gray-300"
              >
                <X size={14} />
              </button>
            )}
          </div>

          {/* Row 1: Sorting + Status Filter */}
          <div className="flex flex-col lg:flex-row gap-4">
            {/* Sorting - horizontal pills */}
            <div className="flex items-center gap-2 flex-wrap">
              <span className="text-sm font-semibold text-gray-600 dark:text-gray-400 flex items-center gap-1 mr-1">
                <ArrowUpDown size={14} />
                {t('inactiveManagement.sorting.title')}
              </span>
              {[
                { key: 'inactivity', label: t('inactiveManagement.sorting.byInactivity') },
                { key: 'name', label: t('inactiveManagement.sorting.byName') },
                { key: 'progression', label: t('inactiveManagement.sorting.byProgression') },
                { key: 'status', label: t('inactiveManagement.sorting.byStatus') },
                { key: 'intervention', label: t('inactiveManagement.sorting.byIntervention') },
                { key: 'date_add', label: t('inactiveManagement.sorting.byDateAdd') },
                ...(showLatestNotes ? [{ key: 'latest_note', label: t('inactiveManagement.noteFilters.sortByNote') }] : []),
              ].map(({ key, label }) => (
                <button
                  key={key}
                  onClick={() => toggleSort(key)}
                  className={`flex items-center gap-1 px-3 py-1.5 rounded-full border text-xs font-medium transition-colors ${
                    sortBy === key ? 'bg-primary-50 dark:bg-primary-900/30 border-primary-200 dark:border-primary-800 text-primary-700 dark:text-primary-400' : 'bg-white dark:bg-slate-800 border-gray-200 dark:border-slate-700 text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-slate-700'
                  }`}
                >
                  {label}
                  {sortBy === key && (
                    sortDirection === 'desc' ? <ArrowDown size={12} /> : <ArrowUp size={12} />
                  )}
                </button>
              ))}
            </div>

            {/* Divider */}
            <div className="hidden lg:block w-px bg-gray-200 dark:bg-slate-600" />

            {/* Status Filter - horizontal pills */}
            <div className="flex items-center gap-2 flex-wrap">
              <span className="text-sm font-semibold text-gray-600 dark:text-gray-400 flex items-center gap-1 mr-1">
                <Filter size={14} />
                {t('inactiveManagement.statusFilter.title')}
              </span>
              <label className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full border text-xs font-medium cursor-pointer transition-colors ${
                statusFilter.active ? 'bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-800 text-green-700 dark:text-green-400' : 'bg-white dark:bg-slate-800 border-gray-200 dark:border-slate-700 text-gray-400 dark:text-gray-500'
              }`}>
                <input type="checkbox" checked={statusFilter.active} onChange={() => toggleStatusFilter('active')} className="sr-only" />
                <CheckCircle2 size={12} />
                {t('inactiveManagement.status.active')}
              </label>
              <label className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full border text-xs font-medium cursor-pointer transition-colors ${
                statusFilter.inactive ? 'bg-red-50 dark:bg-red-900/20 border-red-200 dark:border-red-800 text-red-700 dark:text-red-400' : 'bg-white dark:bg-slate-800 border-gray-200 dark:border-slate-700 text-gray-400 dark:text-gray-500'
              }`}>
                <input type="checkbox" checked={statusFilter.inactive} onChange={() => toggleStatusFilter('inactive')} className="sr-only" />
                <UserX size={12} />
                {t('inactiveManagement.status.inactive')}
              </label>
              <label className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full border text-xs font-medium cursor-pointer transition-colors ${
                statusFilter.never_started ? 'bg-purple-50 dark:bg-purple-900/20 border-purple-200 dark:border-purple-800 text-purple-700 dark:text-purple-400' : 'bg-white dark:bg-slate-800 border-gray-200 dark:border-slate-700 text-gray-400 dark:text-gray-500'
              }`}>
                <input type="checkbox" checked={statusFilter.never_started} onChange={() => toggleStatusFilter('never_started')} className="sr-only" />
                <Clock size={12} />
                {t('inactiveManagement.status.neverStarted')}
              </label>
              <label className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full border text-xs font-medium cursor-pointer transition-colors ${
                statusFilter.snoozed ? 'bg-amber-50 dark:bg-amber-900/20 border-amber-200 dark:border-amber-800 text-amber-700 dark:text-amber-400' : 'bg-white dark:bg-slate-800 border-gray-200 dark:border-slate-700 text-gray-400 dark:text-gray-500'
              }`}>
                <input type="checkbox" checked={statusFilter.snoozed} onChange={() => toggleStatusFilter('snoozed')} className="sr-only" />
                <AlarmClock size={12} />
                {t('inactiveManagement.status.snoozed')}
              </label>
              <label className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full border text-xs font-medium cursor-pointer transition-colors ${
                statusFilter.dismissed ? 'bg-gray-100 dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-600 dark:text-gray-400' : 'bg-white dark:bg-slate-800 border-gray-200 dark:border-slate-700 text-gray-400 dark:text-gray-500'
              }`}>
                <input type="checkbox" checked={statusFilter.dismissed} onChange={() => toggleStatusFilter('dismissed')} className="sr-only" />
                <Ban size={12} />
                {t('inactiveManagement.status.dismissed')}
              </label>

              {/* Select / Deselect all */}
              <button
                onClick={() => {
                  const allOn = statusFilter.active && statusFilter.inactive && statusFilter.never_started && statusFilter.snoozed && statusFilter.dismissed;
                  setStatusFilter(allOn
                    ? { active: false, inactive: false, never_started: false, snoozed: false, dismissed: false }
                    : { active: true, inactive: true, never_started: true, snoozed: true, dismissed: true }
                  );
                }}
                className="px-2.5 py-1.5 rounded-full border border-gray-200 dark:border-slate-700 text-xs font-medium text-gray-500 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors"
              >
                {statusFilter.active && statusFilter.inactive && statusFilter.never_started && statusFilter.snoozed && statusFilter.dismissed
                  ? t('inactiveManagement.statusFilter.deselectAll')
                  : t('inactiveManagement.statusFilter.selectAll')
                }
              </button>
            </div>

          </div>

          {/* Row: Toggles (CV planifié + Note filters) */}
          <div className="flex items-center gap-2 flex-wrap border-t border-gray-100 dark:border-slate-700 pt-4">
            {/* CV planifié = Actif toggle */}
            <label className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full border text-xs font-medium cursor-pointer transition-colors ${
              cvPlannedIsActive ? 'bg-teal-50 dark:bg-teal-900/20 border-teal-200 dark:border-teal-800 text-teal-700 dark:text-teal-400' : 'bg-white dark:bg-slate-800 border-gray-200 dark:border-slate-700 text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-slate-700'
            }`}>
              <input type="checkbox" checked={cvPlannedIsActive} onChange={() => setCvPlannedIsActive(!cvPlannedIsActive)} className="sr-only" />
              <CalendarClock size={12} />
              CV planifié = Actif
            </label>

            {/* Note filters (only when showLatestNotes is enabled) */}
            {showLatestNotes && (
              <>
                <div className="w-px h-5 bg-gray-200 dark:bg-slate-600 mx-1" />
                <span className="text-sm font-semibold text-gray-600 dark:text-gray-400 flex items-center gap-1 mr-1">
                  <MessageSquare size={14} />
                  {t('inactiveManagement.latestNote')}
                </span>
                <button
                  onClick={() => { setNoteFilterWithNote(v => !v); setNoteFilterWithoutNote(false); }}
                  className={`flex items-center gap-1 px-3 py-1.5 rounded-full border text-xs font-medium transition-colors ${
                    noteFilterWithNote
                      ? 'bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-800 text-green-700 dark:text-green-400'
                      : 'bg-white dark:bg-slate-800 border-gray-200 dark:border-slate-700 text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-slate-700'
                  }`}
                >
                  {t('inactiveManagement.noteFilters.withNote')}
                </button>
                <button
                  onClick={() => { setNoteFilterWithoutNote(v => !v); setNoteFilterWithNote(false); setNoteFilterOlderThan(false); }}
                  className={`flex items-center gap-1 px-3 py-1.5 rounded-full border text-xs font-medium transition-colors ${
                    noteFilterWithoutNote
                      ? 'bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-800 text-green-700 dark:text-green-400'
                      : 'bg-white dark:bg-slate-800 border-gray-200 dark:border-slate-700 text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-slate-700'
                  }`}
                >
                  {t('inactiveManagement.noteFilters.withoutNote')}
                </button>
                <button
                  onClick={() => { setNoteFilterOlderThan(v => !v); setNoteFilterWithoutNote(false); }}
                  className={`flex items-center gap-1 px-3 py-1.5 rounded-full border text-xs font-medium transition-colors ${
                    noteFilterOlderThan
                      ? 'bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-800 text-green-700 dark:text-green-400'
                      : 'bg-white dark:bg-slate-800 border-gray-200 dark:border-slate-700 text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-slate-700'
                  }`}
                >
                  {t('inactiveManagement.noteFilters.noteOlderThan', { days: noteOlderThanDays })}
                </button>
                {noteFilterOlderThan && (
                  <input
                    type="number"
                    value={noteOlderThanInput}
                    onChange={(e) => setNoteOlderThanInput(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') {
                        const val = Math.max(1, Math.min(365, parseInt(noteOlderThanInput) || 1));
                        setNoteOlderThanDays(val);
                        setNoteOlderThanInput(String(val));
                        e.target.blur();
                      }
                    }}
                    onBlur={() => {
                      const val = Math.max(1, Math.min(365, parseInt(noteOlderThanInput) || 1));
                      setNoteOlderThanDays(val);
                      setNoteOlderThanInput(String(val));
                    }}
                    className="w-16 px-2 py-1.5 border border-gray-200 dark:border-slate-600 rounded-lg text-xs dark:bg-slate-700 dark:text-white focus:outline-none focus:ring-2 focus:ring-green-500"
                    min="1"
                    max="365"
                  />
                )}
              </>
            )}
          </div>

          {/* Row 2: ADF + Formateur + Category Filters side by side */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 border-t border-gray-100 dark:border-slate-700 pt-4">
            {/* ADF Filter */}
            <div>
              <button
                onClick={() => setShowAdfDropdown(!showAdfDropdown)}
                className="w-full flex items-center justify-between px-3 py-2 rounded-lg border border-gray-200 dark:border-slate-700 hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors"
              >
                <div className="flex items-center gap-2">
                  <BookOpen size={16} className="text-gray-600 dark:text-gray-400" />
                  <span className="text-sm font-medium text-gray-900 dark:text-white">Filtrer par formation (ADF)</span>
                  {selectedADFs.length > 0 && (
                    <span className="px-2 py-0.5 bg-primary-100 dark:bg-primary-900/30 text-primary-700 dark:text-primary-400 text-xs font-medium rounded-full">
                      {selectedADFs.length}
                    </span>
                  )}
                </div>
                {showAdfDropdown ? <ChevronDown size={16} className="text-gray-400 dark:text-gray-300" /> : <ChevronRight size={16} className="text-gray-400 dark:text-gray-300" />}
              </button>

              {showAdfDropdown && data && (() => {
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
                      placeholder="Rechercher une formation..."
                      className="w-full px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm dark:bg-slate-700 dark:text-white dark:placeholder-gray-500"
                    />
                    {selectedButHiddenADFs.length > 0 && (
                      <div className="space-y-1 border border-primary-200 dark:border-primary-800 bg-primary-50/50 dark:bg-primary-900/20 rounded-lg p-2">
                        <p className="text-[10px] font-medium text-primary-600 uppercase tracking-wide px-2">Sélectionnées</p>
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
                        <p className="text-sm text-gray-500 dark:text-gray-400 text-center py-2">Aucune formation trouvée</p>
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
                              {filteredADFs.length > 0 && filteredADFs.every(adf => selectedADFs.includes(adf.id)) ? 'Tout désélectionner' : 'Tout sélectionner'}
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
                        {selectedADFs.length} formation{selectedADFs.length > 1 ? 's' : ''} sélectionnée{selectedADFs.length > 1 ? 's' : ''}
                      </p>
                    )}
                  </div>
                );
              })()}
            </div>

            {/* Formateur Filter */}
            <div>
              <button
                onClick={() => setShowFormateurDropdown(!showFormateurDropdown)}
                className="w-full flex items-center justify-between px-3 py-2 rounded-lg border border-gray-200 dark:border-slate-700 hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors"
              >
                <div className="flex items-center gap-2">
                  <User size={16} className="text-gray-600 dark:text-gray-400" />
                  <span className="text-sm font-medium text-gray-900 dark:text-white">Filtrer par formateur</span>
                  {selectedFormateurs.length > 0 && (
                    <span className="px-2 py-0.5 bg-primary-100 dark:bg-primary-900/30 text-primary-700 dark:text-primary-400 text-xs font-medium rounded-full">
                      {selectedFormateurs.length}
                    </span>
                  )}
                </div>
                {showFormateurDropdown ? <ChevronDown size={16} className="text-gray-400 dark:text-gray-300" /> : <ChevronRight size={16} className="text-gray-400 dark:text-gray-300" />}
              </button>

              {showFormateurDropdown && data && (() => {
                const filteredFormateurs = formateurList.filter(formateur =>
                  formateur.fullName.toLowerCase().includes(formateurSearchTerm.toLowerCase())
                );

                const selectedButHiddenFormateurs = formateurSearchTerm
                  ? formateurList.filter(f => selectedFormateurs.includes(f.id) && !f.fullName.toLowerCase().includes(formateurSearchTerm.toLowerCase()))
                  : [];

                return (
                  <div className="mt-2 space-y-2">
                    <input
                      type="text"
                      value={formateurSearchTerm}
                      onChange={(e) => setFormateurSearchTerm(e.target.value)}
                      placeholder="Rechercher un formateur..."
                      className="w-full px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm dark:bg-slate-700 dark:text-white dark:placeholder-gray-500"
                    />
                    {selectedButHiddenFormateurs.length > 0 && (
                      <div className="space-y-1 border border-primary-200 dark:border-primary-800 bg-primary-50/50 dark:bg-primary-900/20 rounded-lg p-2">
                        <p className="text-[10px] font-medium text-primary-600 uppercase tracking-wide px-2">Sélectionnés</p>
                        {selectedButHiddenFormateurs.map((formateur) => (
                          <label key={formateur.id} className="flex items-start gap-2 px-2 py-1.5 rounded hover:bg-primary-100/50 cursor-pointer transition-colors">
                            <input
                              type="checkbox"
                              checked={true}
                              onChange={() => setSelectedFormateurs(selectedFormateurs.filter(id => id !== formateur.id))}
                              className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500 mt-0.5"
                            />
                            <span className="text-xs text-primary-700 leading-tight">{formateur.fullName || 'Formateur sans nom'}</span>
                          </label>
                        ))}
                      </div>
                    )}
                    <div className="max-h-48 overflow-y-auto space-y-1 border border-gray-200 dark:border-slate-700 rounded-lg p-2">
                      {filteredFormateurs.length === 0 ? (
                        <p className="text-sm text-gray-500 dark:text-gray-400 text-center py-2">Aucun formateur trouvé</p>
                      ) : (
                        <>
                          <label className="flex items-center gap-2 px-2 py-1.5 rounded hover:bg-gray-50 dark:hover:bg-slate-700 cursor-pointer transition-colors border-b border-gray-200 dark:border-slate-700">
                            <input
                              type="checkbox"
                              checked={filteredFormateurs.length > 0 && filteredFormateurs.every(f => selectedFormateurs.includes(f.id))}
                              onChange={(e) => {
                                if (e.target.checked) {
                                  setSelectedFormateurs(prev => [...new Set([...prev, ...filteredFormateurs.map(f => f.id)])]);
                                } else {
                                  const filteredIds = new Set(filteredFormateurs.map(f => f.id));
                                  setSelectedFormateurs(prev => prev.filter(id => !filteredIds.has(id)));
                                }
                              }}
                              className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500"
                            />
                            <span className="text-xs font-semibold text-gray-700 dark:text-gray-300">
                              {filteredFormateurs.length > 0 && filteredFormateurs.every(f => selectedFormateurs.includes(f.id)) ? 'Tout désélectionner' : 'Tout sélectionner'}
                            </span>
                          </label>
                          {filteredFormateurs.map((formateur) => (
                            <label key={formateur.id} className="flex items-start gap-2 px-2 py-1.5 rounded hover:bg-gray-50 dark:hover:bg-slate-700 cursor-pointer transition-colors">
                              <input
                                type="checkbox"
                                checked={selectedFormateurs.includes(formateur.id)}
                                onChange={(e) => {
                                  if (e.target.checked) {
                                    setSelectedFormateurs([...selectedFormateurs, formateur.id]);
                                  } else {
                                    setSelectedFormateurs(selectedFormateurs.filter(id => id !== formateur.id));
                                  }
                                }}
                                className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500 mt-0.5"
                              />
                              <span className="text-xs text-gray-700 dark:text-gray-300 leading-tight">{formateur.fullName || 'Formateur sans nom'}</span>
                            </label>
                          ))}
                        </>
                      )}
                    </div>
                    {selectedFormateurs.length > 0 && (
                      <p className="text-xs text-gray-500 dark:text-gray-400">
                        {selectedFormateurs.length} formateur{selectedFormateurs.length > 1 ? 's' : ''} sélectionné{selectedFormateurs.length > 1 ? 's' : ''}
                      </p>
                    )}
                  </div>
                );
              })()}
            </div>

            {/* Category Filter */}
            <div>
              <button
                onClick={() => setShowCategoryDropdown(!showCategoryDropdown)}
                className="w-full flex items-center justify-between px-3 py-2 rounded-lg border border-gray-200 dark:border-slate-700 hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors"
              >
                <div className="flex items-center gap-2">
                  <Filter size={16} className="text-gray-600 dark:text-gray-400" />
                  <span className="text-sm font-medium text-gray-900 dark:text-white">{t('inactiveManagement.categoryFilter.title')}</span>
                  {selectedCategories.length > 0 && (
                    <span className="px-2 py-0.5 bg-primary-100 dark:bg-primary-900/30 text-primary-700 dark:text-primary-400 text-xs font-medium rounded-full">
                      {selectedCategories.length}
                    </span>
                  )}
                </div>
                {showCategoryDropdown ? <ChevronDown size={16} className="text-gray-400 dark:text-gray-300" /> : <ChevronRight size={16} className="text-gray-400 dark:text-gray-300" />}
              </button>

              {showCategoryDropdown && data && (() => {
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
                      placeholder={t('inactiveManagement.categoryFilter.searchPlaceholder')}
                      className="w-full px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm dark:bg-slate-700 dark:text-white dark:placeholder-gray-500"
                    />
                    {selectedButHiddenCategories.length > 0 && (
                      <div className="space-y-1 border border-primary-200 dark:border-primary-800 bg-primary-50/50 dark:bg-primary-900/20 rounded-lg p-2">
                        <p className="text-[10px] font-medium text-primary-600 uppercase tracking-wide px-2">Sélectionnées</p>
                        {selectedButHiddenCategories.map((cat) => (
                          <label key={cat.name} className="flex items-start gap-2 px-2 py-1.5 rounded hover:bg-primary-100/50 cursor-pointer transition-colors">
                            <input
                              type="checkbox"
                              checked={true}
                              onChange={() => setSelectedCategories(selectedCategories.filter(name => name !== cat.name))}
                              className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500 mt-0.5"
                            />
                            <span className="text-xs text-primary-700 leading-tight flex items-center gap-1.5">
                              {cat.color && (
                                <span
                                  className="inline-block w-2.5 h-2.5 rounded-full flex-shrink-0"
                                  style={{ backgroundColor: `#${cat.color}` }}
                                />
                              )}
                              {cat.name}
                            </span>
                          </label>
                        ))}
                      </div>
                    )}
                    <div className="max-h-48 overflow-y-auto space-y-1 border border-gray-200 dark:border-slate-700 rounded-lg p-2">
                      {filteredCategories.length === 0 ? (
                        <p className="text-sm text-gray-500 dark:text-gray-400 text-center py-2">{t('inactiveManagement.categoryFilter.noResults')}</p>
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
                                  setSelectedCategories(prev => prev.filter(name => !filteredNames.has(name)));
                                }
                              }}
                              className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500"
                            />
                            <span className="text-xs font-semibold text-gray-700 dark:text-gray-300">
                              {filteredCategories.length > 0 && filteredCategories.every(cat => selectedCategories.includes(cat.name)) ? t('inactiveManagement.categoryFilter.deselectAll') : t('inactiveManagement.categoryFilter.selectAll')}
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
                                    setSelectedCategories(selectedCategories.filter(name => name !== cat.name));
                                  }
                                }}
                                className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500 mt-0.5"
                              />
                              <span className="text-xs text-gray-700 dark:text-gray-300 leading-tight flex items-center gap-1.5">
                                {cat.color && (
                                  <span
                                    className="inline-block w-2.5 h-2.5 rounded-full flex-shrink-0"
                                    style={{ backgroundColor: `#${cat.color}` }}
                                  />
                                )}
                                {cat.name}
                              </span>
                            </label>
                          ))}
                        </>
                      )}
                    </div>
                    {selectedCategories.length > 0 && (
                      <p className="text-xs text-gray-500 dark:text-gray-400">
                        {selectedCategories.length} {t('inactiveManagement.categoryFilter.selectedCount')}
                      </p>
                    )}
                  </div>
                );
              })()}
            </div>
          </div>
        </div>

        {/* Loading State */}
        {isLoading && (
          <div className="flex items-center justify-center py-12">
            <Loader2 className="w-8 h-8 animate-spin text-primary-600" />
          </div>
        )}

        {/* Error State */}
        {error && (
          <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4 mb-6">
            <p className="text-red-800 dark:text-red-400">
              {t('common.error')}: {error.message}
            </p>
          </div>
        )}

        {/* Statistics Cards */}
        {data && !isLoading && (
          <>
            <div className={showInterventionCounters ? "grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4 mb-6" : "grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-3 gap-4 mb-6"}>
              <div className="bg-white dark:bg-slate-800 rounded-lg border border-green-200 dark:border-green-800 p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-green-700 dark:text-green-400">{t('inactiveManagement.stats.active')}</p>
                    <p className="text-3xl font-bold text-green-900 dark:text-green-100 mt-2">{filteredStats.active}</p>
                  </div>
                  <div className="p-3 bg-green-100 dark:bg-green-900/30 rounded-lg">
                    <CheckCircle2 size={24} className="text-green-600 dark:text-green-400" />
                  </div>
                </div>
              </div>

              <div className="bg-white dark:bg-slate-800 rounded-lg border border-red-200 dark:border-red-800 p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-red-700 dark:text-red-400">{t('inactiveManagement.stats.inactive')}</p>
                    <p className="text-3xl font-bold text-red-900 dark:text-red-100 mt-2">{filteredStats.inactive}</p>
                  </div>
                  <div className="p-3 bg-red-100 dark:bg-red-900/30 rounded-lg">
                    <UserX size={24} className="text-red-600 dark:text-red-400" />
                  </div>
                </div>
              </div>

              <div className="bg-white dark:bg-slate-800 rounded-lg border border-purple-200 dark:border-purple-800 p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-purple-700 dark:text-purple-400">{t('inactiveManagement.stats.neverStarted')}</p>
                    <p className="text-3xl font-bold text-purple-900 dark:text-purple-100 mt-2">{filteredStats.never_started}</p>
                  </div>
                  <div className="p-3 bg-purple-100 dark:bg-purple-900/30 rounded-lg">
                    <Clock size={24} className="text-purple-600 dark:text-purple-400" />
                  </div>
                </div>
              </div>

              {showInterventionCounters && (
                <>
                  <div className="bg-white dark:bg-slate-800 rounded-lg border border-amber-200 dark:border-amber-800 p-6">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="text-sm text-amber-700 dark:text-amber-400">{t('inactiveManagement.stats.snoozed')}</p>
                        <p className="text-3xl font-bold text-amber-900 dark:text-amber-100 mt-2">{filteredStats.snoozed}</p>
                      </div>
                      <div className="p-3 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                        <AlarmClock size={24} className="text-amber-600 dark:text-amber-400" />
                      </div>
                    </div>
                  </div>

                  <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-300 dark:border-slate-600 p-6">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="text-sm text-gray-600 dark:text-gray-400">{t('inactiveManagement.stats.dismissed')}</p>
                        <p className="text-3xl font-bold text-gray-900 dark:text-white mt-2">{filteredStats.dismissed}</p>
                      </div>
                      <div className="p-3 bg-gray-100 dark:bg-slate-700 rounded-lg">
                        <Ban size={24} className="text-gray-500 dark:text-gray-400" />
                      </div>
                    </div>
                  </div>
                </>
              )}

            </div>

            {/* Page Size Selector + Progression Range + Count */}
            <div className="flex items-center gap-6 mb-4 flex-wrap">
              {/* Per page */}
              <div className="flex items-center gap-2">
                <span className="text-sm text-gray-600 dark:text-gray-400">{t('pagination.show')}</span>
                {PAGE_SIZE_OPTIONS.map((size) => (
                  <button
                    key={size}
                    onClick={() => setPageSize(size)}
                    className={`px-3 py-1 rounded-full border text-xs font-medium transition-colors ${
                      pageSize === size
                        ? 'bg-primary-50 dark:bg-primary-900/30 border-primary-200 dark:border-primary-800 text-primary-700 dark:text-primary-400'
                        : 'bg-white dark:bg-slate-800 border-gray-200 dark:border-slate-700 text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-slate-700'
                    }`}
                  >
                    {size === 0 ? t('common.all') : size}
                  </button>
                ))}
                <span className="text-sm text-gray-600 dark:text-gray-400">{t('pagination.perPage')}</span>
              </div>

              {/* Divider */}
              <div className="w-px h-6 bg-gray-200 dark:bg-slate-600" />

              {/* Progression Range Slider */}
              <div className="flex items-center gap-3">
                <span className="text-sm font-medium text-gray-600 dark:text-gray-400 flex items-center gap-1 whitespace-nowrap">
                  <BarChart3 size={14} />
                  Progression
                </span>
                <span className="text-xs font-medium text-gray-500 dark:text-gray-400 w-10 text-right">{progressionRange[0]}%</span>
                <div className="relative w-40 h-5 flex items-center">
                  {/* Track background */}
                  <div className="absolute inset-x-0 h-1.5 bg-gray-200 dark:bg-slate-600 rounded-full" />
                  {/* Active range highlight */}
                  <div
                    className="absolute h-1.5 bg-primary-400 rounded-full"
                    style={{
                      left: `${progressionRange[0]}%`,
                      right: `${100 - progressionRange[1]}%`,
                    }}
                  />
                  {/* Min handle */}
                  <input
                    type="range"
                    min={0}
                    max={100}
                    value={progressionRange[0]}
                    onChange={(e) => {
                      const val = Math.min(Number(e.target.value), progressionRange[1]);
                      setProgressionRange([val, progressionRange[1]]);
                    }}
                    className="absolute inset-0 w-full appearance-none bg-transparent pointer-events-none [&::-webkit-slider-thumb]:pointer-events-auto [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-4 [&::-webkit-slider-thumb]:h-4 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-white [&::-webkit-slider-thumb]:border-2 [&::-webkit-slider-thumb]:border-primary-500 [&::-webkit-slider-thumb]:shadow-sm [&::-webkit-slider-thumb]:cursor-pointer [&::-webkit-slider-thumb]:hover:border-primary-600 [&::-webkit-slider-thumb]:hover:shadow-md [&::-moz-range-thumb]:pointer-events-auto [&::-moz-range-thumb]:appearance-none [&::-moz-range-thumb]:w-4 [&::-moz-range-thumb]:h-4 [&::-moz-range-thumb]:rounded-full [&::-moz-range-thumb]:bg-white [&::-moz-range-thumb]:border-2 [&::-moz-range-thumb]:border-primary-500 [&::-moz-range-thumb]:shadow-sm [&::-moz-range-thumb]:cursor-pointer"
                    style={{ zIndex: progressionRange[0] > 50 ? 2 : 1 }}
                  />
                  {/* Max handle */}
                  <input
                    type="range"
                    min={0}
                    max={100}
                    value={progressionRange[1]}
                    onChange={(e) => {
                      const val = Math.max(Number(e.target.value), progressionRange[0]);
                      setProgressionRange([progressionRange[0], val]);
                    }}
                    className="absolute inset-0 w-full appearance-none bg-transparent pointer-events-none [&::-webkit-slider-thumb]:pointer-events-auto [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-4 [&::-webkit-slider-thumb]:h-4 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-white [&::-webkit-slider-thumb]:border-2 [&::-webkit-slider-thumb]:border-primary-500 [&::-webkit-slider-thumb]:shadow-sm [&::-webkit-slider-thumb]:cursor-pointer [&::-webkit-slider-thumb]:hover:border-primary-600 [&::-webkit-slider-thumb]:hover:shadow-md [&::-moz-range-thumb]:pointer-events-auto [&::-moz-range-thumb]:appearance-none [&::-moz-range-thumb]:w-4 [&::-moz-range-thumb]:h-4 [&::-moz-range-thumb]:rounded-full [&::-moz-range-thumb]:bg-white [&::-moz-range-thumb]:border-2 [&::-moz-range-thumb]:border-primary-500 [&::-moz-range-thumb]:shadow-sm [&::-moz-range-thumb]:cursor-pointer"
                    style={{ zIndex: 2 }}
                  />
                </div>
                <span className="text-xs font-medium text-gray-500 dark:text-gray-400 w-10">{progressionRange[1]}%</span>
                {(progressionRange[0] > 0 || progressionRange[1] < 100) && (
                  <button
                    onClick={() => setProgressionRange([0, 100])}
                    className="text-gray-400 dark:text-gray-500 hover:text-gray-600 dark:hover:text-gray-300 transition-colors"
                    title="Reset"
                  >
                    <X size={14} />
                  </button>
                )}
              </div>

              {/* Divider */}
              <div className="w-px h-6 bg-gray-200 dark:bg-slate-600" />

              {/* Result count */}
              <span className="text-sm text-gray-500 dark:text-gray-400">
                Nb de résultats: {totalItems}
              </span>
            </div>

            {/* Grouped by Course View */}
            {groupByCourse && data.by_course && (
              <div className="space-y-4">
                {paginatedGroups.map((course) => (
                    <div key={course.course_id} className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700">
                      {/* Course Header */}
                      <div className="px-6 py-4 flex items-center justify-between border-b border-gray-200 dark:border-slate-700">
                        <div className="flex items-center gap-4 flex-1">
                          <div className="p-2 bg-primary-100 dark:bg-primary-900/30 rounded-lg">
                            <BookOpen size={20} className="text-primary-600 dark:text-primary-400" />
                          </div>
                          <div className="text-left flex-1">
                            <Link
                              to={`/courses/${course.course_id}`}
                              className="font-semibold text-gray-900 dark:text-white hover:text-primary-600 dark:hover:text-primary-400 transition-colors"
                            >
                              {course.course_title}
                            </Link>
                            <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
                              {t('inactiveManagement.showing')}: {course.filteredParticipants.length} / {course.total_participants}
                            </p>
                          </div>
                          <div className="flex items-center gap-3">
                            <span className="px-3 py-1 bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-400 rounded-full text-sm font-medium">
                              {course.active_count} {t('inactiveManagement.status.active')}
                            </span>
                            <span className="px-3 py-1 bg-red-100 dark:bg-red-900/30 text-red-800 dark:text-red-400 rounded-full text-sm font-medium">
                              {course.inactive_count} {t('inactiveManagement.status.inactive')}
                            </span>
                            {course.never_started_count > 0 && (
                              <span className="px-3 py-1 bg-purple-100 dark:bg-purple-900/30 text-purple-800 dark:text-purple-400 rounded-full text-sm font-medium">
                                {course.never_started_count} {t('inactiveManagement.status.neverStarted')}
                              </span>
                            )}
                          </div>
                        </div>
                        <button
                          onClick={() => toggleCourse(course.course_id)}
                          className="ml-4 p-1 hover:bg-gray-100 dark:hover:bg-slate-700 rounded transition-colors"
                        >
                          {expandedCourses.has(course.course_id) ? (
                            <ChevronDown size={20} className="text-gray-400 dark:text-gray-500" />
                          ) : (
                            <ChevronRight size={20} className="text-gray-400 dark:text-gray-500" />
                          )}
                        </button>
                      </div>

                      {/* Participants List */}
                      {expandedCourses.has(course.course_id) && (
                        <div className="divide-y divide-gray-200 dark:divide-slate-700">
                          {course.filteredParticipants.map((participant) => {
                            const pKey = `${participant.id}-${participant.id_action_formation}`;
                            return (
                            <div key={participant.id} className={`transition-colors ${
                              participant.is_dismissed ? 'opacity-40 bg-gray-50 dark:bg-slate-900' :
                              participant.has_active_snooze ? 'opacity-60 bg-amber-50/30 dark:bg-amber-900/10' :
                              'hover:bg-gray-50 dark:hover:bg-slate-700'
                            }`}>
                              <div className="px-6 py-4">
                              <div className="flex items-center justify-between">
                                <div className="flex items-center gap-4 flex-1">
                                  <div className={`px-3 py-1 rounded-full text-xs font-medium border flex items-center gap-1 ${getStatusColor(getDisplayStatus(participant))}`}>
                                    {getStatusIcon(getDisplayStatus(participant))}
                                    <span>{getStatusLabel(getDisplayStatus(participant))}</span>
                                    {participant.has_active_snooze && participant.snooze_until && (
                                      <span className="ml-0.5">{new Date(participant.snooze_until).toLocaleDateString('fr-FR')}</span>
                                    )}
                                  </div>
                                  <div className="flex-1">
                                    <div className="flex items-center gap-2">
                                      <Link
                                        to={`/participants/${participant.id}`}
                                        className="font-medium text-gray-900 dark:text-white hover:text-primary-600 dark:hover:text-primary-400 transition-colors"
                                      >
                                        {participant.nom} {participant.prenom}
                                      </Link>
                                      <span className="text-sm text-gray-500 dark:text-gray-400">
                                        ({(participant.current_progression || participant.overall_progression || 0).toFixed(1)}%)
                                      </span>
                                    </div>
                                    <div className="flex items-center gap-4 mt-1 text-sm text-gray-600 dark:text-gray-400">
                                      <span className="flex items-center gap-1">
                                        <Calendar size={14} />
                                        Ajouté: {formatDate(participant.enrollment_date)}
                                      </span>
                                      <span
                                        className="group/source flex items-center gap-1"
                                        title={participant.last_activity_source ? `${t('inactiveManagement.lastActivitySource')}: ${t(`inactiveManagement.activitySource.${participant.last_activity_source}`)}` : ''}
                                      >
                                        <Clock size={14} />
                                        {participant.days_inactive || 0} {t('common.daysInactive')}
                                        {participant.last_activity_source && (
                                          <span className={`opacity-0 group-hover/source:opacity-100 transition-opacity inline-flex items-center ml-1 px-1.5 py-0.5 rounded text-[10px] font-medium ${
                                            participant.last_activity_source === 'elearning'
                                              ? 'bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400'
                                              : 'bg-violet-50 dark:bg-violet-900/20 text-violet-600 dark:text-violet-400'
                                          }`}>
                                            {t(`inactiveManagement.activitySource.${participant.last_activity_source}`)}
                                          </span>
                                        )}
                                      </span>
                                      {participant.upcoming_sessions_count > 0 && participant.next_session_date ? (
                                        <span
                                          className="flex items-center gap-1 text-xs bg-teal-50 dark:bg-teal-900/20 text-teal-700 dark:text-teal-400 px-2 py-0.5 rounded-full cursor-default"
                                          title={`${new Date(participant.next_session_date).toLocaleDateString()}\n${participant.upcoming_sessions_count} session${participant.upcoming_sessions_count > 1 ? 's' : ''} à venir`}
                                        >
                                          <CalendarClock size={12} />
                                          CV dans {Math.max(0, Math.ceil((new Date(participant.next_session_date) - new Date()) / (1000 * 60 * 60 * 24)))}j
                                        </span>
                                      ) : (
                                        <span className="flex items-center gap-1 text-xs bg-gray-50 dark:bg-slate-700 text-gray-400 dark:text-gray-500 px-2 py-0.5 rounded-full cursor-default">
                                          <CalendarClock size={12} />
                                          pas de CV
                                        </span>
                                      )}
                                      {participant.total_planned_duration_hours > 0 && (
                                        <span
                                          className="flex items-center gap-1 text-xs bg-blue-50 dark:bg-blue-900/20 text-blue-700 dark:text-blue-400 px-2 py-0.5 rounded-full cursor-default"
                                          title={participant.liveroom_planned_duration_hours > 0
                                            ? `E-learning: ${formatHoursMinutes((participant.total_time_spent_hours - (participant.liveroom_time_spent_hours || 0)) * 3600)} / ${formatHoursMinutes((participant.total_planned_duration_hours - (participant.liveroom_planned_duration_hours || 0)) * 3600)}\nClasse virtuelle: ${formatHoursMinutes((participant.liveroom_time_spent_hours || 0) * 3600)} / ${formatHoursMinutes((participant.liveroom_planned_duration_hours || 0) * 3600)}`
                                            : ''}
                                        >
                                          <Clock size={12} />
                                          {formatTimeSpentInHours((participant.total_time_spent_hours || 0) * 3600)} / {formatTimeSpentInHours((participant.total_planned_duration_hours || 0) * 3600)}
                                        </span>
                                      )}
                                      {participant.formateurs && participant.formateurs.length > 0 && (
                                        <span
                                          className="flex items-center gap-1 text-xs bg-purple-50 dark:bg-purple-900/20 text-purple-700 dark:text-purple-400 px-2 py-0.5 rounded-full cursor-default"
                                          title={participant.formateurs.map(f => `${f.prenom || ''} ${f.nom || ''}`.trim()).join(', ')}
                                        >
                                          <User size={12} />
                                          {participant.formateurs.length} formateur{participant.formateurs.length > 1 ? 's' : ''}
                                        </span>
                                      )}
                                      {participant.category_name && (
                                        <span
                                          className="flex items-center gap-1 text-xs px-2 py-0.5 rounded-full cursor-default"
                                          style={{
                                            backgroundColor: participant.category_color ? `#${participant.category_color}20` : '#f3f4f6',
                                            color: participant.category_color ? `#${participant.category_color}` : '#6b7280'
                                          }}
                                        >
                                          {participant.category_color && (
                                            <span
                                              className="inline-block w-2 h-2 rounded-full flex-shrink-0"
                                              style={{ backgroundColor: `#${participant.category_color}` }}
                                            />
                                          )}
                                          {participant.category_name}
                                        </span>
                                      )}
                                      {showLatestNotes && participant.latest_note_date && (
                                        <span className="flex items-center gap-1 text-xs bg-green-50 dark:bg-green-900/20 text-green-700 dark:text-green-400 px-2 py-0.5 rounded-full cursor-default">
                                          <MessageSquare size={12} />
                                          {t('inactiveManagement.latestNote')}: {new Date(participant.latest_note_date).toLocaleDateString('fr-FR')}
                                        </span>
                                      )}
                                      {showLatestNotes && !participant.latest_note_date && (
                                        <span className="flex items-center gap-1 text-xs bg-gray-50 dark:bg-slate-700 text-gray-400 dark:text-gray-500 px-2 py-0.5 rounded-full cursor-default">
                                          <MessageSquare size={12} />
                                          {t('inactiveManagement.noNote')}
                                        </span>
                                      )}
                                    </div>
                                  </div>
                                </div>
                                {/* Expand button for intervention panel */}
                                <button
                                  onClick={() => toggleParticipantExpand(pKey)}
                                  className="ml-2 p-1 hover:bg-gray-200 dark:hover:bg-slate-600 rounded transition-colors"
                                  title={t('inactiveManagement.interventions.title')}
                                >
                                  {expandedParticipants.has(pKey)
                                    ? <ChevronDown size={16} className="text-gray-400 dark:text-gray-500" />
                                    : <ChevronRight size={16} className="text-gray-400 dark:text-gray-500" />
                                  }
                                </button>
                              </div>
                              </div>
                              {/* Intervention Panel */}
                              {expandedParticipants.has(pKey) && (
                                <InterventionPanel participant={participant} />
                              )}
                            </div>
                            );
                          })}
                        </div>
                      )}
                    </div>
                ))}
              </div>
            )}

            {/* Flat List View */}
            {!groupByCourse && data.participants && (
              <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700">
                <div className="divide-y divide-gray-200 dark:divide-slate-700">
                  {paginatedFlat.map((participant) => {
                    const pKey = `${participant.id}-${participant.id_action_formation}`;
                    return (
                    <div key={`${participant.id}-${participant.course_id}`} className={`transition-colors ${
                      participant.is_dismissed ? 'opacity-40 bg-gray-50 dark:bg-slate-900' :
                      participant.has_active_snooze ? 'opacity-60 bg-amber-50/30 dark:bg-amber-900/10' :
                      'hover:bg-gray-50 dark:hover:bg-slate-700'
                    }`}>
                      <div className="px-6 py-4">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-4 flex-1">
                          <div className={`px-3 py-1 rounded-full text-xs font-medium border flex items-center gap-1 ${getStatusColor(getDisplayStatus(participant))}`}>
                            {getStatusIcon(getDisplayStatus(participant))}
                            <span>{getStatusLabel(getDisplayStatus(participant))}</span>
                            {participant.has_active_snooze && participant.snooze_until && (
                              <span className="ml-0.5">{new Date(participant.snooze_until).toLocaleDateString('fr-FR')}</span>
                            )}
                          </div>
                          <div className="flex-1">
                            <div className="flex items-center gap-2">
                              <Link
                                to={`/participants/${participant.id}`}
                                className="font-medium text-gray-900 dark:text-white hover:text-primary-600 dark:hover:text-primary-400 transition-colors"
                              >
                                {participant.nom} {participant.prenom}
                              </Link>
                              <span className="text-sm text-gray-500 dark:text-gray-400">•</span>
                              {participant.course_title && participant.course_id && (
                                <>
                                  <Link
                                    to={`/courses/${participant.course_id}`}
                                    className="text-sm text-gray-500 dark:text-gray-400 hover:text-primary-600 dark:hover:text-primary-400 transition-colors"
                                  >
                                    {participant.course_title}
                                  </Link>
                                  <span className="text-sm text-gray-500 dark:text-gray-400">•</span>
                                </>
                              )}
                              <span className="text-sm text-gray-500 dark:text-gray-400">
                                ({(participant.current_progression || participant.overall_progression || 0).toFixed(1)}%)
                              </span>
                            </div>
                            <div className="flex items-center gap-4 mt-1 text-sm text-gray-600 dark:text-gray-400">
                              <span className="flex items-center gap-1">
                                <Calendar size={14} />
                                Ajouté: {formatDate(participant.enrollment_date)}
                              </span>
                              <span
                                className="group/source flex items-center gap-1"
                                title={participant.last_activity_source ? `${t('inactiveManagement.lastActivitySource')}: ${t(`inactiveManagement.activitySource.${participant.last_activity_source}`)}` : ''}
                              >
                                <Clock size={14} />
                                {participant.days_inactive || 0} {t('common.daysInactive')}
                                {participant.last_activity_source && (
                                  <span className={`opacity-0 group-hover/source:opacity-100 transition-opacity inline-flex items-center ml-1 px-1.5 py-0.5 rounded text-[10px] font-medium ${
                                    participant.last_activity_source === 'elearning'
                                      ? 'bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400'
                                      : 'bg-violet-50 dark:bg-violet-900/20 text-violet-600 dark:text-violet-400'
                                  }`}>
                                    {t(`inactiveManagement.activitySource.${participant.last_activity_source}`)}
                                  </span>
                                )}
                              </span>
                              {participant.upcoming_sessions_count > 0 && participant.next_session_date ? (
                                <span
                                  className="flex items-center gap-1 text-xs bg-teal-50 dark:bg-teal-900/20 text-teal-700 dark:text-teal-400 px-2 py-0.5 rounded-full cursor-default"
                                  title={`${new Date(participant.next_session_date).toLocaleDateString()}\n${participant.upcoming_sessions_count} session${participant.upcoming_sessions_count > 1 ? 's' : ''} à venir`}
                                >
                                  <CalendarClock size={12} />
                                  CV dans {Math.max(0, Math.ceil((new Date(participant.next_session_date) - new Date()) / (1000 * 60 * 60 * 24)))}j
                                </span>
                              ) : (
                                <span className="flex items-center gap-1 text-xs bg-gray-50 dark:bg-slate-700 text-gray-400 dark:text-gray-500 px-2 py-0.5 rounded-full cursor-default">
                                  <CalendarClock size={12} />
                                  pas de CV
                                </span>
                              )}
                              {participant.total_planned_duration_hours > 0 && (
                                <span
                                  className="flex items-center gap-1 text-xs bg-blue-50 dark:bg-blue-900/20 text-blue-700 dark:text-blue-400 px-2 py-0.5 rounded-full cursor-default"
                                  title={participant.liveroom_planned_duration_hours > 0
                                    ? `E-learning: ${formatHoursMinutes((participant.total_time_spent_hours - (participant.liveroom_time_spent_hours || 0)) * 3600)} / ${formatHoursMinutes((participant.total_planned_duration_hours - (participant.liveroom_planned_duration_hours || 0)) * 3600)}\nClasse virtuelle: ${formatHoursMinutes((participant.liveroom_time_spent_hours || 0) * 3600)} / ${formatHoursMinutes((participant.liveroom_planned_duration_hours || 0) * 3600)}`
                                    : ''}
                                >
                                  <Clock size={12} />
                                  {formatTimeSpentInHours((participant.total_time_spent_hours || 0) * 3600)} / {formatTimeSpentInHours((participant.total_planned_duration_hours || 0) * 3600)}
                                </span>
                              )}
                              {participant.formateurs && participant.formateurs.length > 0 && (
                                <span
                                  className="flex items-center gap-1 text-xs bg-purple-50 dark:bg-purple-900/20 text-purple-700 dark:text-purple-400 px-2 py-0.5 rounded-full cursor-default"
                                  title={participant.formateurs.map(f => `${f.prenom || ''} ${f.nom || ''}`.trim()).join(', ')}
                                >
                                  <User size={12} />
                                  {participant.formateurs.length} formateur{participant.formateurs.length > 1 ? 's' : ''}
                                </span>
                              )}
                              {participant.category_name && (
                                <span
                                  className="flex items-center gap-1 text-xs px-2 py-0.5 rounded-full cursor-default"
                                  style={{
                                    backgroundColor: participant.category_color ? `#${participant.category_color}20` : '#f3f4f6',
                                    color: participant.category_color ? `#${participant.category_color}` : '#6b7280'
                                  }}
                                >
                                  {participant.category_color && (
                                    <span
                                      className="inline-block w-2 h-2 rounded-full flex-shrink-0"
                                      style={{ backgroundColor: `#${participant.category_color}` }}
                                    />
                                  )}
                                  {participant.category_name}
                                </span>
                              )}
                              {showLatestNotes && participant.latest_note_date && (
                                <span className="flex items-center gap-1 text-xs bg-green-50 dark:bg-green-900/20 text-green-700 dark:text-green-400 px-2 py-0.5 rounded-full cursor-default">
                                  <MessageSquare size={12} />
                                  {t('inactiveManagement.latestNote')}: {new Date(participant.latest_note_date).toLocaleDateString('fr-FR')}
                                </span>
                              )}
                              {showLatestNotes && !participant.latest_note_date && (
                                <span className="flex items-center gap-1 text-xs bg-gray-50 dark:bg-slate-700 text-gray-400 dark:text-gray-500 px-2 py-0.5 rounded-full cursor-default">
                                  <MessageSquare size={12} />
                                  {t('inactiveManagement.noNote')}
                                </span>
                              )}
                            </div>
                          </div>
                        </div>
                        {/* Expand button for intervention panel */}
                        <button
                          onClick={() => toggleParticipantExpand(pKey)}
                          className="ml-2 p-1 hover:bg-gray-200 dark:hover:bg-slate-600 rounded transition-colors"
                          title={t('inactiveManagement.interventions.title')}
                        >
                          {expandedParticipants.has(pKey)
                            ? <ChevronDown size={16} className="text-gray-400" />
                            : <ChevronRight size={16} className="text-gray-400" />
                          }
                        </button>
                      </div>
                      </div>
                      {/* Intervention Panel */}
                      {expandedParticipants.has(pKey) && (
                        <InterventionPanel participant={participant} />
                      )}
                    </div>
                    );
                  })}
                </div>
              </div>
            )}

            {/* Pagination Controls */}
            {pageSize !== 0 && totalPages > 1 && (
              <div className="flex items-center justify-between bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700 px-6 py-3 mt-4">
                <p className="text-sm text-gray-600 dark:text-gray-400">
                  {t('pagination.showing', { start: pageStart + 1, end: pageEnd, total: totalItems })}
                </p>
                <div className="flex items-center gap-1">
                  <button
                    onClick={() => setCurrentPage(1)}
                    disabled={safePage <= 1}
                    className="px-2 py-1.5 rounded border border-gray-200 dark:border-slate-700 text-sm text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-slate-700 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
                    title={t('pagination.firstPage')}
                  >
                    1
                  </button>
                  <button
                    onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
                    disabled={safePage <= 1}
                    className="p-1.5 rounded border border-gray-200 dark:border-slate-700 text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-slate-700 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
                    title={t('pagination.previousPage')}
                  >
                    <ChevronLeft size={16} />
                  </button>
                  <span className="px-3 py-1.5 text-sm font-medium text-gray-900 dark:text-white">
                    {safePage} / {totalPages}
                  </span>
                  <button
                    onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))}
                    disabled={safePage >= totalPages}
                    className="p-1.5 rounded border border-gray-200 dark:border-slate-700 text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-slate-700 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
                    title={t('pagination.nextPage')}
                  >
                    <ChevronRight size={16} />
                  </button>
                  <button
                    onClick={() => setCurrentPage(totalPages)}
                    disabled={safePage >= totalPages}
                    className="px-2 py-1.5 rounded border border-gray-200 dark:border-slate-700 text-sm text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-slate-700 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
                    title={t('pagination.lastPage')}
                  >
                    {totalPages}
                  </button>
                </div>
              </div>
            )}

            {/* Empty State */}
            {data.total_participants === 0 && (
              <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700 p-12 text-center">
                <UserX size={64} className="mx-auto text-gray-400 dark:text-gray-500 mb-4" />
                <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">
                  {t('inactiveManagement.noInactive')}
                </h2>
                <p className="text-gray-600 dark:text-gray-400 max-w-md mx-auto">
                  {t('inactiveManagement.noInactiveDescription')}
                </p>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
};

export default InactiveManagement;

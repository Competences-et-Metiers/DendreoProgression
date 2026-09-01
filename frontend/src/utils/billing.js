/**
 * HubSpot deal billing status ("facturation").
 *
 * HubSpot uses the label as the internal value, so these strings are what the
 * API returns and what we send back — they are never translated.
 */

export const FACTURATION_VALUES = [
  'Non facturée',
  'À facturer',
  'Partielle',
  'Facturée',
  'Encaissement partiel',
  'Encaissée',
];

// Tone per status, following the billing workflow: not started (gray),
// due (red), in progress (amber/teal), done (green/emerald).
export const FACTURATION_TONES = {
  'Non facturée': 'bg-gray-100 dark:bg-slate-700 text-gray-600 dark:text-gray-400 border-gray-300 dark:border-slate-600',
  'À facturer': 'bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-400 border-red-200 dark:border-red-800',
  'Partielle': 'bg-amber-50 dark:bg-amber-900/20 text-amber-700 dark:text-amber-400 border-amber-200 dark:border-amber-800',
  'Facturée': 'bg-green-50 dark:bg-green-900/20 text-green-700 dark:text-green-400 border-green-200 dark:border-green-800',
  'Encaissement partiel': 'bg-teal-50 dark:bg-teal-900/20 text-teal-700 dark:text-teal-400 border-teal-200 dark:border-teal-800',
  'Encaissée': 'bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-400 border-emerald-200 dark:border-emerald-800',
};

export const NO_STATUS_TONE =
  'bg-gray-50 dark:bg-slate-800 text-gray-400 dark:text-gray-500 border-gray-200 dark:border-slate-700';

export const getFacturationTone = (value) => FACTURATION_TONES[value] || NO_STATUS_TONE;

// Status filter value meaning "enrollments with no linked deal at all".
export const NO_DEAL = '__no_deal__';

/**
 * Does one billing row pass the current filters? Empty selections match
 * everything, and multiple selections within a filter are OR'd while the
 * filters themselves are AND'd — same semantics as Inactive Management.
 */
export const matchesBillingFilters = (row, filters = {}) => {
  const {
    courses = [],
    formateurs = [],
    categories = [],
    financements = [],
    status = '',
    search = '',
  } = filters;

  if (courses.length > 0 && !courses.includes(row.id_action_formation)) return false;
  if (formateurs.length > 0 && !row.formateurs?.some((f) => formateurs.includes(f.id_formateur))) {
    return false;
  }
  if (categories.length > 0 && !categories.includes(row.category_name)) return false;
  if (financements.length > 0 && !financements.includes(row.deal_type_financement)) return false;

  if (status === NO_DEAL) {
    if (row.deal_id) return false;
  } else if (status && row.deal_facturation !== status) {
    return false;
  }

  const term = search.trim().toLowerCase();
  if (term) {
    const haystack = `${row.prenom || ''} ${row.nom || ''} ${row.email || ''} ${row.course_title || ''} ${row.category_name || ''}`.toLowerCase();
    if (!haystack.includes(term)) return false;
  }
  return true;
};

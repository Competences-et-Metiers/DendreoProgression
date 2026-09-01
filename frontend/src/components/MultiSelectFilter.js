import React, { useState, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { ChevronDown, ChevronRight } from 'lucide-react';

/**
 * Collapsible multi-select filter: search, select-all over the current search,
 * and selections pinned above the list so a search can never hide what is
 * already active. Same behaviour as the Inactive Management filters.
 *
 * options: [{ value, label, color? }] — color is an optional hex without '#'.
 */
const MultiSelectFilter = ({
  label,
  icon: Icon,
  options = [],
  selected = [],
  onChange,
  searchPlaceholder,
  emptyText,
  summary,
}) => {
  const { t } = useTranslation();
  const [open, setOpen] = useState(false);
  const [search, setSearch] = useState('');

  const term = search.toLowerCase();
  const matching = useMemo(
    () => options.filter((o) => (o.label || '').toLowerCase().includes(term)),
    [options, term]
  );
  // Selected options the search would otherwise hide — shown pinned so they
  // stay visible (and removable) while searching for something else.
  const selectedButHidden = useMemo(
    () =>
      term
        ? options.filter(
            (o) => selected.includes(o.value) && !(o.label || '').toLowerCase().includes(term)
          )
        : [],
    [options, selected, term]
  );

  const allMatchingSelected =
    matching.length > 0 && matching.every((o) => selected.includes(o.value));

  const toggle = (value, checked) => {
    onChange(checked ? [...selected, value] : selected.filter((v) => v !== value));
  };

  const toggleAll = (checked) => {
    if (checked) {
      onChange([...new Set([...selected, ...matching.map((o) => o.value)])]);
    } else {
      const hide = new Set(matching.map((o) => o.value));
      onChange(selected.filter((v) => !hide.has(v)));
    }
  };

  const renderLabel = (option) => (
    <span className="text-xs text-gray-700 dark:text-gray-300 leading-tight flex items-center gap-1.5">
      {option.color && (
        <span
          className="inline-block w-2.5 h-2.5 rounded-full flex-shrink-0"
          style={{ backgroundColor: `#${option.color}` }}
        />
      )}
      {option.label}
    </span>
  );

  return (
    <div>
      <button
        onClick={() => setOpen(!open)}
        className="w-full flex items-center justify-between px-3 py-2 rounded-lg border border-gray-200 dark:border-slate-700 hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors"
      >
        <div className="flex items-center gap-2">
          {Icon && <Icon size={16} className="text-gray-600 dark:text-gray-400" />}
          <span className="text-sm font-medium text-gray-900 dark:text-white">{label}</span>
          {selected.length > 0 && (
            <span className="px-2 py-0.5 bg-primary-100 dark:bg-primary-900/30 text-primary-700 dark:text-primary-400 text-xs font-medium rounded-full">
              {selected.length}
            </span>
          )}
        </div>
        {open ? (
          <ChevronDown size={16} className="text-gray-400 dark:text-gray-300" />
        ) : (
          <ChevronRight size={16} className="text-gray-400 dark:text-gray-300" />
        )}
      </button>

      {open && (
        <div className="mt-2 space-y-2">
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder={searchPlaceholder || t('multiSelect.search')}
            className="w-full px-3 py-2 border border-gray-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-sm dark:bg-slate-700 dark:text-white dark:placeholder-gray-500"
          />

          {selectedButHidden.length > 0 && (
            <div className="space-y-1 border border-primary-200 dark:border-primary-800 bg-primary-50/50 dark:bg-primary-900/20 rounded-lg p-2">
              <p className="text-[10px] font-medium text-primary-600 uppercase tracking-wide px-2">
                {t('multiSelect.selected')}
              </p>
              {selectedButHidden.map((option) => (
                <label
                  key={option.value}
                  className="flex items-start gap-2 px-2 py-1.5 rounded hover:bg-primary-100/50 dark:hover:bg-primary-900/30 cursor-pointer transition-colors"
                >
                  <input
                    type="checkbox"
                    checked
                    onChange={() => toggle(option.value, false)}
                    className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500 mt-0.5"
                  />
                  {renderLabel(option)}
                </label>
              ))}
            </div>
          )}

          <div className="max-h-48 overflow-y-auto space-y-1 border border-gray-200 dark:border-slate-700 rounded-lg p-2">
            {matching.length === 0 ? (
              <p className="text-sm text-gray-500 dark:text-gray-400 text-center py-2">
                {emptyText || t('multiSelect.noResults')}
              </p>
            ) : (
              <>
                <label className="flex items-center gap-2 px-2 py-1.5 rounded hover:bg-gray-50 dark:hover:bg-slate-700 cursor-pointer transition-colors border-b border-gray-200 dark:border-slate-700">
                  <input
                    type="checkbox"
                    checked={allMatchingSelected}
                    onChange={(e) => toggleAll(e.target.checked)}
                    className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500"
                  />
                  <span className="text-xs font-semibold text-gray-700 dark:text-gray-300">
                    {allMatchingSelected ? t('multiSelect.deselectAll') : t('multiSelect.selectAll')}
                  </span>
                </label>
                {matching.map((option) => (
                  <label
                    key={option.value}
                    className="flex items-start gap-2 px-2 py-1.5 rounded hover:bg-gray-50 dark:hover:bg-slate-700 cursor-pointer transition-colors"
                  >
                    <input
                      type="checkbox"
                      checked={selected.includes(option.value)}
                      onChange={(e) => toggle(option.value, e.target.checked)}
                      className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500 mt-0.5"
                    />
                    {renderLabel(option)}
                  </label>
                ))}
              </>
            )}
          </div>

          {selected.length > 0 && summary && (
            <p className="text-xs text-gray-500 dark:text-gray-400">{summary(selected.length)}</p>
          )}
        </div>
      )}
    </div>
  );
};

export default MultiSelectFilter;

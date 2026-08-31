import React, { useState, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { FileText, X, Download, GripVertical, Filter as FilterIcon, FileSpreadsheet } from 'lucide-react';
import { MODULE_EXPORT_COLUMNS } from '../utils/moduleExportColumns';

const STORAGE_KEY = 'moduleManagement.pdfColumns';
const FORMAT_STORAGE_KEY = 'moduleManagement.exportFormat';

const defaultColumns = () => MODULE_EXPORT_COLUMNS.filter(c => c.default).map(c => c.key);

const ModulePdfExportModal = ({ isOpen, onClose, items, activeFilters }) => {
  const { t, i18n } = useTranslation();

  const [selectedKeys, setSelectedKeys] = useState(() => {
    try {
      const cached = localStorage.getItem(STORAGE_KEY);
      if (cached) {
        const parsed = JSON.parse(cached);
        const valid = parsed.filter(k => MODULE_EXPORT_COLUMNS.some(c => c.key === k));
        if (valid.length > 0) return valid;
      }
    } catch (_) { /* ignore */ }
    return defaultColumns();
  });

  const [dragKey, setDragKey] = useState(null);

  const [format, setFormat] = useState(() => {
    const cached = localStorage.getItem(FORMAT_STORAGE_KEY);
    return cached === 'excel' ? 'excel' : 'pdf';
  });

  const orderedAvailable = useMemo(() => {
    const inSelection = selectedKeys
      .map(k => MODULE_EXPORT_COLUMNS.find(c => c.key === k))
      .filter(Boolean);
    const notSelected = MODULE_EXPORT_COLUMNS.filter(c => !selectedKeys.includes(c.key));
    return { selected: inSelection, notSelected };
  }, [selectedKeys]);

  if (!isOpen) return null;

  const toggleColumn = (key) => {
    setSelectedKeys(prev => prev.includes(key)
      ? prev.filter(k => k !== key)
      : [...prev, key]
    );
  };

  const resetToDefault = () => setSelectedKeys(defaultColumns());

  const handleDrop = (targetKey) => {
    if (!dragKey || dragKey === targetKey) return;
    setSelectedKeys(prev => {
      const next = prev.filter(k => k !== dragKey);
      const targetIdx = next.indexOf(targetKey);
      if (targetIdx < 0) return prev;
      next.splice(targetIdx, 0, dragKey);
      return next;
    });
    setDragKey(null);
  };

  const handleExport = async () => {
    if (selectedKeys.length === 0) return;
    localStorage.setItem(STORAGE_KEY, JSON.stringify(selectedKeys));
    localStorage.setItem(FORMAT_STORAGE_KEY, format);
    const lang = i18n.language?.startsWith('fr') ? 'fr' : 'en';
    // jspdf/xlsx are loaded here rather than at module scope so they stay out of
    // the initial bundle and only download when someone actually exports.
    const { generateModuleReport, generateModuleExcel } = await import('../utils/moduleExport');
    const generator = format === 'excel' ? generateModuleExcel : generateModuleReport;
    generator({ items, columns: selectedKeys, activeFilters, t, lang });
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="fixed inset-0 bg-black/50" onClick={onClose} />
      <div className="relative bg-white dark:bg-slate-800 rounded-xl shadow-xl border border-gray-200 dark:border-slate-700 max-w-2xl w-full mx-4 max-h-[90vh] flex flex-col">
        {/* Header */}
        <div className="flex items-start justify-between p-6 border-b border-gray-200 dark:border-slate-700">
          <div className="flex items-start gap-3">
            <div className="p-2 bg-primary-100 dark:bg-primary-900/30 rounded-lg">
              <FileText size={24} className="text-primary-600 dark:text-primary-400" />
            </div>
            <div>
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                {t('moduleManagement.pdf.modalTitle')}
              </h3>
              <p className="mt-1 text-sm text-gray-600 dark:text-gray-400">
                {t('moduleManagement.pdf.modalSubtitle', { count: items.length })}
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1 hover:bg-gray-100 dark:hover:bg-slate-700 rounded text-gray-400"
          >
            <X size={20} />
          </button>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-y-auto p-6 space-y-5">
          {/* Format selector */}
          <div>
            <h4 className="text-xs font-semibold text-gray-600 dark:text-gray-400 uppercase tracking-wide mb-2">
              {t('moduleManagement.pdf.format')}
            </h4>
            <div className="grid grid-cols-2 gap-2">
              <button
                type="button"
                onClick={() => setFormat('pdf')}
                className={`flex items-center gap-2 px-3 py-2 rounded-lg border text-sm font-medium transition-colors ${
                  format === 'pdf'
                    ? 'bg-primary-50 dark:bg-primary-900/20 border-primary-200 dark:border-primary-800 text-primary-700 dark:text-primary-300'
                    : 'bg-white dark:bg-slate-800 border-gray-200 dark:border-slate-700 text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-slate-700'
                }`}
              >
                <FileText size={16} />
                PDF
              </button>
              <button
                type="button"
                onClick={() => setFormat('excel')}
                className={`flex items-center gap-2 px-3 py-2 rounded-lg border text-sm font-medium transition-colors ${
                  format === 'excel'
                    ? 'bg-primary-50 dark:bg-primary-900/20 border-primary-200 dark:border-primary-800 text-primary-700 dark:text-primary-300'
                    : 'bg-white dark:bg-slate-800 border-gray-200 dark:border-slate-700 text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-slate-700'
                }`}
              >
                <FileSpreadsheet size={16} />
                Excel
              </button>
            </div>
          </div>

          {/* Active filters preview */}
          <div>
            <h4 className="flex items-center gap-2 text-xs font-semibold text-gray-600 dark:text-gray-400 uppercase tracking-wide mb-2">
              <FilterIcon size={12} />
              {t('moduleManagement.pdf.appliedFilters')}
            </h4>
            {activeFilters.length === 0 ? (
              <p className="text-xs text-gray-500 dark:text-gray-400 italic">
                {t('moduleManagement.pdf.noFilters')}
              </p>
            ) : (
              <ul className="space-y-1">
                {activeFilters.map((f, i) => (
                  <li key={i} className="text-xs text-gray-700 dark:text-gray-300 bg-gray-50 dark:bg-slate-700/50 rounded px-3 py-1.5">
                    • {f}
                  </li>
                ))}
              </ul>
            )}
          </div>

          {/* Column selection */}
          <div>
            <div className="flex items-center justify-between mb-2">
              <h4 className="text-xs font-semibold text-gray-600 dark:text-gray-400 uppercase tracking-wide">
                {t('moduleManagement.pdf.columns')}
              </h4>
              <button
                onClick={resetToDefault}
                className="text-xs text-primary-600 dark:text-primary-400 hover:underline"
              >
                {t('moduleManagement.pdf.resetColumns')}
              </button>
            </div>

            {/* Selected (ordered, draggable) */}
            <div className="space-y-1 mb-3">
              {orderedAvailable.selected.length === 0 && (
                <p className="text-xs text-red-600 dark:text-red-400">
                  {t('moduleManagement.pdf.noColumnsSelected')}
                </p>
              )}
              {orderedAvailable.selected.map((col) => (
                <div
                  key={col.key}
                  draggable
                  onDragStart={() => setDragKey(col.key)}
                  onDragOver={(e) => e.preventDefault()}
                  onDrop={() => handleDrop(col.key)}
                  onDragEnd={() => setDragKey(null)}
                  className={`flex items-center gap-2 px-3 py-2 rounded-lg border bg-primary-50 dark:bg-primary-900/20 border-primary-200 dark:border-primary-800 cursor-move transition-opacity ${
                    dragKey === col.key ? 'opacity-50' : ''
                  }`}
                >
                  <GripVertical size={14} className="text-primary-400 flex-shrink-0" />
                  <input
                    type="checkbox"
                    checked
                    onChange={() => toggleColumn(col.key)}
                    className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500"
                  />
                  <span className="text-sm text-primary-700 dark:text-primary-300 font-medium flex-1">
                    {t(`moduleManagement.pdf.col_${col.key}`)}
                  </span>
                  {col.default && (
                    <span className="text-[10px] text-primary-500 dark:text-primary-400 uppercase tracking-wider">
                      {t('moduleManagement.pdf.defaultTag')}
                    </span>
                  )}
                </div>
              ))}
            </div>

            {/* Unselected */}
            {orderedAvailable.notSelected.length > 0 && (
              <>
                <p className="text-[10px] uppercase tracking-wide text-gray-400 dark:text-gray-500 mb-1">
                  {t('moduleManagement.pdf.notSelected')}
                </p>
                <div className="space-y-1">
                  {orderedAvailable.notSelected.map((col) => (
                    <label
                      key={col.key}
                      className="flex items-center gap-2 px-3 py-2 rounded-lg border border-gray-200 dark:border-slate-700 hover:bg-gray-50 dark:hover:bg-slate-700 cursor-pointer transition-colors"
                    >
                      <span className="w-3.5" />
                      <input
                        type="checkbox"
                        checked={false}
                        onChange={() => toggleColumn(col.key)}
                        className="w-4 h-4 text-primary-600 rounded focus:ring-2 focus:ring-primary-500"
                      />
                      <span className="text-sm text-gray-700 dark:text-gray-300 flex-1">
                        {t(`moduleManagement.pdf.col_${col.key}`)}
                      </span>
                      {col.default && (
                        <span className="text-[10px] text-gray-400 uppercase tracking-wider">
                          {t('moduleManagement.pdf.defaultTag')}
                        </span>
                      )}
                    </label>
                  ))}
                </div>
              </>
            )}
          </div>
        </div>

        {/* Footer */}
        <div className="flex items-center justify-end gap-3 p-6 border-t border-gray-200 dark:border-slate-700">
          <button
            onClick={onClose}
            className="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-slate-800 border border-gray-300 dark:border-slate-600 rounded-lg hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors"
          >
            {t('common.cancel')}
          </button>
          <button
            onClick={handleExport}
            disabled={selectedKeys.length === 0 || items.length === 0}
            className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-primary-600 hover:bg-primary-700 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <Download size={16} />
            {t('moduleManagement.pdf.download')}
          </button>
        </div>
      </div>
    </div>
  );
};

export default ModulePdfExportModal;

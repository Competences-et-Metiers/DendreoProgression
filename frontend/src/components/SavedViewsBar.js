import React, { useState, useEffect, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiService } from '../services/api';
import { queryKeys } from '../queryClient';
import { Bookmark, Plus, X, Check, Loader2, Save, Trash2 } from 'lucide-react';

const SavedViewsBar = ({ onLoadView, getCurrentFilters }) => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const [showNameInput, setShowNameInput] = useState(false);
  const [viewName, setViewName] = useState('');
  const [activeViewId, setActiveViewId] = useState(null);
  const [confirmDeleteId, setConfirmDeleteId] = useState(null);
  const [isDirty, setIsDirty] = useState(false);
  const savedFiltersRef = useRef(null);

  const { data: views = [], isLoading } = useQuery({
    queryKey: queryKeys.savedViews,
    queryFn: apiService.getSavedViews,
    staleTime: 10 * 60 * 1000,
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });

  // Track filter changes to detect dirty state
  useEffect(() => {
    if (!activeViewId || !savedFiltersRef.current) return;
    const currentFilters = getCurrentFilters();
    const changed = JSON.stringify(currentFilters) !== JSON.stringify(savedFiltersRef.current);
    setIsDirty(changed);
  });

  const createMutation = useMutation({
    mutationFn: ({ name, filterConfig }) => apiService.createSavedView(name, filterConfig),
    onSuccess: (newView) => {
      queryClient.invalidateQueries({ queryKey: queryKeys.savedViews });
      setShowNameInput(false);
      setViewName('');
      setActiveViewId(newView.id);
      savedFiltersRef.current = getCurrentFilters();
      setIsDirty(false);
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ viewId, name, filterConfig }) => apiService.updateSavedView(viewId, name, filterConfig),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.savedViews });
      savedFiltersRef.current = getCurrentFilters();
      setIsDirty(false);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (viewId) => apiService.deleteSavedView(viewId),
    onSuccess: (_, deletedId) => {
      queryClient.invalidateQueries({ queryKey: queryKeys.savedViews });
      if (activeViewId === deletedId) {
        setActiveViewId(null);
        savedFiltersRef.current = null;
        setIsDirty(false);
      }
      setConfirmDeleteId(null);
    },
  });

  const handleSave = () => {
    const name = viewName.trim();
    if (!name) return;
    createMutation.mutate({ name, filterConfig: getCurrentFilters() });
  };

  const handleUpdate = (e, view) => {
    e.stopPropagation();
    updateMutation.mutate({ viewId: view.id, name: view.name, filterConfig: getCurrentFilters() });
  };

  const handleLoad = (view) => {
    setActiveViewId(view.id);
    savedFiltersRef.current = view.filter_config;
    setIsDirty(false);
    setConfirmDeleteId(null);
    onLoadView(view.filter_config);
  };

  const handleDeleteClick = (e, viewId) => {
    e.stopPropagation();
    setConfirmDeleteId(prev => prev === viewId ? null : viewId);
  };

  const handleDeleteConfirm = (e, viewId) => {
    e.stopPropagation();
    deleteMutation.mutate(viewId);
  };

  const handleDeleteCancel = (e) => {
    e.stopPropagation();
    setConfirmDeleteId(null);
  };

  return (
    <div className="flex items-center gap-2 flex-wrap">
      <Bookmark size={16} className="text-gray-400 flex-shrink-0" />

      {isLoading && <Loader2 size={14} className="animate-spin text-gray-400" />}

      {views.map((view) => (
        <div key={view.id} className="relative">
          <button
            onClick={() => handleLoad(view)}
            className={`group flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-medium transition-colors ${
              activeViewId === view.id
                ? 'bg-blue-100 text-blue-700 border border-blue-300'
                : 'bg-gray-100 text-gray-600 border border-gray-200 hover:bg-gray-200'
            }`}
          >
            {view.name}
            {activeViewId === view.id && isDirty && (
              <span
                onClick={(e) => handleUpdate(e, view)}
                className="ml-0.5 cursor-pointer text-blue-500 hover:text-green-600 transition-colors"
                title={t('savedViews.update')}
              >
                {updateMutation.isPending ? <Loader2 size={12} className="animate-spin" /> : <Save size={12} />}
              </span>
            )}
            <span
              onClick={(e) => handleDeleteClick(e, view.id)}
              className={`${activeViewId === view.id ? '' : 'opacity-0 group-hover:opacity-100'} transition-all ml-0.5 hover:text-red-500 cursor-pointer`}
            >
              <Trash2 size={12} />
            </span>
          </button>

          {/* Delete confirmation popover */}
          {confirmDeleteId === view.id && (
            <div className="absolute top-full left-0 mt-1.5 z-20 bg-white rounded-lg shadow-lg border border-gray-200 p-3 min-w-[180px]">
              <p className="text-xs text-gray-600 mb-2">{t('savedViews.deleteConfirm')}</p>
              <div className="flex items-center gap-2">
                <button
                  onClick={(e) => handleDeleteConfirm(e, view.id)}
                  disabled={deleteMutation.isPending}
                  className="flex items-center gap-1 px-2.5 py-1 text-xs font-medium rounded bg-red-600 text-white hover:bg-red-700 disabled:opacity-50 transition-colors"
                >
                  {deleteMutation.isPending ? <Loader2 size={10} className="animate-spin" /> : <Trash2 size={10} />}
                  {t('savedViews.deleteYes')}
                </button>
                <button
                  onClick={handleDeleteCancel}
                  className="px-2.5 py-1 text-xs font-medium rounded bg-gray-100 text-gray-600 hover:bg-gray-200 transition-colors"
                >
                  {t('savedViews.deleteNo')}
                </button>
              </div>
            </div>
          )}
        </div>
      ))}

      {showNameInput ? (
        <div className="flex items-center gap-1.5">
          <input
            type="text"
            value={viewName}
            onChange={(e) => setViewName(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') handleSave();
              if (e.key === 'Escape') { setShowNameInput(false); setViewName(''); }
            }}
            placeholder={t('savedViews.namePlaceholder')}
            className="px-2.5 py-1 text-sm border border-gray-300 rounded-full focus:outline-none focus:border-blue-400 w-40"
            autoFocus
            disabled={createMutation.isPending}
          />
          <button
            onClick={handleSave}
            disabled={!viewName.trim() || createMutation.isPending}
            className="p-1 rounded-full text-green-600 hover:bg-green-50 disabled:opacity-40"
          >
            {createMutation.isPending ? <Loader2 size={14} className="animate-spin" /> : <Check size={14} />}
          </button>
          <button
            onClick={() => { setShowNameInput(false); setViewName(''); }}
            className="p-1 rounded-full text-gray-400 hover:bg-gray-100"
          >
            <X size={14} />
          </button>
        </div>
      ) : (
        <button
          onClick={() => setShowNameInput(true)}
          className="flex items-center gap-1 px-3 py-1.5 rounded-full text-sm text-gray-500 border border-dashed border-gray-300 hover:border-gray-400 hover:text-gray-600 transition-colors"
        >
          <Plus size={14} />
          {t('savedViews.save')}
        </button>
      )}
    </div>
  );
};

export default SavedViewsBar;

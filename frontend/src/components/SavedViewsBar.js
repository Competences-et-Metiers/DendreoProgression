import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiService } from '../services/api';
import { queryKeys } from '../queryClient';
import { Bookmark, Plus, X, Check, Loader2, Save } from 'lucide-react';

const SavedViewsBar = ({ onLoadView, getCurrentFilters }) => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const [showNameInput, setShowNameInput] = useState(false);
  const [viewName, setViewName] = useState('');
  const [activeViewId, setActiveViewId] = useState(null);

  const { data: views = [], isLoading } = useQuery({
    queryKey: queryKeys.savedViews,
    queryFn: apiService.getSavedViews,
    staleTime: 10 * 60 * 1000,
    refetchOnMount: false,
    refetchOnWindowFocus: false,
  });

  const createMutation = useMutation({
    mutationFn: ({ name, filterConfig }) => apiService.createSavedView(name, filterConfig),
    onSuccess: (newView) => {
      queryClient.invalidateQueries({ queryKey: queryKeys.savedViews });
      setShowNameInput(false);
      setViewName('');
      setActiveViewId(newView.id);
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ viewId, name, filterConfig }) => apiService.updateSavedView(viewId, name, filterConfig),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.savedViews });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (viewId) => apiService.deleteSavedView(viewId),
    onSuccess: (_, deletedId) => {
      queryClient.invalidateQueries({ queryKey: queryKeys.savedViews });
      if (activeViewId === deletedId) setActiveViewId(null);
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
    onLoadView(view.filter_config);
  };

  const handleDelete = (e, viewId) => {
    e.stopPropagation();
    deleteMutation.mutate(viewId);
  };

  return (
    <div className="flex items-center gap-2 flex-wrap">
      <Bookmark size={16} className="text-gray-400 flex-shrink-0" />

      {isLoading && <Loader2 size={14} className="animate-spin text-gray-400" />}

      {views.map((view) => (
        <button
          key={view.id}
          onClick={() => handleLoad(view)}
          className={`group flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-medium transition-colors ${
            activeViewId === view.id
              ? 'bg-blue-100 text-blue-700 border border-blue-300'
              : 'bg-gray-100 text-gray-600 border border-gray-200 hover:bg-gray-200'
          }`}
        >
          {view.name}
          {activeViewId === view.id && (
            <span
              onClick={(e) => handleUpdate(e, view)}
              className="ml-0.5 hover:text-blue-800 cursor-pointer"
              title={t('savedViews.update')}
            >
              {updateMutation.isPending ? <Loader2 size={12} className="animate-spin" /> : <Save size={12} />}
            </span>
          )}
          <span
            onClick={(e) => handleDelete(e, view.id)}
            className={`${activeViewId === view.id ? '' : 'opacity-0 group-hover:opacity-100'} transition-opacity ml-0.5 hover:text-red-500 cursor-pointer`}
          >
            <X size={12} />
          </span>
        </button>
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

import React, { useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { useCacheManager } from '../hooks/useQuery';
import { 
  Database, 
  RefreshCw, 
  Trash2, 
  Clock,
  CheckCircle,
  XCircle,
  ChevronDown,
  ChevronUp
} from 'lucide-react';

const CacheStatus = () => {
  const [isExpanded, setIsExpanded] = useState(false);
  const queryClient = useQueryClient();
  const { clearCache, invalidateAll } = useCacheManager();

  const getQueryCacheStats = () => {
    const queryCache = queryClient.getQueryCache();
    const queries = queryCache.getAll();
    
    const stats = {
      total: queries.length,
      fresh: 0,
      stale: 0,
      inactive: 0,
      error: 0
    };

    queries.forEach(query => {
      if (query.state.status === 'error') {
        stats.error++;
      } else if (query.isStale()) {
        stats.stale++;
      } else if (!query.getObserversCount()) {
        stats.inactive++;
      } else {
        stats.fresh++;
      }
    });

    return stats;
  };

  const getCacheSize = () => {
    const queryCache = queryClient.getQueryCache();
    const queries = queryCache.getAll();
    return queries.reduce((size, query) => {
      if (query.state.data) {
        return size + JSON.stringify(query.state.data).length;
      }
      return size;
    }, 0);
  };

  const formatBytes = (bytes) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  const handleClearCache = () => {
    if (window.confirm('Are you sure you want to clear all cached data? This will force a refresh of all data.')) {
      clearCache();
    }
  };

  const handleInvalidateAll = () => {
    if (window.confirm('Are you sure you want to invalidate all cached data? This will trigger a background refresh.')) {
      invalidateAll();
    }
  };

  const stats = getQueryCacheStats();
  const cacheSize = getCacheSize();

  return (
    <div className="bg-white border border-gray-200 rounded-lg shadow-sm">
      <div 
        className="px-4 py-3 border-b border-gray-200 cursor-pointer hover:bg-gray-50"
        onClick={() => setIsExpanded(!isExpanded)}
      >
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <Database size={16} className="text-blue-500" />
            <span className="font-medium text-gray-900">Cache Status</span>
            <span className="text-sm text-gray-500">
              ({stats.total} queries, {formatBytes(cacheSize)})
            </span>
          </div>
          <div className="flex items-center space-x-2">
            <div className="flex items-center space-x-1">
              <CheckCircle size={12} className="text-green-500" />
              <span className="text-xs text-gray-600">{stats.fresh}</span>
            </div>
            <div className="flex items-center space-x-1">
              <Clock size={12} className="text-yellow-500" />
              <span className="text-xs text-gray-600">{stats.stale}</span>
            </div>
            <div className="flex items-center space-x-1">
              <XCircle size={12} className="text-gray-400" />
              <span className="text-xs text-gray-600">{stats.inactive}</span>
            </div>
            {isExpanded ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
          </div>
        </div>
      </div>

      {isExpanded && (
        <div className="p-4">
          {/* Cache Actions */}
          <div className="flex items-center space-x-2 mb-4">
            <button
              onClick={handleInvalidateAll}
              className="inline-flex items-center px-3 py-1 border border-gray-300 rounded text-xs font-medium text-gray-700 bg-white hover:bg-gray-50"
            >
              <RefreshCw size={12} className="mr-1" />
              Refresh All
            </button>
            <button
              onClick={handleClearCache}
              className="inline-flex items-center px-3 py-1 border border-red-300 rounded text-xs font-medium text-red-700 bg-white hover:bg-red-50"
            >
              <Trash2 size={12} className="mr-1" />
              Clear Cache
            </button>
          </div>

          {/* Cache Statistics */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            <div className="text-center p-2 bg-green-50 rounded">
              <div className="text-lg font-semibold text-green-600">{stats.fresh}</div>
              <div className="text-xs text-green-600">Fresh</div>
            </div>
            <div className="text-center p-2 bg-yellow-50 rounded">
              <div className="text-lg font-semibold text-yellow-600">{stats.stale}</div>
              <div className="text-xs text-yellow-600">Stale</div>
            </div>
            <div className="text-center p-2 bg-gray-50 rounded">
              <div className="text-lg font-semibold text-gray-600">{stats.inactive}</div>
              <div className="text-xs text-gray-600">Inactive</div>
            </div>
            <div className="text-center p-2 bg-red-50 rounded">
              <div className="text-lg font-semibold text-red-600">{stats.error}</div>
              <div className="text-xs text-red-600">Error</div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default CacheStatus; 
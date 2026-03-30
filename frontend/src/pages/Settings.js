import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Settings as SettingsIcon, AlarmClock, Ban } from 'lucide-react';

const Settings = () => {
  const { t } = useTranslation();

  const [showInterventionCounters, setShowInterventionCounters] = useState(() => {
    const cached = localStorage.getItem('inactiveManagement.showInterventionCounters');
    return cached ? JSON.parse(cached) : false;
  });

  const handleToggle = () => {
    setShowInterventionCounters(prev => {
      const next = !prev;
      localStorage.setItem('inactiveManagement.showInterventionCounters', JSON.stringify(next));
      return next;
    });
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center">
            <div className="p-2 bg-gray-100 rounded-lg mr-4">
              <SettingsIcon size={24} className="text-gray-600" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-gray-900">{t('settings.title')}</h1>
              <p className="text-gray-600 mt-1">{t('settings.subtitle')}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Inactive Management section */}
        <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
          <div className="px-6 py-4 border-b border-gray-100">
            <h2 className="text-lg font-semibold text-gray-900">{t('settings.inactiveManagement.title')}</h2>
            <p className="text-sm text-gray-500 mt-0.5">{t('settings.inactiveManagement.subtitle')}</p>
          </div>

          <div className="divide-y divide-gray-100">
            {/* Intervention counters toggle */}
            <div className="flex items-center justify-between px-6 py-4">
              <div className="flex items-center gap-3">
                <div className="flex items-center gap-1 text-amber-500">
                  <AlarmClock size={18} />
                  <Ban size={18} className="text-gray-400" />
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-900">{t('settings.inactiveManagement.showInterventionCounters')}</p>
                  <p className="text-xs text-gray-500">{t('settings.inactiveManagement.showInterventionCountersDesc')}</p>
                </div>
              </div>
              <button
                onClick={handleToggle}
                className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                  showInterventionCounters ? 'bg-primary-600' : 'bg-gray-200'
                }`}
              >
                <span
                  className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                    showInterventionCounters ? 'translate-x-6' : 'translate-x-1'
                  }`}
                />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Settings;

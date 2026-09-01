import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Settings as SettingsIcon, AlarmClock, Ban, Moon, Sun, Globe, MessageSquare } from 'lucide-react';
import { useTheme } from '../contexts/ThemeContext';
import LanguageSelector from '../components/LanguageSelector';

const Settings = () => {
  const { t } = useTranslation();
  const { isDark, toggleTheme } = useTheme();

  const [showInterventionCounters, setShowInterventionCounters] = useState(() => {
    const cached = localStorage.getItem('inactiveManagement.showInterventionCounters');
    return cached ? JSON.parse(cached) : false;
  });

  const handleInterventionToggle = () => {
    setShowInterventionCounters(prev => {
      const next = !prev;
      localStorage.setItem('inactiveManagement.showInterventionCounters', JSON.stringify(next));
      return next;
    });
  };

  const [showLatestNotes, setShowLatestNotes] = useState(() => {
    const cached = localStorage.getItem('inactiveManagement.showLatestNotes');
    return cached === null ? true : JSON.parse(cached);
  });

  const handleLatestNotesToggle = () => {
    setShowLatestNotes(prev => {
      const next = !prev;
      localStorage.setItem('inactiveManagement.showLatestNotes', JSON.stringify(next));
      return next;
    });
  };

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-slate-900">
      {/* Header */}
      <div className="bg-white dark:bg-slate-800 border-b border-gray-200 dark:border-slate-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center">
            <div className="p-2 bg-gray-100 dark:bg-slate-700 rounded-lg mr-4">
              <SettingsIcon size={24} className="text-gray-600 dark:text-gray-300" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-gray-900 dark:text-white">{t('settings.title')}</h1>
              <p className="text-gray-600 dark:text-gray-400 mt-1">{t('settings.subtitle')}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-6">
        {/* Appearance section */}
        <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700 overflow-hidden">
          <div className="px-6 py-4 border-b border-gray-100 dark:border-slate-700">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">{t('settings.appearance.title')}</h2>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-0.5">{t('settings.appearance.subtitle')}</p>
          </div>

          <div className="divide-y divide-gray-100 dark:divide-slate-700">
            <div className="flex items-center justify-between px-6 py-4">
              <div className="flex items-center gap-3">
                <div className="text-gray-500 dark:text-gray-400">
                  {isDark ? <Moon size={18} /> : <Sun size={18} />}
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-900 dark:text-white">{t('settings.appearance.theme')}</p>
                  <p className="text-xs text-gray-500 dark:text-gray-400">{t('settings.appearance.themeDesc')}</p>
                </div>
              </div>
              <button
                onClick={toggleTheme}
                className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                  isDark ? 'bg-primary-600' : 'bg-gray-200'
                }`}
              >
                <span
                  className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                    isDark ? 'translate-x-6' : 'translate-x-1'
                  }`}
                />
              </button>
            </div>
          </div>
        </div>

        {/* Language section */}
        <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700 overflow-hidden">
          <div className="px-6 py-4 border-b border-gray-100 dark:border-slate-700">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">{t('settings.language.title')}</h2>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-0.5">{t('settings.language.subtitle')}</p>
          </div>

          <div className="divide-y divide-gray-100 dark:divide-slate-700">
            <div className="flex items-center justify-between px-6 py-4">
              <div className="flex items-center gap-3">
                <div className="text-gray-500 dark:text-gray-400">
                  <Globe size={18} />
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-900 dark:text-white">{t('settings.language.label')}</p>
                </div>
              </div>
              <LanguageSelector />
            </div>
          </div>
        </div>

        {/* Inactive Management section */}
        <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700 overflow-hidden">
          <div className="px-6 py-4 border-b border-gray-100 dark:border-slate-700">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">{t('settings.inactiveManagement.title')}</h2>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-0.5">{t('settings.inactiveManagement.subtitle')}</p>
          </div>

          <div className="divide-y divide-gray-100 dark:divide-slate-700">
            <div className="flex items-center justify-between px-6 py-4">
              <div className="flex items-center gap-3">
                <div className="flex items-center gap-1 text-amber-500">
                  <AlarmClock size={18} />
                  <Ban size={18} className="text-gray-400" />
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-900 dark:text-white">{t('settings.inactiveManagement.showInterventionCounters')}</p>
                  <p className="text-xs text-gray-500 dark:text-gray-400">{t('settings.inactiveManagement.showInterventionCountersDesc')}</p>
                </div>
              </div>
              <button
                onClick={handleInterventionToggle}
                className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                  showInterventionCounters ? 'bg-primary-600' : 'bg-gray-200 dark:bg-slate-600'
                }`}
              >
                <span
                  className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                    showInterventionCounters ? 'translate-x-6' : 'translate-x-1'
                  }`}
                />
              </button>
            </div>

            <div className="flex items-center justify-between px-6 py-4">
              <div className="flex items-center gap-3">
                <div className="text-green-500">
                  <MessageSquare size={18} />
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-900 dark:text-white">{t('settings.inactiveManagement.showLatestNotes')}</p>
                  <p className="text-xs text-gray-500 dark:text-gray-400">{t('settings.inactiveManagement.showLatestNotesDesc')}</p>
                </div>
              </div>
              <button
                onClick={handleLatestNotesToggle}
                className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                  showLatestNotes ? 'bg-primary-600' : 'bg-gray-200 dark:bg-slate-600'
                }`}
              >
                <span
                  className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                    showLatestNotes ? 'translate-x-6' : 'translate-x-1'
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

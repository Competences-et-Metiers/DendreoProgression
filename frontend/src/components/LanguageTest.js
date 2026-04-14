import React from 'react';
import { useTranslation } from 'react-i18next';

const LanguageTest = () => {
  const { t, i18n } = useTranslation();

  return (
    <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg mb-4">
      <h3 className="text-lg font-semibold text-blue-900 mb-2">
        Language Test Component
      </h3>
      <div className="space-y-2 text-sm">
        <p><strong>Current Language:</strong> {i18n.language}</p>
        <p><strong>French Test:</strong> {t('common.loading')}</p>
        <p><strong>ADF List Title:</strong> {t('adfList.title')}</p>
        <p><strong>Error Message:</strong> {t('common.error')}</p>
        <p><strong>Refresh Button:</strong> {t('common.refresh')}</p>
      </div>
    </div>
  );
};

export default LanguageTest; 
import React from 'react';
import { useTranslation } from 'react-i18next';
import { UserX, Construction } from 'lucide-react';

const InactiveManagement = () => {
  const { t } = useTranslation();

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center">
            <div className="p-2 bg-orange-100 rounded-lg mr-4">
              <UserX size={24} className="text-orange-600" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-gray-900">{t('inactiveManagement.title')}</h1>
              <p className="text-gray-600 mt-1">{t('inactiveManagement.subtitle')}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="bg-white rounded-lg border border-gray-200 p-12 text-center">
          <Construction size={64} className="mx-auto text-gray-400 mb-4" />
          <h2 className="text-xl font-semibold text-gray-900 mb-2">
            {t('common.comingSoon')}
          </h2>
          <p className="text-gray-600 max-w-md mx-auto">
            {t('inactiveManagement.placeholder')}
          </p>
        </div>
      </div>
    </div>
  );
};

export default InactiveManagement;

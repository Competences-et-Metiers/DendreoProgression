import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { UserCircle, Lock, Eye, EyeOff, CheckCircle, AlertCircle } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import api from '../api';

const Account = () => {
  const { t } = useTranslation();
  const { user } = useAuth();
  const [passwordForm, setPasswordForm] = useState({
    current_password: '',
    new_password: '',
    confirm_password: ''
  });
  const [showPasswords, setShowPasswords] = useState({
    current: false,
    new: false,
    confirm: false
  });
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState(null);

  const handlePasswordChange = async (e) => {
    e.preventDefault();
    setMessage(null);

    // Validation
    if (passwordForm.new_password !== passwordForm.confirm_password) {
      setMessage({ type: 'error', text: t('account.passwordMismatch') });
      return;
    }

    if (passwordForm.new_password.length < 6) {
      setMessage({ type: 'error', text: t('account.passwordTooShort') });
      return;
    }

    setLoading(true);

    try {
      await api.put('/auth/change-password', {
        current_password: passwordForm.current_password,
        new_password: passwordForm.new_password
      });

      setMessage({ type: 'success', text: t('account.passwordChangeSuccess') });
      setPasswordForm({
        current_password: '',
        new_password: '',
        confirm_password: ''
      });
    } catch (error) {
      const errorMessage = error.response?.data?.detail || t('account.passwordChangeError');
      setMessage({ type: 'error', text: errorMessage });
    } finally {
      setLoading(false);
    }
  };

  const togglePasswordVisibility = (field) => {
    setShowPasswords(prev => ({
      ...prev,
      [field]: !prev[field]
    }));
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center">
            <div className="p-2 bg-primary-100 rounded-lg mr-4">
              <UserCircle size={24} className="text-primary-600" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-gray-900">{t('account.title')}</h1>
              <p className="text-gray-600 mt-1">{t('account.subtitle')}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* User Info Card */}
        <div className="bg-white rounded-lg border border-gray-200 p-6 mb-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">
            {t('account.userInformation')}
          </h2>
          <div className="space-y-3">
            <div className="flex items-center">
              <span className="text-gray-600 w-32">{t('account.username')}:</span>
              <span className="text-gray-900 font-medium">{user?.username || '-'}</span>
            </div>
            <div className="flex items-center">
              <span className="text-gray-600 w-32">{t('account.email')}:</span>
              <span className="text-gray-900 font-medium">{user?.email || '-'}</span>
            </div>
          </div>
        </div>

        {/* Change Password Card */}
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <div className="flex items-center mb-4">
            <Lock size={20} className="text-gray-600 mr-2" />
            <h2 className="text-lg font-semibold text-gray-900">
              {t('account.changePassword')}
            </h2>
          </div>

          {message && (
            <div
              className={`mb-4 p-4 rounded-lg flex items-start ${
                message.type === 'success'
                  ? 'bg-green-50 text-green-800 border border-green-200'
                  : 'bg-red-50 text-red-800 border border-red-200'
              }`}
            >
              {message.type === 'success' ? (
                <CheckCircle size={20} className="mr-2 flex-shrink-0 mt-0.5" />
              ) : (
                <AlertCircle size={20} className="mr-2 flex-shrink-0 mt-0.5" />
              )}
              <span>{message.text}</span>
            </div>
          )}

          <form onSubmit={handlePasswordChange} className="space-y-4">
            {/* Current Password */}
            <div>
              <label htmlFor="current_password" className="block text-sm font-medium text-gray-700 mb-1">
                {t('account.currentPassword')}
              </label>
              <div className="relative">
                <input
                  type={showPasswords.current ? 'text' : 'password'}
                  id="current_password"
                  value={passwordForm.current_password}
                  onChange={(e) =>
                    setPasswordForm({ ...passwordForm, current_password: e.target.value })
                  }
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent pr-10"
                  required
                />
                <button
                  type="button"
                  onClick={() => togglePasswordVisibility('current')}
                  className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-700"
                >
                  {showPasswords.current ? <EyeOff size={20} /> : <Eye size={20} />}
                </button>
              </div>
            </div>

            {/* New Password */}
            <div>
              <label htmlFor="new_password" className="block text-sm font-medium text-gray-700 mb-1">
                {t('account.newPassword')}
              </label>
              <div className="relative">
                <input
                  type={showPasswords.new ? 'text' : 'password'}
                  id="new_password"
                  value={passwordForm.new_password}
                  onChange={(e) =>
                    setPasswordForm({ ...passwordForm, new_password: e.target.value })
                  }
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent pr-10"
                  required
                  minLength={6}
                />
                <button
                  type="button"
                  onClick={() => togglePasswordVisibility('new')}
                  className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-700"
                >
                  {showPasswords.new ? <EyeOff size={20} /> : <Eye size={20} />}
                </button>
              </div>
              <p className="text-sm text-gray-500 mt-1">{t('account.passwordRequirements')}</p>
            </div>

            {/* Confirm Password */}
            <div>
              <label htmlFor="confirm_password" className="block text-sm font-medium text-gray-700 mb-1">
                {t('account.confirmPassword')}
              </label>
              <div className="relative">
                <input
                  type={showPasswords.confirm ? 'text' : 'password'}
                  id="confirm_password"
                  value={passwordForm.confirm_password}
                  onChange={(e) =>
                    setPasswordForm({ ...passwordForm, confirm_password: e.target.value })
                  }
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent pr-10"
                  required
                />
                <button
                  type="button"
                  onClick={() => togglePasswordVisibility('confirm')}
                  className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-700"
                >
                  {showPasswords.confirm ? <EyeOff size={20} /> : <Eye size={20} />}
                </button>
              </div>
            </div>

            {/* Submit Button */}
            <div className="pt-2">
              <button
                type="submit"
                disabled={loading}
                className="w-full bg-primary-600 text-white px-4 py-2 rounded-lg hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                {loading ? t('account.changing') : t('account.changePasswordButton')}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default Account;

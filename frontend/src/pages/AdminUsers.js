import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  UserCog,
  Loader2,
  Search,
  ShieldCheck,
  RotateCcw,
  CheckCircle2,
  XCircle,
} from 'lucide-react';
import { adminService } from '../services/admin';
import { queryKeys } from '../queryClient';
import { useAuth } from '../contexts/AuthContext';

const ROLES = ['admin', 'manager', 'billing', 'user'];

const ROLE_PILL = {
  admin: 'bg-purple-50 dark:bg-purple-900/20 text-purple-700 dark:text-purple-400 border-purple-200 dark:border-purple-800',
  manager: 'bg-blue-50 dark:bg-blue-900/20 text-blue-700 dark:text-blue-400 border-blue-200 dark:border-blue-800',
  billing: 'bg-orange-50 dark:bg-orange-900/20 text-orange-700 dark:text-orange-400 border-orange-200 dark:border-orange-800',
  user: 'bg-gray-100 dark:bg-slate-700 text-gray-600 dark:text-gray-400 border-gray-300 dark:border-slate-600',
};

const AdminUsers = () => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const { user: currentUser } = useAuth();
  const [search, setSearch] = useState('');
  const [error, setError] = useState(null);
  const [pendingId, setPendingId] = useState(null);

  const { data: users = [], isLoading } = useQuery({
    queryKey: queryKeys.adminUsers,
    queryFn: adminService.getUsers,
    staleTime: 30000,
  });

  const mutation = useMutation({
    mutationFn: ({ userId, payload }) => adminService.updateUser(userId, payload),
    onMutate: ({ userId }) => {
      setError(null);
      setPendingId(userId);
    },
    onError: (err) => setError(err?.response?.data?.detail || t('adminUsers.updateError')),
    onSettled: () => {
      setPendingId(null);
      queryClient.invalidateQueries({ queryKey: queryKeys.adminUsers });
    },
  });

  const term = search.trim().toLowerCase();
  const visibleUsers = term
    ? users.filter((u) =>
        [u.username, u.display_name, u.email].some((f) => f && f.toLowerCase().includes(term))
      )
    : users;

  return (
    <div className="p-6 space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900 dark:text-white flex items-center gap-2">
            <UserCog size={24} className="text-primary-600" />
            {t('adminUsers.title')}
          </h1>
          <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">{t('adminUsers.subtitle')}</p>
        </div>
        <div className="relative">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder={t('adminUsers.searchPlaceholder')}
            className="pl-9 pr-3 py-2 w-64 text-sm rounded-lg border border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-gray-900 dark:text-white"
          />
        </div>
      </div>

      {error && (
        <div className="rounded-lg border border-red-200 dark:border-red-800 bg-red-50 dark:bg-red-900/20 px-4 py-3 text-sm text-red-700 dark:text-red-400">
          {error}
        </div>
      )}

      <div className="bg-white dark:bg-slate-800 rounded-lg border border-gray-200 dark:border-slate-700 overflow-hidden">
        {isLoading ? (
          <div className="py-16 flex justify-center">
            <Loader2 className="w-6 h-6 animate-spin text-primary-600" />
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 dark:bg-slate-700/50 text-gray-600 dark:text-gray-400">
                <tr>
                  <th className="text-left font-medium px-4 py-3">{t('adminUsers.user')}</th>
                  <th className="text-left font-medium px-4 py-3">{t('adminUsers.provider')}</th>
                  <th className="text-left font-medium px-4 py-3">{t('adminUsers.role')}</th>
                  <th className="text-left font-medium px-4 py-3">{t('adminUsers.roleSource')}</th>
                  <th className="text-left font-medium px-4 py-3">{t('adminUsers.status')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 dark:divide-slate-700">
                {visibleUsers.map((u) => {
                  const isSelf = u.id === currentUser?.id;
                  const busy = pendingId === u.id && mutation.isPending;
                  return (
                    <tr key={u.id} className="hover:bg-gray-50 dark:hover:bg-slate-700/50">
                      <td className="px-4 py-3">
                        <div className="font-medium text-gray-900 dark:text-white">
                          {u.display_name || u.username}
                          {isSelf && (
                            <span className="ml-2 text-xs text-gray-400">{t('adminUsers.you')}</span>
                          )}
                        </div>
                        <div className="text-xs text-gray-500 dark:text-gray-400">
                          {u.email || u.username}
                        </div>
                      </td>
                      <td className="px-4 py-3 text-gray-600 dark:text-gray-400">
                        {u.auth_provider === 'microsoft' ? 'Microsoft 365' : t('adminUsers.local')}
                      </td>
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-2">
                          <span
                            className={`inline-flex items-center px-2 py-0.5 rounded border text-xs font-medium ${ROLE_PILL[u.role] || ROLE_PILL.user}`}
                          >
                            {t(`adminUsers.roles.${u.role}`, u.role)}
                          </span>
                          <select
                            value={u.role}
                            disabled={isSelf || busy}
                            onChange={(e) =>
                              mutation.mutate({ userId: u.id, payload: { role: e.target.value } })
                            }
                            title={isSelf ? t('adminUsers.cannotEditSelf') : undefined}
                            className="text-xs rounded border border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-gray-900 dark:text-white px-2 py-1 disabled:opacity-50 disabled:cursor-not-allowed"
                          >
                            {ROLES.map((r) => (
                              <option key={r} value={r}>
                                {t(`adminUsers.roles.${r}`, r)}
                              </option>
                            ))}
                          </select>
                          {busy && <Loader2 size={14} className="animate-spin text-primary-600" />}
                        </div>
                      </td>
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-2">
                          <span
                            className="inline-flex items-center gap-1 text-xs text-gray-600 dark:text-gray-400"
                            title={
                              u.role_source === 'manual'
                                ? t('adminUsers.manualHint')
                                : t('adminUsers.groupHint')
                            }
                          >
                            <ShieldCheck size={12} />
                            {u.role_source === 'manual'
                              ? t('adminUsers.sourceManual')
                              : t('adminUsers.sourceGroup')}
                          </span>
                          {u.role_source === 'manual' && !isSelf && (
                            <button
                              onClick={() =>
                                mutation.mutate({
                                  userId: u.id,
                                  payload: { reset_role_to_group: true },
                                })
                              }
                              disabled={busy}
                              title={t('adminUsers.resetToGroup')}
                              className="p-1 rounded text-gray-400 hover:text-primary-600 hover:bg-gray-100 dark:hover:bg-slate-700 disabled:opacity-50"
                            >
                              <RotateCcw size={13} />
                            </button>
                          )}
                        </div>
                      </td>
                      <td className="px-4 py-3">
                        <button
                          onClick={() =>
                            mutation.mutate({ userId: u.id, payload: { is_active: !u.is_active } })
                          }
                          disabled={isSelf || busy}
                          title={isSelf ? t('adminUsers.cannotEditSelf') : t('adminUsers.toggleActive')}
                          className={`inline-flex items-center gap-1.5 text-xs px-2 py-1 rounded border disabled:opacity-50 disabled:cursor-not-allowed ${
                            u.is_active
                              ? 'bg-green-50 dark:bg-green-900/20 text-green-700 dark:text-green-400 border-green-200 dark:border-green-800'
                              : 'bg-gray-100 dark:bg-slate-700 text-gray-500 dark:text-gray-400 border-gray-300 dark:border-slate-600'
                          }`}
                        >
                          {u.is_active ? <CheckCircle2 size={12} /> : <XCircle size={12} />}
                          {u.is_active ? t('adminUsers.active') : t('adminUsers.inactive')}
                        </button>
                      </td>
                    </tr>
                  );
                })}
                {visibleUsers.length === 0 && (
                  <tr>
                    <td colSpan={5} className="px-4 py-10 text-center text-gray-500 dark:text-gray-400">
                      {t('adminUsers.noUsers')}
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};

export default AdminUsers;

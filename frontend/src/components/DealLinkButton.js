import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link2, X, ExternalLink, Loader, ChevronDown } from 'lucide-react';
import { useHubspotDeals, useLinkDeal, useUnlinkDeal } from '../hooks/useQuery';

const DealLinkButton = ({ participantId, idActionFormation, email, hubspotDeal }) => {
  const { t } = useTranslation();
  const [showDropdown, setShowDropdown] = useState(false);

  // Fetch deals only when dropdown is opened
  const {
    data: dealsData,
    isLoading: dealsLoading,
    error: dealsError,
  } = useHubspotDeals(email, showDropdown);

  const linkMutation = useLinkDeal();
  const unlinkMutation = useUnlinkDeal();

  const isLinked = !!hubspotDeal?.deal_id;

  const handleLink = (deal) => {
    linkMutation.mutate({
      participantId,
      idActionFormation,
      dealId: deal.id,
    });
    setShowDropdown(false);
  };

  const handleUnlink = (e) => {
    e.stopPropagation();
    unlinkMutation.mutate({ participantId, idActionFormation });
  };

  const formatAmount = (amount) => {
    if (!amount) return '';
    const num = parseFloat(amount);
    if (isNaN(num)) return amount;
    return new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'EUR' }).format(num);
  };

  if (isLinked) {
    const linkedDealUrl = `https://app-eu1.hubspot.com/contacts/25868618/record/0-3/${hubspotDeal.deal_id}`;
    return (
      <div className="group/deal inline-flex items-center">
        <a
          href={linkedDealUrl}
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-orange-50 dark:bg-orange-900/20 text-orange-700 dark:text-orange-400 border border-orange-200 dark:border-orange-800 hover:bg-orange-100 dark:hover:bg-orange-900/30 transition-colors"
          title={t('hubspotDeal.openDeal')}
        >
          <ExternalLink size={10} className="mr-1" />
          {t('hubspotDeal.linkedLabel', 'HubSpot Transac')}
        </a>
        <button
          onClick={handleUnlink}
          disabled={unlinkMutation.isPending}
          className="ml-1 opacity-0 group-hover/deal:opacity-100 p-0.5 text-gray-400 dark:text-gray-500 hover:text-red-500 transition-all"
          title={t('hubspotDeal.unlink')}
        >
          {unlinkMutation.isPending ? (
            <Loader size={12} className="animate-spin" />
          ) : (
            <X size={12} />
          )}
        </button>
      </div>
    );
  }

  return (
    <div className="relative inline-block">
      <button
        onClick={() => setShowDropdown(!showDropdown)}
        disabled={!email || linkMutation.isPending}
        className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium text-gray-500 dark:text-gray-400 bg-gray-50 dark:bg-slate-900 border border-gray-200 dark:border-slate-700 hover:bg-gray-100 dark:hover:bg-slate-700 hover:text-gray-700 dark:hover:text-gray-300 transition-colors disabled:opacity-30 disabled:cursor-not-allowed"
        title={!email ? t('hubspotDeal.noEmail') : t('hubspotDeal.linkDeal')}
      >
        {linkMutation.isPending ? (
          <Loader size={10} className="mr-1 animate-spin" />
        ) : (
          <Link2 size={10} className="mr-1" />
        )}
        {t('hubspotDeal.linkDeal')}
        {!linkMutation.isPending && <ChevronDown size={10} className="ml-1" />}
      </button>

      {showDropdown && (
        <>
          <div className="fixed inset-0 z-10" onClick={() => setShowDropdown(false)} />
          <div className="absolute right-0 mt-1 w-72 bg-white dark:bg-slate-800 rounded-lg shadow-lg dark:shadow-slate-900/50 border border-gray-200 dark:border-slate-700 z-20 max-h-60 overflow-y-auto">
            {dealsLoading && (
              <div className="p-4 text-center text-sm text-gray-500 dark:text-gray-400">
                <Loader size={16} className="animate-spin inline mr-2" />
                {t('common.loading')}
              </div>
            )}
            {dealsError && (
              <div className="p-4 text-center text-sm text-red-500">
                {t('hubspotDeal.fetchError')}
              </div>
            )}
            {dealsData && dealsData.deals?.length === 0 && (
              <div className="p-4 text-center text-sm text-gray-500 dark:text-gray-400">
                {t('hubspotDeal.noDeals')}
              </div>
            )}
            {dealsData?.deals?.map((deal) => (
              <div
                key={deal.id}
                className="px-4 py-2.5 hover:bg-gray-50 dark:hover:bg-slate-700 border-b border-gray-100 dark:border-slate-700 last:border-b-0 transition-colors"
              >
                <button
                  onClick={() => handleLink(deal)}
                  disabled={linkMutation.isPending}
                  className="w-full text-left disabled:opacity-50"
                >
                  <div className="text-sm font-medium text-gray-900 dark:text-white truncate">
                    {deal.dealname || `Deal #${deal.id}`}
                  </div>
                  {deal.formation_detaillee && (
                    <div className="text-xs text-gray-600 dark:text-gray-300 mt-0.5 truncate">
                      {deal.formation_detaillee}
                    </div>
                  )}
                  {deal.amount && (
                    <div className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                      {formatAmount(deal.amount)}
                    </div>
                  )}
                  {(deal.edof_date_debut || deal.edof_date_fin) && (
                    <div className="text-xs text-teal-700 dark:text-teal-400 mt-0.5">
                      EDOF: {deal.edof_date_debut ? new Date(deal.edof_date_debut).toLocaleDateString('fr-FR') : '?'} → {deal.edof_date_fin ? new Date(deal.edof_date_fin).toLocaleDateString('fr-FR') : '?'}
                    </div>
                  )}
                </button>
                <a
                  href={`https://app-eu1.hubspot.com/contacts/25868618/record/0-3/${deal.id}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  onClick={(e) => e.stopPropagation()}
                  className="inline-flex items-center gap-1 mt-1.5 text-xs text-primary-600 dark:text-primary-400 hover:underline"
                >
                  <ExternalLink size={11} />
                  {t('hubspotDeal.viewOnHubspot', 'Voir sur HubSpot')}
                </a>
              </div>
            ))}
          </div>
        </>
      )}
    </div>
  );
};

export default DealLinkButton;

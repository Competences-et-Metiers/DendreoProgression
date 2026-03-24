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
    return (
      <div className="group/deal inline-flex items-center">
        <a
          href={hubspotDeal.deal_url}
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-orange-50 text-orange-700 border border-orange-200 hover:bg-orange-100 transition-colors"
          title={t('hubspotDeal.openDeal')}
        >
          <ExternalLink size={10} className="mr-1" />
          HubSpot Deal
        </a>
        <button
          onClick={handleUnlink}
          disabled={unlinkMutation.isPending}
          className="ml-1 opacity-0 group-hover/deal:opacity-100 p-0.5 text-gray-400 hover:text-red-500 transition-all"
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
        disabled={!email}
        className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium text-gray-500 bg-gray-50 border border-gray-200 hover:bg-gray-100 hover:text-gray-700 transition-colors disabled:opacity-30"
        title={!email ? t('hubspotDeal.noEmail') : t('hubspotDeal.linkDeal')}
      >
        <Link2 size={10} className="mr-1" />
        {t('hubspotDeal.linkDeal')}
        <ChevronDown size={10} className="ml-1" />
      </button>

      {showDropdown && (
        <>
          <div className="fixed inset-0 z-10" onClick={() => setShowDropdown(false)} />
          <div className="absolute right-0 mt-1 w-72 bg-white rounded-lg shadow-lg border border-gray-200 z-20 max-h-60 overflow-y-auto">
            {dealsLoading && (
              <div className="p-4 text-center text-sm text-gray-500">
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
              <div className="p-4 text-center text-sm text-gray-500">
                {t('hubspotDeal.noDeals')}
              </div>
            )}
            {dealsData?.deals?.map((deal) => (
              <button
                key={deal.id}
                onClick={() => handleLink(deal)}
                disabled={linkMutation.isPending}
                className="w-full px-4 py-2.5 text-left hover:bg-gray-50 border-b border-gray-100 last:border-b-0 transition-colors"
              >
                <div className="text-sm font-medium text-gray-900 truncate">
                  {deal.dealname || `Deal #${deal.id}`}
                </div>
                {deal.amount && (
                  <div className="text-xs text-gray-500 mt-0.5">
                    {formatAmount(deal.amount)}
                  </div>
                )}
              </button>
            ))}
          </div>
        </>
      )}
    </div>
  );
};

export default DealLinkButton;

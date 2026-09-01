import React from 'react';
import { useTranslation } from 'react-i18next';
import { Euro, Landmark, Wallet, CreditCard, Receipt } from 'lucide-react';
import { getFacturationTone } from '../utils/billing';

const formatEUR = (value) => {
  if (value === null || value === undefined || value === '') return null;
  const num = parseFloat(value);
  if (isNaN(num)) return String(value);
  return new Intl.NumberFormat('fr-FR', {
    style: 'currency',
    currency: 'EUR',
    maximumFractionDigits: 2,
  }).format(num);
};

/**
 * Billing status and financial fields of the HubSpot deal linked to an ADF
 * enrollment. Values are mirrored from HubSpot (see ParticipantHubspotData) —
 * fields the deal doesn't carry are simply omitted.
 */
const DealFinancials = ({ deal }) => {
  const { t } = useTranslation();

  if (!deal) return null;

  const items = [
    { key: 'amount', icon: Euro, label: t('hubspotDeal.amount'), value: formatEUR(deal.amount) },
    {
      key: 'financement',
      icon: Landmark,
      label: t('hubspotDeal.typeDeFinancement'),
      value: deal.type_de_financement || null,
    },
    { key: 'pec', icon: Wallet, label: t('hubspotDeal.montantPec'), value: formatEUR(deal.montant_pec) },
    { key: 'rac', icon: CreditCard, label: t('hubspotDeal.montantRac'), value: formatEUR(deal.montant_rac) },
  ].filter((i) => i.value !== null);

  if (items.length === 0 && !deal.facturation) return null;

  return (
    <div className="mb-3 flex flex-wrap items-center gap-2">
      {deal.facturation && (
        <div
          className={`inline-flex items-center gap-1.5 rounded-md border px-2 py-1 text-xs ${getFacturationTone(deal.facturation)}`}
          title={`${t('hubspotDeal.facturation')} (HubSpot)`}
        >
          <Receipt size={12} className="shrink-0" />
          <span className="font-medium">{deal.facturation}</span>
        </div>
      )}
      {items.map(({ key, icon: Icon, label, value }) => (
        <div
          key={key}
          className="inline-flex items-center gap-1.5 rounded-md border border-orange-200 dark:border-orange-900/50 bg-orange-50 dark:bg-orange-900/20 px-2 py-1 text-xs"
          title={`${label} (HubSpot)`}
        >
          <Icon size={12} className="text-orange-500 dark:text-orange-400 shrink-0" />
          <span className="text-gray-500 dark:text-gray-400">{label}</span>
          <span className="font-medium text-gray-900 dark:text-white">{value}</span>
        </div>
      ))}
    </div>
  );
};

export default DealFinancials;

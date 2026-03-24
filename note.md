# Notes & TODO

## TODO
- **Deal link → LAP property**: When a deal is linked via POST `/api/hubspot/link-deal`, also write the deal ID to the ADF's LAP record property in Dendreo
- **Rename "deal" to "transaction"**: All user-facing text (UI labels, i18n keys) should use "transaction" instead of "deal" for French consistency. Affects `frontend/src/i18n/locales/fr.json` and `en.json` (`hubspotDeal` section), and `DealLinkButton.js` display text.

## Where deal linking data is stored
- **Database table**: `participant_hubspot_data` — columns `c_id_transaction_hubspot`, `c_url_transaction_hubspot`, `is_manual_link`
- **Model**: `back/app/models/models.py` → `ParticipantHubspotData` (unique constraint on `participant_id` + `id_action_formation`)
- **API endpoints**: `back/app/api/routes/hubspot.py` — GET `/deals/{email}`, POST `/link-deal`, POST `/unlink-deal`
- **HubSpot client method**: `back/app/services/hubspot_client.py` → `get_deals_for_contact(email)`
- **Frontend component**: `frontend/src/components/DealLinkButton.js`
- **Frontend hooks**: `frontend/src/hooks/useQuery.js` → `useHubspotDeals`, `useLinkDeal`, `useUnlinkDeal`
- **Frontend API**: `frontend/src/services/api.js` → `getHubspotDeals`, `linkDeal`, `unlinkDeal`
- **i18n**: `frontend/src/i18n/locales/fr.json` and `en.json` → `hubspotDeal` section
- **Sync guard**: `back/app/services/dendreo_sync.py` — two paths (~line 321, ~line 880) skip overwrite when `is_manual_link=True`

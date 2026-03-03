import { PublicClientApplication, LogLevel } from '@azure/msal-browser';

const clientId = process.env.REACT_APP_AZURE_AD_CLIENT_ID || '';
const tenantId = process.env.REACT_APP_AZURE_AD_TENANT_ID || '';

const msalConfig = {
  auth: {
    clientId,
    authority: `https://login.microsoftonline.com/${tenantId || 'common'}`,
    redirectUri: process.env.REACT_APP_AZURE_AD_REDIRECT_URI || window.location.origin + '/login',
    postLogoutRedirectUri: window.location.origin + '/login',
  },
  cache: {
    cacheLocation: 'sessionStorage',
    storeAuthStateInCookie: false,
  },
  system: {
    loggerOptions: {
      logLevel: LogLevel.Warning,
    },
  },
};

export const loginRequest = {
  scopes: ['openid', 'profile', 'email'],
};

// Only create MSAL instance if client ID is configured and crypto API is available
let _msalInstance = null;
if (clientId) {
  try {
    _msalInstance = new PublicClientApplication(msalConfig);
  } catch (e) {
    console.warn('MSAL initialization failed (likely insecure context - crypto API unavailable):', e.message);
  }
}
export const msalInstance = _msalInstance;

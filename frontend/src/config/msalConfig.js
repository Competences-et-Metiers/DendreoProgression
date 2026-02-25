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

// Only create MSAL instance if client ID is configured
export const msalInstance = clientId
  ? new PublicClientApplication(msalConfig)
  : null;

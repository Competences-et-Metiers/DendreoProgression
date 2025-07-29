import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import LanguageDetector from 'i18next-browser-languagedetector';

// Import translation files
import enTranslations from './locales/en.json';
import frTranslations from './locales/fr.json';

const resources = {
  en: {
    translation: enTranslations
  },
  fr: {
    translation: frTranslations
  }
};

i18n
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    resources,
    fallbackLng: 'fr', // French as default
    debug: process.env.NODE_ENV === 'development',
    
    interpolation: {
      escapeValue: false, // React already escapes values
    },
    
    detection: {
      // Order and from where user language should be detected
      order: ['localStorage', 'navigator', 'htmlTag'],
      
      // Keys or params to lookup language from
      lookupLocalStorage: 'i18nextLng',
      lookupFromPathIndex: 0,
      lookupFromSubdomainIndex: 0,
      
      // Cache user language on
      caches: ['localStorage'],
      excludeCacheFor: ['cimode'], // Languages to not persist (cookie, localStorage)
      
      // Optional expire and domain for set cookie
      cookieExpirationDate: new Date(),
      cookieDomain: 'myDomain',
      cookieSecure: false, // Enable if using https
      
      // Optional htmlTag with lang attribute, the default is:
      htmlTag: document.documentElement,
      
      // Optional set cookie options, the default is:
      cookieOptions: { path: '/', sameSite: 'strict' }
    },
    
    react: {
      useSuspense: false
    }
  });

export default i18n; 
import { useEffect } from 'react';
import { useTranslation } from 'react-i18next';

export const useLanguageEffect = () => {
  const { i18n } = useTranslation();

  useEffect(() => {
    // Update the HTML lang attribute when language changes
    document.documentElement.lang = i18n.language;
    
    // Also update the title if needed
    const title = document.title;
    if (title.includes('Dashboard')) {
      document.title = i18n.language === 'fr' 
        ? 'Tableau de bord de progression Dendreo'
        : 'Dendreo Progression Dashboard';
    }
  }, [i18n.language]);

  return i18n.language;
}; 
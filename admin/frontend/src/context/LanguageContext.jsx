import { createContext, useContext, useState, useEffect } from 'react';
import { translations } from '../translations/translations';

const LanguageContext = createContext();

export function LanguageProvider({ children }) {
  const [lang, setLang] = useState(() => {
    return localStorage.getItem('admin_app_language') || 'en';
  });

  useEffect(() => {
    localStorage.setItem('admin_app_language', lang);
  }, [lang]);

  const changeLanguage = (newLang) => {
    setLang(newLang);
  };

  const t = (key) => {
    const dict = translations[lang] || translations['en'];
    return dict[key] || translations['en'][key] || key;
  };

  return (
    <LanguageContext.Provider value={{ lang, changeLanguage, t }}>
      {children}
    </LanguageContext.Provider>
  );
}

export function useLanguage() {
  const context = useContext(LanguageContext);
  if (!context) {
    throw new Error('useLanguage must be used within a LanguageProvider');
  }
  return context;
}

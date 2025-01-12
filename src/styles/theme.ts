export type Theme = 'light' | 'dark';

export const lightTheme = {
  background: '#ffffff',
  text: '#1a1a1a',
  primary: '#007AFF',
  secondary: '#5856D6',
  accent: '#FF2D55',
  surface: '#f5f5f5',
  border: '#e0e0e0'
};

export const darkTheme = {
  background: '#1a1a1a',
  text: '#ffffff',
  primary: '#0A84FF',
  secondary: '#5E5CE6',
  accent: '#FF375F',
  surface: '#2c2c2c',
  border: '#404040'
};

export const applyTheme = (theme: Theme) => {
  const themeObj = theme === 'light' ? lightTheme : darkTheme;
  Object.entries(themeObj).forEach(([property, value]) => {
    document.documentElement.style.setProperty(`--${property}`, value);
  });
};
